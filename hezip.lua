do -- he.zip

--[[  

	Add zip/unzip wrapping functions to he

	Requires InfoZip zip and unzip commands
	
	Coppyright (c) 2009-2011  Ph. Leblanc 

	Redistribution and use of this file in source and binary forms, 
	with or without modification, are permitted without royalty 
	provided that the copyright notice and this notice are preserved.
	This file is offered as-is, without any warranty.


]]
------------------------------------------------------------------------

require 'he'

local hezip = {} -- the hezip module

he.zip = hezip

------------------------------------------------------------------------

local strip, split = string.strip, string.split
local app, join = list.app, list.join


--[[  

unzip zipinfo format  (same for linux and win32??)

on win32, 091130:

D:\Temp\hezip>unzip -ZTs d2
Archive:  d2.zip   717 bytes   3 files
drwx---     2.3 ntf        0 bx stor 20091130.124402 d/
-rw-a--     2.3 ntf        8 tx stor 20091130.124402 d/ab
-rw-a--     2.3 ntf        9 tx stor 20091130.124402 d/bef
3 files, 17 bytes uncompressed, 17 bytes compressed:  0.0%

]]

local function reformat_ziplines(ziplines)
    -- reformat unzip -ZTs  output  (see example above)
    -- (zipinfo list format - hopefully identical between linux and win32)
    local nzt = {}
    local reinfo = ("^%S+%s+%S+%s+%S+%s+(%d+) %S+ %S+ "
            .. "(%d%d%d%d%d%d%d%d%.%d%d%d%d%d%d) (%S.+[^/])$")
    local siz, tim, pnam
    for i, s in ipairs(ziplines) do
        siz, tim, pnam = string.match(s, reinfo)
        if pnam and not pnam:endswith('/') then
            siz = string.format("%9s", siz)
            tim = string.gsub(tim, "%.", "-")
            app(nzt, {tim, siz, pnam})
        end
    end
    table.sort(nzt, function(a,b) return a[3]<b[3] end)
	local function mkl(t) return table.concat(t, ' ') end
    return list.map(nzt, mkl)
end

function hezip.ziplist(zipfn)
    local zl = he.shlines('unzip -ZTs '..zipfn)
    if #zl < 2 then return nil end
    local nzl = reformat_ziplines(zl)
    return nzl
end

function hezip.zip(fn, zipfn)
    zipfn = zipfn or fn..'.zip'
--~     ret = os.execute(string.format('zip -r %s %s', zipfn, fn))
    local ret = he.shell(string.format('zip -q -r %s %s', zipfn, fn))
    return ret
end

function hezip.unzip(zipfn, dirfn)
	-- extract in dirfn or current dir if dirfn is not specified
	dirfn = dirfn or '.'
    local ret = he.shell(string.format('unzip -d %s %s', dirfn, zipfn))
    return ret
end


------------------------------------------------------------------------
end -- he.zip