do -- he.zen

--[[

	Add crypto and compression functions to he

	Requires luazen so/dll
	
	
   Coppyright (c) 2009, 2010, 2011  Ph. Leblanc 

	Redistribution and use of this file in source and binary forms, 
	with or without modification, are permitted without royalty 
	provided that the copyright notice and this notice are preserved.
	This file is offered as-is, without any warranty.


]]


require 'he'
local luazen = require 'luazen'

_G.luazen = nil  -- should fix luazen.c ... -110427

he.zen = luazen

luazen.encrypt = luazen.rc4
luazen.decrypt = luazen.rc4


local strf = string.format
local byte = string.byte
local char = string.char


function luazen.hexencode(s)
	s  = s:gsub('.', function(c)  return strf('%02x', byte(c)) end)
	return s
end

function luazen.hexdecode(s)
	s  = s:gsub('(%x%x)', function(c)  return char(tonumber(c, 16)) end)
	return s	
end


------------------------------------------------------------------------
end --do --luazen
