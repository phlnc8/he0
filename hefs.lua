do -- he.fs 

--[[ 

	Add file system functions to he (path, file, directory ...)

	Requires lfs.

	Coppyright (c) 2009, 2010, 2011  Ph. Leblanc 

	Redistribution and use of this file in source and binary forms, 
	with or without modification, are permitted without royalty 
	provided that the copyright notice and this notice are preserved.
	This file is offered as-is, without any warranty.

        
]]

------------------------------------------------------------------------

require 'he'
local lfs = require 'lfs'

_G.lfs = nil  --  (lfs.dll (for 5.1) does not respect the 5.2 convention)

local strip, rstrip, split = string.strip, string.rstrip, string.split
local startswith = string.startswith
local app, join = list.app, list.join

------------------------------------------------------------------------

local hefs = {}

he.fs = hefs -- fs submodule is not returned, but inserted in 'he' namespace

------------------------------------------------------------------------
-- pathname functions
------------------------------------------------------------------------

local win = he.windows
    -- this flag is usd only for path functions. 
    -- it can be changed if needed 
    -- (eg. working on windows paths on a linux platform)

local sep = win and '\\' or '/'
local resep = win and '%\\' or '/'  -- can be used in a re

hefs.sep, hefs.resep = sep, resep

local function cleansep(p)
    if p == sep then return p end
    p = p:gsub(resep..resep..'+', sep)
    p = p:gsub( win and '%\\$' or '/$', '') 
    return p
end

local function striprsep(p) 
    -- remove sep at end of path
    if p == sep then return p end
    local rersep = win and '%\\$' or '/$'  
    return p:gsub(rersep, '') 
end

local function wdrive(p)
    if win and p:match('^%a:') then return p:sub(1,2)
    else return nil
    end
end

