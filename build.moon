loveReleaseCheck = [[
  echo Checking dependencies...
  if ! dpkg -l libzip-dev &> /dev/null; then
    echo "Installing libzip-dev..."
    sudo apt-get update
    sudo apt-get install libzip-dev -y &> /dev/null
  fi
  if ! command -v luarocks &> /dev/null; then
    echo "Installing LuaRocks..."
    ROCKSVER=2.4.4      # CHECK FOR NEW VERSION AT https://luarocks.github.io/luarocks/releases
    sudo apt-get update
    sudo apt-get install lua5.1 liblua5.1-0-dev zip unzip libreadline-dev libncurses5-dev libpcre3-dev openssl libssl-dev perl make build-essential -y
    wget https://luarocks.github.io/luarocks/releases/luarocks-$ROCKSVER.tar.gz
    tar xvf luarocks-$ROCKSVER.tar.gz
    cd luarocks-$ROCKSVER
    ./configure
    make build
    sudo make install
    cd ..
    rm -rf luarocks*
  fi
  if ! command -v love-release &> /dev/null; then
    echo "Installing love-release..."
    sudo -H luarocks install love-release &> /dev/null
  fi
]]

moonCheck = [[
  echo Checking dependencies for moonscript...
  if ! command -v moonc &> /dev/null; then
    echo "Installing moonscript..."
    sudo -H luarocks install moonscript &> /dev/null
  fi
]]

mkdebCheck = [[
  echo Checking dependencies for making .deb files...
  if ! dpkg -l fakeroot &> /dev/null; then
    echo "Installing fakeroot..."
    sudo apt-get update
    sudo apt-get install fakeroot -y &> /dev/null
  fi
  if ! dpkg -l dpkg-deb &> /dev/null; then
    echo "Installing dpkg-deb..."
    sudo apt-get update
    sudo apt-get install dpkg-deb -y &> /dev/null
  fi
]]

luajitCheck = [[
  echo Checking dependencies for compiling to bytecode...
  if ! command -v luajit &> /dev/null; then
    echo "Installing LuaJIT..."
    sudo apt-get update
    sudo apt-get install luajit -y &> /dev/null
  fi
]]

butlerCheck = [[
  echo Checking dependencies for butler...
  if ! command -v butler &> /dev/null; then
    echo "Installing butler..."
    wget https://dl.itch.ovh/butler/linux-amd64/head/butler
    chmod +x ./butler
    sudo mv ./butler /bin/butler
    echo "INSTRUCTIONS FOR REMOTE SERVER:"
    echo " Open the URL provided by butler on your machine to login,"
    echo " then copy the address it redirects you to back to the terminal."
    butler login
  fi
]]

exists = (name) ->
  if file = io.open name
    file\close!
    return true

