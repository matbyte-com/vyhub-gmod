local print = print
local net_Receive = net.Receive
local net_ReadString = net.ReadString
local string_Replace = string.Replace
local RunString = RunString

net_Receive("vyhub_run_lua", function()
	local lua = net_ReadString()

	print("Received VyHub Lua: " .. lua)

	if lua then
		lua = string_Replace(lua, '\\', '')

		RunString(lua) 
	end
end)

print("Loaded cl_main")