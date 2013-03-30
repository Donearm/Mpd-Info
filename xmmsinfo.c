#include <stdlib.h>
#include <xmmsclient/xmmsclient.h>

void get_mediainfo(xmmsc_connection_t *connection, int id)
{
	xmmsc_result_t *result;
	xmmsv_t *return_value;
	const char *err_buf;

	xmmsv_t *dict_entry;
	xmmsv_t *infos;
	const char *val;
	int intval;

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

	printf("Artist = %s\n", val);

	if(!xmmsv_dict_get(infos, "title", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Title";
	}

	printf("Title = %s\n", val);

	if(!xmmsv_dict_get(infos, "album", &dict_entry) ||
			!xmmsv_get_string(dict_entry, &val)) {
		val = "No Album";
	}

	printf("Album = %s\n", val);

	xmmsv_unref(infos);
	xmmsc_result_unref(result);
}



int main (int argc, char **argv)
{

	xmmsc_connection_t *connection;
	xmmsc_result_t *result;
	xmmsv_t *return_value;
	const char *err_buf;

	/* variables that we'll need later */
	xmmsv_list_iter_t *it;

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

	// ask for the playlist
	result = xmmsc_playlist_list_entries(connection, NULL);
	xmmsc_result_wait(result);
	return_value = xmmsc_result_get_value(result);

	if(xmmsv_get_error(return_value, &err_buf)) {
		fprintf(stderr, "Error while asking for the playlist, %s\n",
				err_buf);
		exit(EXIT_FAILURE);
	}

	// extract the iterator over the list
	if(!xmmsv_get_list_iter(return_value, &it)) {
		fprintf(stderr, "xmmsc_playlist_list_entries didn't \
				return a list as expected\n");
		exit(EXIT_FAILURE);
	}

	// loop over the list
	for(; xmmsv_list_iter_valid(it); xmmsv_list_iter_next(it)) {
		int id;
		xmmsv_t *list_entry;

		if(!xmmsv_list_iter_entry(it, &list_entry)) {
			fprintf(stderr, "Couldn't get entry from list\n");
			exit(EXIT_FAILURE);
		}
		// extract the int from the entry
		if(!xmmsv_get_int(list_entry, &id)) {
			fprintf(stderr, "Couldn't get int from list entry\n");
			exit(EXIT_FAILURE);
		}

		get_mediainfo(connection, id);
	}

	xmmsc_result_unref(result);
	xmmsc_unref(connection);
	return(EXIT_SUCCESS);
}