-- TODO doesn't handle when an option is specified multiple times
--  behavior should be to make an array of its values
getopts = (args={}, ...) ->
  opts = {}
  ignoreNext = false

  for flag in pairs args
    if "table" == type flag
      args[flag] = setmetatable flag, __tostring: (t) -> return table.concat t, "|"

  valueless = (flag) ->
    arg = args[flag]
    unless arg
      for k,v in pairs args
        if "table" == type k
          for a in *k
            if a == flag
              arg = v
              break
    if "table" == type arg
      return not arg[1]
    else
      return not arg

  required = (flag) ->
    arg = args[flag]
    unless arg
      for k,v in pairs args
        if "table" == type k
          for a in *k
            if a == flag
              arg = v
              break
    if "table" == type arg
      return arg[1]
    else
      return arg == true

  for i = 1, select "#", ...
    if ignoreNext
      ignoreNext = false
      continue
    flag = select i, ...
    value = select i+1, ...
    flag, count = flag\gsub "%-", ""
    if count > 0
      if not value or valueless flag
        opts[flag] = true
      else
        _, count = value\gsub "%-", ""
        if count > 0
          opts[flag] = true
        else
          opts[flag] = value
          ignoreNext = true
    else
      opts[#opts + 1] = flag

  for flag in pairs args
    if required flag
      exists = false
      if "table" == type flag
        for key in *flag
          exists or= opts[key]
      else
        exists = opts[flag]
      error "Required argument '#{flag}' not specified!" unless exists

  return opts

opts = getopts {
  [1]: "Source directory."
  [2]: "Builds directory."
  "dry-run": {false, "Skip uploading via butler."}
  [{"v", "version"}]: "Specify version number of build."
  [{"l", "love"}]: "Specify LÖVE version to use."
  -- TODO handle --exclude and -x options -> config.releases.excludeFileList
  -- TODO handle --include and -i options -> config.build.includeFiles
  -- NOTE exclude is a pattern, include is for specific files
}, ...

opts[1] or= "./src"
opts[2] or= "./builds"

os.execute loveReleaseCheck

if exists "#{opts[1]}/main.moon"
  os.execute moonCheck
  os.execute "moonc #{opts[1]}"

love = {}
config = setmetatable {}, __index: (t, k) ->
  t[k] = {}
  return t[k]

if pcall -> require "#{opts[1]}/conf"
  love.conf config if love.conf

pcall ->
  version = require "#{opts[1]}/version"
  config.releases.version = version

-- default: Build Windows 32, Mac OS, and Debian packages; compile source
loveReleaseOptions = {
  "-D", "-M", "-W 32", "-b"
}

removeOption = (name) ->
  for k,v in ipairs loveReleaseOptions
    if v == name
      table.remove loveReleaseOptions, k
      break

-- version precedence:
--  specified on command-line
--  returned by src/version.lua
--  specified in config.releases.version
config.releases.version = opts.version or opts.v if opts.version or opts.v

-- build timestamp defaults to true
--  to disable: config.build.timestamp = false
if config.releases.version
  if config.build.timestamp ~= false
    config.releases.version ..= "#{config.releases.version\find("%+") and "." or "+"}#{os.time os.date "!*t"}"
  table.insert loveReleaseOptions, "-v #{config.releases.version}"
else
  -- if no version specified, will not build a Debian package
  removeOption "-D"

-- loveVersion precedence:
--  specified on command-line
--  specified in config.releases.loveVersion
--  specified in config.version
--  11.1
config.releases.loveVersion = opts.love or opts.l if opts.love or opts.l
config.releases.loveVersion or= config.version or "11.1"
table.insert loveReleaseOptions, "-l #{config.releases.loveVersion}"

-- identifier precedence:
--  specified on command-line
--  specified in config.releases.identifier
--  TODO generated from first available:
--   config.releases.homepage|config.releases.author|config.releases.email, config.releases.package|config.releases.title|config.identity
--  generated from config.identity (TODO remove this when the above generator is done)
config.releases.identifier = opts.uti if opts.uti
config.releases.identifier or= config.identity and config.identity\gsub "%W", ""

-- NOTE temporary reference for above note about generation of UTIs
-- t.releases = {
--   title = "Test Package",
--   package = "TestPackage",
--   author = "Paul L",
--   email = "paul.liverman.iii@gmail.com",
--   description = "A test package.",
--   homepage = "https://example.com",
-- }

removeOption("-b") if config.releases.compile == false
removeOption("-D") if config.build.debian == false
removeOption("-M") if config.build.macos == false or config.build.osx == false

if config.build.win64 or config.build.win32 == false
  removeOption "-W 32"
  if config.build.win32
    table.insert loveReleaseOptions, "-W"
  else
    table.insert loveReleaseOptions, "-W 64"

-- rewrite version.lua if needed
if opts.version or opts.v or config.build.timestamp ~= false
  file = io.open "#{opts[1]}/version.lua", "w"
  file\write "return \"#{config.releases.version}\"\n"
  file\close!

optionSet = (name) ->
  for option in *loveReleaseOptions
    if option == name
      return true

if optionSet "-D"
  os.execute mkdebCheck
if optionSet "-b"
  os.execute luajitCheck

command = "love-release #{table.concat loveReleaseOptions, " "} \"#{opts[2]}\" \"#{opts[1]}\""
print command -- NOTE temporary

-- TODO handle include option once available
-- TODO upload with butler!
-- TODO ignore butler if dry-run specified
