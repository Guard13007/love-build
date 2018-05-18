# love-build

A simple wrapper around [love-release](https://github.com/MisterDA/love-release)
adding default options, more options/features, and adding automated uploading to
Itch.io using [butler](https://itch.io/docs/butler/).

## Installation

Either copy `build.lua` into the same directory as your project and use
`lua ./build.lua <ARGS>` to run it (making sure you have the dependencies), or
install it using LuaRocks (`luarocks install love-build`) and run `love-build`.
(NOTE: NOT ON LUAROCKS JUST YET!)

## Usage

The most basic usage involves using arguments, but the easier option is to
modify your `conf.lua` file to add options to it, then you can just run
love-build with the source directory as the only argument (builds will be placed
in `./builds` by default, although this can be overridden in the config as
well).

Example config:

```lua
function love.conf(t)
  -- TODO I will finish writing this with a "complete" conf soon
  {
    title = 'src',
    package = 'src',
    loveVersion = '11.1',
    version = nil,
    author = nil,
    email = nil,
    description = nil,
    homepage = nil,
    identifier = 'fuck.me',
    excludeFileList = { ''} ,
    compile = true,
    projectDirectory = '/home/simplexdev/Documents/love-build/test/./src',
    releaseDirectory = '/home/simplexdev/Documents/love-build/test/./builds',
  }
end
```

(Note that while the `conf.lua` file being used in this manner is intended to be
deprecated by `love-release`, it will continue to be accepted there and by this
project. Once this occurs, I will use a derivation of their config format if I
am able to (if not, another format will be used).)

Output of love-build -h:

<pre>
Checking dependency: love-release
Warning: Cannot check for dependencies, please verify dependencies yourself.
Usage: love-build [--dry-run] [--skip-butler] [-v <build_version>]
       [-l <love_version>] [-x file] [-D] [-C] [-B] [-S] [-X] [-L]
       [--no-version-file] [--no-overwrite-version]
       [--keep-moonscript] [-a <author>] [-d <desc>] [-e <email>]
       [-p <package>] [-t <title>] [-u <url>] [-uti <uti>] [-I file]
       [--version] [-h] [<source>] [<build_dir>] [-W [32|64]]

A simple wrapper for love-release, adding default options and builds for major OSes, extra options, and automated uploading to Itch.io via butler.

Arguments:
   source                Source directory. (default: ./src)
   build_dir             Directory to place builds in. (default: ./builds)

Testing:
   --dry-run             Do everything up to calling love-release, print the command to be sent to love-release, and stop.
   --skip-butler         Skip uploading via butler, even if configured.

Turning off defaults:
   -C, --no-compile-moonscript
                         Do not compile .moon files before building.
   -B, --no-luajit-bytecode
                         Do not compile to LuaJIT bytecode.
   -S, --no-timestamp    Do not append a timestamp to builds.
   -X, --no-mac          Do not build a Mac OS version.
   -L, --no-love         Do not build a version with a .love file (intended for Linux distribution).
   --no-version-file     Do not write version.lua in source directory with a file returning the current version.
   --no-overwrite-version
                         Do not overwrite version.lua in source directory if it already exists.
   --keep-moonscript     Keep .moon files in builds.

Project metadata (love-release options):
         -a <author>,    Author's full name.
   --author <author>
       -d <desc>,        Project description.
   --desc <desc>
        -e <email>,      Author's email.
   --email <email>
          -p <package>,  Package/Executable/Command name.
   --package <package>
        -t <title>,      Project title.
   --title <title>
      -u <url>,          Project homepage URL.
   --url <url>
   -uti <uti>            Project Uniform Type Identifier (it's a Mac thing).

Other options:
                -v <build_version>,
   --build-version <build_version>
                         Specify version number of build.
               -l <love_version>,
   --love-version <love_version>
                         Specify LÖVE version to use. (default: 11.1)
   -W [32|64]            Build Windows executables (32/64 bit). (default: 32)
          -x file,       Exclude files in source directory by Lua pattern.
   --exclude file
   -D, --debian          Build a Debian package. (Not recommended.)
               -I file,  Include specific files (alongside executables, not within). (Does not apply to Debian builds.)
   --include-file file
   --version             Print version of love-build and exit.
   -h, --help            Show this help message and exit.

All love-release options are also supported here. For more info, see https://github.com/Guard13007/love-build
</pre>
