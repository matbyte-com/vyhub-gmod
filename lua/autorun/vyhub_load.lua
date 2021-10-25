
VyHub = VyHub or {}
VyHub.Config = VyHub.Config or {}
VyHub.ready = false

f = string.format

local vyhub_root = "vyhub"

function VyHub:msg(message, type)
    type = type or "neutral"

	if type == "success" then
		MsgC("[VyHub] ", Color(0, 255, 0), message .. "\n")
	elseif type == "error" then
		MsgC("[VyHub] ", Color(255, 0, 0), message .. "\n")
	elseif type == "neutral" then
		MsgC("[VyHub] ", Color(255, 255, 255), message .. "\n")
    elseif type == "warning" then
		MsgC("[VyHub] ", Color(211, 120, 0), message .. "\n")
    elseif type == "debug" and VyHub.Config.debug then
		MsgC("[VyHub] [Debug] ", Color(255, 255, 255), message .. "\n")
	end
end

VyHub:msg("Initializing...")

hook.Run("vyhub_loading_start")

if SERVER then
    -- libs
    VyHub:msg("Loading lib files...")
    local files = file.Find( vyhub_root .."/lib/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        AddCSLuaFile( vyhub_root .. "/lib/" .. file )
        include( vyhub_root .. "/lib/" .. file )
    end

    -- Config Files
    VyHub:msg("Loading config files...")
    include( vyhub_root .. '/config/sv_config.lua' )
    include( vyhub_root .. '/config/sh_config.lua' )
    AddCSLuaFile( vyhub_root .. "/config/sh_config.lua" )

    -- Language
    VyHub:msg('Loading ' .. VyHub.Config.lang .. ' language...')
    include( vyhub_root .. '/lang/' .. VyHub.Config.lang .. '.lua' )
    AddCSLuaFile( vyhub_root .. '/lang/' .. VyHub.Config.lang .. '.lua' )

    --Client Files
    VyHub:msg("Loading client files...")
    local files = file.Find( vyhub_root .."/client/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        AddCSLuaFile( vyhub_root .."/client/" .. file )
    end

    -- Shared Files
    VyHub:msg("Loading shared files...")
    local files = file.Find( vyhub_root .."/shared/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        AddCSLuaFile( vyhub_root .. "/shared/" .. file )
        include( vyhub_root .. "/shared/" .. file )
    end

    -- Server Files
    VyHub:msg("Loading server files...")
    local files = file.Find( vyhub_root .. "/server/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        include( vyhub_root .. "/server/" .. file )
    end

    game.ConsoleCommand("sv_hibernate_think 1\n")

    file.CreateDir("vyhub")
end

if CLIENT then
    -- libs
    VyHub:msg("Loading lib files...")
    local files = file.Find( vyhub_root .."/lib/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        include( vyhub_root .. "/lib/" .. file )
    end

    --Config Files
    VyHub:msg("Loading config files...")
    local files = file.Find( vyhub_root .."/config/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        if not string.StartWith(file, 'sv_') then
            include( vyhub_root .. "/config/" .. file )
        end
    end

    -- Language
    VyHub:msg('Loading ' .. VyHub.Config.lang .. ' language...')
    include( vyhub_root .. '/lang/' .. VyHub.Config.lang .. '.lua' )

    --Client Files
    VyHub:msg("Loading client files...")
    local files = file.Find( vyhub_root .."/client/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        include( vyhub_root .."/client/" .. file )
    end

    --Shared Files
    VyHub:msg("Loading shared files...")
    local files = file.Find( vyhub_root .."/shared/*.lua", "LUA" )
    for _, file in ipairs( files ) do
        include( vyhub_root .. "/shared/" .. file )
    end
end

timer.Simple(2, function()
    hook.Run("vyhub_loading_finish")
end)

VyHub:msg("Finished loading!")