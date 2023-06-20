local f = string.format

VyHub.Player = VyHub.Player or {}

VyHub.Player.connect_queue = VyHub.Player.connect_queue or {}
VyHub.Player.table = VyHub.Player.table or {}

local meta_ply = FindMetaTable("Player")

function VyHub.Player:initialize(ply, retry)
    if not IsValid(ply) then return end

    local steamid = ply:SteamID64()

    VyHub:msg(f("Initializing user %s, %s", ply:Nick(), steamid))

    VyHub.API:get("/user/%s", {steamid}, {type = "STEAM"}, function(code, result)
        VyHub:msg(f("Found existing user %s for steam id %s (%s).", result.id, steamid, ply:Nick()), "success")

        VyHub.Player.table[steamid] = result
        ply:SetNWString("vyhub_id", result.id)
        ply:SetNWBool("vyhub_admin", result.admin)

        VyHub.Player:refresh(ply)

        hook.Run("vyhub_ply_initialized", ply)

        local ply_timer_name = "vyhub_player_" .. steamid

        timer.Create(ply_timer_name, VyHub.Config.player_refresh_time, 0, function()
            if IsValid(ply) then
                VyHub.Player:refresh(ply)
            else
                timer.Remove(ply_timer_name)
            end
        end)
    end, function(code, reason)
        if code != 404 then
            VyHub:msg(f("Could not check if users %s exists. Retrying in a minute..", steamid), "error")

            timer.Simple(60, function ()
                VyHub.Player:initialize(ply)
            end)

            return
        end

        if retry then
            VyHub:msg(f("Could not create user %s. Retrying in a minute..", steamid), "error")

            timer.Simple(60, function()
                VyHub.Player:initialize(ply)
            end)

            return
        end

        VyHub.Player:create(steamid, function()
            VyHub.Player:initialize(ply, true)
        end, function ()
            VyHub.Player:initialize(ply, true)
        end)
    end, { 404 })
end

local creation_began = {}
local creation_success = {}
local creation_err = {}

function VyHub.Player:create(steamid, success, err)
    -- Creation can take longer. If multiple creation requests occur, merge them to one.
    if not istable(creation_success[steamid]) then creation_success[steamid] = {} end
    if not istable(creation_err[steamid]) then creation_err[steamid] = {} end

    table.insert(creation_success[steamid], success)
    table.insert(creation_err[steamid], err)

    if creation_began[steamid] and os.time() - creation_began[steamid] < 10 then
        VyHub:msg(f("Queued creation request for steamid %s", steamid), "debug")
        return
    end

    VyHub:msg(f("No existing user found for steam id %s. Creating..", steamid))

    creation_began[steamid] = os.time()

    local function reset_queue()
        creation_began[steamid] = 0
        creation_success[steamid] = {}
        creation_err[steamid] = {}
    end

    VyHub.API:post('/user/', nil, { identifier = steamid, type = 'STEAM' }, function()
        for _, success_callback in pairs(creation_success[steamid]) do
            if success_callback then
                success_callback()
            end
        end
        reset_queue()
    end, function()
        for _, err_callback in pairs(creation_err[steamid]) do
            if err_callback then
                err_callback()
            end
        end
        reset_queue()
    end)
end

-- Return nil if steamid is nil or API error
-- Return false if steamid is false or could not create user
function VyHub.Player:get(steamid, callback, retry)
    if steamid == nil then
        callback(nil)
        return
    end

    if steamid == false then
        callback(false)
        return
    end

    if VyHub.Player.table[steamid] != nil then
        callback(VyHub.Player.table[steamid])
    else
        VyHub.API:get("/user/%s", {steamid}, {type = "STEAM"}, function(code, result)
            VyHub:msg(f("Received user %s for steam id %s.", result.id, steamid), "debug")
    
            VyHub.Player.table[steamid] = result

            callback(result)
        end, function(code)
            VyHub:msg(f("Could not receive user %s.", steamid), "error")

            if code == 404 and retry == nil then
                VyHub.Player:create(steamid, function ()
                    VyHub.Player:get(steamid, callback, true)
                end, function ()
                    callback(false)
                end)
            else
                callback(nil)
            end
        end, {404})
    end
end

function VyHub.Player:check_group(ply, callback)
    if ply:VyHubID() == nil then
        VyHub:msg(f("Could not check groups for user %s, because no VyHub id is available.", ply:SteamID64()), "debug")
        return
    end

    VyHub.API:get("/user/%s/group", {ply:VyHubID()}, { serverbundle_id = VyHub.server.serverbundle_id }, function(code, result)
        if not IsValid(ply) then return end

        local steamid64 = ply:SteamID64()
        local nick = ply:Nick()

        local highest = nil

        for _, group in pairs(result) do
            if highest == nil or highest.permission_level < group.permission_level then
                highest = group
            end
        end

        if highest == nil then
            VyHub:msg(f("Could not find any active group for %s (%s)", nick, steamid64), "error")
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
            VyHub:msg(f("Could not find group name mapping for group %s.", highest.name), "error")
            return
        end

        local curr_group = ply:GetUserGroup()

        if curr_group != group then
            VyHub.Group.group_changes[steamid64] = group

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
            
            VyHub:msg("Added " .. nick .. " to group " .. group, "success")
            VyHub.Util:print_chat(ply, f(VyHub.lang.ply.group_changed, group))
        end
    end, function()
        
    end)
end

function VyHub.Player:refresh(ply, callback)
    VyHub.Player:check_group(ply)
end

function VyHub.Player:get_group(ply)
    if not IsValid(ply) then
        return nil
    end

    local group = VyHub.groups_mapped[ply:GetUserGroup()]

    if group == nil then
        return nil
    end

    return group
end

function VyHub.Player:check_property(ply, property)
    if not IsValid(ply) then return false end

    local group = VyHub.Player:get_group(ply)

    if group != nil then
        local prop = group.properties[property]

        if prop != nil and prop.granted then
            return true 
        end
    end

    if ply:GetNWBool("vyhub_admin", false) then
        return true
    end

    return false
end

function meta_ply:VyHubID(callback)
    if IsValid(self) then
        local id = self:GetNWString("vyhub_id", nil)

        if id == nil or id == "" then
            VyHub.Player:get(self:SteamID64(), function(user)
                if user then
                    self:SetNWString("vyhub_id", user.id)

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
end

hook.Add("vyhub_ply_connected", "vyhub_ply_vyhub_ply_connected", function(ply)
    VyHub.Player:initialize(ply)
end)

hook.Add("PlayerInitialSpawn","vyhub_ply_PlayerInitialSpawn", function(ply)
    if IsValid(ply) and not ply:IsBot() then
        if VyHub.ready then
            hook.Run("vyhub_ply_connected", ply)
        else
            VyHub.Player.connect_queue[#VyHub.Player.connect_queue+1] = ply
        end
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
