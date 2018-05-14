local loveReleaseCheck = [[  echo Checking dependencies...
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
local moonCheck = [[  echo Checking dependencies for moonscript...
  if ! command -v moonc &> /dev/null; then
    echo "Installing moonscript..."
    sudo -H luarocks install moonscript &> /dev/null
  fi
]]
local mkdebCheck = [[  echo Checking dependencies for making .deb files...
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
local luajitCheck = [[  echo Checking dependencies for compiling to bytecode...
  if ! command -v luajit &> /dev/null; then
    echo "Installing LuaJIT..."
    sudo apt-get update
    sudo apt-get install luajit -y &> /dev/null
  fi
]]
local butlerCheck = [[  echo Checking dependencies for butler...
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
local exists
exists = function(name)
  do
    local file = io.open(name)
    if file then
      file:close()
      return true
    end
  end
end
local getopts
getopts = function(args, ...)
  if args == nil then
    args = { }
  end
  local opts = { }
  local ignoreNext = false
  for flag in pairs(args) do
    if "table" == type(flag) then
      args[flag] = setmetatable(flag, {
        __tostring = function(t)
          return table.concat(t, "|")
        end
      })
    end
  end
  local valueless
  valueless = function(flag)
    local arg = args[flag]
    if not (arg) then
      for k, v in pairs(args) do
        if "table" == type(k) then
          for _index_0 = 1, #k do
            local a = k[_index_0]
            if a == flag then
              arg = v
              break
            end
          end
        end
      end
    end
    if "table" == type(arg) then
      return not arg[1]
    else
      return not arg
    end
  end
  local required
  required = function(flag)
    local arg = args[flag]
    if not (arg) then
      for k, v in pairs(args) do
        if "table" == type(k) then
          for _index_0 = 1, #k do
            local a = k[_index_0]
            if a == flag then
              arg = v
              break
            end
          end
        end
      end
    end
    if "table" == type(arg) then
      return arg[1]
    else
      return arg == true
    end
  end
  for i = 1, select("#", ...) do
    local _continue_0 = false
    repeat
      if ignoreNext then
        ignoreNext = false
        _continue_0 = true
        break
      end
      local flag = select(i, ...)
      local value = select(i + 1, ...)
      local count
      flag, count = flag:gsub("%-", "")
      if count > 0 then
        if not value or valueless(flag) then
          opts[flag] = true
        else
          local _
          _, count = value:gsub("%-", "")
          if count > 0 then
            opts[flag] = true
          else
            opts[flag] = value
            ignoreNext = true
          end
        end
      else
        opts[#opts + 1] = flag
      end
      _continue_0 = true
    until true
    if not _continue_0 then
      break
    end
  end
  for flag in pairs(args) do
    if required(flag) then
      exists = false
      if "table" == type(flag) then
        for _index_0 = 1, #flag do
          local key = flag[_index_0]
          exists = exists or opts[key]
        end
      else
        exists = opts[flag]
      end
      if not (exists) then
        error("Required argument '" .. tostring(flag) .. "' not specified!")
      end
    end
  end
  return opts
end
local opts = getopts({
  [1] = "Source directory.",
  [2] = "Builds directory.",
  ["dry-run"] = {
    false,
    "Skip uploading via butler."
  },
  [{
    "v",
    "version"
  }] = "Specify version number of build.",
  [{
    "l",
    "love"
  }] = "Specify LÖVE version to use."
}, ...)
opts[1] = opts[1] or "./src"
opts[2] = opts[2] or "./builds"
os.execute(loveReleaseCheck)
if exists(tostring(opts[1]) .. "/main.moon") then
  os.execute(moonCheck)
  os.execute("moonc " .. tostring(opts[1]))
end
local love = { }
local config = setmetatable({ }, {
  __index = function(t, k)
    t[k] = { }
    return t[k]
  end
})
if pcall(function()
  return require(tostring(opts[1]) .. "/conf")
end) then
  if love.conf then
    love.conf(config)
  end
end
pcall(function()
  local version = require(tostring(opts[1]) .. "/version")
  config.releases.version = version
end)
local loveReleaseOptions = {
  "-D",
  "-M",
  "-W 32",
  "-b"
}
local removeOption
removeOption = function(name)
  for k, v in ipairs(loveReleaseOptions) do
    if v == name then
      table.remove(loveReleaseOptions, k)
      break
    end
  end
end
if opts.version or opts.v then
  config.releases.version = opts.version or opts.v
end
if config.releases.version then
  if config.build.timestamp ~= false then
    config.releases.version = config.releases.version .. tostring(config.releases.version:find("%+") and "." or "+") .. tostring(os.time(os.date("!*t")))
  end
  table.insert(loveReleaseOptions, "-v " .. tostring(config.releases.version))
else
  removeOption("-D")
end
if opts.love or opts.l then
  config.releases.loveVersion = opts.love or opts.l
end
config.releases.loveVersion = config.releases.loveVersion or (config.version or "11.1")
table.insert(loveReleaseOptions, "-l " .. tostring(config.releases.loveVersion))
if opts.uti then
  config.releases.identifier = opts.uti
end
config.releases.identifier = config.releases.identifier or (config.identity and config.identity:gsub("%W", ""))
if config.releases.compile == false then
  removeOption("-b")
end
if config.build.debian == false then
  removeOption("-D")
end
if config.build.macos == false or config.build.osx == false then
  removeOption("-M")
end
if config.build.win64 or config.build.win32 == false then
  removeOption("-W 32")
  if config.build.win32 then
    table.insert(loveReleaseOptions, "-W")
  else
    table.insert(loveReleaseOptions, "-W 64")
  end
end
if opts.version or opts.v or config.build.timestamp ~= false then
  local file = io.open(tostring(opts[1]) .. "/version.lua", "w")
  file:write("return \"" .. tostring(config.releases.version) .. "\"\n")
  file:close()
end
local optionSet
optionSet = function(name)
  for _index_0 = 1, #loveReleaseOptions do
    local option = loveReleaseOptions[_index_0]
    if option == name then
      return true
    end
  end
end
if optionSet("-D") then
  os.execute(mkdebCheck)
end
if optionSet("-b") then
  os.execute(luajitCheck)
end
local command = "love-release " .. tostring(table.concat(loveReleaseOptions, " ")) .. " \"" .. tostring(opts[2]) .. "\" \"" .. tostring(opts[1]) .. "\""
return print(command)
