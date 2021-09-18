
hook.Add("vyhub_ready", "vyhub_group_vyhub_ready", function ()
    VyHub.API:get("/group", nil, { serverbundle_id = VyHub.server.serverbundle_id }, function(code, result)
        VyHub.groups = result
        
        VyHub:msg(string.format("Found groups: %s", json.encode(result)), "debug")
    end)
end)