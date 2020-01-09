#include <stdlib.h>
#include <stdio.h>
#include <xmmsclient/xmmsclient.h>
#include <lua.h>

lua_State* L;

struct Info {
	const char *state;
	const char *artist;
	const char *album;
	const char *song;
	int32_t id;
	const char *uri;
};

int show_xmmsinfo_c(lua_State *L)
{
	xmmsc_connection_t *connection;
	xmmsc_result_t *state;
	xmmsv_t *state_value;
	const char *err_buf;
	int32_t status;

	// string containing the current xmms2 state
	char *state_str;

	// initialize the Info struct
	struct Info i;

	// initialize the connection
	connection = xmmsc_init("xmmsinfo");
	if (!connection) {
		fprintf(stderr, "No connection!\n");
		return(EXIT_FAILURE);
	}

	// try to connect
	if (!xmmsc_connect(connection, getenv("XMMS_PATH"))) {
		fprintf(stderr, "Connection failed, %s\n",
				xmmsc_get_last_error(connection));
		return(EXIT_FAILURE);
	}

	// get current xmms2 status
	state = xmmsc_playback_status(connection);
	xmmsc_result_wait(state);
	state_value = xmmsc_result_get_value(state);

	if(xmmsv_get_error(state_value, &err_buf)) {
		fprintf(stderr, "Error while asking for the connection status, %s\n",
				err_buf);
	}

	if(!xmmsv_get_int(state_value, &status)) {
		fprintf(stderr, "Couldn't get connection status, %d\n", status);
	}

	// 0 == stopped; 1 == playing; 2 == paused
	if(status == XMMS_PLAYBACK_STATUS_PLAY) {
		state_str = "playing";
	} else if (status == XMMS_PLAYBACK_STATUS_PAUSE) {
		state_str = "paused";
	} else {
		state_str = "stopped";
	}

	i.state = state_str;

	// get current position in the playlist
	xmmsc_result_t *current_id;
	xmmsv_t *current_id_value;
	int32_t cur_id;

	current_id = xmmsc_playback_current_id(connection);
	xmmsc_result_wait(current_id);
	current_id_value = xmmsc_result_get_value(current_id);
	xmmsv_get_int(current_id_value, &cur_id);



	// initialize variables for the song info
	xmmsc_result_t *result;
	xmmsv_t *return_value;
	xmmsv_t *dict_entry;
	xmmsv_t *infos;
	const char *val;

	result = xmmsc_medialib_get_info(connection, cur_id);
	xmmsc_result_wait(result);
	return_value = xmmsc_result_get_value(result);

	if(xmmsv_get_error(return_value, &err_buf)) {
		fprintf(stderr, "Medialib returns error, %s\n",
				err_buf);
		return(EXIT_FAILURE);
	}

	infos = xmmsv_propdict_to_dict(return_value, NULL);
	if(!xmmsv_dict_get(infos, "artist", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Artist";
	}

	i.artist = val;

	if(!xmmsv_dict_get(infos, "album", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Album";
	}

	i.album = val;

	if(!xmmsv_dict_get(infos, "title", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Title";
	}

	i.song = val;

	i.id = cur_id;

	if(!xmmsv_dict_get(infos, "url", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = NULL;
	}

	i.uri = val;

	// push everything to lua
	lua_pushstring(L, i.state);
	lua_pushstring(L, i.artist);
	lua_pushstring(L, i.album);
	lua_pushstring(L, i.song);
	lua_pushinteger(L, i.id);
	lua_pushstring(L, i.uri);


	// clean up
	xmmsv_unref(infos);
	xmmsc_result_unref(result);
	xmmsc_result_unref(state);
	xmmsc_result_unref(current_id);
	xmmsc_unref(connection);
	return 6;
}


int luaopen_xmmsinfo(lua_State *L)
{
	lua_register(L, "showxmmsinfo", show_xmmsinfo_c);
	return 1;
}
