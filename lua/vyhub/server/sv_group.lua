
VyHub.Group = VyHub.Group or {}

VyHub.groups = VyHub.groups or nil
VyHub.groups_mapped = VyHub.groups_mapped or nil

function VyHub.Group:refresh()
    VyHub.API:get("/group", nil, { serverbundle_id = VyHub.server.serverbundle_id }, function(code, result)
        if result != VyHub.groups then
            VyHub.groups = result
        
            VyHub:msg(string.format("Found groups: %s", json.encode(result)), "debug")

            VyHub.groups_mapped = {}

            local no_server_group = {}

            for _, group in pairs(VyHub.groups) do
                local server_group = group.properties['server_group']

                if server_group != nil and isstring(server_group.value) then
                    VyHub.groups_mapped[server_group.value] = group
                else
                    no_server_group[group.name] = group
                end
            end

            for name, group in pairs(no_server_group) do
                if VyHub.groups_mapped[name] == nil then
                    VyHub.groups_mapped[name] = group
                end
            end
        end
    end)
end

function VyHub.Group:set(steamid, groupname, seconds, callback)
    if VyHub.groups_mapped[groupname] == nil then
        VyHub:msg(f("Could not find VyHub group with name %s", groupname), "error")

        if callback then
            callback(false)
            return
        end
        return 
    end

    VyHub.Player:get(steamid, function (user)
        if user == nil then
            if callback then
                callback(false)
                return
            end
        end

        local end_date = nil 

        if minutes != nil then
            end_date = VyHub.Util:format_datetime(os.time() + seconds)
        end

        VyHub.API:post('/user/%s/membership', {user.id}, {
            begin = VyHub.Util.format_datetime(),
            ["end"] = end_date,
            group_id = group_id,
        }, function (code, result)
            VyHub:msg(f("Added %s to group %s.", steamid, group_id), "success")

            local ply = player.GetBySteamID64(steamid)

            if IsValid(ply) then
                VyHub.Player:refresh(ply)
            end

            if callback then
                callback(true)
            end
        end, function (reason)
            VyHub:msg(f("Could not add %s to group %s.", steamid, group_id), "error")
            if callback then
                callback(false)
            end
        end)
    end)
end

hook.Add("vyhub_ready", "vyhub_group_vyhub_ready", function ()
    VyHub.Group:refresh()

    timer.Create("vyhub_group_refresh", VyHub.Config.group_refresh_time, 0, function ()
        VyHub.Group:refresh()
    end)
end)