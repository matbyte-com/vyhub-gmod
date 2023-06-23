local f = string.format

local meta_ply = FindMetaTable("Player")

local user_id = nil

function meta_ply:VyHubID()
    if IsValid(self) then
        if self == LocalPlayer() then        
            return user_id
        else
            MsgN("ERROR: Cannot get VyHubID of other users on the client side.")
        end
    end
end

net.Receive("vyhub_user_id", function ()
    user_id = net.ReadString()
end)