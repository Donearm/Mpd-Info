#include <stdlib.h>
#include <xmmsclient/xmmsclient.h>
#include <lua.h>

lua_State* L;

void get_mediainfo(xmmsc_connection_t *connection, int id, lua_State *L)
{
	xmmsc_result_t *result;
	xmmsv_t *return_value;
	const char *err_buf;

	xmmsv_t *dict_entry;
	xmmsv_t *infos;
	const char *val;

	result = xmmsc_medialib_get_info(connection, id);
	xmmsc_result_wait(result);
	return_value = xmmsc_result_get_value(result);

	if(xmmsv_get_error(return_value, &err_buf)) {
		fprintf(stderr, "Medialib returns error, %s\n",
				err_buf);
		exit(EXIT_FAILURE);
	}

	infos = xmmsv_propdict_to_dict(return_value, NULL);
	if(!xmmsv_dict_get(infos, "artist", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Artist";
	}

	lua_pushstring(L, val);
	printf("Artist = %s\n", val);

	if(!xmmsv_dict_get(infos, "album", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Album";
	}

	lua_pushstring(L, val);
	printf("Album = %s\n", val);

	if(!xmmsv_dict_get(infos, "title", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Title";
	}

	lua_pushstring(L, val);
	printf("Title = %s\n", val);

	lua_pushinteger(L, id);
	printf("Id = %d\n", id);

	if(!xmmsv_dict_get(infos, "url", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = NULL;
	}

	lua_pushstring(L, val);
	printf("Uri = %s\n", val);

	xmmsv_unref(infos);
	xmmsc_result_unref(result);
}



int main (int argc, char **argv, lua_State *L)
{

	xmmsc_connection_t *connection;
	xmmsc_result_t *state;
	xmmsv_t *state_value;
	const char *err_buf;
	int32_t status;

	// string containing the current xmms2 state
	char *state_str;

	// initialize the connection
	connection = xmmsc_init("xmmsinfo");
	if (!connection) {
		fprintf(stderr, "No connection!\n");
		exit(EXIT_FAILURE);
	}

	// try to connect
	if (!xmmsc_connect(connection, getenv("XMMS_PATH"))) {
		fprintf(stderr, "Connection failed, %s\n",
				xmmsc_get_last_error(connection));
		exit(EXIT_FAILURE);
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
		printf("Status is playing, %d\n", status);
		state_str = "playing";
	} else if (status == XMMS_PLAYBACK_STATUS_PAUSE) {
		printf("Status is paused, %d\n", status);
		state_str = "paused";
	} else {
		printf("Status is stopped, %d\n", status);
		state_str = "stopped";
	}

	// register mediainfo function to lua
	lua_register(L, "getmediainfo", get_mediainfo);
	// push state_str to lua
	lua_pushstring(L, state_str);

	// get current position in the playlist
	xmmsc_result_t *current_id;
	xmmsv_t *current_id_value;
	int32_t cur_id;

	current_id = xmmsc_playback_current_id(connection);
	xmmsc_result_wait(current_id);
	current_id_value = xmmsc_result_get_value(current_id);
	xmmsv_get_int(current_id_value, &cur_id);

	printf("Current song id is, %d\n", cur_id);

	get_mediainfo(connection, cur_id, L);

	xmmsc_result_unref(state);
	xmmsc_result_unref(current_id);
	xmmsc_unref(connection);
	return(EXIT_SUCCESS);
}


