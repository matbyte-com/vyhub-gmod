VyHub.Server = VyHub.Server or {}

VyHub.Server.extra_defaults = {
    res_slots = 0,
    res_slots_keep_free = false,
    res_slots_hide = false,
}

function VyHub.Server:get_extra(key)
    if VyHub.server.extra[key] != nil then
        return VyHub.server.extra[key]
    end

    return VyHub.Server.extra_defaults[key]
end

function VyHub.Server:update_status()
    local data = {
        users_max = VyHub.Server.max_slots_visible,
        users_current = #player.GetAll(),
        map = game.GetMap(),
        is_alive = true,
    }

    VyHub:msg(string.format("Updating status: %s", util.TableToJSON(data)), "debug")

    VyHub.API:patch(
        '/server/%s',
        {VyHub.server.id},
        data,
        nil,
        function ()
            VyHub:msg("Could not update server status.", "error")
        end
    )
end

function VyHub.Server:update_max_slots()
	RunConsoleCommand("sv_visiblemaxplayers", VyHub.Server.max_slots_visible)
end

function VyHub.Server:init_slots()
    VyHub.Server.max_slots = game.MaxPlayers() - VyHub.Server:get_extra("res_slots")
    VyHub.Server.max_slots_visible = VyHub.Server.max_slots

    if VyHub.Server:get_extra("res_slots_hide") then
		VyHub.Server:update_max_slots()

		hook.Add("PlayerDisconnected", "vyhub_server_PlayerDisconnected", function(ply)
			timer.Create("vyhub_slots", 0.5, 20, function()
				if not IsValid(ply) then
					timer.Remove("vyhub_slots")
					VyHub.Server:update_max_slots()
				end
			end)
		end)
	else
		VyHub.Server.max_slots_visible = game.MaxPlayers()
	end
end

hook.Add("vyhub_ready", "vyhub_server_vyhub_ready", function ()
    VyHub.Server:init_slots()
    VyHub.Server:update_status()

    timer.Create("vyhub_status_update", 60, 0, function ()
        VyHub.Server:update_status()
    end)
end)