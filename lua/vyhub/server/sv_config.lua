function VyHub.Config:load_cache_config()
    local ccfg = VyHub.Cache:get("config")

    if ccfg != nil and #table.GetKeys(ccfg) > 0 then
        VyHub.Config = table.Merge(VyHub.Config, ccfg)
        VyHub:msg(f("Loaded cache config values: %s", table.concat(table.GetKeys(ccfg), ', ')))
    end
end

concommand.Add("vh_config", function (ply, _, args)
    if not VyHub.Util:is_server(ply) then return end

    local ccfg = VyHub.Cache:get("config")

    if not args[1] or not args[2] then 
        if istable(ccfg) then
            VyHub:msg("Additional config options:")
            PrintTable(ccfg)
        else
            VyHub:msg("No additional config options set.")
        end
        return
    end

    local key = args[1]
    local value = args[2]

    if not istable(ccfg) then
        ccfg = {}
    end

    ccfg[key] = value
    VyHub.Cache:save("config", ccfg)

    VyHub.Config[key] = value

    VyHub:msg(f("Successfully set config value %s.", key))
end)

concommand.Add("vh_config_reset", function (ply)
    if not VyHub.Util:is_server(ply) then return end

    VyHub.Cache:save("config", {})

    VyHub:msg(f("Successfully cleared additional config.", key))
end)