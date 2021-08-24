VyHub.API = VyHub.API or {}

local content_type = "application/json; charset=utf-8"


function VyHub.API:request(method, url, path_params, query, headers, body, type, success, failed)
    if path_params != nil then
        url = string.format(url, unpack(path_params))
    end

    if istable(body) then
        body = util.TableToJSON(body)
    end

    success_func = function(code, body, headers)
        result = util.JSONToTable(body)

        if code >= 200 and code < 300 then
            VyHub:msg(string.format("HTTP %s %s: %s", method, url, code), "debug")

            if success != nil then
                success(code, result, headers)
            end
        else
            VyHub:msg(string.format("HTTP %s %s: %s %s", method, url, code, body), "error")

            if failed != nil then
                failed(code, result, headers)
            end
        end
    end

    failed_func = function(reason)
        VyHub:msg(string.format("HTTP %s request to %s failed with reason '%s'.\nQuery: %s\nBody: %s", method, url, reason, query, body), "error")

        if failed != nil then
            failed(0, reason, {})
        end
    end

    HTTP({
        method = method,
        url = url,
        parameters = query,
        headers = headers,
        body = body,
        type = type,
        success = success_func,
        failed = failed_func,
    })
end

function VyHub.API:get(endpoint, path_params, query, success, failed)
    url = string.format("%s%s", VyHub.API.url, endpoint)

    VyHub.API:request("GET", url, path_params, query, self.headers, nil, content_type, success, failed)
end

function VyHub.API:delete(endpoint, path_params, success, failed)
    url = string.format("%s%s", VyHub.API.url, endpoint)

    self:request("DELETE", url, path_params, nil, self.headers, nil, content_type, success, failed)
end

function VyHub.API:post(endpoint, path_params, body, success, failed)
    url = string.format("%s%s", VyHub.API.url, endpoint)

    self:request("POST", url, path_params, nil, self.headers, body, content_type, success, failed)
end

function VyHub.API:patch(endpoint, path_params, body, success, failed)
    url = string.format("%s%s", VyHub.API.url, endpoint)

    self:request("PATCH", url, path_params, nil, self.headers, body, content_type, success, failed)
end

function VyHub.API:put(endpoint, path_params, body, success, failed)
    url = string.format("%s%s", VyHub.API.url, endpoint)

    self:request("PUT", url, path_params, nil, self.headers, body, content_type, success, failed)
end

hook.Add("vyhub_loading_finish", "vyhub_api_vyhub_loading_finish", function()
    VyHub.API.url = VyHub.Config.api_url
    VyHub.API.headers = {
        Authorization = string.format("Bearer %s", VyHub.Config.api_key)
    }

    if string.EndsWith(VyHub.API.url, "/") then
        VyHub.API.url = string.sub(VyHub.API.url, 1, -2)
    end

    VyHub:msg(string.format("API URL is %s", VyHub.API.url))

    VyHub.API:get("/openapi.json", nil, nil, function(code, result, headers)
        VyHub:msg(string.format("Connection to API %s version %s successful!", result.info.title, result.info.version), "success")

        hook.Run("vyhub_api_ready")
    end, function()
        VyHub:msg("Connection to API failed! Trying to use cache.", "error")

        hook.Run("vyhub_api_failed")
    end)
end)

concommand.Add("vyhub_reinit", function ()
    hook.Run("vyhub_loading_finish")
end)