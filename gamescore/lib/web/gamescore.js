// https://kripken.github.io/emscripten-site/docs/porting/connecting_cpp_and_javascript/Interacting-with-code.html
let LibraryGameScore = {
    // This can be accessed from the bootstrap code in the .html file
    $GameScoreLib: {
        _callback: null,
        _gs: null,
        _data: {},

        init_callbacks: function (gs, callback_ids) {
            gs.ads.on("start", () => GameScoreLib.send(callback_ids.ads_start));
            gs.ads.on("close", (success) => GameScoreLib.send(callback_ids.ads_close, success));
            gs.ads.on("fullscreen:start", () => GameScoreLib.send(callback_ids.ads_fullscreen_start));
            gs.ads.on("fullscreen:close", (success) => GameScoreLib.send(callback_ids.ads_fullscreen_close, success));
            gs.ads.on("preloader:start", () => GameScoreLib.send(callback_ids.ads_preloader_start));
            gs.ads.on("preloader:close", (success) => GameScoreLib.send(callback_ids.ads_preloader_close, success));
            gs.ads.on("rewarded:start", () => GameScoreLib.send(callback_ids.ads_rewarded_start));
            gs.ads.on("rewarded:close", (success) => GameScoreLib.send(callback_ids.ads_rewarded_close, success));
            gs.ads.on("rewarded:reward", () => GameScoreLib.send(callback_ids.ads_rewarded_reward));
            gs.ads.on("sticky:start", () => GameScoreLib.send(callback_ids.ads_sticky_start));
            gs.ads.on("sticky:render", () => GameScoreLib.send(callback_ids.ads_sticky_render));
            gs.ads.on("sticky:refresh", () => GameScoreLib.send(callback_ids.ads_sticky_refresh));
            gs.ads.on("sticky:close", () => GameScoreLib.send(callback_ids.ads_sticky_close));
            gs.player.on("sync", (success) => GameScoreLib.send(callback_ids.player_sync, success));
            gs.player.on("load", (success) => GameScoreLib.send(callback_ids.player_load, success));
            gs.player.on("login", (success) => GameScoreLib.send(callback_ids.player_login, success));
            gs.player.on("fetchFields", (success) => GameScoreLib.send(callback_ids.player_fetch_fields, success));
            gs.player.on("change", () => GameScoreLib.send(callback_ids.player_change));
            gs.achievements.on("unlock", (achievement) => GameScoreLib.send(callback_ids.achievements_unlock, achievement));
            gs.achievements.on("error:unlock", (error) => GameScoreLib.send(callback_ids.achievements_unlock_error, error));
            gs.achievements.on("open", () => GameScoreLib.send(callback_ids.achievements_open));
            gs.achievements.on("close", () => GameScoreLib.send(callback_ids.achievements_close));
            gs.achievements.on("fetch", (result) => GameScoreLib.send(callback_ids.achievements_fetch, result));
            gs.achievements.on("error:fetch", (error) => GameScoreLib.send(callback_ids.achievements_fetch_error, error));
            gs.payments.on("purchase", (result) => GameScoreLib.send(callback_ids.payments_purchase, result));
            gs.payments.on("error:purchase", (error) => GameScoreLib.send(callback_ids.payments_purchase_error, error));
            gs.payments.on("consume", (result) => GameScoreLib.send(callback_ids.payments_consume, result));
            gs.payments.on("error:consume", (error) => GameScoreLib.send(callback_ids.payments_consume_error, error));
            gs.payments.on("fetchProducts", (result) => GameScoreLib.send(callback_ids.payments_fetch_products, result));
            gs.payments.on("error:fetchProducts", (error) => GameScoreLib.send(callback_ids.payments_fetch_products_error, error));
            gs.variables.on("fetch", () => GameScoreLib.send(callback_ids.game_variables_fetch));
            gs.variables.on("error:fetch", (error) => GameScoreLib.send(callback_ids.game_variables_fetch_error, error));
            gs.gamesCollections.on("open", () => GameScoreLib.send(callback_ids.games_collections_open));
            gs.gamesCollections.on("close", () => GameScoreLib.send(callback_ids.games_collections_close));
            gs.gamesCollections.on("fetch", (result) => GameScoreLib.send(callback_ids.games_collections_fetch, result));
            gs.gamesCollections.on("error:fetch", (error) => GameScoreLib.send(callback_ids.games_collections_fetch_error, error));
            gs.fullscreen.on("open", () => GameScoreLib.send(callback_ids.fullscreen_open));
            gs.fullscreen.on("close", () => GameScoreLib.send(callback_ids.fullscreen_close));
            gs.fullscreen.on("change", () => GameScoreLib.send(callback_ids.fullscreen_change));
            gs.documents.on("open", () => GameScoreLib.send(callback_ids.documents_open));
            gs.documents.on("close", () => GameScoreLib.send(callback_ids.documents_close));
            gs.documents.on("fetch", (document) => GameScoreLib.send(callback_ids.documents_fetch, document));
            gs.documents.on("error:fetch", (error) => GameScoreLib.send(callback_ids.documents_fetch_error, error));
        },

        send: function (callback_id, data) {
            if (GameScoreLib._callback && callback_id > 0) {
                let message = data === undefined || data === null ? "" :
                    typeof (data) === "object" ? JSON.stringify(data) :
                        typeof (data) === "string" ? data : data.toString();
                let msg = allocate(intArrayFromString(message), ALLOC_NORMAL);
                {{{makeDynCall("viii", "GameScoreLib._callback")}}}(callback_id, msg);
                Module._free(msg);
            }
        },

        call_api: function (method, parameters, callback_id, native_api) {
            let method_name = UTF8ToString(method);
            let string_parameters = UTF8ToString(parameters);
            let save_as_var = null;
            let saved_object = null;
            if (native_api) {
                let method_parse = method_name.split("=");
                if (method_parse[1]) {
                    save_as_var = method_parse[0];
                    method_name = method_parse[1];
                }
                method_parse = method_name.split(":");
                if (method_parse[1]) {
                    saved_object = GameScoreLib._data[method_parse[0]];
                    if (!saved_object) {
                        let error = `The "${method_parse[0]}" object has not been previously saved!`;
                        return JSON.stringify({error: error});
                    }
                    method_name = method_parse[1];
                }
            }
            let path = method_name.split(".");
            let parent_object = native_api ? saved_object ? saved_object :
                GameScoreLib._gs.platform.getNativeSDK() : GameScoreLib._gs;
            let result_object = parent_object;
            let last_index = path.length - 1
            for (let index = 0; index < path.length; index++) {
                let item = path[index];
                if (parent_object[item]) {
                    if (index === last_index) {
                        result_object = parent_object[item];
                    } else {
                        parent_object = parent_object[item];
                    }
                } else {
                    let error = `Field or function "${method_name}" not found!`;
                    return JSON.stringify({error: error});
                }
            }
            let array_parameters = JSON.parse(string_parameters);
            switch (typeof result_object) {
                case "string":
                case "number":
                case "boolean":
                    return JSON.stringify({value: result_object});
                case "object":
                    if (native_api) {
                        try {
                            return JSON.stringify(result_object);
                        } catch (error) {
                            return JSON.stringify({error: error});
                        }
                    }
                    let result = {};
                    for (let item in result_object) {
                        let type = typeof (result_object[item]);
                        if (type === "string" || type === "boolean" || type === "number") {
                            result[item] = result_object[item];
                        }
                    }
                    array_parameters.forEach(function (item) {
                        result[item] = result_object[item];
                    });
                    return JSON.stringify(result);
                case "function":
                    try {
                        let called_function = result_object.bind(parent_object);
                        if (callback_id === 0) {
                            let result = called_function(...array_parameters);
                            switch (typeof result) {
                                case "string":
                                case "number":
                                case "boolean":
                                    return JSON.stringify({value: result});
                                case "object":
                                    return JSON.stringify(result);
                            }
                            return JSON.stringify({error: `"${typeof result}" type not supported!`});
                        } else {
                            called_function(...array_parameters).then(
                                function (success) {
                                    if (save_as_var) {
                                        GameScoreLib._data[save_as_var] = success
                                    }
                                    GameScoreLib.send(callback_id, success);
                                }).catch(
                                function (error) {
                                    GameScoreLib.send(callback_id, JSON.stringify({error: error}));
                                })
                        }
                    } catch (error) {
                        return JSON.stringify({error: error});
                    }
                    return;
                default:
                    return JSON.stringify({error: `"${typeof result_object}" type not supported!`});
            }
        },
    },

    // These can be called from within the extension, in C++
    GameScore_RegisterCallback: function (callback) {
        GameScoreLib._callback = callback;
    },

    GameScore_RemoveCallback: function () {
        GameScoreLib._callback = null;
    },

    GameScore_Init: function (parameters, callback_id) {
        let callback_ids = JSON.parse(UTF8ToString(parameters));
        GameScoreLib.init = function (gs, initResult) {
            GameScoreLib._gs = gs;
            if (initResult === true) {
                GameScoreLib.init_callbacks(gs, callback_ids);
            }
            GameScoreLib.send(callback_id, initResult);
        }
        if (window.GameScoreInit !== undefined) {
            GameScoreLib.init(window.GameScoreInstance, window.GameScoreInit);
        }
    },

    GameScore_CallApi: function (method, parameters, callback_id, native_api) {
        let result = GameScoreLib.call_api(method, parameters, callback_id, native_api);
        if (result) {
            if (callback_id > 0) {
                GameScoreLib.send(callback_id, result)
            }
            return allocate(intArrayFromString(result), ALLOC_NORMAL);
        }
    },
}

autoAddDeps(LibraryGameScore, '$GameScoreLib');
mergeInto(LibraryManager.library, LibraryGameScore);