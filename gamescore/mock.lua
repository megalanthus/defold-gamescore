local M = {}

local mock_api = require("gamescore.mock_api")

local callback
local mock_native_api

local function send(callback_id, message)
    callback(nil, callback_id, message)
end

---Установить заглушки для нативного API
---@param tbl table таблица с заглушками нативного API
function M.set_native_api(tbl)
    if type(tbl) ~= "table" then
        error("Native API must be a table!", 2)
    end
    mock_native_api = tbl
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

function M.call_api(method, parameters, callback_id, native_api)
    local result
    local method_api
    if native_api == true then
        method_api = mock_native_api[method]
    else
        method_api = mock_api[method]
    end
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

M.set_native_api(require("gamescore.mock_native_api"))
return M