function hefs.psplit(p) 
    local pl = split(p, sep)
    if pl[1] == '' then pl[1] = sep end
    if pl[#pl] == '' then table.remove(pl, #pl) end
    return pl
end

function hefs.psplitdir(p)
    -- return dir, name
    if p == '' then return "", "" end
    local pl = hefs.psplit(p)
    local name = pl[#pl]
    table.remove(pl, #pl)
    return hefs.pjoin(pl), name
end

function hefs.psplitext(p)
    --return basename, ext
    p = striprsep(p)
    local i0 = 1; local i
    while true do
        i = p:find('.', i0+1,  true)
        if not i then
            if i0 == 1 or p:find(resep, i0) 
                then return p, ''  -- no dot or last dot not in last name
            else break
            end 
        end
        i0 = i
    end --while
    -- i0 index of last dot in last name
    return p:sub(1, i0-1), p:sub(i0+1, #p)
end

function hefs.pjoin(a, ...)
    -- build a path from name components
    -- 2 forms: pjoin(namelist) or pjoin(name1, name2, ...)
    if type(a) == 'table' then 
        return cleansep(join(a, sep))
    else 
        return cleansep(join({a, ...}, sep))
    end
end

function hefs.pnormw(p)
    -- normalize a path for windows
    local np = string.gsub(p, '/', '\\')
    return np
end

function hefs.pnormu(p)
    -- normalize a path for unix
    local np = string.gsub(p, '%\\', '/')
    return np
end
    
function hefs.pnorm(p)
    return win and hefs.pnormw(p) or hefs.pnormu(p)
end

function hefs.pabs(p, pbase)
    -- pbase defaults to current dir.
    -- pbase must be an abs path.
    pbase = pbase or lfs.currentdir()
    p = striprsep(p)
    if win then
        if wdrive(p) then return p end
        local wdb = wdrive(pbase)
        if p:sub(1,1) == sep then 
            return cleansep(wdb and (wdb .. p) or p)
        else return cleansep(pbase .. sep .. p)
        end
    else --not win
        if p:sub(1,1) == sep then return cleansep(p)
        else return cleansep(pbase .. sep .. p)
        end
    end
end




------------------------------------------------------------------------
-- functions using lfs 
------------------------------------------------------------------------

-- lfs synonyms
hefs.currentdir = lfs.currentdir
hefs.chdir = lfs.chdir
hefs.rmdir = lfs.rmdir
hefs.mkdir = lfs.mkdir
hefs.touch = lfs.touch
--

local att = lfs.attributes

function hefs.fmod(fn) return att(fn, 'modification') end
function hefs.fsize(fn) return att(fn, 'size') end
function hefs.fexists(fn) return not (not att(fn, 'size')) end
function hefs.isdir(fn) return att(fn, 'mode') == 'directory' end
function hefs.isfile(fn) return att(fn, 'mode') == 'file' end

function hefs.issymlink(fn)
    if he.windows then return false
    else
        error('how to detect symlinks??')
    end
end

function hefs.fileinfo(fn)
	-- returns a record (a table) with file info 
	-- (fn=filepath, mod=modification date (iso fmt), siz=file size)
	-- or nil if fn doesn't exist or is not a file
	if not (att(fn, 'mode') == 'file')  then  return nil  end
	return {
		fn = fn,
		mod = he.isodate(att(fn, 'modification')),
		size = att(fn, 'size'),
	}
end

--~ pp(hefs.fileinfo"./hefs.lua")

function hefs.samefile(fna, fnb)
    return win and (fna == fnb) or (att(fna, 'ino')  == att(fnb, 'ino'))
end

function hefs.dir(p)
    -- p defaults to cur dir (not implemented by lfs.dir)
    return lfs.dir(p or lfs.currentdir())
end

--[[  simplified glob pattern matching
pattern 'x' matches 'x' only, not 'xy' or 'yx'
pattern 'x*' matches 'xabc'
pattern '*x' matches 'abcx'
pattern '*x*'  matches 'abxcde', but not 'ax' or 'xb' --??why??130324 
]]
function hefs.glob2re(globpat)
    local repat = '^' .. he.escape_re(globpat) .. '$'
    repat = string.gsub(repat, '%%%*', '.*')
    return repat
end

function hefs.find(dp, recurse, modefilter, globpat)
    -- finds entries in dp matching optional pattern globpat 
    -- (globpat is a simplified glob pattern. eg *.i or 123*.z -- no '?')
    -- modefilter is a filter function
    --      eg. isfile or isdir can be used here
    -- recurses in subdirs if recurse is true (non nil)
    -- 
    dp  = dp or '.'
    local repat = globpat and glob2re(globpat) or ""
    -- (if repat is '', string.match(fn, repat) will be true)
    if not modefilter then 
        modefilter = function()  return true end
    end
    local pl = he.list()
    local pn, mode
    for fn in lfs.dir(dp) do
        pn = hefs.pjoin{dp, fn}
        if fn == '.' or fn == '..' then --continue
        else
            mode = att(pn, 'mode')
--~ 			print(mode, pn)
            if modefilter(pn) and string.match(fn, repat)  then 
                app(pl, pn)
            end
            if  recurse and mode == 'directory' then
                pl:extend(hefs.find(pn, recurse, modefilter, globpat))
            end
        end
    end --for
    table.sort(pl)
    return pl
end --find
    

function hefs.files(dp, pat)
    -- find files in dp matching optional glob pattern pat. (no recursion.)
    return hefs.find(dp, false, hefs.isfile, pat)
end

function hefs.dirs(dp, pat)
    -- find dirs in dp matching optional glob pattern pat. (no recursion)
    return hefs.find(dp, false, hefs.isdir, pat)
end

function hefs.findfiles(dp, pat)
    -- find files in dp and subdirs,  matching optional glob pattern pat
    return hefs.find(dp, true, hefs.isfile, pat)
end

function hefs.finddirs(dp, pat)
    -- recursively find dirs in dp matching optional glob pattern pat
    return hefs.find(dp, true, hefs.isdir, pat)
end

--~ pp(files('.', pred.match, 'cmd'))
--~ pp(dirs('d:\\'))
--~ pp(findfiles('d:\\phl\\wtx', function(x) return fsize(x) > 20000000 end))
--~ pp(files('.', print, 'hello'))


function hefs.mkdirs(pn)
    -- recursive mkdir. make sure pn and all parent dirs exists.
    -- doesnt fail if pn already exists and is a dir.
	-- (equivalent to mkdir -p)
	error('Not Yet Implemented')
end

function hefs.rmdir(pn)
	if win then
		local r = he.shell("rmdir /s /q " .. pn)
        if r == "" then return true else return nil, r  end
	else
		local r = he.shell("(rm -r " .. pn .. " 2>&1 ; echo $? )")
        if strip(r) == "0" then return true else return nil, r  end
	end
end


-- push/pop dirs  usage:
-- hefs.pushd('/a/b'); ...do smtg.... hefs.popd()
--
local _dirstack = { }

function hefs.pushd(dir)
    list.app(_dirstack, hefs.currentdir())
    hefs.chdir(dir)
    return dir
end

function hefs.popd()
    local prevdir = list.pop(_dirstack)
    if prevdir then hefs.chdir(prevdir)  end
    return prevdir
end

------------------------------------------------------------------------


end -- he.fs module


