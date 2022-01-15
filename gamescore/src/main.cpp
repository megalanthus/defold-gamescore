#define EXTENSION_NAME gamescore
#define LIB_NAME "gamescore"
#define MODULE_NAME LIB_NAME

#define DLIB_LOG_DOMAIN LIB_NAME
#include <dmsdk/sdk.h>

#if defined(DM_PLATFORM_HTML5)

typedef void (*ObjectMessage)(const int callback_id, const char* message, const int length);

extern "C" void GameScore_RegisterCallback(ObjectMessage cb_string);
extern "C" void GameScore_RemoveCallback();
extern "C" void GameScore_Init(const char* parameters, const int callback_id);
extern "C" char* GameScore_CallApi(const char* method, const char* parameters, const int callback_id);

struct GameScoreListener {
    GameScoreListener() : m_L(0), m_Callback(LUA_NOREF), m_Self(LUA_NOREF) {}
    lua_State* m_L;
    int m_Callback;
    int m_Self;
};

dmArray<GameScoreListener> m_listeners;

static int GetEqualIndexOfListener(lua_State* L, GameScoreListener* cbk)
{
    lua_rawgeti(L, LUA_REGISTRYINDEX, cbk->m_Callback);
    int first = lua_gettop(L);
    int second = first + 1;
    for(uint32_t i = 0; i != m_listeners.Size(); ++i)
    {
        GameScoreListener* cb = &m_listeners[i];
        lua_rawgeti(L, LUA_REGISTRYINDEX, cb->m_Callback);
        if (lua_equal(L, first, second)){
            lua_pop(L, 1);
            lua_rawgeti(L, LUA_REGISTRYINDEX, cbk->m_Self);
            lua_rawgeti(L, LUA_REGISTRYINDEX, cb->m_Self);
            if (lua_equal(L, second, second + 1)){
              lua_pop(L, 3);
              return i;
            }
            lua_pop(L, 2);
        } else {
            lua_pop(L, 1);
        }
      }
      lua_pop(L, 1);
      return -1;
}

static void UnregisterCallback(lua_State* L, GameScoreListener* cbk)
{
    int index = GetEqualIndexOfListener(L, cbk);
    if (index >= 0) {
      if(cbk->m_Callback != LUA_NOREF)
      {
          dmScript::Unref(cbk->m_L, LUA_REGISTRYINDEX, cbk->m_Callback);
          dmScript::Unref(cbk->m_L, LUA_REGISTRYINDEX, cbk->m_Self);
          cbk->m_Callback = LUA_NOREF;
      }
      m_listeners.EraseSwap(index);
      if (m_listeners.Size() == 0) {
          GameScore_RemoveCallback();
        }
    } else {
      dmLogError("Can't remove a callback that didn't not register.");
    }
}

static bool check_callback_and_instance(GameScoreListener* cbk)
{
    if(cbk->m_Callback == LUA_NOREF)
    {
        dmLogInfo("Callback do not exist.");
        return false;
    }
    lua_State* L = cbk->m_L;
    int top = lua_gettop(L);
    lua_rawgeti(L, LUA_REGISTRYINDEX, cbk->m_Callback);
    //[-1] - callback
    lua_rawgeti(L, LUA_REGISTRYINDEX, cbk->m_Self);
    //[-1] - self
    //[-2] - callback
    lua_pushvalue(L, -1);
    //[-1] - self
    //[-2] - self
    //[-3] - callback
    dmScript::SetInstance(L);
    //[-1] - self
    //[-2] - callback
    if (!dmScript::IsInstanceValid(L)) {
        UnregisterCallback(L, cbk);
        dmLogError("Could not run callback because the instance has been deleted.");
        lua_pop(L, 2);
        assert(top == lua_gettop(L));
        return false;
    }
    return true;
}

static void GameScore_SendStringMessage(const int callback_id, const char* message, const int length)
{
    for(int i = m_listeners.Size() - 1; i >= 0; --i)
    {
        if(i > m_listeners.Size()) {
          return;
        }
        GameScoreListener* cbk = &m_listeners[i];
        lua_State* L = cbk->m_L;
        int top = lua_gettop(L);
        if (check_callback_and_instance(cbk)) {
            lua_pushinteger(L, callback_id);
            lua_pushlstring(L, message, length);
            int ret = lua_pcall(L, 3, 0, 0);
            if(ret != 0) {
                dmLogError("Error running callback: %s", lua_tostring(L, -1));
                lua_pop(L, 1);
            }
        }
        assert(top == lua_gettop(L));
    }
}

static int AddListener(lua_State* L)
{
    GameScoreListener cbk;
    cbk.m_L = dmScript::GetMainThread(L);

    luaL_checktype(L, 1, LUA_TFUNCTION);
    lua_pushvalue(L, 1);
    cbk.m_Callback = dmScript::Ref(L, LUA_REGISTRYINDEX);

    dmScript::GetInstance(L);
    cbk.m_Self = dmScript::Ref(L, LUA_REGISTRYINDEX);

    if(cbk.m_Callback != LUA_NOREF)
    {
      int index = GetEqualIndexOfListener(L, &cbk);
        if (index < 0){
            if(m_listeners.Full())
            {
                m_listeners.OffsetCapacity(1);
            }
            m_listeners.Push(cbk);
      } else {
        dmLogError("Can't register a callback again. Callback has been registered before.");
      }
      if (m_listeners.Size() == 1){
          GameScore_RegisterCallback((ObjectMessage)GameScore_SendStringMessage);
      }
    }
    return 0;
}

static int RemoveListener(lua_State* L)
{
    GameScoreListener cbk;
    cbk.m_L = dmScript::GetMainThread(L);

    luaL_checktype(L, 1, LUA_TFUNCTION);
    lua_pushvalue(L, 1);

    cbk.m_Callback = dmScript::Ref(L, LUA_REGISTRYINDEX);

    dmScript::GetInstance(L);
    cbk.m_Self = dmScript::Ref(L, LUA_REGISTRYINDEX);

    UnregisterCallback(L, &cbk);
    return 0;
}

static int Init(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 0);
    GameScore_Init(luaL_checkstring(L, 1), luaL_checkinteger(L, 2));
    return 0;
}

static int CallApi(lua_State* L)
{
    DM_LUA_STACK_CHECK(L, 1);
    const char* result = GameScore_CallApi(luaL_checkstring(L, 1), lua_isnoneornil(L, 2) ? "" : luaL_checkstring(L, 2), lua_isnoneornil(L, 3) ? 0 : luaL_checkinteger(L, 3));
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
    {"add_listener", AddListener},
    {"remove_listener", RemoveListener},
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
    return dmExtension::RESULT_OK;
}

static dmExtension::Result FinalizeExtension(dmExtension::Params* params)
{
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