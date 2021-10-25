if SERVER then
	util.AddNetworkString("vyhub_run_lua")
end

function VyHub:replace_colors(message)
	message = string.Replace(message, '"', '')
	message = string.Replace(message, '<red>', '", Color(255, 24, 35), "')
	message = string.Replace(message, '</red>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<green>', '", Color(45, 170, 0), "')
	message = string.Replace(message, '</green>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<blue>', '", Color(0, 115, 204), "')
	message = string.Replace(message, '</blue>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<yellow>', '", Color(229, 221, 0), "')
	message = string.Replace(message, '</yellow>', '", Color(255, 255, 255), "')
	message = string.Replace(message, '<pink>', '", Color(229, 0, 218), "')
	message = string.Replace(message, '</pink>', '", Color(255, 255, 255), "')

	return message
end

function VyHub:print_chat(ply, message, tag, color)
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

			message = string.Replace(message, '\r', '')
			message = string.Replace(message, '\n', '')

			message = VyHub:replace_colors(message)

			local tosend = [[chat.AddText(]] .. tag .. [[Color(]] .. color .. [[), "]] .. message .. [[" )]]

			net.Start("vyhub_run_lua")
				net.WriteString(tosend)
			net.Send(ply)
		end
	end
end