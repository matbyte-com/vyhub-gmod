VyHub.Statistic = VyHub.Statistic or {}
VyHub.Statistic.playtime = VyHub.Statistic.playtime or {}
VyHub.Statistic.attr_def = VyHub.Statistic.attr_def or nil

local pairs = pairs
local player_GetHumans = player.GetHumans
local string_len = string.len
local table_GetKeys = table.GetKeys
local timer_Create = timer.Create
local table_Count = table.Count
local table_remove = table.remove
local math_Round = math.Round
local tostring = tostring
local hook_Add = hook.Add

function VyHub.Statistic:save_playtime()
    VyHub:msg(f("Saved playtime statistics: %s", json.encode(VyHub.Statistic.playtime)), "debug")

    VyHub.Cache:save("playtime", VyHub.Statistic.playtime)
end

function VyHub.Statistic:add_one_minute()
    for _, ply in pairs(player_GetHumans()) do
        local steamid = ply:SteamID64()
        ply:VyHubID(function (user_id)
            if user_id == nil or string_len(user_id) < 10 then
                VyHub:msg(f("Could not add playtime for user %s", steamid))
                return
            end

            VyHub.Statistic.playtime[user_id] = VyHub.Statistic.playtime[user_id] or 0
            VyHub.Statistic.playtime[user_id] = VyHub.Statistic.playtime[user_id] + 60
        end)
    end

    VyHub.Statistic:save_playtime()
end

function VyHub.Statistic:send_playtime()
    VyHub.Statistic:get_or_create_attr_definition(function (attr_def)
        if attr_def == nil then
            VyHub:msg("Could not send playtime statistics to API.", "warning")
            return
        end

        user_ids = table_GetKeys(VyHub.Statistic.playtime)
            
        timer_Create("vyhub_send_stats", 0.3, table_Count(user_ids), function ()
            i =  table_Count(user_ids)
            user_id = user_ids[i]

            if user_id != nil then
                seconds = VyHub.Statistic.playtime[user_id]
                table_remove(user_ids, i)

                if seconds != nil and seconds > 0 then
                    local hours = math_Round(seconds / 60 / 60, 2)

                    if hours > 0 then
                        if string_len(user_id) < 10 then
                            VyHub.Statistic.playtime[user_id] = nil
                            return
                        end

                        VyHub.API:post("/user/attribute/", nil, {
                            definition_id = attr_def.id,
                            user_id = user_id,
                            serverbundle_id = VyHub.server.serverbundle.id,
                            value = tostring(hours),
                        }, function (code, result)
                            VyHub.Statistic.playtime[user_id] = nil
                            VyHub.Statistic:save_playtime()
                        end, function (code, reason)
                            VyHub:msg(f("Could not send %s seconds playtime of %s to API.", seconds, user_id), "warning")
                        end)
                    end
                else
                    VyHub.Statistic.playtime[user_id] = nil
                end
            end
        end)
    end)
end

function VyHub.Statistic:get_or_create_attr_definition(callback)
    local function cb_wrapper(attr_def)
        VyHub.Statistic.attr_def = attr_def

        callback(attr_def)
    end

    if VyHub.Statistic.attr_def != nil then
        callback(VyHub.Statistic.attr_def)
        return
    end

    VyHub.API:get("/user/attribute/definition/%s", { "playtime" }, nil, function (code, result)
        VyHub.Cache:save("playtime_attr_def", result)
        cb_wrapper(result)
    end, function (code, reason)
        if code != 404 then
            local attr_def = VyHub.Cache:get("playtime_attr_def")

            cb_wrapper(attr_def)
        else
            VyHub.API:post("/user/attribute/definition/", nil, {
                name = "playtime",
                title = "Play Time",
                unit = "Hours",
                type = "ACCUMULATED",
                accumulation_interval = "day",
                unspecific = "true",
            }, function (code, result)
                VyHub.Cache:save("playtime_attr_def", result)
                cb_wrapper(result)
            end, function (code, reason)
                cb_wrapper(nil)
            end)
        end
    end)
end

hook_Add("vyhub_ready", "vyhub_reward_vyhub_ready", function ()
    VyHub.Statistic.playtime = VyHub.Cache:get("playtime") or {}

    VyHub.Statistic:send_playtime()

    timer_Create("vyhub_statistic_playtime_tick", 60, 0, function ()
        VyHub.Statistic:add_one_minute()
    end)

    timer_Create("vyhub_statistic_send_playtime", 3600, 0, function ()
        VyHub.Statistic:send_playtime()
    end)
end)