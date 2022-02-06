local M = {}

local version = "GameScore for Defold v0.2.1"
local json_encode = require("gamescore.json")
local callback_ids = require("gamescore.callback_ids")
if not html5 then
    gamescore = require("gamescore.mock")
end

local is_init = false

local function check_callback(callback)
    if callback == nil or type(callback) == "function" then
        return
    end
    error(string.format("The callback parameter must be a function!"), 3)
end

local function check_key(key)
    if type(key) ~= "string" then
        error("The key must be a string!", 3)
    end
end

local function check_value(value)
    if type(value) ~= "string" and type(value) ~= "number" and type(value) ~= "boolean" then
        error("The value must be a string, number, or boolean!", 3)
    end
end

local function check_number_value(value)
    if type(value) ~= "number" then
        error("The value must be a number!", 3)
    end
end

local function check_table(tbl, parameter_name)
    if tbl == nil or type(tbl) == "table" then
        return
    end
    error(string.format("The '%s' parameter must be a table!", parameter_name), 3)
end

local function check_table_required(tbl, parameter_name)
    if type(tbl) ~= "table" then
        error(string.format("The '%s' parameter must be a table!", parameter_name), 3)
    end
end

local function make_parameters_id_or_tag(id_or_tag, id_or_tag_name)
    if id_or_tag == nil then
        error(string.format("%s id or tag is required!", id_or_tag_name), 3)
    end
    local parameters = {}
    if type(id_or_tag) == "number" then
        parameters.id = id_or_tag
    elseif type(id_or_tag) == "string" then
        parameters.tag = id_or_tag
    else
        error(string.format("%s must be a number or a string!", id_or_tag_name), 3)
    end
    return parameters
end

local function get_event_callback_name(callback_id)
    for callback_name, id in pairs(callback_ids) do
        if callback_id == id then
            return callback_name
        end
    end
end

local function decode_result(result)
    if result then
        local is_ok, value = pcall(json.decode, result)
        if is_ok then
            return value
        else
            return result
        end
    end
end

local function on_event_callback(self, message, id)
    local callback_name = get_event_callback_name(id)
    if callback_name ~= nil then
        local callback = M.callbacks[callback_name]
        if callback == nil then
            return
        end
        assert(type(callback) == "function", string.format("callbacks.'%s' must be a function!", callback_name))
        if message == "" then
            callback()
        else
            callback(decode_result(message))
        end
    end
end

---Выполнить функцию gamescore API. Если method API является объектом, то в parameters дополнительно можно перечислить
---методы (геттеры).
---@param method string выполняемый метод объект или поле объекта, например: "player.sync"
---@param parameters any параметры метода, если параметров несколько, то таблица (массив) параметров.
---@param callback function функция обратного вызова, если nil, тогда функция сразу вернет результат
---@param native_api boolean если true, то будет вызван нативный метод
---@return any результат выполнения метода, или nil, если задан callback
local function call_api(method, parameters, callback, native_api)
    if type(parameters) ~= "table" then
        parameters = { parameters }
    end
    parameters = json_encode.encode(parameters)
    if callback then
        gamescore.call_api(method, parameters, native_api, function(self, message)
            if message == "" then
                callback()
            else
                callback(decode_result(message))
            end
        end)
    else
        local result = gamescore.call_api(method, parameters, native_api)
        return decode_result(result)
    end
end

M.callbacks = {
    ads_start = nil,
    ads_close = nil,
    ads_fullscreen_start = nil,
    ads_fullscreen_close = nil,
    ads_preloader_start = nil,
    ads_preloader_close = nil,
    ads_rewarded_start = nil,
    ads_rewarded_close = nil,
    ads_rewarded_reward = nil,
    ads_sticky_start = nil,
    ads_sticky_render = nil,
    ads_sticky_refresh = nil,
    ads_sticky_close = nil,
    player_sync = nil,
    player_load = nil,
    player_login = nil,
    player_fetch_fields = nil,
    player_change = nil,
    achievements_unlock = nil,
    achievements_unlock_error = nil,
    achievements_open = nil,
    achievements_close = nil,
    achievements_fetch = nil,
    achievements_fetch_error = nil,
    payments_purchase = nil,
    payments_purchase_error = nil,
    payments_consume = nil,
    payments_consume_error = nil,
    payments_fetch_products = nil,
    payments_fetch_products_error = nil,
    games_collections_open = nil,
    games_collections_close = nil,
    games_collections_fetch = nil,
    games_collections_fetch_error = nil,
    fullscreen_open = nil,
    fullscreen_close = nil,
    fullscreen_change = nil
}

