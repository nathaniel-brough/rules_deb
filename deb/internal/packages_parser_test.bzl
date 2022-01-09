load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    ":packages_parser.bzl",
    "DebPackageDependencyInfo",
    "package_as_dict",
    "parse_dependencies",
    "parse_dependency",
    "split_packages",
)

SAMPLE_PACKAGE_LIST = """
"Package": "0ad"
"Version": "0.0.17-1"
"Installed-Size": "10470"
"Maintainer": "Debian Games Team <pkg-games-devel@lists.alioth.debian.org>"
"Architecture": "amd64"
"Depends": "0ad-data (>= 0.0.17), 0ad-data (<= 0.0.17-1), 0ad-data-common (>= 0.0.17), 0ad-data-common (<= 0.0.17-1), libboost-filesystem1.55.0, libc6 (>= 2.15), libcurl3-gnutls (>= 7.16.2), libenet7, libgcc1 (>= 1:4.1.1), libgl1-mesa-glx | libgl1, libgloox12, libicu52 (>= 52~m1-1~), libjpeg62-turbo (>= 1:1.3.1), libminiupnpc10 (>= 1.9.20140610), libmozjs-24-0, libnvtt2, libopenal1 (>= 1.14), libpng12-0 (>= 1.2.13-4), libsdl1.2debian (>= 1.2.11), libstdc++6 (>= 4.9), libvorbisfile3 (>= 1.1.2), libwxbase3.0-0 (>= 3.0.2), libwxgtk3.0-0 (>= 3.0.2), libx11-6, libxcursor1 (>> 1.1.2), libxml2 (>= 2.9.0), zlib1g (>= 1:1.2.0)"
"Pre-Depends": "dpkg (>= 1.15.6~)"
"Description": "Real-time strategy game of ancient warfare"
"Homepage": "http://play0ad.com/"
"Description-md5": "d943033bedada21853d2ae54a2578a7b"
"Tag": "uitoolkit::sdl, uitoolkit::wxwidgets"
"Section": "games"
"Priority": "optional"
"Filename": "pool/main/0/0ad/0ad_0.0.17-1_amd64.deb"
"Size": "2862930"
"MD5sum": "8b679b5afa15afc1de5b2faee1892faa"
"SHA1": "ef532e216e58862700f3824000d3c8c816dc5156"
"SHA256": "d850ad98b399016b3456dd516d2e114fd72c956aa7b5ddaa0858f792bb005c5e"

"Package": "0ad-dbg"
"Source": "0ad"
"Version": "0.0.17-1"
"Installed-Size": "58345"
"Maintainer": "Debian Games Team <pkg-games-devel@lists.alioth.debian.org>"
"Architecture": "amd64"
"Depends": "0ad (= 0.0.17-1)"
"Pre-Depends": "dpkg (>= 1.15.6~)"
"Description": "Real-time strategy game of ancient warfare (debug)"
"Homepage": "http://play0ad.com/"
"Description-md5": "a858b67397d1d84d8b4cac9d0deae0d7"
"Tag": "role::debug-symbols"
"Section": "debug"
"Priority": "extra"
"Filename": "pool/main/0/0ad/0ad-dbg_0.0.17-1_amd64.deb"
"Size": "56883580"
"MD5sum": "12a652824ad891d482cbf18614acb031"
"SHA1": "7a4192317707b698288565ff6ad6ecf74ae65688"
"SHA256": "3c401795b7bf4c75984ba030c6b6a35e5a54b1a281c7a81b8b7a8b217b8dc14c"

"Package": "0ad-data"
"Version": "0.0.17-1"
"Installed-Size": "1422289"
"Maintainer": "Debian Games Team <pkg-games-devel@lists.alioth.debian.org>"
"Architecture": "all"
"Pre-Depends": "dpkg (>= 1.15.6~)"
"Suggests": "0ad"
"Description": "Real-time strategy game of ancient warfare (data files)"
"Homepage": "http://play0ad.com/"
"Description-md5": "26581e685027d5ae84824362a4ba59ee"
"Tag": "role::app-data"
"Section": "games"
"Priority": "optional"
"Filename": "pool/main/0/0ad-data/0ad-data_0.0.17-1_all.deb"
"Size": "566073422"
"MD5sum": "b82e30c2927ed595cabbe8000ebb93b0"
"SHA1": "08e4a649d2f2f7d9ae5ec4835fcd44ff58b0d3c2"
"SHA256": "84ee024e2f19f0ffd732b419da2e594e57f615f45341926a3fb427746b7dc82b"
"""

