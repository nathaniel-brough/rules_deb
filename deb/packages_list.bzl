load(
    "//deb/internal:packages_parser.bzl",
    "deb_packages_dict",
)
load(
    "//deb/internal:deb_repository_init_builder.bzl",
    "generate_deb_repository_init_script",
)

def _deb_repositories_impl(repository_ctx):
    repository_ctx.download(
        url = "{url}/dists/{dist}/{channel}/binary-{arch}/Packages.gz".format(
            url = repository_ctx.attr.url,
            dist = repository_ctx.attr.dist,
            channel = repository_ctx.attr.channel,
            arch = repository_ctx.attr.arch,
        ),
        output = "Packages.gz",
        sha256 = repository_ctx.attr.package_list_sha256,
    )
    if "snapshot" not in repository_ctx.attr.url:
        print("WARNING: This repository is not a snapshot, it will likely go \
out of date very quickly. It is strongly recommended to use one of the \
snapshots available at https://snapshot.debian.org")

    repository_ctx.report_progress("Extracting package list")
    repository_ctx.execute(["gunzip", "Packages.gz"])
    repository_ctx.execute(["rm", "Packages.gz"])

    repository_ctx.report_progress("Parsing package list")
    package_dict = deb_packages_dict(repository_ctx.read("Packages"))

    repository_ctx.report_progress(
        "Generating workspace files.",
    )
    repository_ctx.file(
        "deb_repository_init.bzl",
        generate_deb_repository_init_script(
            package_dict,
            repository_ctx.attr.url,
            "",
            repository_ctx.attr.break_deps,
        ),
    )
    repository_ctx.file(
        "packages_db.bzl",
        "PACKAGES_DB = " + str(package_dict),
    )

    repository_ctx.file("BUILD.bazel", "exports_files(glob(['**/*']))")

deb_repository = repository_rule(
    implementation = _deb_repositories_impl,
    attrs = {
        "url": attr.string(
            mandatory = True,
            doc = "The url of the deb archive.",
        ),
        "dist": attr.string(
            mandatory = True,
            doc = "The distribution of the deb archive. e.g. jessie.",
        ),
        "channel": attr.string(
            mandatory = True,
            doc = "The channel of the deb archive. e.g. main.",
        ),
        "arch": attr.string(
            mandatory = True,
            doc = "The architecture for the repository e.g. amd64.",
            default = "amd64",
        ),
        "package_list_sha256": attr.string(
            doc = "The sha256 of the package list. The package list can be \
found under the path {repo_url}/dists/{dist}/{channel}/binary-{arch}/Packages.gz",
        ),
        "break_deps": attr.string_list(
            default = [
                "libc6-x32",
                "libc6-pic",
                "libc6-i386",
                "libc6-dev-x32",
                "libc6-dev-i386",
                "libc6-dev",
                "libc6-dbg",
                "libc6",
                "libc6",
                "libgcc1",
                "libstdc++6",
                "libstdc++-4.9-dev",
                "libstdc++-4.9-dbg",
                "libstdc++-4.8-dev",
                "libstdc++-4.8-dbg",
                "libstdc++-5",
            ],
            doc = "List of packages that should be broken out of the dependency tree this is useful for excluding packages that are otherwise captured by the toolchain e.g. libc6, libgcc1 etc. Note that this attribute is transitively applied to all deb archives.",
        ),
    },
)
