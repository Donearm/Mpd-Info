#!/usr/bin/env lua

--- Print song information of the currently playing one in XMMS2 and search 
-- for a album cover in its directory.
-- @author Gianluca Fiore
-- @copyright 2011-2020, Gianluca Fiore <forod.g@gmail.com>
--
-- Requires Lua FileSystem
-- (http://keplerproject.github.com/luafilesystem/index.html)


local lfs = require("lfs")
local lsleep = require("sleep")
local xmmsinfo = require("xmmsinfo")

--- Sleep function
--@param n number of seconds to sleep
function secsleep(n)
	if n > 0 then
		sleep(n)
	end
end

--- Find the path to the cover album image of the current playing song.
-- @param file The path of the song currently being played.
function coversearch(file)
	local fdir = string.gsub(file, '(.*/)(.*)', "%1")
	local sdir = string.gsub(fdir, '+', ' ') -- substitute '+' coming 
									-- from xmms2 api with whitespaces
	local dir = string.gsub(sdir, 'file://', '') -- remove "file://"
	for files in lfs.dir(dir) do
		if files ~= "." and files ~= ".." then
			local f = dir .. files
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

-- load initial status info with xmmsinfo c module
local istate, iartist, ialbum, ititle, iid, ifile = showxmmsinfo() 

--- Check if we have a successful connection with XMMS2 server or
--otherwise exit.
if not istate then
	print("XMMS2 server not running or no connection has been possible")
	-- exit if no connection has been possible to the server
	return
end

while true do
	local state, artist, album, title, id, file = showxmmsinfo()
	if state ~= istate then
		if state == "playing" then
			cover = coversearch(file)
			np_string = string.format("Now Playing \nArtist:\t%s\nAlbum:\t%s\nSong:\t%s\n", artist, album, title)
			print(np_string)
		elseif state == "paused" then
			print("In pause")
		else
			print("No song playing")
		end
		istate = showxmmsinfo()
	end

	if id ~= iid and state ~= "stopped" then
		iid = id
		print("Song changed")
		cover = coversearch(file)
		np_string = string.format("Now Playing \nArtist:\t%s\nAlbum:\t%s\nSong:\t%s\n", artist, album, title)
		print(np_string)
	end
	secsleep(2)
end
