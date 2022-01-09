load("@debian_package_list//:packages_db.bzl", "PACKAGES_DB")
load("@rules_deb//deb/internal:virtual_filesystem.bzl", "write_path_to_label_mapping")
load("@rules_deb//deb/internal:packages_parser.bzl", "sanitize_package_name")
load("@rules_deb//deb/internal:ldconfig.bzl", "create_shlibs_symlinks")

def _remove_extension(path, extension):
    """ Removes the extension from a path. """
    return path[:-len(extension)] if path.endswith(extension) else path

def lib_info(static_libs, shared_libs):
    """ Returns a list of library information for the current package.

    Libraries usually ship with two versions a static library and a shared both
    of which are located in the same directory with different extensions. This
    function returns a list of libraries with both of the shared and static
    versions of the library, or either if only one link mode is available.

    Args:
        static_libs: A list of static library paths.
        shared_libs: A list of shared library paths.

    Returns:
        A list of dicts in the format
        [{'static': static_path, 'shared': shared_path},...].
    """
    lib_info = {_remove_extension(lib, ".a"): {"static": lib, "shared": None} for lib in static_libs}
    for shared_lib in shared_libs:
        if _remove_extension(shared_lib, ".so") in lib_info:
            lib_info[_remove_extension(shared_lib, ".so")]["shared"] = shared_lib
        else:
            lib_info[_remove_extension(shared_lib, ".so")] = {"static": None, "shared": shared_lib}

    return lib_info.values()

def _build_cc_deps_info(repository_ctx, packages_db, break_deps):
    """ Builds the C/C++ dependencies info. """

    # Starlark doesn't support sets, so we can instead use a dict to
    # deduplicate.
    return {
        "@{dep}//:cc_{dep}".format(dep = dep.name): None
        for dep in packages_db[repository_ctx.name].depends
        if dep.name not in [
            sanitize_package_name(dep)
            for dep in break_deps
        ]
    }.keys()

def _build_package_info(repository_ctx, break_deps):
    return {
        "name": repository_ctx.name,
        "cc_deps": _build_cc_deps_info(repository_ctx, PACKAGES_DB, break_deps),
    }

def _file_exists(repository_ctx, path):
    return repository_ctx.execute(["test", "-f", path]).return_code == 0

def _deb_archive_base_impl(repository_ctx):
    """ Builds the base Debian archive. """

    break_deps = [
        sanitize_package_name(dep)
        for dep in repository_ctx.attr.break_deps
    ]
    repository_ctx.download(
        url = repository_ctx.attr.url,
        sha256 = repository_ctx.attr.sha256,
        output = "package.deb",
    )
    repository_ctx.report_progress("Extracting package.")
    result = repository_ctx.execute(["ar", "x", "package.deb"])

    repository_ctx.execute(["rm", "package.deb"])

    for archive in ["data.tar.xz", "control.tar.gz"]:
        # Only extract if the archive exists.
        if _file_exists(repository_ctx, archive):
            repository_ctx.extract(archive)
            repository_ctx.execute(["rm", archive])

    if repository_ctx.attr.build_file_content and \
       repository_ctx.attr.build_file:
        fail("Specify either build_file_content or build_file, not both.")

    if repository_ctx.attr.build_file_content:
        repository_ctx.file(
            "BUILD.bazel",
            repository_ctx.attr.build_file_content,
        )
    else:
        repository_ctx.symlink(repository_ctx.attr.build_file, "BUILD.bazel")

    repository_ctx.report_progress("Creating package info.")
    repository_ctx.file(
        "package_info.bzl",
        "INFO = " + str(_build_package_info(
            repository_ctx,
            break_deps,
        )),
    )
    create_shlibs_symlinks(repository_ctx)

    write_path_to_label_mapping(
        repository_ctx,
        PACKAGES_DB[repository_ctx.name].depends,
        break_deps,
    )

deb_archive = repository_rule(
    implementation = _deb_archive_base_impl,
    attrs = {
        "url": attr.string(
            mandatory = True,
            doc = "The URL of the package to download.",
        ),
        "sha256": attr.string(
            doc = "The SHA256 of the package to download.",
        ),
        "build_file": attr.label(
            doc = "The BUILD file to use for this package.",
        ),
        "build_file_content": attr.string(
            doc = "The content of the BUILD file to use, if 'build_file' is not specified.",
        ),
        "break_deps": attr.string_list(
            doc = "A list of dependencies to break. e.g. libc is provided by the toolchain, but is often depended on by other packages.",
        ),
    },
)
