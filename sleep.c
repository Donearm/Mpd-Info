#include <lua.h>
#include <time.h>

/* Sleep functions for Lua */

lua_State* L;

static int sleep_c(lua_State *L)
{
	long secs = lua_tointeger(L, -1);
	sleep(secs);
	return 0;
}

int luaopen_sleep(lua_State *L)
{
	lua_register(L, "sleep", sleep_c);
	return 0;
}
