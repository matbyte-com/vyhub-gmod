VyHub.groups_mapped = VyHub.groups_mapped or nil

local net_Receive = net.Receive
local net_ReadTable = net.ReadTable

net_Receive("vyhub_group_data", function()
	VyHub.groups_mapped = net_ReadTable()
end)