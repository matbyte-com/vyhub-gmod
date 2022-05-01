VyHub.groups_mapped = VyHub.groups_mapped or nil

net.Receive("vyhub_group_data", function()
	VyHub.groups_mapped = net.ReadTable()
end)