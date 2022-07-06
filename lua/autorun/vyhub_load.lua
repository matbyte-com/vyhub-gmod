VyHub = VyHub or {}
VyHub.Config = VyHub.Config or {}
VyHub.ready = false

f = string.format

local vyhub_root = "vyhub"
local MsgC = MsgC
local Color = Color
local color_green = Color(0, 255, 0)
local color_red = Color(255, 0 , 0)
local color_orange = Color(211, 120, 0)
local file_Exists = file.Exists
local hook_Run = hook.Run
local file_Find = file.Find
local ipairs = ipairs
local AddCSLuaFile = AddCSLuaFile
local include = include
local game_ConsoleCommand = SERVER and game.ConsoleCommand
local file_CreateDir = file.CreateDir
local timer_Simple = timer.Simple
local string_StartWith = string.StartWith

function VyHub:msg(message, type)
    type = type or "neutral"

	if type == "success" then
		MsgC("[VyHub] ", color_green, message .. "\n")
	elseif type == "error" then
		MsgC("[VyHub] ", color_red, message .. "\n")
	elseif type == "neutral" then
		MsgC("[VyHub] ", color_white, message .. "\n")
    elseif type == "warning" then
		MsgC("[VyHub] ", color_orange, message .. "\n")
    elseif type == "debug" and VyHub.Config.debug then
		MsgC("[VyHub] [Debug] ", color_white, message .. "\n")
	end
end

VyHub:msg("Initializing...")

if SERVER then
    if file_Exists(vyhub_root .. "/config/sv_config.lua", "LUA") then
        hook_Run("vyhub_loading_start")

        -- libs
        VyHub:msg("Loading lib files...")
        local files = file_Find(vyhub_root .."/lib/*.lua", "LUA")
        for _, file in ipairs(files) do
            AddCSLuaFile(vyhub_root .. "/lib/" .. file)
            include(vyhub_root .. "/lib/" .. file)
        end

        -- Shared Config
        include(vyhub_root .. "/config/sh_config.lua")
        AddCSLuaFile(vyhub_root .. "/config/sh_config.lua")

        -- Language
        VyHub:msg("Loading " .. VyHub.Config.lang .. " language...")
        include(vyhub_root .. "/lang/" .. VyHub.Config.lang .. ".lua")
        AddCSLuaFile(vyhub_root .. "/lang/" .. VyHub.Config.lang .. ".lua")

        -- Config Files
        VyHub:msg("Loading config files...")
        include(vyhub_root .. "/config/sv_config.lua")

        -- Shared Files
        VyHub:msg("Loading shared files...")
        local files = file_Find(vyhub_root .."/shared/*.lua", "LUA")
        for _, file in ipairs(files) do
            AddCSLuaFile(vyhub_root .. "/shared/" .. file)
            include(vyhub_root .. "/shared/" .. file)
        end

        --Client Files
        VyHub:msg("Loading client files...")
        local files = file_Find(vyhub_root .."/client/*.lua", "LUA")
        for _, file in ipairs(files) do
            AddCSLuaFile(vyhub_root .."/client/" .. file)
        end

        -- Server Files
        VyHub:msg("Loading server files...")
        local files = file_Find(vyhub_root .. "/server/*.lua", "LUA")
        for _, file in ipairs(files) do
            include(vyhub_root .. "/server/" .. file)
        end

        game_ConsoleCommand("sv_hibernate_think 1\n")

        file_CreateDir("vyhub")

        timer_Simple(2, function()
            hook_Run("vyhub_loading_finish")
        end)

        VyHub:msg("Finished loading!")
    else
        VyHub:msg("Could not find lua/vyhub/config/sv_config.lua. Please make sure it exists.", "error")
    end
end


if CLIENT then
    hook_Run("vyhub_loading_start")

    -- libs
    VyHub:msg("Loading lib files...")
    local files = file_Find(vyhub_root .."/lib/*.lua", "LUA")
    for _, file in ipairs(files) do
        include(vyhub_root .. "/lib/" .. file)
    end

    --Config Files
    VyHub:msg("Loading config files...")
    local files = file_Find(vyhub_root .."/config/*.lua", "LUA")
    for _, file in ipairs(files) do
        if not string_StartWith(file, "sv_") then
            include(vyhub_root .. "/config/" .. file)
        end
    end

    -- Language
    VyHub:msg("Loading " .. VyHub.Config.lang .. " language...")
    include(vyhub_root .. "/lang/" .. VyHub.Config.lang .. ".lua")

    --Shared Files
    VyHub:msg("Loading shared files...")
    local files = file_Find(vyhub_root .."/shared/*.lua", "LUA")
    for _, file in ipairs(files) do
        include(vyhub_root .. "/shared/" .. file)
    end

    --Client Files
    VyHub:msg("Loading client files...")
    local files = file_Find(vyhub_root .."/client/*.lua", "LUA")
    for _, file in ipairs(files) do
        include(vyhub_root .."/client/" .. file)
    end

    timer_Simple(2, function()
        hook_Run("vyhub_loading_finish")
    end)

    VyHub:msg("Finished loading!")
end