# rules_deb
[![CI](https://github.com/silvergasp/rules_deb/actions/workflows/ci.yml/badge.svg)](https://github.com/silvergasp/rules_deb/actions/workflows/ci.yml)

A set of bazel rules for hermetic builds using debian packages.

** WARNING **: Some functionality is not complete, this is an ongoing project.

Currently it is quite difficult to create a deterministic build that depends 
on system libraries. While there are some alternative approaches to creating
deterministic builds that depend on system packages (e.g. combining local_repository and a docker container), this particular approach is
intended as a light-weight alternative. 

It is important to note that this set of rules differs from 'rules_pkg' in that
rules_pkg is designed to create packages, whereas 'rules_deb' is designed
to run 

## Getting started
To get started add the following to you WORKSPACE file. 
``` py
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "rules_deb",
    remote = "https://github.com/silvergasp/rules_deb.git",
    commit = "<TODO>",
)

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

# Initialise each package in the repository. Each debian package maps directly
# to a bazel repository.
deb_repository_init()
```

**NOTE:** The Debian snapshot repositories are somewhat unreliable, if you get a
connection refused error, this is most likely the Debian repository and not 
these Bazel rules. The solution I have found so far is to wait a few seconds and
attempt fetching your dependencies again, you might have to repeat this multiple
times until you have downloaded all your deps. This reliability is an active 
area of development i.e. implementing retries automatically etc.

You will also need to add in the following dependencies for this library to
work properly; 
- [@bazel_skylib](https://github.com/bazelbuild/bazel-skylib)

To see the list of Debian packages that are available in your repository, you can make use of the bazel query command e.g. 
```
bazel query //external:all
```

You can test that the packages have been setup correctly by executing one of the
binaries exported in each package e.g.
```
bazel run @bash//:bin/bash -- --help
```

Should download the most up to date version of bash in the snapshot and print
the help menu.

You can also depend on shared C/C++ libraries where the dependency tree is 
extracted from the debian packages. e.g. checkout tests/libusb_app/BUILD.bazel.
```
cc_binary(
    name = "listdevs",
    srcs = ["listdevs.c"],
    copts = ["-pthread"],
    linkopts = ["-lpthread"],
    # Depend on libusb version 1.
    deps = ["@libusb-1.0-0-dev//:cc_libusb-1.0-0-dev"],
)
```

