VyHub.Player = VyHub.Player or {}

VyHub.Player.connect_queue = VyHub.Player.connect_queue or {}
VyHub.Player.table = VyHub.Player.table or {}

local meta_ply = FindMetaTable("Player")

function VyHub.Player:initialize(ply, retry)
    if not IsValid(ply) then return end

    VyHub:msg(string.format("Initializing user %s, %s", ply:Nick(), ply:SteamID64()))

    VyHub.API:get("/user/%s", {ply:SteamID64()}, {type = "STEAM"}, function(code, result)
        VyHub:msg(string.format("Found existing user %s for steam id %s (%s).", result.id, ply:SteamID64(), ply:Nick()), "success")

        VyHub.Player.table[ply:SteamID64()] = result
        ply:SetNWString("vyhub_id", result.id)

        VyHub.Player:refresh(ply)

        hook.Run("vyhub_ply_initialized", ply)

        local ply_timer_name = "vyhub_player_" .. ply:SteamID64()

        timer.Create(ply_timer_name, VyHub.Config.player_refresh_time, 0, function()
            if IsValid(ply) then
                VyHub.Player:refresh(ply)
            else
                timer.Remove(ply_timer_name)
            end
        end)
    end, function(code, reason)
        if code != 404 then
            VyHub:msg(string.format("Could not check if users %s exists. Retrying in a minute..", ply:SteamID64()), "error")

            timer.Simple(60, function ()
                VyHub.Player:initialize(ply)
            end)

            return
        end

        if retry then
            VyHub:msg(string.format("Could not create user %s. Retrying in a minute..", ply:SteamID64()), "error")

            timer.Simple(60, function()
                VyHub.Player:initialize(ply)
            end)

            return
        end

        VyHub:msg(string.format("No existing user found for steam id %s. Creating..", ply:SteamID64()))

        VyHub.API:post('/user/', nil, { identifier = ply:SteamID64(), type = 'STEAM' }, function()
            VyHub.Player:initialize(ply, true)
        end, function()
            VyHub.Player:initialize(ply, true)
        end)
    end)
end

function VyHub.Player:get(steamid, callback)
    if steamid == nil then
        callback(nil)
        return
    end

    if steamid == false  then
        callback(false)
        return
    end

    if VyHub.Player.table[steamid] != nil then
        callback(VyHub.Player.table[steamid])
    else
        VyHub.API:get("/user/%s", {steamid}, {type = "STEAM"}, function(code, result)
            VyHub:msg(string.format("Received user %s for steam id %s.", result.id, steamid), "debug")
    
            VyHub.Player.table[steamid] = result

            callback(result)
        end, function(code)
            VyHub:msg(string.format("Could not receive user %s.", steamid), "error")

            if code == 404 then
                callback(false)
            else
                callback(nil)
            end
        end)
    end
end

function VyHub.Player:check_group(ply, callback)
    if ply:VyHubID() == nil then
        VyHub:msg(f("Could not check groups for user %s, because no VyHub id is available.", ply:SteamID64()), "debug")
        return
    end

    VyHub.API:get("/user/%s/group", {ply:VyHubID()}, { serverbundle_id = VyHub.server.serverbundle_id }, function(code, result)
        local highest = nil

        for _, group in pairs(result) do
            if highest == nil or highest.permission_level < group.permission_level then
                highest = group
            end
        end

        if highest == nil then
            VyHub:msg(string.format("Could not find any active group for %s", ply:SteamID64()), "error")
            return
        end

        local group = nil

        for _, mapping in pairs(highest.mappings) do
            if mapping.serverbundle_id == nil or mapping.serverbundle_id == VyHub.server.serverbundle.id then
                group = mapping.name
                break
            end
        end

        if group == nil then
            VyHub:msg(string.format("Could not find group name mapping for group %s.", highest.name), "error")
            return
        end

        curr_group = ply:GetUserGroup()

        if curr_group != group then
            if serverguard then
                serverguard.player:SetRank(ply, group, false, true)
            elseif ulx then
                ULib.ucl.addUser( ply:SteamID(), {}, {}, group, true )
            elseif sam then
                sam.player.set_rank(ply, group, 0, true)
            elseif xAdmin and xAdmin.Admin.RegisterBan then
                xAdmin.SetGroup(ply, group, true)
            else
                ply:SetUserGroup(group, true)
            end
            
            VyHub:msg("Added " .. ply:Nick() .. " to group " .. group, "success")
            VyHub.Util:print_chat(ply, f(VyHub.lang.ply.group_changed, group))
        end
    end, function()
        
    end)
end

function VyHub.Player:refresh(ply, callback)
    VyHub.Player:check_group(ply)
end

function meta_ply:VyHubID(callback)
    local id = self:GetNWString("vyhub_id", nil)

    if id == nil then
        VyHub.Player:get(self:SteamID64(), function(user)
            if user != nil then
                ply:SetNWString("vyhub_id", user.id)

                if callback then
                    callback(user.id)
                end
            else
                if callback then
                    callback(nil)
                end
            end
        end)
    else
        if callback then
            callback(id)
        end
    end
    
    return id
end

hook.Add("vyhub_ply_connected", "vyhub_ply_vyhub_ply_connected", function(ply)
    VyHub.Player:initialize(ply)
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