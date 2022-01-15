local M = {}

local mock_api = require("gamescore.mock_api")

local callback

local function send(callback_id, message)
    callback(nil, callback_id, message)
end

function M.add_listener(listener)
    callback = listener
end

function M.remove_listener()
    callback = nil
end

function M.init(parameters, callback_id)
    mock_api.send = send
    mock_api.init()
    send(callback_id, true)
end

function M.call_api(method, parameters, callback_id)
    local result
    local method_api = mock_api[method]
    if method_api then
        if type(method_api) == "function" then
            result = method_api(unpack(json.decode(parameters)))
        else
            result = method_api
        end
    end
    if callback_id and callback_id > 0 then
        send(callback_id, result)
    else
        return result
    end
end

return M