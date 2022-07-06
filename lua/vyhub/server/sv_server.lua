VyHub.Server = VyHub.Server or {}

VyHub.Server.extra_defaults = {
    res_slots = 0,
    res_slots_keep_free = false,
    res_slots_hide = false,
}

local pairs = pairs
local player_GetHumans = player.GetHumans
local string_FormattedTime = string.FormattedTime
local table_insert = table.insert
local player_GetAll = player.GetAll
local game_GetMap = game.GetMap
local string_format = string.format
local RunConsoleCommand = RunConsoleCommand
local game_MaxPlayers = game.MaxPlayers
local hook_Add = hook.Add
local timer_Create = timer.Create
local IsValid = IsValid
local timer_Remove = timer.Remove

function VyHub.Server:get_extra(key)
    if VyHub.server.extra != nil and VyHub.server.extra[key] != nil then
        return VyHub.server.extra[key]
    end

    return VyHub.Server.extra_defaults[key]
end

function VyHub.Server:update_status()
    local user_activities = {}

    for _, ply in pairs(player_GetHumans()) do
        local id = ply:VyHubID()

        if id != nil then
            local tt = string_FormattedTime(ply:TimeConnected())

            table_insert(user_activities, { user_id = id, extra = { 
                Score = ply:Frags(), 
                Deaths = ply:Deaths(), 
                Nickname = ply:Nick(),
                Playtime = f('%02d:%02d:%02d', tt.h, tt.m, tt.s), 
            }})
        end
    end

    local data = {
        users_max = VyHub.Server.max_slots_visible,
        users_current = #player_GetAll(),
        map = game_GetMap(),
        is_alive = true,
        user_activities = user_activities,
    }

    VyHub:msg(string_format("Updating status: %s", json.encode(data)), "debug")

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
    VyHub.Server.max_slots = game_MaxPlayers() - VyHub.Server:get_extra("res_slots")
    VyHub.Server.max_slots_visible = VyHub.Server.max_slots

    if VyHub.Server:get_extra("res_slots_hide") then
		VyHub.Server:update_max_slots()

		hook_Add("PlayerDisconnected", "vyhub_server_PlayerDisconnected", function(ply)
			timer_Create("vyhub_slots", 0.5, 20, function()
				if not IsValid(ply) then
					timer_Remove("vyhub_slots")
					VyHub.Server:update_max_slots()
				end
			end)
		end)
	else
		VyHub.Server.max_slots_visible = game_MaxPlayers()
	end
end

hook_Add("vyhub_ready", "vyhub_server_vyhub_ready", function ()
    VyHub.Server:init_slots()
    VyHub.Server:update_status()

    timer_Create("vyhub_status_update", 60, 0, function ()
        VyHub.Server:update_status()
    end)

    VyHub.Util:register_chat_command("!dashboard", function(ply, args)
		if ply and IsValid(ply) then
            VyHub:get_frontend_url(function (url)
                ply:vh_open_url(f('%s/server-dashboard/%s', url, VyHub.server.id))
            end)
		end
	end)
end)