def _split_packages_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, 3, len(split_packages(SAMPLE_PACKAGE_LIST)))
    return unittest.end(env)

split_packages_test = unittest.make(_split_packages_test_impl)

def _package_as_dict_test_impl(ctx):
    env = unittest.begin(ctx)
    package = split_packages(SAMPLE_PACKAGE_LIST)[0]
    asserts.equals(
        env,
        {
            "Package": "0ad",
            "Version": "0.0.17-1",
            "Installed-Size": "10470",
            "Maintainer": "Debian Games Team <pkg-games-devel@lists.alioth.debian.org>",
            "Architecture": "amd64",
            "Depends": "0ad-data (>= 0.0.17), 0ad-data (<= 0.0.17-1), 0ad-data-common (>= 0.0.17), 0ad-data-common (<= 0.0.17-1), libboost-filesystem1.55.0, libc6 (>= 2.15), libcurl3-gnutls (>= 7.16.2), libenet7, libgcc1 (>= 1:4.1.1), libgl1-mesa-glx | libgl1, libgloox12, libicu52 (>= 52~m1-1~), libjpeg62-turbo (>= 1:1.3.1), libminiupnpc10 (>= 1.9.20140610), libmozjs-24-0, libnvtt2, libopenal1 (>= 1.14), libpng12-0 (>= 1.2.13-4), libsdl1.2debian (>= 1.2.11), libstdc++6 (>= 4.9), libvorbisfile3 (>= 1.1.2), libwxbase3.0-0 (>= 3.0.2), libwxgtk3.0-0 (>= 3.0.2), libx11-6, libxcursor1 (>> 1.1.2), libxml2 (>= 2.9.0), zlib1g (>= 1:1.2.0)",
            "Pre-Depends": "dpkg (>= 1.15.6~)",
            "Description": "Real-time strategy game of ancient warfare",
            "Homepage": "http://play0ad.com/",
            "Description-md5": "d943033bedada21853d2ae54a2578a7b",
            "Tag": "uitoolkit::sdl, uitoolkit::wxwidgets",
            "Section": "games",
            "Priority": "optional",
            "Filename": "pool/main/0/0ad/0ad_0.0.17-1_amd64.deb",
            "Size": "2862930",
            "MD5sum": "8b679b5afa15afc1de5b2faee1892faa",
            "SHA1": "ef532e216e58862700f3824000d3c8c816dc5156",
            "SHA256": "d850ad98b399016b3456dd516d2e114fd72c956aa7b5ddaa0858f792bb005c5e",
        },
        package_as_dict(package),
    )
    return unittest.end(env)

package_as_dict_test = unittest.make(_package_as_dict_test_impl)

def _parse_dependency_test(ctx):
    env = unittest.begin(ctx)

    # Has version information.
    asserts.equals(
        env,
        DebPackageDependencyInfo(
            name = "libc6",
            version_range = ">= 2.15",
        ),
        parse_dependency("libc6 (>= 2.15)"),
    )

    # No version information.
    asserts.equals(
        env,
        DebPackageDependencyInfo(
            name = "libc6",
            version_range = None,
        ),
        parse_dependency("libc6"),
    )
    return unittest.end(env)

parse_dependency_test = unittest.make(_parse_dependency_test)

def _parse_dependencies_test(ctx):
    env = unittest.begin(ctx)

    # Has version information.
    asserts.equals(
        env,
        [
            DebPackageDependencyInfo(
                name = "libc6",
                version_range = ">= 2.15",
            ),
            DebPackageDependencyInfo(
                name = "libcurl3-gnutls",
                version_range = ">= 7.16.2",
            ),
            DebPackageDependencyInfo(
                name = "libenet7",
                version_range = None,
            ),
        ],
        parse_dependencies("libc6 (>= 2.15), libcurl3-gnutls (>= 7.16.2), libenet7"),
    )
    return unittest.end(env)

parse_dependencies_test = unittest.make(_parse_dependencies_test)

def packages_parser_test_suite(name):
    unittest.suite(
        name,
        split_packages_test,
        package_as_dict_test,
        parse_dependency_test,
        parse_dependencies_test,
    )
