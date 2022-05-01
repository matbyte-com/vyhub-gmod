if VyHub.Config.chat_tags and not DarkRP then
	hook.Add("OnPlayerChat", "vyhub_chattag_OnPlayerChat", function(ply, msg)
		if IsValid(ply) then
			local group = VyHub.Group:get(ply:GetUserGroup())

			if group then
				local teamcolor = team.GetColor(ply:Team())
				local deadTag = ""

				if not ply:Alive() then
					deadTag = f("*%s* ", VyHub.lang.other.dead)
				end

				chat.AddText(VyHub.Util:hex2rgb(group.color), "[", group.name, "]", " ", Color(255, 0, 0), deadTag, teamcolor, ply:Nick(), Color(255,255,255), ": ", msg)

				return true
			end
		end
	end)
end