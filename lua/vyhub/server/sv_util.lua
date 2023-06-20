local f = string.format

local meta_ply = FindMetaTable("Player")

function meta_ply:vh_open_url(url)
	self:SendLua([[gui.OpenURL("]] .. url .. [[")]])
end