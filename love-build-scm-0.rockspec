package = "love-build"
version = "scm-0"
source = {
  url = "git+https://github.com/Guard13007/love-build.git"
}
description = {
  summary = "Wrapper for love-release, adds defaults & itch.io upload",
  detailed = "A wrapper for love-release adding default compiling options for Windows/Linux/Mac OS, and supporting uploads to itch.io via butler.",
  homepage = "https://github.com/Guard13007/love-build",
  license = "MIT",
  issues_url = "https://github.com/Guard13007/love-build/issues",
  maintainer = "Paul Liverman III <paul.liverman.iii@gmail.com>",
  labels = { "ci", "love", "commandline", "linux" }
}
supported_platforms = { "linux" }
-- build_dependencies = { "moonscript" }
dependencies = {
  "lua 5.1",
  "argparse",
  "loadconf",
  "love-release"
}
build = {
  type = "builtin",
  install = {
    bin = {
      ["love-build"] = "build.lua"
    }
  }
}
