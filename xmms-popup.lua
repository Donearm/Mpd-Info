#!/usr/bin/env lua

--- Popup with info about current playing song in xmms2.
-- To be loaded from awesomeWM's rc.lua
-- @author Gianluca Fiore
-- @copyright 2011-2013, Gianluca Fiore <forod.g@gmail.com>
--
-- Requires Lua FileSystem
-- (http://keplerproject.github.com/luafilesystem/index.html)


local lfs = require("lfs")
local xmmsinfo = require("xmmsinfo")
local lsleep = require("sleep")

--- Sleep function
--@param n number of seconds to sleep
function secsleep(n)
	if n > 0 then
		sleep(n)
	end
end

--- Escape characters in a string
--@param s the string containing characters to be escaped
function escape(s)
	return (s:gsub("[%-%.%+%[%]%(%)%$%^%%%?%*%']", '%%%1'):gsub('%z', '%%z'))
end


--- Find the path to the cover album image of the current playing song.
-- @param file The path of the song currently being played.
function coversearch(file)
	local fdir = string.gsub(file, '(.*/)(.*)', "%1")
	local sdir = escape(fdir)
	local dir = string.gsub(sdir, 'file://', '') -- remove "file://"
	for files in lfs.dir(dir) do
		if files ~= "." and files ~= ".." then
			local f = dir .. '/' .. files
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

--- Main loop function.
-- @param argid A numeric value corresponding to the Id of the song 
-- played.
function xmms_main(argid)
	last_id = argid or arg[1]

	if last_id == nil then
		-- last_id may be nil at first call from awesomewm, make it 0 
		-- then because nil can't be indexed
		last_id = 0
	end
	-- load status info with xmmsinfo c module
	local state, artist, album, title, id, file = showxmmsinfo() 

	if id ~= last_id then
		if state == "playing" then
			cover = coversearch(file)
			np_string = string.format("Now Playing \nArtist:\t%s\nAlbum:\t%s\nSong:\t%s\n", artist, album, title)
			return id, np_string, cover
		elseif state == "paused" then
			return id
		else
			return id
		end
	else
		return id
	end
end
