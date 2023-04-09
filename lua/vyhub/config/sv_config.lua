-- VyHub Server Config
-- BEWARE: Additional config values can be set in data/vyhub/config.json with the `vh_config <key> <value>` console command.
--         The configuration in this file is overwritten by the configuration in data/vyhub/config.json

-- ONLY SET THE 3 FOLLOWING OPTIONS IF YOU KNOW WHAT YOU ARE DOING!
-- PLEASE FOLLOW THE INSTALLATION INSTRUCTIONS HERE: https://docs.vyhub.net/latest/game/gmod/#installation
VyHub.Config.api_url = "" -- https://api.vyhub.app/<name>/v1
VyHub.Config.api_key = "" -- Admin -> Settings -> Server -> Setup
VyHub.Config.server_id = "" -- Admin -> Settings -> Server -> Setup

-- Player groups are checked every X seconds
VyHub.Config.player_refresh_time = 120
-- Groups are refreshed every X seconds
VyHub.Config.group_refresh_time = 300
-- Every X seconds, an advert message is shown.
VyHub.Config.advert_interval = 180 

-- Printed before every advert line
VyHub.Config.advert_prefix = "[★] " 

-- Replace ULib ban list with VyHub bans
VyHub.Config.replace_ulib_bans = false

-- Customize the ban message that banned players see when trying to connect
VyHub.Config.ban_message = ">>> Ban Message <<<" .. "\n\n"
.. VyHub.lang.other.reason .. ": %reason%" .. "\n" 
.. VyHub.lang.other.ban_date .. ": %ban_date%" .. "\n" 
.. VyHub.lang.other.unban_date .. ": %unban_date%" .. "\n" 
.. VyHub.lang.other.admin .. ": %admin%" .. "\n" 
.. VyHub.lang.other.id .. ": %id%" .. "\n\n" 
.. VyHub.lang.other.unban_url .. ": %unban_url%" .. "\n\n" 