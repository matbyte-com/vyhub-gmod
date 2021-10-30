VyHub.Util = VyHub.Util or {}

function VyHub.Util:format_datetime(unix_timestamp)
    unix_timestamp = unix_timestamp or os.time()

    local tz_wrong = os.date("%z", unix_timestamp)
    local timezone = string.format("%s:%s", string.sub(tz_wrong, 1, 3), string.sub(tz_wrong, 4, 5))

    return os.date("%Y-%m-%dT%H:%M:%S" .. timezone)
end

function VyHub.Util:is_server(obj)
	if type(obj) == "Entity" and (obj.EntIndex and obj:EntIndex() == 0) and !IsValid(obj) then
		return true
	else
		return false
	end
end