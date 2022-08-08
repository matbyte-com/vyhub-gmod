VyHub.Config.date_format = VyHub.Config.date_format or "%Y-%m-%d %H:%M:%S %z"

if SERVER then
    VyHub.Config.advert_interval = VyHub.Config.advert_interval or 180 
    VyHub.Config.advert_prefix = "[★] " 

    -- Do not allow too small refresh intervals
    if VyHub.Config.player_refresh_time < 5 then
        VyHub.Config.player_refresh_time = 5
    end
    if VyHub.Config.group_refresh_time < 5 then
        VyHub.Config.group_refresh_time = 5
    end
end