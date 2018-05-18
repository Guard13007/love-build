local version = "v2.1.0"
local check = setmetatable({
  ["love-release"] = [[    # note: none of the stdout/stderr redirection works
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
  ]],
  moonscript = [[    # doesn't check for LuaRocks, as it should be installed before it gets to this point
    set +o errexit   # does not work for some reason
    if ! command -v moonc &> /dev/null; then
      echo "Installing moonscript..."
      sudo -H luarocks install moonscript &> /dev/null
    fi
  ]],
  luajit = [[    set +o errexit   # does not work for some reason
    if ! command -v luajit &> /dev/null; then
      echo "Installing LuaJIT..."
      sudo apt-get update
      sudo apt-get install luajit -y &> /dev/null
    fi
  ]],
  fakeroot = [[    set +o errexit   # does not work for some reason
    if ! dpkg -l fakeroot &> /dev/null; then
      echo "Installing fakeroot..."
      sudo apt-get update
      sudo apt-get install fakeroot -y &> /dev/null
    fi
  ]],
  ["dpkg-deb"] = [[    set +o errexit   # does not work for some reason
    if ! dpkg -l dpkg-deb &> /dev/null; then
      echo "Installing dpkg-deb..."
      sudo apt-get update
      sudo apt-get install dpkg-deb -y &> /dev/null
    fi
  ]],
  butler = [[    set +o errexit   # does not work for some reason
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
  __call = function(t, ...)
    for i = 1, select("#", ...) do
      local name = select(i, ...)
      local script = t[name]
      if not (script) then
        error("Invalid dependency check for \"" .. tostring(name) .. "\"")
      end
      print("Checking dependency: " .. tostring(name))
      print("Warning: Cannot check for dependencies, please verify dependencies yourself.")
    end
  end
})
local run_safe
run_safe = function(fn)
  local success, result = pcall(fn)
  if success and result then
    return result
  end
  return error("Cannot resolve a dependency, please check the required dependencies and install missing dependencies. Originating error: " .. tostring(result))
end
local file_exists
file_exists = function(name)
  do
    local file = io.open(name)
    if file then
      file:close()
      return true
    end
  end
end
check("love-release")
local opts = run_safe(function()
  local argparse = require("argparse")
  local parser = argparse()
  parser:name("love-build")
  parser:description("A simple wrapper for love-release, adding default options and builds for major OSes, extra options, and automated uploading to Itch.io via butler.")
  parser:argument("source", "Source directory.", "./src")
  parser:argument("build_dir", "Directory to place builds in.", "./builds")
  parser:group("Testing", parser:flag("--dry-run", "Do everything up to calling love-release, print the command to be sent to love-release, and stop."), parser:flag("--skip-butler", "Skip uploading via butler, even if configured."))
  parser:option("-v --build-version", "Specify version number of build.")
  parser:option("-l --love-version", "Specify LÖVE version to use.", "11.1")
  parser:option({
    name = "-W",
    description = "Build Windows executables (32/64 bit). (default: 32)",
    target = "windows",
    argname = "32|64",
    default = {
      {
        "32"
      }
    },
    count = "0-2",
    args = "0-1"
  })
  parser:option({
    name = "-i --include",
    description = "Include files by Lua pattern (alongside executables, not within). (Does not apply to Debian builds.)",
    argname = "file",
    count = "*",
    hidden = true
  })
  parser:option({
    name = "-x --exclude",
    description = "Exclude files in source directory by Lua pattern.",
    argname = "file",
    count = "*"
  })
  parser:flag("-D --debian", "Build a Debian package. (Not recommended.)")
  parser:group("Turning off defaults", parser:flag("-C --no-compile-moonscript", "Do not compile .moon files before building."), parser:flag("-B --no-luajit-bytecode", "Do not compile to LuaJIT bytecode."), parser:flag("-S --no-timestamp", "Do not append a timestamp to builds."), parser:flag("-X --no-mac", "Do not build a Mac OS version."), parser:flag("-L --no-love", "Do not build a version with a .love file (intended for Linux distribution)."), parser:flag("--no-version-file", "Do not write version.lua in source directory with a file returning the current version."), parser:flag("--no-overwrite-version", "Do not overwrite version.lua in source directory if it already exists."), parser:flag("--keep-moonscript", "Keep .moon files in builds."))
  parser:flag({
    name = "-M",
    description = "No effect, Mac OS applications are built by default. (Use --no-mac to disable.)",
    hidden = true
  })
  parser:group("Project metadata (love-release options)", parser:option("-a --author", "Author's full name."), parser:option({
    name = "-d --desc",
    description = "Project description.",
    target = "description"
  }), parser:option("-e --email", "Author's email."), parser:option("-p --package", "Package/Executable/Command name."), parser:option("-t --title", "Project title."), parser:option("-u --url", "Project homepage URL."), parser:option("-uti", "Project Uniform Type Identifier (it's a Mac thing)."))
  parser:option({
    name = "-I --include-file",
    description = "Include specific files (alongside executables, not within). (Does not apply to Debian builds.)",
    target = "files",
    argname = "file",
    count = "*",
    convert = io.open
  })
  parser:flag({
    name = "--version",
    description = "Print version of love-build and exit.",
    action = function()
      print("love-build " .. tostring(version))
      return os.exit(0)
    end
  })
  parser:epilog("All love-release options are also supported here. For more info, see https://github.com/Guard13007/love-build")
  return parser:parse()
end)
local options
options = {
  add = function(arg)
    return table.insert(options, arg)
  end,
  remove = function(arg)
    for i = 1, #options do
      if options[i] == arg then
        table.remove(options, i)
        return 
      end
    end
  end
}
if not (opts.no_compile_moonscript) then
  if file_exists(tostring(opts.source) .. "/main.moon") then
    check("moonscript")
    os.execute("moonc " .. tostring(opts.source))
  end
end
local conf = run_safe(function()
  return require("loadconf").parse_file(tostring(opts.source) .. "/conf.lua") or { }
end)
conf.releases = conf.releases or { }
conf.build = conf.build or { }
if conf.releases.compile ~= false or not opts.no_luajit_bytecode then
  check("luajit")
  options.add("-b")
end
opts.build_version = opts.build_version or conf.releases.version
local success
success, version = pcall(function()
  return require(tostring(opts.source) .. "/version")
end)
if success then
  opts.build_version = opts.build_version or version
end
if opts.debian and opts.build_version and (not conf.build.debian) then
  check("fakeroot")
  check("dpkg-deb")
  options.add("-D")
end
opts.love_version = opts.love_version or conf.releases.loveVersion
opts.love_version = opts.love_version or conf.version
options.add("-l " .. tostring(opts.love_version))
opts.no_timestamp = not conf.build.timestamp
if opts.build_version and not opts.no_timestamp then
  opts.build_version = opts.build_version .. tostring(opts.build_version:find("%+") and "." or "+") .. tostring(os.time(os.date("!*t")))
end
if opts.build_version then
  options.add("-v " .. tostring(opts.build_version))
end
local write_version
write_version = function()
  local file = assert(io.open(tostring(opts.source) .. "/version.lua", "w"), "Unable to open " .. tostring(opts.source) .. "/version.lua to update version information!")
  file:write("return \"" .. tostring(opts.build_version:gsub('"', '\\"')) .. "\"\n")
  return file:close()
end
if opts.build_version and (not opts.no_version_file) then
  if file_exists(tostring(opts.source) .. "/version.lua") then
    if not (opts.no_overwrite_version) then
      write_version()
    end
  else
    write_version()
  end
end
opts.author = opts.author or conf.releases.author
opts.description = opts.description or conf.releases.description
opts.email = opts.email or conf.releases.email
opts.package = opts.package or conf.releases.package
opts.title = opts.title or conf.releases.title
opts.url = opts.url or conf.releases.homepage
opts.uti = opts.uti or conf.releases.identifier
if not (opts.uti) then
  opts.uti = conf.releases.homepage or conf.releases.author or conf.releases.email
  local part2 = conf.releases.package or conf.releases.title or conf.identity
  if opts.uti then
    opts.uti = opts.uti .. "." .. tostring(part2)
  else
    opts.uti = part2
  end
  if opts.uti then
    opts.uti = opts.util:gsub("%W", "%.")
  end
end
if not (opts.keep_moonscript) then
  options.add("-x .-%.moon$")
end
if opts.exclude then
  local _list_0 = opts.exclude
  for _index_0 = 1, #_list_0 do
    local value = _list_0[_index_0]
    options.add("-x " .. tostring(value))
  end
end
if conf.releases.excludeFileList then
  local _list_0 = conf.releases.excludeFileList
  for _index_0 = 1, #_list_0 do
    local value = _list_0[_index_0]
    options.add("-x " .. tostring(value))
  end
end
local w32 = conf.build.win32
local w64 = conf.build.win64
for _, v in pairs(opts.windows) do
  if v[1] == "32" and w32 == nil then
    w32 = true
  elseif v[1] == "64" and w64 == nil then
    w64 = true
  end
end
if w32 then
  options.add("-W 32")
end
if w64 then
  options.add("-W 64")
end
if conf.build.macos ~= false and conf.build.osx ~= false and not opts.no_mac then
  options.add("-M")
end
if opts.author then
  options.add("-a " .. tostring(opts.author))
end
if opts.description then
  options.add("-d " .. tostring(opts.description))
end
if opts.email then
  options.add("-e " .. tostring(opts.email))
end
if opts.package then
  options.add("-p " .. tostring(opts.package))
end
if opts.title then
  options.add("-t " .. tostring(opts.title))
end
if opts.url then
  options.add("-u " .. tostring(opts.url))
end
if opts.uti then
  options.add("-uti " .. tostring(opts.uti))
end
options.add(opts.build_dir)
options.add(opts.source)
local command = "love-release " .. tostring(table.concat(options, " "))
if opts.dry_run then
  print(command)
  os.exit(0)
else
  os.execute(command)
end
if not (opts.skip_butler) then
  check("butler")
  print("butler upload and -I option not implemented yet!")
  return os.exit(1)
end
