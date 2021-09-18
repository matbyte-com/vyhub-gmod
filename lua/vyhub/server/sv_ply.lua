VyHub.Player = VyHub.Player or {}

VyHub.Player.connect_queue = VyHub.Player.connect_queue or {}
VyHub.Player.table = VyHub.Player.table or {}

function VyHub.Player:Initialize(ply, retry)
    if not IsValid(ply) then return end

    VyHub:msg(string.format("Initializing user %s, %s", ply:Nick(), ply:SteamID64()))

    VyHub.API:get("/user/%s", {ply:SteamID64()}, nil, function(code, result)
        VyHub:msg(string.format("Found existing user %s for steam id %s.", result.id, ply:SteamID64()), "success")

        VyHub.Player.table[ply:SteamID64()] = result

        hook.Run("vyhub_ply_initialized", ply)
    end, function()
        if retry then
            VyHub:msg(string.format("Could not create user %s. Retrying in a minute..", ply:SteamID64()), "error")

            timer.Simple(60, function()
                VyHub.Player:Initialize(ply)
            end)

            return
        end

        VyHub:msg(string.format("No existing user found for steam id %s. Creating..", ply:SteamID64()))

        VyHub.API:post('/user/', nil, { identifier = ply:SteamID64(), type = 'STEAM' }, function()
            VyHub.Player:Initialize(ply, true)
        end, function()
            VyHub.Player:Initialize(ply, true)
        end)
    end)
end

function VyHub.Player:get(steamid64, callback)
    if VyHub.Player.table[steamid64] != nil then
        callback(VyHub.Player.table[steamid64])
    else
        VyHub.API:get("/user/%s", {steamid64}, nil, function(code, result)
            VyHub:msg(string.format("Received user %s for steam id %s.", result.id, steamid64), "debug")
    
            VyHub.Player.table[ply:SteamID64()] = result

            callback(result)
        end, function()
            VyHub:msg(string.format("Could not receive user %s.", steamid64), "error")

            callback(nil)
        end)
    end
end


hook.Add("vyhub_ply_connected", "vyhub_ply_vyhub_ply_connected", function(ply)
    VyHub.Player:Initialize(ply)
end)

hook.Add("PlayerInitialSpawn","vyhub_ply_PlayerInitialSpawn", function(ply)
	if VyHub.ready then
		hook.Run("vyhub_ply_connected", ply)
	else
		VyHub.Player.connect_queue[#VyHub.Player.connect_queue+1] = ply
	end
end)


hook.Add("vyhub_ready", "vyhub_ply_vyhub_ready", function ()
    timer.Simple(5, function()
        for _, ply in pairs(VyHub.Player.connect_queue) do
            if IsValid(ply) then
                hook.Run("vyhub_ply_connected", ply)
            end
        end

        VyHub.Player.connect_queue = {}
    end)
end)