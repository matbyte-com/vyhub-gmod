
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

                if serAppliedPacketModelver_group != nil and isstring(server_group.value) then
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
    end, function (code, reason)
        VyHub:msg("Could not refresh groups. Retrying in a minute.", "error")
        timer.Simple(60, function ()
            VyHub.Group:refresh()
        end)
    end)
end

function VyHub.Group:set(steamid, groupname, seconds, processor_id, callback)
    if VyHub.groups_mapped == nil then
        VyHub:msg("Groups not initialized yet. Please try again later.", "error")

        return
    end

    group = VyHub.groups_mapped[groupname]

    if group == nil then
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

        if seconds != nil then
            end_date = VyHub.Util:format_datetime(os.time() + seconds)
        end

        local url = '/user/%s/membership'

        if processor_id != nil then
            url = url .. '?morph_user_id=' .. processor_id
        end

        VyHub.API:post(url, {user.id}, {
            begin = VyHub.Util.format_datetime(),
            ["end"] = end_date,
            group_id = group.id,
            morph_user_id  = processor_id,
        }, function (code, result)
            VyHub:msg(f("Added %s to group %s.", steamid, groupname), "success")

            local ply = player.GetBySteamID64(steamid)

            if IsValid(ply) then
                VyHub.Player:refresh(ply)
            end

            if callback then
                callback(true)
            end
        end, function (code, reason)
            VyHub:msg(f("Could not add %s to group %s.", steamid, groupname), "error")
            if callback then
                callback(false)
            end
        end)
    end)
end

function VyHub.Group:remove(steamid, processor_id, callback)
    VyHub.Player:get(steamid, function (user)
        if user == nil then
            if callback then
                callback(false)
                return
            end
        end

        local url = '/user/%s/membership'

        if processor_id != nil then
            url = url .. '?morph_user_id=' .. processor_id
        end

        VyHub.API:delete(url, {user.id}, function (code, result)
            VyHub:msg(f("Removed %s from all groups.", steamid), "success")

            local ply = player.GetBySteamID64(steamid)

            if IsValid(ply) then
                VyHub.Player:refresh(ply)
            end

            if callback then
                callback(true)
            end
        end, function (code, reason)
            VyHub:msg(f("Could not remove %s from all groups.", steamid), "error")

            if callback then
                callback(false)
            end
        end)
    end)
end

hook.Add("vyhub_ready", "vyhub_group_vyhub_ready", function ()
    local meta_ply = FindMetaTable("Player")

    VyHub.Group:refresh()

    timer.Create("vyhub_group_refresh", VyHub.Config.group_refresh_time, 0, function ()
        VyHub.Group:refresh()
    end)

	concommand.Add("vyhub_setgroup", function(ply, _, args)
		if VyHub.Util:is_server(ply) then
			local steamid = args[1]
			local group = args[2]
			local bundle = args[3]

			if steamid and group then
				VyHub.Group:set(steamid, group)
			end
		end
	end, _, bit.bor(FCVAR_SERVER_CAN_EXECUTE, FCVAR_PROTECTED))

	local _setusergroup = meta_ply.SetUserGroup

	if not ULib and not serverguard then
		meta_ply.SetUserGroup = function(ply, name, ignore_vh)
			if not ignore_vh then
				if VyHub.Group:set(ply:SteamID64(), name) or VyHub.Config.disable_group_check then
					_setusergroup(ply, name)
				end
			else
				_setusergroup(ply, name)
			end
		end
	end

	if ULib then
		local ulx_adduser = ULib.ucl.addUser
		local ulx_removeuser = ULib.ucl.removeUser

		ULib.ucl.addUser = function(steamid32, allow, deny, groupname, ignore_vh)
			if not ignore_vh then
                local steamid64 = util.SteamIDTo64(steamid32)
				VyHub.Group:set(steamid64, groupname, nil, nil, function(success)
                    if success then
                        ulx_adduser( steamid32, allow, deny, groupname )
                    end
                end)
			end
		end

		ULib.ucl.removeUser = function(id)
			local steamid64 = nil

			if string.find(id, ":") then
				steamid64 = util.SteamIDTo64(id)
			else
				local ply = player.GetByUniqueID(id)

				if IsValid(ply) then
					steamid64 = ply:SteamID64()
				end
			end

			if steamid64 then
                VyHub.Group:remove(steamid64, nil, function (success)
                    if success then
                        ulx_removeuser( id )
                    end
                end)
			end
		end
	end
	
	if serverguard then
		local servergaurd_setrank = serverguard.player["SetRank"]

		function serverguard.player:SetRank(target, rank, length, ignore_vh)
			if not ignore_vh then
				if target then
					if type(target) == "Player" and IsValid(target) then
                        VyHub.Group:set(target:SteamID64(), rank, nil, nil, function(success)
                            if success then
                                servergaurd_setrank(self, target, rank, length)
                            end
                        end)
					elseif type(target) == "string" and string.match(target, "STEAM_%d:%d:%d+") then
						local steamid = util.SteamIDTo64(target)

                        VyHub.Group:set(steamid, rank, nil, nil, function(success)
                            if success then
                                servergaurd_setrank(self, target, rank, length)
                            end
                        end)
					end
				end
			end
		end
	end
end)