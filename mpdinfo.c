/* inspired by https://github.com/mjheagle8/status */

#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <mpd/client.h>

#define MPD_HOST "localhost" /* the host where mpd listens to */
#define	MPD_PORT 0	/* the mpd port; 0 for default */
#define	MPD_TIMEOUT 0 /* 0, the default timeout in ms */

struct Info {
	char *state;
	char *artist;
	char *album;
	char *song;
	char *id;
	char *uri;
};


struct mpd_connection *connection = NULL;
lua_State* L;


int show_mpdinfo_c(lua_State *L)
{
	/* initialize status, state and song */
	struct mpd_status *status = NULL;
	struct mpd_song *song = NULL;
	char *state;
	/* initialize the Info struct */
	struct Info i;

	/* try a connection if there's not one already */
	if (!connection)
		connection = mpd_connection_new(MPD_HOST, MPD_PORT, MPD_TIMEOUT);
	/* get status */
	status = mpd_run_status(connection);
	/* if no status, try reconnecting */
	if (!status)
	{
		fprintf(stderr, "connection failed: %s\n", mpd_connection_get_error_message(connection));
/*		lua_pushstring(L, mpd_connection_get_error_message(connection)); */
		lua_pushboolean(L, 0);
		mpd_connection_free(connection);
		return 1;
	}

	/* get play state */
	enum mpd_state playstate = mpd_status_get_state(status);
	if (playstate == MPD_STATE_STOP)
	{
		state = "stopped";
		lua_pushstring(L, "stopped");
		return 1;
	}
	else if (playstate == MPD_STATE_PAUSE)
	{
		state = "paused";
	}
	else if (playstate == MPD_STATE_PLAY)
	{
		state = "playing";
	}
	else
	{
		state = "?";
	}
	mpd_status_free(status);

	/* check what mpd is doing */
	if (strcmp(state, "playing") == 0 || strcmp(state, "paused") == 0 )
	{
		song = mpd_run_current_song(connection);
		const char *artist = mpd_song_get_tag(song, MPD_TAG_ARTIST, 0);
		const char *album = mpd_song_get_tag(song, MPD_TAG_ALBUM, 0);
		const char *title = mpd_song_get_tag(song, MPD_TAG_TITLE, 0);
		const char *id = mpd_song_get_tag(song, MPD_TAG_TRACK, 0);
		const char *uri = mpd_song_get_uri(song);
		i.state = state;
		i.artist = artist;
		i.album = album;
		i.song = title;
		i.id = id;
		i.uri = uri;
/*		printf("From the struct:\n"); */
/*		printf("Artist: %s\n", i.artist); */
/*		printf("Album: %s\n", i.album); */
/*		printf("Song: %s\n", i.song); */
/*		printf("File: %s\n", i.uri); */
		
		/* push infos into Lua stack */
		lua_pushstring(L, i.state);
		lua_pushstring(L, i.artist);
		lua_pushstring(L, i.album);
		lua_pushstring(L, i.song);
		lua_pushstring(L, i.id);
		lua_pushstring(L, i.uri);

		mpd_song_free(song);

		return 6;
	}
	else
	{
/*		printf("Mpd is %s", state); */
		lua_pushstring(L, state);
		return 1;
	}
	mpd_connection_free(connection);
}

int luaopen_mpdinfo(lua_State *L)
{
	lua_register(L, "showmpdinfo", show_mpdinfo_c);
	return 1;
}