M.PLATFORM_CRAZY_GAMES = "CRAZY_GAMES"
M.PLATFORM_GAME_DISTRIBUTION = "GAME_DISTRIBUTION"
M.PLATFORM_GAME_MONETIZE = "GAME_MONETIZE"
M.PLATFORM_OK = "OK"
M.PLATFORM_VK = "VK"
M.PLATFORM_YANDEX = "YANDEX"

---Возвращает версию плагина
---@return string
function M.get_plugin_version()
    return version
end

---Инициализация gamescore
---@param callback function функция обратного вызова по завершению инициализации: callback(success)
function M.init(callback)
    if is_init then
        error("Gamescore already initialized!", 2)
    end
    if callback == nil then
        error("Callback function must be specified!", 2)
    end
    check_callback(callback)
    is_init = true
    gamescore.init(json_encode.encode(callback_ids), on_event_callback, function(self, message, callback_id)
        callback(message)
    end)
end

---В разработке?
---@return boolean
function M.is_dev()
    return call_api("isDev").value == true
end

---Мобильное устройство?
---@return boolean
function M.is_mobile()
    return call_api("isMobile").value == true
end

function M.get_server_time()
    return call_api("serverTime").value
end

---Получить текущий язык
---@return string код языка в формате ISO 639-1
function M.language()
    return call_api("language").value
end

---Установить язык
---@param language_code string код языка в формате ISO 639-1
function M.change_language(language_code)
    if type(language_code) ~= "string" then
        error("The language code must be a string!", 2)
    end
    call_api("changeLanguage", language_code)
end

---Получить сведения об игре
---@return table таблица со сведениями
function M.app()
    return call_api("app", { "url" })
end

---Получить сведения о платформе
---@return table таблица со сведениями
function M.platform()
    local parameters = { "type", "hasIntegratedAuth", "isExternalLinksAllowed", "isSecretCodeAuthAvailable" }
    return call_api("platform", parameters)
end

---Выполнить нативный метод платформы. Если method API является объектом.
---@param method string выполняемый метод объект или поле объекта, например: "feedback.canReview"
---@param parameters any параметры метода, если параметров несколько, то таблица (массив) параметров.
---@param callback function|nil функция обратного вызова
---@return any результат выполнения операции или возвращаемые данные
function M.call_native_sdk(method, parameters, callback)
    if type(method) ~= "string" or method == "" then
        error("The method must be a string!", 2)
    end
    check_callback(callback)
    return call_api(method, parameters, callback, true)
end

---Получить свойства менеджера рекламы
---@return table таблица со сведениями
function M.ads()
    local parameters = { "isFullscreenAvailable", "isPreloaderAvailable", "isRewardedAvailable", "isStickyAvailable" }
    return call_api("ads", parameters)
end

---Показать полноэкранную рекламу
---@param callback function функция обратного вызова по завершению рекламы: callback(result)
function M.ads_show_fullscreen(callback)
    check_callback(callback)
    call_api("ads.showFullscreen", nil, callback)
end

---Показать баннерную рекламу (preloader)
---@param callback function функция обратного вызова по завершению рекламы: callback(result)
function M.ads_show_preloader(callback)
    check_callback(callback)
    call_api("ads.showPreloader", nil, callback)
end

---Показать рекламу за вознаграждение
---@param callback function функция обратного вызова по завершению рекламы: callback(result)
function M.ads_show_rewarded_video(callback)
    check_callback(callback)
    call_api("ads.showRewardedVideo", nil, callback)
end

---Показать баннер
---@param callback function функция обратного вызова по результату показа: callback(result)
function M.ads_show_sticky(callback)
    check_callback(callback)
    call_api("ads.showSticky", nil, callback)
end

---Обновить баннер
---@param callback function функция обратного вызова по результату обновления: callback(result)
function M.ads_refresh_sticky(callback)
    check_callback(callback)
    call_api("ads.refreshSticky", nil, callback)
end

---Закрыть баннер
---@param callback function функция обратного вызова по результату закрытия: callback()
function M.ads_close_sticky(callback)
    check_callback(callback)
    call_api("ads.closeSticky", nil, callback)
end

---Получить данные игрока
---@return table таблица со сведениями
function M.player()
    return call_api("player", { "id", "score", "name", "avatar", "isStub", "fields" })
end

---Синхронизация игрока
---@param parameters table параметры
---@param callback function функция обратного вызова по результату синхронизации: callback()
function M.player_sync(parameters, callback)
    check_table(parameters, "parameters")
    check_callback(callback)
    call_api("player.sync", { parameters }, callback)
end

---Загрузка игрока с сервера с перезаписью локального
---@param callback function функция обратного вызова по результату синхронизации: callback()
function M.player_load(callback)
    check_callback(callback)
    call_api("player.load", nil, callback)
end

---Вход
---@param callback function функция обратного вызова по результату входа: callback(result)
function M.player_login(callback)
    check_callback(callback)
    call_api("player.login", nil, callback)
end

