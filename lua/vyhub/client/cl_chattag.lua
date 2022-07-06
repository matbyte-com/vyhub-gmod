local hook_Add = hook.Add
local IsValid = IsValid
local team_GetColor = team.GetColor
local chat_AddText = chat.AddText
local Color = Color
local color_red = Color(255, 0 ,0)

if VyHub.Config.chat_tags and not DarkRP then
	hook_Add("OnPlayerChat", "vyhub_chattag_OnPlayerChat", function(ply, msg)
		if IsValid(ply) then
			local group = VyHub.Group:get(ply:GetUserGroup())

			if group then
				local teamcolor = team_GetColor(ply:Team())
				local deadTag = ""

				if not ply:Alive() then
					deadTag = f("*%s* ", VyHub.lang.other.dead)
				end

				chat_AddText(VyHub.Util:hex2rgb(group.color), "[", group.name, "]", " ", color_red, deadTag, teamcolor, ply:Nick(), color_white, ": ", msg)

				return true
			end
		end
	end)
end