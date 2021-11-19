VyHub.Warning = VyHub.Warning or {}

function VyHub.Warning:create(steamid, reason, processor_steamid)
    processor_steamid = processor_steamid or nil

    VyHub.Player:get(steamid, function (user)
        if user == nil then
            VyHub.Util:print_chat_steamid(processor_steamid, f("<red>Cannot find VyHub user with SteamID %s.</red>", steamid))
        end

        VyHub.Player:get(processor_steamid, function (processor)
            if processor_steamid != nil and processor == nil then
                return
            end

            local url = '/warning'

            if processor != nil then
                url = url .. f('?morph_user_id=%s', processor.id)
            end

            VyHub.API:post(url, nil, {
                reason = reason,
                serverbundle_id = VyHub.server.serverbundle.id,
                user_id = user.id
            }, function (code, result)
                VyHub.Ban:refresh()
                VyHub:msg(f("Added warning for player <green>%s</green>: %s", user.username, reason))
                VyHub.Util:print_chat_steamid(processor_steamid, f("Added warning for player <green>%s</green>: %s", user.username, reason))
            end, function (code, err_reason, _, err_text)
                VyHub:msg(f("Error while adding warning for player <green>%s</green>: %s", user.username, err_text), "error")
                VyHub.Util:print_chat_steamid(processor_steamid, f("Error while adding warning for player <green>%s</green>: %s", user.username, err_text))
            end)
        end)
    end)
end


hook.Add("vyhub_ready", "vyhub_warning_vyhub_ready", function ()   
    concommand.Add("vh_warn", function(ply, _, args)
        if not args[1] or not args[2] then return end

        if VyHub.Util:is_server(ply) then
            VyHub.Warning:create(args[1], args[2])
        elseif IsValid(ply) then
            VyHub.Warning:create(args[1], args[2], ply:SteamID64())
        end
    end)

    VyHub.Util:register_chat_command("!warn", function(ply, args)
		if not args[1] or not args[2] then return end

		local reason = VyHub.Util:concat_args(args, 2)

		local target = VyHub.Util:get_player_by_nick(args[1])

		if target and IsValid(target) then
			local nickparts = string.Explode(' ', target:Nick())

			if #nickparts > 1 then
				nickparts = VyHub.Util:concat_args(nickparts, 2) .. ' '
				reason = string.Replace(reason, nickparts, '')
			end

			VyHub.Warning:create(target:SteamID64(), reason, ply:SteamID64())

			return false;
		end
	end)
end)