# Only include paths to libs not provided by the toolchain i.e.
# not libc, libc++ etc.
load(":package_info.bzl", "INFO")
load(":vfs.bzl", "SHARED_LIBS", "STATIC_LIBS", "deb_file")
load("@rules_deb//deb/internal:deb_archive.bzl", "lib_info")

INCLUDE_PATHS = [
    "usr/local/include",
    "usr/include",
]

LIB_INFO = lib_info(
    STATIC_LIBS.keys(),
    SHARED_LIBS.keys(),
)

HDRS = glob([include + "/**/*" for include in INCLUDE_PATHS])

cc_library(
    name = "cc_" + INFO["name"],
    hdrs = [deb_file(f) for f in HDRS],
    includes = INCLUDE_PATHS,
    visibility = ["//visibility:public"],
    deps = [
        ":imports_" + str(hash(str(lib)))
        for lib in LIB_INFO
    ] + INFO["cc_deps"],
)

[
    cc_import(
        name = "imports_" + str(hash(str(lib))),
        shared_library = deb_file(lib["shared"]),
        static_library = deb_file(lib["static"]),
    )
    for lib in LIB_INFO
]

exports_files(glob([
    "usr/bin/*",
    "bin/*",
    "**/*.so*",
    "**/*.a",
]))
