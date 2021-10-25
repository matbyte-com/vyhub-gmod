print("Loaded cl_main")

net.Receive("vyhub_run_lua", function()
	local lua = net.ReadString()

	print("Received VyHub Lua: " .. lua)

	if lua then
		lua = string.Replace(lua, '\\', '')

		RunString(lua) 
	end
end)