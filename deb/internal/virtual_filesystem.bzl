""" When extracting debian packages, it is assumed that the it is 
overlayed on top of the root filesystem. However as we are extracting
each package to a seperate directory we must be able to produce a 
mapping between the package -> Bazel targets.
"""

def _remove_leading_relative_paths(paths):
    """ Removes the leading relative path from a path."""
    removed = []
    for path in paths:
        if path.startswith("./"):
            removed.append(path[2:])
        else:
            removed.append(path)
    return removed

def _path_to_target(package, path):
    """ Converts a path to a Bazel target. """
    return "@{package}//:{path}".format(package = package, path = path)

def _find_in_directory(repository_ctx, args):
    """ Finds the files in the given directory. """
    find_result = repository_ctx.execute(
        ["find"] + args,
    )
    if find_result.return_code != 0:
        fail("Failed to find files in directory: %s" % find_result.stderr)
    return _remove_leading_relative_paths(find_result.stdout.splitlines())

def _get_symlink_target(repository_ctx, path):
    """ Gets the target of a symlink. """
    readlink_result = repository_ctx.execute(
        ["realpath", "-m", "--relative-to=.", path],
    )
    if readlink_result.return_code != 0:
        fail("Failed to read symlink: %s" % readlink_result.stderr)
    return _remove_leading_relative_paths(
        [readlink_result.stdout.strip("\n")],
    )[0]

def _find_all_files_in_package(repository_ctx):
    """ Find all files in the package.

    Args:
      repository_ctx: The repository context.

    Returns:
        A dict containing valid files and broken symlinks.
    """

    # Find files and valid symlinks.
    valid_files = _find_in_directory(
        repository_ctx,
        [".", "-not", "-type", "d"],
    )

    # Find broken symlinks.
    broken_symlinks = _find_in_directory(
        repository_ctx,
        [".", "-type", "l", "-xtype", "l"],
    )

    broken_symlink_mapping = {
        path: _get_symlink_target(repository_ctx, path)
        for path in broken_symlinks
    }

    return {
        "valid_files": valid_files,
        "broken_symlinks": broken_symlink_mapping,
    }

def map_broken_symlinks_to_dependent_targets(
        broken_symlinks,  # {symlink_path: target_path}
        dependent_package_mapping):
    return {
        symlink_path: dependent_package_mapping.get(target_path, "@broken//dependency")
        for symlink_path, target_path in broken_symlinks.items()
    }

LOAD_TEMPLATE = \
    'load("{script_name}", {local_symbol_name} = "{symbol_name}")'

def _generate_load_statement(script_name, symbol_name, local_symbol_name):
    """ Generates a load statement. """
    return LOAD_TEMPLATE.format(
        script_name = script_name,
        symbol_name = symbol_name,
        local_symbol_name = local_symbol_name,
    )

VFS_TEMPLATE = """
# Repeated loads from dependencies, this should load dependent
# package files.
{loads}

load("@rules_deb//deb/internal:virtual_filesystem.bzl",
    "map_broken_symlinks_to_dependent_targets")

load("@bazel_skylib//lib:dicts.bzl", "dicts")

_BROKEN_SYMLINKS = {broken_symlinks}

# Combined files from dependencies.
_DEPENDANT_PACKAGE_FILES = dicts.add({dependant_package_files})

FILE_MAPPING__ = dicts.add({file_mapping},
    map_broken_symlinks_to_dependent_targets(
        _BROKEN_SYMLINKS, 
        _DEPENDANT_PACKAGE_FILES,
    )
)
SHARED_LIBS = {{f: t 
    for f, t in FILE_MAPPING__.items() 
    if f.endswith(".so")}}

# TODO(#3): Uncomment this when we have a way to deal with
# linking PIC and non-PIC static libs. e.g. we need to solve
# 'relocation R_X86_64_PC32 cannot be used against symbol'.
# linker errors.
# STATIC_LIBS = {{f: t 
#     for f, t in FILE_MAPPING__.items() 
#     if f.endswith(".a")}}
STATIC_LIBS ={{}} 

def deb_file(path):
    return FILE_MAPPING__.get(path, None)
"""

def _local_symbol_name(package_name):
    return package_name.replace(".", "_").replace("-", "_") + \
           "_FILE_MAPPING__"

def _create_dependency_load_statements(dependencies, break_deps):
    """ Creates a list of load statements for the given dependencies. """
    load_statements = []
    variable_names = []

    for dependency in dependencies:
        if _local_symbol_name(dependency.name) not in variable_names and \
           dependency.name not in break_deps:
            load_statements.append(_generate_load_statement(
                script_name = "@{dep_name}//:vfs.bzl".format(
                    dep_name = dependency.name,
                ),
                symbol_name = "FILE_MAPPING__",
                local_symbol_name = _local_symbol_name(dependency.name),
            ))
            variable_names.append(_local_symbol_name(dependency.name))
    return (load_statements, variable_names)

def generate_file_vfs_package_plugin(
        file_mapping,
        broken_symlinks,
        dependencies,
        break_deps):
    """ Generates a file vfs package plugin. 

    Generates a .bzl file that stores the mapping between
    paths->bazel_targets for the given package. Relative symlinks
    are broken by splitting the extraction of each package. Because of this we
    need to remap the broken symlinks to the correct target. This is done by
    looking up the 'symlink target' path in the target mapping of dependent
    packages.

    Args:
        file_mapping: A dict containing the mapping between paths and bazel
            targets.
        broken_symlinks: A dict containing the mapping between broken
            symlinks and their target.
        dependencies: A list of dependencies.
        break_deps: A list of dependencies to break.
    """
    load_statement_list, variable_names = \
        _create_dependency_load_statements(dependencies, break_deps)
    return VFS_TEMPLATE.format(
        loads = "\n".join(load_statement_list),
        broken_symlinks = str(broken_symlinks),
        dependant_package_files = ",\n".join(variable_names),
        file_mapping = str(file_mapping),
    )

def write_path_to_label_mapping(repository_ctx, package_deps, break_deps):
    """ Builds a mapping between each file in the package and a Bazel target

    Any broken symlinks are resolved to the dependant packages location.

    Args:
        repository_ctx: The repository context.
        package_deps: A list of package dependencies.
        break_deps: A list of dependencies to break.

    Returns:
        A dictionary mapping each path to a Bazel target.
    """
    all_files = _find_all_files_in_package(repository_ctx)
    package = repository_ctx.name
    file_mapping = {
        path: _path_to_target(package, path)
        for path in all_files["valid_files"]
    }

    repository_ctx.file("vfs.bzl", generate_file_vfs_package_plugin(
        file_mapping,
        all_files["broken_symlinks"],
        package_deps,
        break_deps,
    ))
