local function printUsage()
    print( "Usages:" )
    print( "install <branch>" )
end

local citadel_os = require('citadel/citadel_os')
local tArgs = { ... }
if #tArgs > 1 then
    printUsage()
    return
elseif #tArgs == 1 then
    citadel_os.branch = tArgs[1]
end

local function sync_file(manifest, manifest_file)
    local source_url = manifest.url..manifest.branch.."/"..manifest_file.source
    local target_file = shell.resolve((manifest_file.label == "installer" and "tmp/"..manifest_file.target) or manifest_file.target)
    if fs.exists(target_file) then
        fs.delete(target_file)
    end

    local ok, err = http.checkURL( source_url )
    if not ok then
        return nil, err
    end

    local response = http.get( source_url , nil , true )
    if not response then
        return nil, "no response"
    end

    local s_response = response.readAll()
    response.close()

    local file = fs.open( target_file, "wb" )
    file.write( s_response )
    file.close()

    return target_file, nil
end

-- first we update citadel_os

local path, err = sync_file(citadel_os, citadel_os.get_citadel_os_file())
if err ~= nil then
    print("Error syncing installer: "..err)
    return
end
citadel_os = require(path)

if type(citadel_os) ~= "table" or citadel_os.version == nil then
    print("Error loading CitadelOS: could not load table or version")
    return
end

local sync_files = citadel_os.get_files()
for _,file in pairs(sync_files) do
    sync_file(citadel_os, file)
end

slowPrint("Installed CitadelOS "..citadel_os.version..".....")
shell.run("reboot")