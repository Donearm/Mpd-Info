#!/usr/bin/env lua

--- Popup with info about current playing song in mpd.
-- To be loaded from awesomeWM's rc.lua
-- @author Gianluca Fiore
-- @copyright 2011-2012, Gianluca Fiore <forod.g@gmail.com>
--
-- Requires lua-mpd (https://github.com/silentbicycle/lua-mpd)
-- and Lua FileSystem 
-- (http://keplerproject.github.com/luafilesystem/index.html)

local mpd = require("mpd")
local lfs = require("lfs")


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

--- Main loop function.
-- @param argid A numeric value corresponding to the Id of the song 
-- played.
-- @param m_connection A previous connection to the mpd server.
function mpd_main(argid, m_connection)
	if m_connection then
		local m = m_connection
	else
		while m == nil do
			-- keep trying to connect to mpd until a connection is made
			m = connection()
		end
	end
	state = m:status()['state']
	id = m:currentsong()['Id']
	last_id = argid or arg[1]
	if last_id == nil then
		-- last_id may be nil at first call from awesomewm, make it 0 
		-- then because nil can't be indexed
		last_id = 0
	end
	if id ~= last_id then
		if state == "play" then
			artist = m:currentsong()['Artist']
			album = m:currentsong()['Album']
			title = m:currentsong()['Title']
			file = m:currentsong()['file']
			cover = coversearch(file, album)
			np_string = string.format("Now Playing \nArtist:\t%s\nAlbum:\t%s\nSong:\t%s\n", artist, album, title)
			return m, id, np_string, cover
		elseif state == "pause" then
			artist = m:currentsong()['Artist']
			album = m:currentsong()['Album']
			title = m:currentsong()['Title']
			return m, id
		else
			return m, id
		end
	else
		return m, id
	end
end
