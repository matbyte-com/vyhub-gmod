local f = string.format

hook.Add("vyhub_ready", "vyhub_commands_vyhub_ready", function ()
    VyHub:get_frontend_url(function (url)
        -- !shop
        for _, cmd in ipairs(VyHub.Config.commands_shop) do
            VyHub.Util:register_chat_command(cmd, function(ply, args)
                if IsValid(ply) then
                    VyHub.Util:open_url(ply, f('%s/shop', url))
                end
            end)
        end

        -- !bans
        for _, cmd in ipairs(VyHub.Config.commands_bans) do
            VyHub.Util:register_chat_command(cmd, function(ply, args)
                if IsValid(ply) then
                    VyHub.Util:open_url(ply, f('%s/bans', url))
                end
            end)
        end

        -- !warnings
        for _, cmd in ipairs(VyHub.Config.commands_warnings) do
            VyHub.Util:register_chat_command(cmd, function(ply, args)
                if IsValid(ply) then
                    VyHub.Util:open_url(ply, f('%s/warnings', url))
                end
            end)
        end

        -- !user
        for _, cmd in ipairs(VyHub.Config.commands_profile) do
            VyHub.Util:register_chat_command(cmd, function(ply, args)
                if IsValid(ply) and args[1] then
                    other_ply = VyHub.Util:get_player_by_nick(args[1])

                    if IsValid(other_ply) then
                        VyHub.Util:open_url(ply, f('%s/profile/steam/%s', url, other_ply:SteamID64()))
                    end
                end
            end)
        end
    end)
end)

