#!/usr/bin/env lua

--- Print song information of the currently playing one in MPD and search 
-- for a album cover in its directory. In pure Lua.
-- @author Gianluca Fiore
-- @copyright 2011-2013, Gianluca Fiore <forod.g@gmail.com>


local mpd = require("mpd")
local lfs = require("lfs")
local socket = require("socket")

--- Sleep function
-- @param n Number of seconds to sleep
function sleep(n)
	if n > 0 then
--		os.execute("ping -n -c " .. tonumber(n+1) .. " localhost > NUL")
		socket.select(nil, nil, n)
	end
end

--- Connect/Reconnect function to the mpd server.
function connection()
	local m = mpd.connect()
	if m then return m end
end

--- Get path of the mpd music directory.
function mpd_directory()
	local f = '/etc/mpd.conf'
	local file = io.input(f)

	for lines in file:lines() do
		local mpd_dir = string.match(lines, '^music_directory.-%"(.-)%"$')
		if mpd_dir then
			return mpd_dir
		end
	end
end

--- Find the path to the cover album image of the current playing song.
-- @param file The path of the song currently being played.
-- @param album The name of the album.
function coversearch(file, album)
	local dir = string.gsub(file, '(.*)/.*', "%1")
	local mpd_dir = mpd_directory()
	for files in lfs.dir(mpd_dir .. '/' .. dir) do
		if files ~= "." and files ~= ".." then
			local f = mpd_dir .. '/' .. dir .. '/' .. files
			attr = lfs.attributes(f)
			if attr.mode ~= "directory" then
				-- get file extension only (without the dot)
				local ext = string.match(f, '.*[.](.+)$')
				for _,v in pairs(images_ext) do
					-- check whether the file is an image or not
					if ext == v then
						for _,p in pairs(coverpatterns) do
							local cover = string.match(f, p)
							if cover then
								print("Cover is: ", f)
								return f
							end
						end
					end
				end
			end
		end
	end
end

-- table of all image extensions
images_ext = { "jpg", "jpeg", "JPEG", "JPG", "PNG", "png", "bmp", "BMP" }
-- table of possible patterns for the cover filename
coverpatterns = { '.*[Ff]ront.*', '.*[Ff]older.*', '.*[Aa]lbumart.*', '.*[Cc]over.*', '.*[Tt]humb.*' }
m = connection()

--- Check if we have a successful connection with MPD server or
--otherwise exit.
if not m then
	print("MPD server not running or no connection has been possible")
	-- exit if no connection has been possible to the server
	return
end

info = m:status()
last_status = info['state']
currentsong = m:currentsong()
last_song = currentsong['Title']
last_id = currentsong['Id']

trackn = currentsong['Track']  -- current song track number
date = currentsong['Date']  -- year of current song
artist = currentsong['Artist']	-- current song artist
album = currentsong['Album']  -- current song album
id = currentsong['Id']  -- numeric id of current song (unique?)
title = currentsong['Title']	-- title of current song
file = currentsong['file']	-- path, relative to mpd music directory, of current song
genre = currentsong['Genre'] -- genre of current song

while true do
	state = m:status()['state']
	id = m:currentsong()['Id']
	if state ~= last_state then
		if state == "play" then
			artist = m:currentsong()['Artist']
			album = m:currentsong()['Album']
			title = m:currentsong()['Title']
			cover = coversearch(file, album)
			np_string = string.format("Now Playing \nArtist:\t%s\nAlbum:\t%s\nSong:\t%s\n", artist, album, title)
			print(np_string)
--			return np_string, cover
		elseif state == "pause" then
			artist = m:currentsong()['Artist']
			album = m:currentsong()['Album']
			title = m:currentsong()['Title']
			print("In pause")
		else
			print("No song playing")
		end
		last_state = m:status()['state']
	end

	if id ~= last_id then
		artist = m:currentsong()['Artist']
		album = m:currentsong()['Album']
		title = m:currentsong()['Title']
		last_id = id
		print("Song changed")
		cover = coversearch(file, album)
		np_string = string.format("Now Playing \nArtist:\t%s\nAlbum:\t%s\nSong:\t%s\n", artist, album, title)
		print(np_string)
--		return np_string, cover
	end
	sleep(2)
end

--m:close()
