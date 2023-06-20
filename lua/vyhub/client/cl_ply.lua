local f = string.format

local meta_ply = FindMetaTable("Player")

function meta_ply:VyHubID()
    if IsValid(self) then        
        return self:GetNWString("vyhub_id", nil)
    end
end