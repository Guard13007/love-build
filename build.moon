version = "v1.0.0"

check = setmetatable {
  -- shell scripts to check for dependencies and install them
  "love-release": [[
    # note: none of the stdout/stderr redirection works
    # note: ! command -v luarocks somehow doesn't work
    set +o errexit   # does not work for some reason
    if ! dpkg -l libzip-dev &> /dev/null; then
      echo "Installing libzip-dev (love-release dependency)..."
      sudo apt-get update &> /dev/null
      sudo apt-get install libzip-dev -y &> /dev/null
    fi
    if ! command -v luarocks &> /dev/null; then
      echo "Installing LuaRocks (dependency for love-release & love-build)..."
      ROCKSVER=2.4.4      # CHECK FOR NEW VERSION AT https://luarocks.github.io/luarocks/releases
      sudo apt-get update &> /dev/null
      # NOTE: Some of these may not be actually needed for LuaRocks...
      sudo apt-get install lua5.1 liblua5.1-0-dev zip unzip libreadline-dev libncurses5-dev libpcre3-dev openssl libssl-dev perl make build-essential -y &> /dev/null
      wget https://luarocks.github.io/luarocks/releases/luarocks-$ROCKSVER.tar.gz &> /dev/null
      tar xvf luarocks-$ROCKSVER.tar.gz &> /dev/null
      cd luarocks-$ROCKSVER
      ./configure &> /dev/null
      make build &> /dev/null
      sudo make install &> /dev/null
      cd ..
      rm -rf luarocks* &> /dev/null
    fi
    if ! command -v love-release &> /dev/null; then
      echo "Installing love-release..."
      sudo -H luarocks install love-release &> /dev/null
    fi
  ]]
  -- NOTE dependencies of love-release not currently checked for: argparse, loadconf
  moonscript: [[
    # doesn't check for LuaRocks, as it should be installed before it gets to this point
    set +o errexit   # does not work for some reason
    if ! command -v moonc &> /dev/null; then
      echo "Installing moonscript..."
      sudo -H luarocks install moonscript &> /dev/null
    fi
  ]]
  luajit: [[
    set +o errexit   # does not work for some reason
    if ! command -v luajit &> /dev/null; then
      echo "Installing LuaJIT..."
      sudo apt-get update
      sudo apt-get install luajit -y &> /dev/null
    fi
  ]]
  fakeroot: [[
    set +o errexit   # does not work for some reason
    if ! dpkg -l fakeroot &> /dev/null; then
      echo "Installing fakeroot..."
      sudo apt-get update
      sudo apt-get install fakeroot -y &> /dev/null
    fi
  ]]
  "dpkg-deb": [[
    set +o errexit   # does not work for some reason
    if ! dpkg -l dpkg-deb &> /dev/null; then
      echo "Installing dpkg-deb..."
      sudo apt-get update
      sudo apt-get install dpkg-deb -y &> /dev/null
    fi
  ]]
  butler: [[
    set +o errexit   # does not work for some reason
    if ! command -v butler &> /dev/null; then
      echo "Installing butler..."
      wget https://dl.itch.ovh/butler/linux-amd64/head/butler &> /dev/null
      chmod +x ./butler &> /dev/null
      sudo mv ./butler /bin/butler &> /dev/null
      echo "INSTRUCTIONS IF ON REMOTE SERVER:"
      echo " Open the URL provided by butler on your machine to login,"
      echo " then copy the address it redirects you to back to the terminal."
      butler login
    fi
    ]]
}, {
  __call: (t, ...) ->
    for i = 1, select "#", ...
      name = select i, ...
      script = t[name]
      error "Invalid dependency check for \"#{name}\"" unless script

      print "Checking dependency: #{name}"
      -- os.execute script
      print "Warning: Cannot check for dependencies, please verify dependencies yourself."
}

run_safe = (fn) ->
  success, result = pcall fn
  return result if success and result
  -- error "Required dependencies were just installed, please run your command again."
  error "Cannot resolve a dependency, please check the required dependencies and install missing dependencies."

file_exists = (name) ->
  if file = io.open name
    file\close!
    return true

-- check "argparse"
-- check "loadconf"
check "love-release"

