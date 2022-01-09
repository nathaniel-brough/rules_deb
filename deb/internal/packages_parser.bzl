def split_packages(packages):
    """
    Split a list of packages into a list of packag strings

    Args:
        packages (list): A string containing the packages descripter
        as downloaded from an apt repository.
    """
    return packages.split("\n\n")

def package_as_dict(package):
    """
    Split a package string into a dictionary

    Args:
        package (str): A string containing the package descripter
        as downloaded from an apt repository.

    Returns:
        dict: A dictionary containing the package information.
    """
    package_dict = {}
    for line in package.split("\n"):
        if ":" in line:
            key, value = line.split(":", 1)
            if key.startswith('"') and key.endswith('"'):
                key = key[1:-1]
            if value.startswith(' "') and value.endswith('"'):
                value = value[2:-1]
            if value:
                package_dict[key] = value

    # Sanity check to ensure this is a valid package
    if "Package" not in package_dict:
        return None
    return package_dict

DebPackageDependencyInfo = provider(doc = "A single package dependency.", fields = {
    "name": "The dependency name",
    "version_range": "The version range of the dependency.",
})

def parse_dependency(dependency_str):
    """ Parse a dependency string into a DebPackageDependencyInfo object.

    Args:
        dependency_str (str): A string containing the dependency information.

    Returns:
        DebPackageDependencyInfo: A DebPackageDependencyInfo object.
    """
    dependency_str = dependency_str.replace(")", "")
    dep_split = dependency_str.split("(", 1)
    if len(dep_split) == 1:
        dep_split.append(None)
    name, version_range = dep_split

    # TODO(#4): Handle multiple optional dependencies. e.g. Depends may be in
    # the form 'libc6-dev | libc-dev'. To simplify this we will just use the
    # first optional dependency ignoring the rest.

    # Use the first optional depenency.
    name = name.split("|")[0]

    # Remove colon from name. e.g. 'python:any'-> 'python'.
    name = name.split(":")[0]

    return DebPackageDependencyInfo(
        name = sanitize_package_name(name),
        version_range = version_range,
    )

def parse_dependencies(package_dependencies_str):
    """ Parse a package dependencies string into a list of DebPackageDependencyInfo objects.
    """
    if not package_dependencies_str:
        return []

    return [
        parse_dependency(dep)
        for dep in package_dependencies_str.split(", ")
    ]

DebPackageInfo = provider(doc = "Information regarding a deb package.", fields = {
    "name": "The name of the package.",
    "version": "The version of the package.",
    "sha256": "The sha256 of the package.",
    "depends": "The dependencies of the package.",
    "architecture": "The architecture of the package.",
    "file_name": "The path to the package in an apt repository.",
    "info": "The original package information.",
})

def sanitize_package_name(name):
    """ Sanitize package name

    Args:
        name (str): package name.

    Returns:
        str: sanitized package name.
    """
    return name.replace("+", "plus").strip(" ")

def sanitize_package_field(field):
    """ Sanitize package field

    Args:
        field (str): package field.

    Returns:
        str: sanitized package field.
    """
    return field.replace(" ", "")

def deb_package(package_str):
    """ Parse a package string into a DebPackageInfo object.

    Args:
        package_str: A string containing the package information.

    Returns:
        DebPackageInfo: A DebPackageInfo object.
    """
    package_dict = package_as_dict(package_str)
    if package_dict == None:
        return None

    return DebPackageInfo(
        name = sanitize_package_name(package_dict["Package"]),
        version = sanitize_package_field(package_dict["Version"]),
        sha256 = sanitize_package_field(package_dict["SHA256"]),
        depends = parse_dependencies(package_dict.get("Depends", "")),
        architecture = sanitize_package_field(package_dict["Architecture"]),
        file_name = sanitize_package_field(package_dict["Filename"]),
        info = package_str,
    )

def deb_packages_dict(packages_str):
    """ Parse a list of packages into a dictionary of DebPackageInfo objects.

    Args:
        packages_str: A string containing the packages information.

    Returns:
        dict: A dictionary of DebPackageInfo objects.
    """
    return {
        package.name: package
        for package in [deb_package(package_str) for package_str in split_packages(packages_str) if package_str != ""]
    }
