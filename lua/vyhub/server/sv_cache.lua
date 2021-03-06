VyHub.Cache = VyHub.Cache or {}

function VyHub.Cache:save(key, value)
    local data = {
        timestamp = os.time(),
        data = value
    }

    local filename = string.format("vyhub/%s.json", key)
    local json = json.encode(data)

    VyHub:msg("Write " .. filename .. ": " .. json, "debuga")

    file.Write(filename, json)
end

function VyHub.Cache:get(key, max_age)
    local path = string.format("vyhub/%s.json", key)

    if not file.Exists(path, "data") then
        return nil
    end

    local data = json.decode(file.Read(path, "data"))

    if istable(data) and data.timestamp and data.data then
        if max_age != nil and os.time() - data.timestamp > max_age then
            return nil
        end

        return data.data
    end

    return nil
end