opts = run_safe ->
  argparse = require "argparse"

  parser = argparse!
  parser\name "love-build"
  parser\description "A simple wrapper for love-release, adding default options and builds for major OSes, extra options, and automated uploading to Itch.io via butler."

  parser\argument "source", "Source directory.", "./src"
  parser\argument "build_dir", "Directory to place builds in.", "./builds"

  parser\flag "--dry-run", "Skip uploading via butler, even if configured."

  parser\option "-v --build-version", "Specify version number of build."
  parser\option "-l --love-version", "Specify LÖVE version to use.", "11.1"
  parser\option
    name: "-W"
    description: "Build Windows executables (32/64 bit). (default: 32)"
    count: "0-2"
    args: "0-1"
    target: "windows"
    argname: "32|64"
    default: {{"32"}}
  parser\option
    name: "-i --include"
    description: "(NOT IMPLEMENTED) Include files by Lua pattern (alongside executables, not within). (Does not apply to Debian builds.)"
    count: "*"
  parser\option
    name: "-x --exclude"
    description: "Exclude files in source directory by Lua pattern."
    count: "*"
  parser\flag "-D --debian", "Build a Debian package. (Not recommended.)"

  parser\flag "-C --no-compile-moonscript", "Do not compile .moon files before building."
  parser\flag "-B --no-luajit-bytecode", "Do not compile to LuaJIT bytecode."
  parser\flag "-S --no-timestamp", "Do not append a timestamp to builds."
  parser\flag "-X --no-mac", "Do not build a Mac OS version."
  parser\flag "-L --no-love", "Do not build a version with a .love file (intended for Linux distribution)."
  parser\flag "--no-overwrite-version", "Do not overwrite version.lua in source directory with a file returning the current version."
  parser\flag "--keep-moonscript", "Keep .moon files in builds."

  parser\flag "-M", "No effect, Mac OS applications are built by default. (Use --no-mac to disable.)"
  parser\option "-a --author", "TODO"
  parser\option
    name: "-d --desc"
    description: "TODO"
    target: "description"
  parser\option "-e --email", "TODO"
  parser\option "-p --package", "TODO"
  parser\option "-t --title", "TODO"
  parser\option "-u", "--url", "TODO"
  parser\option "-uti", "TODO"

  parser\option
    name: "-I --include-file"
    description: "Include specific files (alongside executables, not within). (Does not apply to Debian builds.)"
    count: "*"

  parser\flag "--version", "Print version of love-build and exit."

  -- parser\epilog "Dependencies: love-release, moonscript (for moonscript source code), butler (when channels are specified)"
  -- Too many Dependencies to list here
  parser\epilog "For more info, see URL" --TODO

  return parser\parse!

if opts.version
  print "love-build #{version}"
  os.exit 0

local options
options = {
  add: (arg) ->
    table.insert options, arg
  remove: (arg) ->
    for i = 1, #options
      if options[i] == arg
        table.remove options, i
        return
}

unless opts.no_compile_moonscript
  if file_exists "#{opts.source}/main.moon"
    check "moonscript"
    os.execute "moonc #{opts.source}"

conf = run_safe -> require("loadconf").parse_file("#{opts.source}/conf.lua") or {}
conf.releases or= {}
conf.build or= {}

if conf.releases.compile == false or not opts.no_luajit_bytecode
  check "luajit"
  options.add "-b"

opts.build_version or= conf.releases.version
success, version = pcall -> require "#{opts.source}/version"
opts.build_version or= version if success

if opts.debian and opts.build_version and (not conf.build.debian)
  check "fakeroot"
  check "dpkg-deb"
  options.add "-D"

opts.love_version or= conf.releases.loveVersion
opts.love_version or= conf.version
options.add "-l #{opts.love_version}"

opts.no_timestamp = not conf.build.timestamp
if opts.build_version and not opts.no_timestamp
  opts.build_version ..= "#{opts.build_version\find("%+") and "." or "+"}#{os.time os.date "!*t"}"

options.add "-v #{opts.build_version}" if opts.build_version

if (not opts.no_overwrite_version) and opts.build_version and file_exists "#{opts.source}/version.lua"
  file = assert io.open("#{opts.source}/version.lua"), "Unable to open #{opts.source}/version.lua to update version information!"
  file\write "return \"#{opts.build_version\gsub '"', '\\"'}\"\n"
  file\close!

-- -- identifier precedence:
-- --  specified on command-line
-- --  specified in config.releases.identifier
-- --  TODO generated from first available:
-- --   config.releases.homepage|config.releases.author|config.releases.email, config.releases.package|config.releases.title|config.identity
-- --  generated from config.identity (TODO remove this when the above generator is done)
-- config.releases.identifier = opts.uti if opts.uti
-- config.releases.identifier or= config.identity and config.identity\gsub "%W", ""
--
-- -- NOTE temporary reference for above note about generation of UTIs
-- -- t.releases = {
-- --   title = "Test Package",
-- --   package = "TestPackage",
-- --   author = "Paul L",
-- --   email = "paul.liverman.iii@gmail.com",
-- --   description = "A test package.",
-- --   homepage = "https://example.com",
-- -- }

-- TODO implement
--       butler, check for butler, -I, --dry-run, -x, -i
--       handle --include and -i options -> config.build.includePatterns

unless opts.keep_moonscript
  options.add "-x .-%.moon$"

if opts.exclude
  for value in *opts.exclude
    options.add "-x #{value}"

-- NOTE probably a duplication of effort and handled by love-release automatically
if conf.releases.excludeFileList
  for value in *conf.releases.excludeFileList
    options.add "-x #{value}"

w32 = conf.build.win32
w64 = conf.build.win64
for _,v in pairs opts.windows
  if v[1] == "32" and w32 == nil
    w32 = true
  elseif v[1] == "64" and w64 == nil
    w64 = true
options.add "-W 32" if w32
options.add "-W 64" if w64
options.add "-M" if conf.build.macos != false and conf.build.osx != false and not opts.no_mac

options.add opts.build_dir
options.add opts.source

print "love-release #{table.concat options, " "}" -- TEMPORARY PRINTING HOW LOVE-RELEASE WILL BE CALLED

unless opts.dry_run
  nil -- TODO upload with butler
