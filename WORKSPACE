workspace(name = "rules_deb")

load("@rules_deb//deb:packages_list.bzl", "deb_repository")

deb_repository(
    # Currently has to use the name debian_package_list.
    name = "debian_package_list",

    # The architecture of the packages.
    arch = "amd64",
    # The debian channel to use.
    channel = "main",
    # The distrubution to use.
    dist = "jessie",

    # The package list sha256, this is used to verify the integrity of
    # all other packages, e.g. each package has a corresponding sha256,
    # that is started in the package list.
    package_list_sha256 = "7240a1c6ce11c3658d001261e77797818e610f7da6c2fb1f98a24fdbf4e8d84c",

    # The snapshot repository url to use. Each of the packages in the
    # repository must remain the same otherwise you will get 404 not found
    # errors when fetching as typical repositories will delete old versions of
    # packages.
    url = "https://snapshot.debian.org/archive/debian/20211201T030112Z",
)

load("@debian_package_list//:deb_repository_init.bzl", "deb_repository_init")

deb_repository_init()

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "bazel_skylib",
    sha256 = "bc283cdfcd526a52c3201279cda4bc298652efa898b10b4db0837dc51652756f",
    urls = [
        "https://github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
        "https://mirror.bazel.build/github.com/bazelbuild/bazel-skylib/releases/download/1.7.1/bazel-skylib-1.7.1.tar.gz",
    ],
)

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

load("//deb/internal:deb_archive.bzl", "deb_archive")

deb_archive(
    name = "single_archive_test",
    build_file_content = "exports_files(glob([\"**/*\"]))",
    sha256 = "cb202dc2190c353dee76e619e714cd9c6d429f03b95c353119449cea8776f815",
    url = "https://snapshot.debian.org/archive/debian/20211211T024809Z/pool/main/libc/libc%2B%2B/libc%2B%2B-dev_3.5-2_amd64.deb",
)
