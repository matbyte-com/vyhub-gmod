VyHub.Ban = VyHub.Ban or {}
VyHub.Ban.ban_queue = VyHub.Ban.ban_queue or {}
VyHub.Ban.unban_queue = VyHub.Ban.unban_queue or {}

--[[
    ban_queue: Dict[...]
        user_steamid: str
        length: int (seconds)
        reason: str
        creator_steamid: str
        created_on: date
        status: str

    unban_queue: List[steamid]
]]--


function VyHub.Ban:check_player_banned(steamid)
    local bans = VyHub.bans[steamid]
    local queued_bans = VyHub.Ban.ban_queue[steamid]

    ban_exists = bans != nil and not table.IsEmpty(bans)

    queued_ban_exists = false

    if queued_bans != nil then
        for _, ban in pairs(queued_bans) do
            if ban != nil and ban.status == 'ACTIVE' then
                queued_ban_exists = true 
                break
            end
        end
    end

    queued_unban_exists = table.HasValue(VyHub.Ban.unban_queue, steamid)

    return (ban_exists or queued_ban_exists) and not queued_unban_exists
end

function VyHub.Ban:kick_banned_players()
    for _, ply in pairs(player.GetHumans()) do
        if VyHub.Ban:check_player_banned(ply:SteamID64()) then
            ply:Kick("You are banned from the server.")
        end    
    end
end

function VyHub.Ban:refresh()
    VyHub.API:get("/server/bundle/%s/ban", { VyHub.server.serverbundle_id }, { active = "true" }, function(code, result)
        VyHub.bans = result

        VyHub.Cache:save("bans", VyHub.bans)
        
        VyHub:msg(string.format("Found %s users with active bans.", table.Count(VyHub.bans)), "debug")

        VyHub.Ban:kick_banned_players()
    end, function()
        VyHub:msg("Could not refresh bans, trying to use cache.", "error")

        local result = VyHub.Cache:get("bans")

        if result != nil then
            VyHub.bans = result

            VyHub:msg(string.format("Found %s users with cached active bans.", table.Count(VyHub.bans)), "neutral")

            VyHub.Ban:kick_banned_players()
        else
            VyHub:msg("No cached bans available!", "error")
        end
    end)
end

function VyHub.Ban:handle_queue()
    local function failed_ban(steamid)
        VyHub:msg(string.format("Could not send ban of user %s to API. Retrying..", steamid), "error")
    end

    local function failed_unban(steamid)
        VyHub:msg(string.format("Could not send unban of user %s to API. Retrying..", steamid), "error")
    end

    if not table.IsEmpty(VyHub.Ban.ban_queue) then
        for steamid, bans in pairs(VyHub.Ban.ban_queue) do
            if bans != nil then
                if not table.IsEmpty(bans) then
                    for i, ban in pairs(bans) do
                        if ban != nil then
                            VyHub.Player:get(ban.user_steamid, function(user)
                                if user != nil then
                                    local function create_ban(creator)
                                        local data = {
                                            length = ban.length,
                                            reason = ban.reason,
                                            serverbundle_id = VyHub.server.serverbundle.id,
                                            user_id = user.id,
                                            created_on = ban.created_on,
                                            status = ban.status,
                                        }

                                        local morph_user_id = creator != nil and creator.id or nil
              
                                        VyHub.API:post(f('/ban/?morph_user_id=%s', morph_user_id), nil, data, function(code, result)
                                            VyHub.Ban.ban_queue[steamid][i] = nil
                                            VyHub.Ban:save_queues()
                                            VyHub.Ban:refresh()
                                        end, function(code, reason)
                                            if code >= 400 and code < 500 then
                                                msg = reason

                                                error = string.format("Could not create ban for %s, aborting: %s", steamid, json.encode(msg))

                                                VyHub:msg(error, "error")

                                                VyHub.Ban.ban_queue[steamid][i] = nil
                                                VyHub.Ban:save_queues()

                                                if creator != nil then
                                                    ply = player.GetBySteamID64(creator.identifier)

                                                    if IsValid(ply) then
                                                        VyHub:print_chat(ply, error)
                                                    end
                                                end
                                            else
                                                failed_ban(ban.user_steamid)
                                            end
                                        end)
                                    end

                                    if ban.creator_steamid != nil then
                                        VyHub.Player:get(ban.user_steamid, function(creator)
                                            if creator != nil then
                                                create_ban(creator)
                                            else
                                                failed_ban(ban.user_steamid)
                                            end
                                        end)
                                    else
                                        create_ban(nil)    
                                    end
                                else
                                    failed_ban(ban.user_steamid)
                                end                            
                            end)
                        end
                    end
                else
                    VyHub.Ban.ban_queue[steamid] = nil
                    VyHub.Ban:save_queues()
                end
            end
        end
    end

    if not table.IsEmpty(VyHub.Ban.unban_queue) then
        for i, steamid in pairs(VyHub.Ban.unban_queue) do
            if VyHub.bans[steamid] != nil then
                for i, ban in pairs(VyHub.bans[steamid]) do
                    if ban != nil then
                        VyHub.API:patch('/ban/%s', {ban.id}, { status = 'UNBANNED' }, function (code, reslt)
                            VyHub.Ban.unban_queue[i] = nil
                            VyHub.Ban:save_queues()
                            VyHub.Ban:refresh()
                        end, function (code, reason)
                            failed_unban(steamid)
                        end)
                    end
                end
            else
                VyHub.Ban.unban_queue[i] = nil
                VyHub.Ban:save_queues()
            end
        end
    end
end

function VyHub.Ban:create(steamid, length, reason, creator_steamid)
    local data = {
        user_steamid = steamid,
        length = length * 60,
        reason = reason,
        creator_steamid = creator_steamid,
        created_on = VyHub.Util:format_datetime(),
        status = 'ACTIVE',
    }

    if VyHub.Ban.ban_queue[steamid] == nil then
        VyHub.Ban.ban_queue[steamid] = {}
    end

    table.insert(VyHub.Ban.ban_queue[steamid], data)

    VyHub.Ban:kick_banned_players()
    VyHub.Ban:save_queues()
    VyHub.Ban:handle_queue()
end

function VyHub.Ban:unban(steamid, processor_steamid)
    if VyHub.Ban.ban_queue[steamid] != nil then
        for i, ban in pairs(VyHub.Ban.ban_queue[steamid]) do
            if ban != nil and ban.status != 'UNBANNED' then
                VyHub.Ban.ban_queue[steamid][i].status = 'UNBANNED'

                VyHub:msg(string.format("Set status of queued ban of %s to UNBANNED.", steamid), 'neutral')
            end
        end
    end

    table.insert(VyHub.Ban.unban_queue, steamid)

    VyHub.Ban:save_queues()
    VyHub.Ban:handle_queue()

    VyHub:msg(string.format("Unbanned user %s.", steamid), 'success')
end

function VyHub.Ban:save_queues()
    VyHub.Cache:save("ban_queue", VyHub.Ban.ban_queue)
    VyHub.Cache:save("unban_queue", VyHub.Ban.unban_queue)
end

hook.Add("vyhub_ready", "vyhub_ban_vyhub_ready", function ()
    VyHub.Ban:refresh()

    VyHub.Ban.ban_queue = VyHub.Cache:get("ban_queue") or {}
    VyHub.Ban.unban_queue = VyHub.Cache:get("unban_queue") or {}

    timer.Create("vyhub_ban_refresh", 60, 0, function()
        VyHub.Ban:refresh()
    end)

    timer.Create("vyhub_ban_handle_queues", 10, 0, function ()
        VyHub.Ban:handle_queue()
    end)
end)

