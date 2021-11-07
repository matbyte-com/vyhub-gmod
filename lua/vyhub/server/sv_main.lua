VyHub.theme = VyHub.theme or nil

function VyHub:server_data_ready()
    VyHub:msg(string.format("I am server %s in bundle %s.", VyHub.server.name, VyHub.server.serverbundle.name))

    hook.Run("vyhub_ready")
end

function VyHub:get_theme(callback)
    if VyHub.theme != nil then
        return VyHub.theme
    end

    VyHub.API:get('/design/theme', nil, nil, function (code, result)
        VyHub.theme = result
        VyHub.Cache:save('theme', result)

        callback(theme)
    end, function ()
        local theme = VyHub.Cache:get('theme')

        if theme == nil then
            VyHub:msg("Could not get theme!", "error")
        end

        callback(theme)
    end)
end

hook.Add("vyhub_api_ready", "vyhub_main_vyhub_api_ready", function ()
    VyHub.API:get("/server/%s", { VyHub.Config.server_id }, nil, function(code, result) 
        VyHub.server = result

        VyHub.Cache:save("server", VyHub.server)

        VyHub:server_data_ready()
    end, function (code, result)
        VyHub:msg(string.format("Could not find server with id %s", VyHub.Config.server_id))
    end)
end)

hook.Add("vyhub_api_failed", "vyhub_main_vyhub_api_failed", function ()
    local server = VyHub.Cache:get("server", 604800)

    if server != nil then
        VyHub.server = server

        VyHub:server_data_ready()
    else
        VyHub:msg("Could not find cached server data or cached data is too old. Please make sure that the server is able to reach the VyHub API.", "error")
        
        timer.Simple(60, function ()
            hook.Run("vyhub_loading_finish")
        end)
    end
end)