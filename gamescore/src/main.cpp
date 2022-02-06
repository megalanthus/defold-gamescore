#define EXTENSION_NAME gamescore
#define LIB_NAME "gamescore"
#define MODULE_NAME LIB_NAME

#define DLIB_LOG_DOMAIN LIB_NAME
#include <dmsdk/sdk.h>

#if defined(DM_PLATFORM_HTML5)

const int start_event_callbacks_id = 0xFF00;

typedef void (*ObjectMessage)(const int callback_id, const char* message, const int length);

extern "C" void GameScore_RegisterCallback(ObjectMessage cb_string);
extern "C" void GameScore_RemoveCallback();
extern "C" void GameScore_Init(const char* parameters, const int callback_id);
extern "C" char* GameScore_CallApi(const char* method, const char* parameters, const int callback_id, const bool native_api);

dmScript::LuaCallbackInfo* event_callback;
dmArray<dmScript::LuaCallbackInfo*> callbacks;

static void InvokeCallback(dmScript::LuaCallbackInfo* cbk, const char* message, const int id)
{
    if (!dmScript::IsCallbackValid(cbk)) return;
    lua_State* L = dmScript::GetCallbackLuaContext(cbk);
    DM_LUA_STACK_CHECK(L, 0);
    if (!dmScript::SetupCallback(cbk))
    {
        dmLogError("Failed to setup callback");
        return;
    }
    lua_pushstring(L, message);
    lua_pushnumber(L, id);
    dmScript::PCall(L, 3, 0);       // instance + 2
    dmScript::TeardownCallback(cbk);
}

static int RegisterCallback(dmScript::LuaCallbackInfo* cbk)
{
    for (int i = 0; i < callbacks.Size(); i++)
    {
        if (callbacks[i] == 0) {
            callbacks[i] = cbk;
            return i + 1;
        }
    }
    if (callbacks.Full()) {
        callbacks.OffsetCapacity(1);
    }
    callbacks.Push(cbk);
    return callbacks.Size();
}

static dmScript::LuaCallbackInfo* GetCallback(const int callback_id)
{
    if (callback_id > callbacks.Size()) {
        dmLogError("Callback with id '%d' not registered!", callback_id);
        return 0;
    }
    int index = callback_id - 1;
    dmScript::LuaCallbackInfo* cbk = callbacks[index];
    callbacks[index] = 0;
    return cbk;
}

static void GameScore_SendStringMessage(const int callback_id, const char* message)
{
    if (callback_id >= start_event_callbacks_id) {
        InvokeCallback(event_callback, message, callback_id);
    } else {
        if (callback_id > callbacks.Size()) {
            dmLogError("Callback with id '%d' not registered!", callback_id);
            return;
        }
        dmScript::LuaCallbackInfo* cbk = GetCallback(callback_id);
        InvokeCallback(cbk, message, 0);
        if (cbk) dmScript::DestroyCallback(cbk);
    }
}

static int Init(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    event_callback = dmScript::CreateCallback(L, 2);
    int callback_id = RegisterCallback(dmScript::CreateCallback(L, 3));
    GameScore_Init(luaL_checkstring(L, 1), callback_id);
    return 0;
}

static int CallApi(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);
    int callback_id = lua_isnoneornil(L, 4) ? 0 : RegisterCallback(dmScript::CreateCallback(L, 4));
    const char* result = GameScore_CallApi(luaL_checkstring(L, 1), lua_isnoneornil(L, 2) ? "" : luaL_checkstring(L, 2),
        callback_id, lua_toboolean(L, 3));
    if (result == 0 || strcmp(result, "") == 0) {
        lua_pushnil(L);
    } else {
        lua_pushstring(L, result);
    }
    free((void*)result);
    return 1;
}

static const luaL_reg Module_methods[] =
{
    {"init", Init},
    {"call_api", CallApi},
    {0, 0}
};

static void LuaInit(lua_State* L)
{
    int top = lua_gettop(L);
    luaL_register(L, MODULE_NAME, Module_methods);
    lua_pop(L, 1);
    assert(top == lua_gettop(L));
}

static dmExtension::Result InitializeExtension(dmExtension::Params* params)
{
    LuaInit(params->m_L);
    GameScore_RegisterCallback((ObjectMessage)GameScore_SendStringMessage);
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeExtension(dmExtension::Params* params)
{
    GameScore_RemoveCallback();
    return dmExtension::RESULT_OK;
}

#else // unsupported platforms

static dmExtension::Result InitializeExtension(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeExtension(dmExtension::Params* params)
{
    return dmExtension::RESULT_OK;
}

#endif

DM_DECLARE_EXTENSION(EXTENSION_NAME, LIB_NAME, 0, 0, InitializeExtension, 0, 0, FinalizeExtension)