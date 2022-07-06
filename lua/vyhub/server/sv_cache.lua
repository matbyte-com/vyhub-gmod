VyHub.Cache = VyHub.Cache or {}

local os_time = os.time
local string_format = string.format
local file_Write = file.Write
local file_Exists = file.Exists
local file_Read = file.Read

function VyHub.Cache:save(key, value)
    local data = {
        timestamp = os_time(),
        data = value
    }

    local filename = string_format("vyhub/%s.json", key)
    local json = json.encode(data)

    VyHub:msg("Write " .. filename .. ": " .. json, "debuga")

    file_Write(filename, json)
end

function VyHub.Cache:get(key, max_age)
    local path = string_format("vyhub/%s.json", key)

    if not file_Exists(path, "data") then
        return nil
    end

    local data = json.decode(file_Read(path, "data"))

    if istable(data) and data.timestamp and data.data then
        if max_age != nil and os_time() - data.timestamp > max_age then
            return nil
        end

        return data.data
    end

    return nil
end