---Получить список полей игрока
---@param callback function функция обратного вызова по результату получения полей игрока: callback()
function M.player_fetch_fields(callback)
    check_callback(callback)
    call_api("player.fetchFields", nil, callback)
end

---Получить значение поля key
---@param key string ключ
---@return string|number|boolean значение поля key
function M.player_get(key)
    check_key(key)
    return call_api("player.get", key).value
end

---Установить значение поля key
---@param key string ключ
---@param value string|number|boolean значение поля key
function M.player_set(key, value)
    check_key(key)
    check_value(value)
    call_api("player.set", { key, value })
end

---Добавить значение к полю key
---@param key string ключ
---@param value number добавляемое значение
function M.player_add(key, value)
    check_key(key)
    check_number_value(value)
    call_api("player.add", { key, value })
end

---Инвертировать значение поля key
---@param key string ключ
function M.player_toggle(key)
    check_key(key)
    call_api("player.toggle", key)
end

---Проверить есть ли поле key и оно не пустое (не 0, '', false, null, undefined)
---@param key string ключ
---@return boolean результат
function M.player_has(key)
    check_key(key)
    return call_api("player.has", key).value
end

---Возвращает состояние игрока объектом
---@return table таблица с данными игрока
function M.player_to_json()
    return call_api("player.toJSON")
end

---Устанавливает состояние игрока из объекта
---@param player table таблица с данными игрока
function M.player_from_json(player)
    check_table(player, "player")
    call_api("player.fromJSON", { player })
end

---Сбрасывает состояние игрока на умолчательное
function M.player_reset()
    call_api("player.reset")
end

---Удаляет игрока — сбрасывает поля и очищает ID
function M.player_remove()
    call_api("player.remove")
end

---Получить поле по ключу key
---@param key string ключ
---@return table результат
function M.player_get_field(key)
    check_key(key)
    return call_api("player.getField", key)
end

---Получить переведенное имя поля по ключу key
---@param key string ключ
---@return string результат
function M.player_get_field_name(key)
    check_key(key)
    return call_api("player.getFieldName", key).value
end

---Получить переведенное имя варианта поля (enum) по ключу key и его значению value
---@param key string ключ
---@param value string значение
---@return table результат
function M.player_get_field_variant_name(key, value)
    check_key(key)
    if type(value) ~= "string" then
        error("The value must be a string!", 2)
    end
    return call_api("player.getFieldVariantName", { key, value }).value
end

---Показать таблицу лидеров во внутриигровом оверлее
---@param parameters table|nil параметры вывода
function M.leaderboard_open(parameters)
    check_table(parameters, "parameters")
    call_api("leaderboard.open", { parameters })
end

---Получить таблицу лидеров
---@param parameters table|nil параметры вывода
---@param callback function функция обратного вызова по результату получения получения таблицы: callback(leaders)
function M.leaderboard_fetch(parameters, callback)
    check_table(parameters, "parameters")
    check_callback(callback)
    call_api("leaderboard.fetch", { parameters }, callback)
end

---Получить рейтинг игрока
---@param parameters table|nil параметры вывода
---@param callback function функция обратного вызова по результату получения получения таблицы: callback(leaders)
function M.leaderboard_fetch_player_rating(parameters, callback)
    check_table(parameters, "parameters")
    check_callback(callback)
    call_api("leaderboard.fetchPlayerRating", { parameters }, callback)
end

---Показать изолированную таблицу лидеров во внутриигровом оверлее
---@param parameters table|nil параметры вывода
---@param callback function функция обратного вызова по результату показа: callback(result)
function M.leaderboard_open_scoped(parameters, callback)
    check_table_required(parameters, "parameters")
    check_callback(callback)
    call_api("leaderboard.openScoped", { parameters }, callback)
end

---Получить изолированную таблицу лидеров
---@param parameters table|nil параметры вывода
---@param callback function функция обратного вызова по результату получения получения таблицы: callback(leaders)
function M.leaderboard_fetch_scoped(parameters, callback)
    check_table_required(parameters, "parameters")
    check_callback(callback)
    call_api("leaderboard.fetchScoped", { parameters }, callback)
end

---Публикация рекорда игрока в изолированную таблицу
---@param parameters table таблица с параметрами и рекордом для записи
---@param callback function функция обратного вызова по результату публикации рекорда: callback(result)
function M.leaderboard_publish_record(parameters, callback)
    check_table_required(parameters, "parameters")
    check_callback(callback)
    call_api("leaderboard.publishRecord", { parameters }, callback)
end

---Получить рейтинг игрока в изолированной таблице
---@param parameters table параметры вывода
---@param callback function функция обратного вызова по результату получения получения таблицы: callback(leaders)
function M.leaderboard_fetch_player_rating_scoped(parameters, callback)
    check_table_required(parameters, "parameters")
    check_callback(callback)
    call_api("leaderboard.fetchPlayerRatingScoped", { parameters }, callback)
