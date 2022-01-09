DEB_ARCHIVE_LIST_ENTRY_TEMPLATE = """("{name}", "{file_name}", "{sha256}"),"""

INIT_MACRO_TEMPLATE = """
load("@rules_deb//deb/internal:deb_archive.bzl", "deb_archive")

PACKAGE_PARAMAETERS = [{entries}]
PACKAGE_BASE_URL = "{base_url}"
BREAK_DEPS = {break_deps}

def deb_repository_init():
    [
        deb_archive(
            name = name,
            url = PACKAGE_BASE_URL + "/" + file_name,
            sha256 = sha256,
            build_file = "@rules_deb//deb/internal:default.BUILD",
            break_deps = BREAK_DEPS,
        )
        for name, file_name, sha256 in PACKAGE_PARAMAETERS
        if not native.existing_rule(name)
    ]
"""

def generate_deb_repository_init_script(package_dict, base_url, package_name_prefix, break_deps):
    """Generates the content of the init_macro for a deb repository

    Args:
        package_dict: A dictionary of package names to package objects.
        base_url: The base url of the deb repository.
        package_name_prefix: The prefix to use for the package names.
        break_deps: List of dependencies to break.

    Returns:
        The content of the init_macro.
    """
    return INIT_MACRO_TEMPLATE.format(
        base_url = base_url,
        break_deps = break_deps,
        entries = "\n".join([DEB_ARCHIVE_LIST_ENTRY_TEMPLATE.format(
            name = package_name,
            file_name = package.file_name,
            sha256 = package.sha256,
        ) for package_name, package in package_dict.items()]),
    )
