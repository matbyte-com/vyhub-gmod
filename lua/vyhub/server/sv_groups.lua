
hook.Add("vyhub_ready", "vyhub_groups_vyhub_ready", function ()
    print("vyhub ready groups")
    VyHub.API.get("/group", nil, { serverbundle_id = VyHub.server.serverbundle_id }, function(code, result)
        VyHub.groups = result
        
        VyHub:msg(string.format("Found groups: %s", util.TableToJSON(result)), "debug")
    end)
end)