end

---Разблокировать достижение
---@param achievement number|string id или tag достижения
---@param callback function функция обратного вызова по результату разблокировки достижения: callback(result)
function M.achievements_unlock(achievement, callback)
    local parameters = make_parameters_id_or_tag(achievement, "Achievement")
    check_callback(callback)
    call_api("achievements.unlock", { parameters }, callback)
end

---Открыть достижения в оверлее
---@param callback function функция обратного вызова по результату открытия достижений: callback()
function M.achievements_open(callback)
    check_callback(callback)
    call_api("achievements.open", nil, callback)
end

---Запросить достижения
---@param callback function функция обратного вызова по результату запроса достижений: callback(achievements)
function M.achievements_fetch(callback)
    check_callback(callback)
    return call_api("achievements.fetch", nil, callback)
end

---Проверка поддержки платежей на платформе
---@return boolean результат
function M.payments_is_available()
    return call_api("payments.isAvailable").value
end

---Покупка
---@param product number|string id или tag продукта
---@param callback function функция обратного вызова по результату покупки продукта: callback(result)
function M.payments_purchase(product, callback)
    local parameters = make_parameters_id_or_tag(product, "Product")
    check_callback(callback)
    call_api("payments.purchase", { parameters }, callback)
end

---Использование покупки
---@param product number|string id или tag продукта
---@param callback function функция обратного вызова по результату использования продукта: callback(result)
function M.payments_consume(product, callback)
    local parameters = make_parameters_id_or_tag(product, "Product")
    check_callback(callback)
    call_api("payments.consume", { parameters }, callback)
end

---Проверка наличия покупки
---@param product number|string id или tag продукта
function M.payments_has(product)
    local parameters = make_parameters_id_or_tag(product, "Product")
    return call_api("payments.has", parameters.id or parameters.tag).value
end

---Получение списка продуктов
---@param callback function функция обратного вызова по результату получения списка продуктов: callback(result)
function M.payments_fetch_products(callback)
    check_callback(callback)
    call_api("payments.fetchProducts", nil, callback)
end

---Возвращает информацию о возможных социальных действиях
---@return table
function M.socials()
    local parameters = {
        "isSupportsNativeShare",
        "isSupportsNativePosts",
        "isSupportsNativeInvite",
        "canJoinCommunity",
        "isSupportsNativeCommunityJoin",
        "communityLink"
    }
    return call_api("socials", parameters)
end

---Поделиться
---@param parameters table|nil
function M.socials_share(parameters)
    check_table(parameters, "parameters")
    call_api("socials.share", { parameters })
end

---Опубликовать пост
---@param parameters table|nil
function M.socials_post(parameters)
    check_table(parameters, "parameters")
    call_api("socials.post", { parameters })
end

---Пригласить друзей
---@param parameters table|nil
function M.socials_invite(parameters)
    check_table(parameters, "parameters")
    call_api("socials.invite", { parameters })
end

---Вступить в сообщество
function M.socials_join_community()
    call_api("socials.joinCommunity")
end

---Открыть оверлей с играми
---@param collection number|string id или tag коллекции
---@param callback function функция обратного вызова по результату открытия оверлея: callback()
function M.games_collections_open(collection, callback)
    check_callback(callback)
    local parameters
    if collection then
        parameters = make_parameters_id_or_tag(collection, "Collection")
    end
    call_api("gamesCollections.open", { parameters }, callback)
end

---Получить коллекцию игр
---@param collection number|string id или tag коллекции
---@param callback function функция обратного вызова по результату получения коллекции игр: callback(result)
---@return table
function M.games_collections_fetch(collection, callback)
    check_callback(callback)
    local parameters
    if collection then
        parameters = make_parameters_id_or_tag(collection, "Collection")
    end
    call_api("gamesCollections.fetch", { parameters }, callback)
end

---Посещение или просмотр страницы
---@param url string адрес страницы
function M.analytics_hit(url)
    if type(url) ~= "string" then
        error("The url parameter must be a string!", 2)
    end
    call_api("analytics.hit", { url })
end

---Отправка достижения цели
---@param event string событие
---@param value string|number|boolean|nil значение
function M.analytics_goal(event, value)
    if type(event) ~= "string" then
        error("The event parameter must be a string!", 2)
    end
    if value then
        check_value(value)
    end
    call_api("analytics.goal", { event, value })
end

---Войти в полноэкранный режим
function M.fullscreen_open()
    call_api("fullscreen.open")
end

---Выйти из полноэкранного режима
function M.fullscreen_close()
    call_api("fullscreen.close")
end

---Переключить полноэкранный режим
function M.fullscreen_toggle()
    call_api("fullscreen.toggle")
end

return M