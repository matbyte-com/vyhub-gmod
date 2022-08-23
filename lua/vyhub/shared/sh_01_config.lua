-- DEFAULTS
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

    VyHub.Config.ban_message = VyHub.Config.ban_message or ">>> Ban Message <<<" .. "\n\n"
    .. VyHub.lang.other.reason .. ": %reason%" .. "\n" 
    .. VyHub.lang.other.ban_date .. ": %ban_date%" .. "\n" 
    .. VyHub.lang.other.unban_date .. ": %unban_date%" .. "\n" 
    .. VyHub.lang.other.admin .. ": %admin%" .. "\n" 
    .. VyHub.lang.other.id .. ": %id%" .. "\n\n" 
    .. VyHub.lang.other.unban_url .. ": %unban_url%" .. "\n\n" 
end
