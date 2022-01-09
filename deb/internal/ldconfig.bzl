LIBRARIES_PATH = "lib/x86_64-linux-gnu"

def _parse_shlibs(shlibs):
    first_line = shlibs.splitlines()[0]
    return tuple(first_line.split(" ")[0:3])

def _file_exists(repository_ctx, path):
    return repository_ctx.execute(["test", "-f", path]).return_code == 0

def create_shlibs_symlinks(repository_ctx):
    if _file_exists(repository_ctx, "./shlibs"):
        library, version, _ = _parse_shlibs(repository_ctx.read("shlibs"))
        library_path = LIBRARIES_PATH + "/" + library + ".so"
        repository_ctx.symlink(
            library_path + "." + version,
            library_path,
        )
