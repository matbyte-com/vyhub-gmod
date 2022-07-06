VyHub.Util = VyHub.Util or {}
VyHub.Util.chat_commands = VyHub.Util.chat_commands or {}

local util_AddNetworkString = SERVER and util.AddNetworkString
local os_time = os.time
local os_date = os.date
local string_format = string.format
local string_sub = string.sub
local IsValid = IsValid
local string_lower = string.lower
local ipairs = ipairs
local player_GetHumans = player.GetHumans
local string_find = string.find
local pairs = pairs
local tostring = tostring
local string_Implode = string.Implode
local hook_Add = hook.Add
local string_Explode = string.Explode
local table_remove = table.remove
local string_Replace = string.Replace
local net_Start = net.Start
local net_WriteString = net.WriteString
local net_Send = SERVER and net.Send
local player_GetBySteamID64 = player.GetBySteamID64
local string_len = string.len
local Color = Color
local tonumber = tonumber

if SERVER then
	util_AddNetworkString("vyhub_run_lua")
end

function VyHub.Util:format_datetime(unix_timestamp)
    unix_timestamp = unix_timestamp or os_time()

    local tz_wrong = os_date("%z", unix_timestamp)
    local timezone = string_format("%s:%s", string_sub(tz_wrong, 1, 3), string_sub(tz_wrong, 4, 5))

    return os_date("%Y-%m-%dT%H:%M:%S" .. timezone, unix_timestamp)
end

function VyHub.Util:is_server(obj)
	if type(obj) == "Entity" and (obj.EntIndex and obj:EntIndex() == 0) and !IsValid(obj) then
		return true
	else
		return false
	end
end

function VyHub.Util:iso_to_unix_timestamp(datetime)
	if datetime == nil then return nil end

	local pd = date(datetime)

	if pd == nil then return nil end

	local time = os_time({
			year = pd:getyear(),
			month = pd:getmonth(),
			day = pd:getday(),
			hour = pd:gethours(),
			minute = pd:getminutes(),
			second = pd:getseconds(),
		})

	return time
end

function VyHub.Util:get_ply_by_nick(nick)
	nick = string_lower(nick);
	
	for _,v in ipairs(player_GetHumans()) do
		if(string_find(string_lower(v:Name()), nick, 1, true) != nil)
			then return v;
		end
	end
end

function VyHub.Util:register_chat_command(strCommand, Func)
	if !strCommand || !Func then return end
	
	for k, v in pairs( VyHub.Util.chat_commands ) do
		if( strCommand == k ) then
			return
		end
	end
	
	VyHub.Util.chat_commands[ tostring( strCommand ) ] = Func;
end

function VyHub.Util:concat_args(args, pos)
	local toconcat = {}

	if pos > 1 then
		for i = pos, #args, 1 do
			toconcat[#toconcat+1] = args[i]
		end
	end

	return string_Implode(" ", toconcat)
end

hook_Add("PlayerSay", "vyhub_util_PlayerSay", function(ply, message)
	if not VyHub.ready then
		VyHub.Util:print_chat(ply, "<red>VyHub is not ready yet.</red>")
		return
	end

	local chat_string = string_Explode(" ", message)
	local found = false
	local ret = nil

	for k, v in pairs( VyHub.Util.chat_commands ) do
		if not found then
			if( string_lower(chat_string[1]) == string_lower(k) ) then
				table_remove(chat_string, 1)
				ret = v(ply, chat_string)
				found = true
			end
		end
	end

	if ret != nil then
		return ret
	end
end)

function VyHub.Util:replace_colors(message)
	message = string_Replace(message, '"', '')
	message = string_Replace(message, '<red>', '", Color(255, 24, 35), "')
	message = string_Replace(message, '</red>', '", Color(255, 255, 255), "')
	message = string_Replace(message, '<green>', '", Color(45, 170, 0), "')
	message = string_Replace(message, '</green>', '", Color(255, 255, 255), "')
	message = string_Replace(message, '<blue>', '", Color(0, 115, 204), "')
	message = string_Replace(message, '</blue>', '", Color(255, 255, 255), "')
	message = string_Replace(message, '<yellow>', '", Color(229, 221, 0), "')
	message = string_Replace(message, '</yellow>', '", Color(255, 255, 255), "')
	message = string_Replace(message, '<pink>', '", Color(229, 0, 218), "')
	message = string_Replace(message, '</pink>', '", Color(255, 255, 255), "')

	return message
end

function VyHub.Util:print_chat(ply, message, tag, color)
	if SERVER then
		if IsValid(ply) then
			if not VyHub.Config.chat_tag then
				VyHub.Config.chat_tag = "VyHub"
			end

			if not tag then
				tag = [[Color(0, 187, 255), "[]] .. VyHub.Config.chat_tag .. [[] ", ]]
			end

			if not color then
				color = [[255, 255, 255]]
			end

			message = string_Replace(message, '"', '')
			message = string_Replace(message, '\r', '')
			message = string_Replace(message, '\n', '')

			message = VyHub.Util:replace_colors(message)

			local tosend = [[chat.AddText(]] .. tag .. [[Color(]] .. color .. [[), "]] .. message .. [[" )]]

			net_Start("vyhub_run_lua")
				net_WriteString(tosend)
			net_Send(ply)
		end
	end
end

function VyHub.Util:print_chat_steamid(steamid, message, tag, color)
	if steamid != nil and steamid != false then
		ply = player_GetBySteamID64(steamid)

		if IsValid(ply) then
			VyHub.Util:print_chat(ply,  message, tag, color)
		end
	end
end

function VyHub.Util:play_sound_steamid(steamid, url)
	if steamid != nil and steamid != false then
		ply = player_GetBySteamID64(steamid)

		if IsValid(ply) then
			net_Start("vyhub_run_lua")
				net_WriteString([[sound.PlayURL ( "]] .. url .. [[", "", function() end)]])
			net_Send(ply)
		end
	end
end

function VyHub.Util:print_chat_all(message, tag, color)
	for _, ply in pairs(player_GetHumans()) do
		VyHub.Util:print_chat(ply, message, tag, color)
	end
end

function VyHub.Util:get_player_by_nick(nick)
	nick = string_lower(nick);
	
	for _,v in ipairs(player_GetHumans()) do
		if(string_find(string_lower(v:Name()), nick, 1, true) != nil)
			then return v;
		end
	end
end

function VyHub.Util:hex2rgb(hex)
    hex = hex:gsub("#","")
    if(string_len(hex) == 3) then
        return Color(tonumber("0x"..hex:sub(1,1)) * 17, tonumber("0x"..hex:sub(2,2)) * 17, tonumber("0x"..hex:sub(3,3)) * 17)
    elseif(string_len(hex) == 6) then
        return Color(tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6)))
    else
    	return color_white
    end
end