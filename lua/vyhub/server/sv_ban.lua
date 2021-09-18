VyHub.Ban = VyHub.Ban or {}
VyHub.Ban.ban_queue = VyHub.Ban.ban_queue or {}
VyHub.Ban.unban_queue = VyHub.Ban.ban_queue or {}

--[[
    ban_queue: Dict[...]
        user_steamid: str
        length: int (seconds)
        reason: str
        creator_steamid: str
        created_on: date

    unban_queue: List[steamid]
]]--


function VyHub.Ban:check_player_banned(ply)
    local bans = VyHub.bans[ply:SteamID64()]
    local queued_bans = VyHub.Ban.ban_queue[ply:SteamID64()]

    ban_exists = bans != nil and not table.IsEmpty(bans)
    queued_ban_exists = queued_bans != nil and not table.IsEmpty(queued_bans)
    queued_unban_exists = VyHub.Ban.unban_queue.HasValue(ply:SteamID64())

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
    VyHub.API:get("/server/bundle/%s/ban", { VyHub.server.serverbundle_id }, { active = true }, function(code, result)
        VyHub.bans = result

        VyHub.Cache:save("bans", VyHub.bans)
        
        VyHub:msg(string.format("Found %s users with active bans.", #VyHub.bans), "debug")

        VyHub.Ban:kick_banned_players()
    end, function()
        VyHub:msg(string.format("Could not refresh bans, trying to use cache.", #VyHub.bans), "error")

        local result = VyHub.Cache:get("bans")

        if result != nil then
            VyHub.bans = result

            VyHub:msg(string.format("Found %s users with cached active bans.", #VyHub.bans), "neutral")

            VyHub.Ban:kick_banned_players()
        else
            VyHub:msg("No cached bans available!", "error")
        end
    end)
end



function VyHub.Ban:handle_queue()
    local function failed_ban(steamid)
        VyHub:msg(string.format("Could not send ban of user %s to API.", steamid), "error")
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
                                            creator_id = creator != nil and creator.id or nil,
                                            created_on = ban.created_on,
                                        }

                                        VyHub.API:post('/ban', nil, data, function(code, result)
                                            VyHub.Ban.ban_queue[steamid][i] = nil
                                            VyHub.Ban:refresh()
                                        end, function(reason)
                                            failed_ban(ban.user_steamid)
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
                end
            end
        end
    end
end

function VyHub.Ban:create(steamid, length, reason, creator_steamid)
    local tz_wrong = os.date("%z")
    local timezone = string.format("%s:%s", string.sub(tz_wrong, 1, 2), string.sub(tz_wrong, 3, 4))

    local data = {
        user_steamid = steamid,
        length = length * 60,
        reason = reason,
        creator_steamid = creator_steamid,
        created_on = os.date("%Y-%m-%dT%H:%M:%S" .. timezone)
    }

    PrintTable(data)

    if VyHub.Ban.ban_queue[steamid] == nil then
        VyHub.Ban.ban_queue[steamid] = {}
    end

    table.insert(VyHub.Ban.ban_queue[steamid], data)

    VyHub.Ban:handle_queue()
end

hook.Add("vyhub_ready", "vyhub_ban_vyhub_ready", function ()
    VyHub.Ban:refresh()

    timer.Create("vyhub_ban_refresh", 60, 0, function()
        VyHub.Ban:refresh()
    end)

    timer.Create("vyhub_ban_handle_queues", 10, 0, function ()
        VyHub.Ban:handle_queue()
    end)
end)

