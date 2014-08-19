--[[    he - a Lua utility module,  v082

    Coppyright (c) 2009-2013  Ph. Leblanc 

	Redistribution and use of this file in source and binary forms, 
	with or without modification, are permitted without royalty 
	provided that the copyright notice and this notice are preserved.
	This file is offered as-is, without any warranty.

	---
	


]]

local VERSION = 'he082, 130402'
print(VERSION)

------------------------------------------------------------------------

-- !! unpack hack !!
-- unpack is a global for 5.1 and field of table for 5.2... 
-- always use table.unpack in he. define it here if needed
if not table.unpack then table.unpack = unpack  end


------------------------------------------------------------------------


local he = {}  -- the he module

local app = function(t, elem) t[#t+1] = elem ; return t end
local rem = function(t, i) table.remove(t, i); return t end
local pop = table.remove
local join = table.concat

function he.equal(a, b, checkmt)
    -- deep equal (beware cycles!! would lead to infinite recursion.)
    -- userdata values are not compared (for them, equal is ==)
    -- if checkmt, metatables are also compared 
    -- default is to ignore metatables
    if a == b then return true end
    local ta, tb = type(a), type(b)
    if ta ~= tb then return false end
    if ta == 'table' then
        if checkmt and (getmetatable(a) ~= getmetatable(b)) then
            return false
        end
        local cnta, cntb = 0, 0
        for k,v in	 pairs(a) do 
            cnta = cnta + 1
            if not he.equal(v, b[k]) then return false end
        end
        -- here, all elem in a have equal elems in b. now,
        -- must check b has no more elems (# doesnt work)
        for k,v in pairs(b) do cntb = cntb+ 1 end
--~         print(cnta, cntb)
        return cnta == cntb
    else return false 
    end
end

function he.compare_any(x, y)
	-- compare data with any type (useful to sort heterogeneous lists)
	-- equivalent to x < y for same type data
	-- order: nil < any number < any string < any other object
	local tx, ty = type(x), type(y)
	if tx == ty then 
		if tx == 'string' or 'number' then return x < y 
		else return true -- ignore order on tables and others
		end
	end
	if x == nil  then return true end
	if y == nil  then return  false end
	if tx == 'number' then return true end
	if tx == 'string' then return ty ~= 'number' end
	if ty == 'string' then return false end
	return true
end

function he.clone(t)
    -- create a copy of table
    -- (this is a shallow clone - no deep copy)
    local ct = {}
    for k,v in pairs(t) do ct[k] = v end
    setmetatable(ct, getmetatable(t))
    return ct
end

------------------------------------------------------------------------
-- string functions
------------------------------------------------------------------------

he.strf = string.format

function he.startswith(s, px)
	-- test if a string starts with  a prefix.
	-- px is either a string or a list of strings (can be a raw table)
	-- if px is a list, each string in list is tested until one matches
	-- prefixes are plain strings, not regular expressions
	-- returns the matching prefix or nil
	if type(px) == "string" then 
		return (string.find(s, px, 1, true) == 1) and px or nil
	else -- assume px is a list of prefix
		for i, p in ipairs(px) do 
			if string.find(s, p, 1, true) == 1 then return p end
		end
	end--if
end--startswith

function he.endswith(s, sx)
	-- test if a string ends with  a suffix.
	-- sx is either a string or a list of strings (can be a raw table)
	-- if sx is a list, each string in list is tested until one matches
	-- suffixes are plain strings, not regular expressions
	-- returns the matching suffix or nil
	if type(sx) == "string" then 
		local j = #s - #sx + 1
		return (string.find(s, sx, j, true) == j) and sx or nil
	else -- assume sx is a list of suffix
		for i, su in ipairs(sx) do 
			local j = #s - #su + 1
			if string.find(s, su, j, true) == j then return su end
		end
	end--if
end--endswith

function he.split(s, sep, cnt)
    -- sep: split on sep, defaults to whitespaces (a la py)
    -- !! sep is a regexp => escape special chars !!
    -- !! to escape a spe-char, use '%<spe-char>' (NOT '\'!!)
    -- !! eg. to split s on a dot: split(s, '%.')
    -- cnt: optional number of split (default to all)
    sep = sep or "%s+"
    cnt = cnt or -1
	local t = list(); local i0 = 1; local i,j  
    local find, sub = string.find, string.sub
	while i0 do
        i,j = find(s, sep, i0)
        if i and (cnt ~= 0) then 
            app(t, sub(s, i0, i-1))
            i0 = j + 1 ;  cnt = cnt - 1
        else break end --if
    end --while
    app(t, sub(s, i0, -1))
    return t
end --split()

function he.lines(s) return he.split(s, '\r?\n') end

function he.lstrip(s) s = string.gsub(s, '^%s+', '') ; return s  end
function he.rstrip(s) s = string.gsub(s, '%s+$', '') ; return s end
function he.strip(s) return he.lstrip(he.rstrip(s)) end

function he.stripnl(s)
	-- strip empty lines at beginning and end of string
	s = string.gsub(s, '^[\r\n]+', '')
	s = string.gsub(s, '[\r\n]+$', '')
	return s
end

------------------------------------------------------------------------
-- string parsing functions

--- parsestring:  parse a string
-- return a tuple with all pattern captures
-- if pattern is nil,  the string is split on spaces, either in as many 
--      pieces as elements in names, or split on all spaces
-- if names is nil, the tuple is a list {val1, val2, ...}
-- if not, names is a list of tuple element names 
-- tuple is returned as a table with names elements: {name1=val1, ...}
--
function he.parse_string(line, pattern, names)
	local t
	if pattern then 
		t = { string.match(line, pattern) }
	elseif names then --names but no pattern: split in one piece per name
		t = he.split(line, nil, #names - 1)
	else -- no names, no pattern: just split on white spaces
		t = he.split(line)
	end
	if not t[1] then return nil end -- line doesnt match!
	if names then
		local r = {}
		for i,name in ipairs(names) do r[name] = t[i] end
		return r
	else -- no names
		return t
	end
end

--- parselines: parse a list of lines
-- returns a list of tuples
-- options is a table with optional elements:
--	names:  a list of field names (see parse_string())
--	mustmatch:  a boolean.  
--		if true, stop parsing on match error, return nil, line index
--		if false, just ignore non matching lines
-- striplines: a boolean
--       if true, strip each line before parsing
--
function he.parse_lines(linelist, pattern, options)
	local rl = list()
	options = options or {}
	local mustmatch = options.mustmatch
	for i, line in ipairs(linelist) do
		if options.striplines then line = line:strip() end
		local r = he.parse_string(line, pattern, options.names)
		if not r and mustmatch then return nil, i  end
		rl:app(r)
	end
	return rl
end

--- nanopat - makes lua pattern for very simple common cases
-- returns a lua re pattern
-- nano-syntax:
--		* match anything, non greedy:  '.-'
--		+ idem, but match is captured:  '(.-)'
--		? match one character: '.'
--		space: match one or several space char: '%s+'
--		anything else matches itself
-- 		pattern is anchored at beg and end of string: '^...$'
--		eg.  nanopat('abc + *') == '^abc%s+(.-)%s+.-$'
function he.nanopat(s)
    local gsub = string.gsub
    local pat = gsub(s, "(%p)", "%%%1")
	pat = gsub(pat, ' ', '%%s*')
    pat = gsub(pat, '%%%*', '.-')
    pat = gsub(pat, '%%%+', '(.-)')
    pat = gsub(pat, '%%%?', '.')
	pat = '^' .. pat .. '$'
--~ 	print(pat)
    return pat
end

------------------------------------------------------------------------
-- string representations

function he.repr(x) 
    if type(x) == 'number' or type(x) == 'boolean' then
        return tostring(x)
    else
        return string.format("%q", tostring(x)) 
    end
end

local repr = he.repr

function he.n2s(n, nf)
    -- display number n as a string with a thousand separator (',')
    -- use optional printf format 'nf' (default is %d)
    nf = nf or "%d"
    local s = string.format(nf, n)
    local t = he.split(s, '%.'); s = t[1]
    s, n = string.gsub(s, '(%d)(%d%d%d)$', '%1,%2')
    while n > 0 do
        s, n = string.gsub(s, '(%d)(%d%d%d),', '%1,%2,')
    end
    t[1] = s
    return join(t, '.')  
end

--- serialize(x)
-- produce a lua source representation of x
-- assume x contains only booleans, numbers, strings and tables 
--	tables can be list or raw tables 
--	(metatables ignored if not list)
--	assume there is no cycle/recursive data definition
function he.serialize(x)
    if type(x) == 'number' or type(x) == 'boolean' then
        return tostring(x)
    elseif type(x) == 'string' then
        return string.format("%q", x) 
	elseif type(x) == 'table' then
		local mt = getmetatable(x)
		local prefix
		local rl = list()
		if mt == he.list then  -- serialize as a list (only array part)
			prefix = 'list{\n' 
			for i,v in ipairs(x) do 
				app(rl, he.serialize(v)); app(rl, ',\n')
			end
			return prefix .. rl:join().. '}'
		end
		-- serialize as a regular table (all keys)
		prefix = '{\n' 
		for k,v in pairs(x) do 
			app(rl, he.strf('[%s]=%s,\n', he.serialize(k), he.serialize(v)))
		end 
		return prefix .. rl:join().. '}'
	else
		error('he.serialize: unsupported type ' .. type(x))
	end--if type
end--serialize()

--- deserialize(s)
-- return the value of some lua expression serialized by he.serialize()
-- !! 's' is evaluated => major security risk if s origin is not controlled !!
function he.deserialize(s)
	local chunk = assert(loadstring('return ' .. s), 
		"he.deserialize: string parse error")
	local x  =  chunk()
	return x
end--deserialize()

function he.l2s(t)
    -- returns list t as a string 
    -- (an evaluable lua list, at least for bool, str and numbers)
	-- !!  beware:  elements of type table are treated by t2s()  !!
	--	=> convenient for debug display or limited use
    local rl = {}
    for i, v in ipairs(t) do 
		app(rl, (type(v) == "table") and he.t2s(v) or repr(v))
    end
    return '{' .. join(rl, ', ') .. '}'
end

function he.t2s(t)
    -- return table t as a string 
    -- (an evaluable lua table, at least for bool, str and numbers)
	-- (!!cycles are not detected!!)
	if type(t) ~= "table" then return repr(t) end
	if getmetatable(t) == he.list then return he.l2s(t)  end
    local rl = {}
    for k, v in pairs(t) do 
		app(rl, '[' .. repr(k) .. ']=' .. he.t2s(v)) 
    end
    return '{' .. join(rl, ', ') .. '}'
end

function he.escape_re(s)
    -- escapes a string to be used as a re pattern
    return string.gsub(s, "(%p)", "%%%1")
end


------------------------------------------------------------------------
-- predicates, compare functions
-- (useful for filter,map functions)
------------------------------------------------------------------------

-- predicates

function he.istrue(v1) return v1 end
function he.iseq(v1, v2) return v1==v2 end
function he.isneq(v1, v2) return v1~=v2 end
function he.islt(v1, v2) return type(v1)==type(v2) and v1<v2 end
function he.isle(v1, v2) return type(v1)==type(v2) and v1<=v2 end
function he.isgt(v1, v2) return type(v1)==type(v2) and v1>v2 end
function he.isge(v1, v2) return type(v1)==type(v2) and v1>=v2 end

function he.isbw(v1, lo, hi) 
	return  (not lo or (type(v1)==type(lo) and v1>=lo)) 
		and (not hi or (type(v1)==type(hi) and v1 < hi)) 
end

function he.isin(v1, v2)
	return type(v2) == "table" and list.has(v2, v1) 
	or type(v2) == "string" and string:find(v2, v1) 
end

-- notp:  test if a predicate is not true
function he.notp(v1, pred, ...) return not pred(v1, ...)  end

-- testf: tuple field predicate - assume t is a tuple (list or dict)
-- f is a tuple field index or name
-- (this can be used in map, filter,... for lists of tuples - eg.:
--   adults = lst:filter('testf', 'age', 'ge', 18)
-- if no argument after 'f' is passed, returns true if field f is defined
function he.testf(t, f, pred, ...)
	if pred then return pred(t[f], ...)  end
	return t[f] ~= nil  -- (if t[f] == false, it is considered as defined)
end

-- testv:  applies a predicate to the value in a key-value pair k,v. 
-- returns k,v if pred(v, ...) is true.  Else, return nil 
-- can be used with tmap() to implement a filter on a table
--testk: same as testv but the predicate is applied to the key.     
function he.testv(k, v, pred, ...) if pred(v, ...) then return k, v end end
function he.testk(k, v, pred, ...) if pred(k, ...) then return k, v end end

function he.reccmp(fn1, fn2, fn3)
	-- returns a function which compares two records (tables) 
	-- on one up to three fields. 
	-- fn1, fn2, fn3 are field indices or names, fn2 and fn3 are optional
	-- fields are assumed to exist and have same type in both tables and
	-- be comparable with '<' (homogeneous numbers or strings)
	-- Can be used to sort lists of records. 
	-- eg. to sort a list of lists on elements 3 then 5:
	--	table.sort(lst, he.reccmp(3, 5))
	-- if no argument is provided, tables are compared on first field
	fn1 = fn1 or 1
	return function(t1, t2)
		if t1[fn1] < t2[fn1] then return true
		elseif t1[fn1] > t2[fn1] then return false
		elseif fn2 and t1[fn2] < t2[fn2] then return true
		elseif fn2 and t1[fn2] > t2[fn2] then return false
		elseif fn3 and t1[fn3] < t2[fn3] then return true
		else return false
		end
	end--function
end -- reccmp

function he.reccmpany(fn1, fn2, fn3)
	-- same as he.reccmp() but uses compare_any(), so
	--    field values may be heterogeneous
	local cmp = he.compare_any
	fn1 = fn1 or 1
	return function(t1, t2)
		if cmp(t1[fn1], t2[fn1]) then return true
		elseif not (t1[fn1] == t2[fn1]) then return false
		elseif fn2 and cmp(t1[fn2], t2[fn2]) then return true
		elseif fn2 and not (t1[fn2] == t2[fn2]) then return false
		elseif fn3 and cmp(t1[fn3], t2[fn3]) then return true
		else return false
		end
	end--function
end -- reccmpany


------------------------------------------------------------------------
-- class
------------------------------------------------------------------------

-- class modified, classwrapper removed 130323 
--    (last version with class and class wrapper is he081)

-- class 
-- ... a minimalist "class" concept!
-- ... just a way to associate methods to tables. 
-- ... no inheritance, no information hiding, no initialization!
--
-- to create a class c, use:  c = class() 
-- to create an instance of c, use:  obj = c()  or  obj = c{x=1, y=2}
--	  constructor argument must be nil 
--   or a table _which becomes the object_
--
local class = { } ; he.class = class
setmetatable(class, class)
function class.__call(c, t)
	-- if t is an object with a metatable mt, mt will be replaced.
	local obj = setmetatable(t or {}, c)
	if c == class then obj.__index = obj end 
	return obj
end




------------------------------------------------------------------------
-- list
------------------------------------------------------------------------

local list = class() ;  he.list = list

list.app = app
list.rem = rem
list.pop = pop
list.join = join
list.equal = he.equal
list.sort = table.sort

function list.extend(lst, otherlist)
    -- extend list with otherlist
    local e = #lst
    for i,v in ipairs(otherlist) do lst[e+i] = v end
	return lst
end

function list.filter(lst, pred, ...)
	-- lst:filter(f, ...)  return a copy with elems e where pred(e, ...) is true
	local t2 = list()
	for k, e in ipairs(lst) do if pred(e, ...) then app(t2, e)  end end
	return t2
end

function list.sorted(lst, cmpf)
	-- returns a sorted shallow copy of lst
	-- l:sorted(cmpf):  use f as a compare function
	--    cmpf(e1, e2) replaces e1 < e2
	local el = list()
	for i,e in ipairs(lst) do app(el, e) end
	table.sort(el, cmpf)
	return el
end --sorted()

function list.map(lst, f)
    -- maps function f over list lst
	-- f(v) is applied to each element v of lst, in sequence
	-- creates a new list with results of f (v) 
	--		(only if result is non false)
	--		(=> cannot be used to make a list with false elems...)
	-- if f is nil, f is assumed to be identity, 
	-- 	ie map(lst) makes a shallow copy of lst
    local r = list()
	local x
    for i, v in ipairs(lst) do
		if f then x = f(v) else x = v end
		if x then app(r, x) end
	end
    return r
end

function list.makeindex(lst, fn)
	-- return a table built from list lst
	-- if fn is a function, each element e in list is inserted in new table
	-- with key fn(e)  --  makeindex({a,b,c}, f) => {f(a)=a, f(b)=b, f(c)=c}
	-- if fn is a string or number, it is assumed that each element e 
	-- is a table, and e is inserted in new table with key e[fn]
	--    makeindex({a,b,c}, fn) => {a[fn]=a, b[fn]=b, c[fn]=c}
	-- else fn is ignored, function returns a set:
	--    makeindex{a,b,c} => {a=1, b=1, c=1}
	local t = {}
	if type(fn) == "function" then
		for i,e in ipairs(lst) do t[fn(e)] = e end
	elseif type(fn) == "string" or type(fn) == "number" then
		for i,e in ipairs(lst) do t[e[fn]] = e end
	else -- build a set
		for i,e in ipairs(lst) do t[e] = 1 end
	end--if
end

function list.lseq(lst, lst2)
	-- "list simple (or shallow) equal" - compare list/array portion of tables
	--  (uses '==' for comparison --ie identity-- for tables. does not recurse)
	local ln = #lst
	if ln ~= #lst2 then return false end
	for i = 1, ln do if lst[i] ~= lst2[i] then return false end end
	return true
end

function list.has(lst, elem)
    for i,v in ipairs(lst) do 
        if v == elem then return true end 
    end
    return false
end

function list.find_elem(lst, pred, ...)
    -- returns an elem e for which pred(e) is true, or nil if none
    for i,e in ipairs(lst) do 
        if pred(e, ...) then return e end 
    end
    return nil
end

function list.all_elems(lst, pred, ...)
    -- return true if pred(e) is true for all elems e in list
    for i,e in ipairs(lst) do 
        if not pred(e, ...) then return false end 
    end
    return true
end

-- equivalent to next() for pairs() - still valid with 5.2?!?
--~ local inext = ipairs({}) 

function list.elems(lst, pred, arg1, arg2, arg3)
	-- iterator over all lst elements
	--    for e in lst:elems() do ...
	-- or for e in lst:elems(he.isgt, 20) do ...
	local i = 1
	if pred then
		return function()
			local e = lst[i]
			while e and not pred(e, arg1, arg2, arg3) do
				i = i +1;  e = lst[i]
			end--while
			return e
		end --function
	else
		return function() local e = lst[i]; i = i +1; return e  end
	end--if
end--elems()

-- list-based set functions

function list.uniq(lst)
	-- return a list of unique elements in lst (named after unix's uniq)
	local t = {}
	for i,e in ipairs(lst) do
		t[e] = 1
	end
	return he.keys(t)
end

function list.uapp(lst, e)
	-- set insert:  append an element only if it is not already in list
	for i,x in ipairs(lst) do if e == x then return end end
	return app(lst, e)
end

function list.uextend(lst, l2)
	-- set extend:  set insert all elements of l2 in lst 
	--   (ie insert only unique elements)
	--   if lst is a list-based set, after uextend,  lst is still a set.
--~ 	local ul2 = list.uniq(l2) --not needed if use uapp()
	for i, x in ipairs(l2) do list.uapp(lst, x) end
	return lst
end

function list.urem(lst, e)
	-- remove 1st occurence of e in lst (set remove for a list-based set)
	local ei
	for i,x in ipairs(lst) do
		if e == x then  ei = i;  break  end
	end
	if ei then table.remove(lst, ei) end
	return lst
end


------------------------------------------------------------------------
-- other useful table functions
------------------------------------------------------------------------


function he.update(t, t2)
	-- append all k,v pairs in table t2 to table t
	-- (if k already exists in t, t[k] is overwritten with t2[k])
	-- return t
	for k,v in pairs(t2) do t[k] = v end
	return t
end

function he.incr(t, k, n)
    -- incr t[k] by n (if no n, incr by 1)
    -- if no t[k], create one with init value=0, then incr.
    local v = (t[k] or 0) + (n or 1)
    t[k] = v
    return v
end

function he.collect(t, k, e)
	-- appends e to list t[k]
	-- creates list if t[k] doesnt exist.
	if not t[k] then t[k] = list() end
	app(t[k], e)
end

function he.ucollect(t, k, e)
	-- appends e to list-based set t[k] if not already in there.  
	-- creates list if t[k] doesnt exist.
	if not t[k] then t[k] = list() end
	list.uapp(t[k], e)
end

function he.tmap(t, f, ...)
    -- maps function f over table t
	-- f(k, v, ...) is applied to each element k, v of table t
	-- creates a new table with results of f
	--		- f should returns ka, va  
	--		-  ka,va is inserted in new table only if ka is non false)
    local r = {}
	local ka, va
    for k, v in pairs(t) do
		ka, va = f(k, v, ...)
		if ka then r[ka] = va end
	end
    return r
end

function he.tmapl(t, f, ...)
    -- maps function f over table t
	-- f(k, v, ...) is applied to each element k, v of table t
	-- creates a new _list_ with result of f(k, v)
	--		- f should returns a value va  
	--		-  va is inserted in new list only if va is non false)
	--		- (=> cannot be used to create a list with false elems)
	-- if f is nil, f is assumed to be (k,v) => v 
	-- 	ie mapl(t) creates a (shallow) copy of values of t
    local r = list()
	local va
    for k, v in pairs(t) do
		if f then va = f(k, v, ...) else va = v end
		if va then app(r, va) end
	end
    return r
end

function he.keys(t, pred, ...) 
    -- returns list of keys of t
    -- if predicate, returns only keys for which pred(v, ...) is true
    local kt = list()
    for k,v in pairs(t) do 
        if not pred or pred(v, ...) then app(kt, k) end 
    end
    return kt  
end

function he.sortedkeys(t, pred, ...)  
    -- returns sorted list of keys of t
    -- if predicate is defined, return only keys for which pred(v, ...) is true
	-- sort works with heterogeneous keys (use compare_any) 
	--   in case of performance issue, simply use sorted(keys(. . .)) )
    local kt = he.keys(t, pred, ...); 
    table.sort(kt, compare_any); 
    return kt 
end

function he.count(t, pred, ...)  
    -- returns number of keys in table t
    -- if pred, count only keys for which pred(v, ...) is true
	local n = 0
	if pred then 
		for k,v in pairs(t) do if pred(v, ...) then  n = n + 1 end end
	else
		for k,v in pairs(t) do n = n + 1 end
    end--if pred
    return n
end


------------------------------------------------------------------------
-- he file and os functions
------------------------------------------------------------------------

function he.isodate(t)     -- format: 20090709T122122
    return os.date("%Y%m%dT%H%M%S", t) 
end

function he.isodate19(t)     -- format: 2009-07-09 12:21:22
    return os.date("%Y-%m-%d %H:%M:%S", t) 
end

function he.isodate11(t)     -- format: 090709_1221
    return os.date("%y%m%d_%H%M", t) 
end

function he.iso2time(s)
	-- parse an iso date - return a time (seconds since epoch)
	-- format: 20090709T122122 or 20090709T1234 or or 20090709
	-- (missing sec, min, hrs are replaced with '00')
	-- (T can be replaced with '-' or '_')
	local t = {}
	t.year, t.month, t.day, t.hour, t.min, t.sec = string.match(s, 
		"(%d%d%d%d)(%d%d)(%d%d)[T_-](%d%d)(%d%d)(%d%d)")
	if t.year then return os.time(t) end
	t.year, t.month, t.day, t.hour, t.min = string.match(s, 
		"(%d%d%d%d)(%d%d)(%d%d)[T_-](%d%d)(%d%d)")
	if t.year then t.sec = '00'; return os.time(t) end
	t.year, t.month, t.day = string.match(s, "(%d%d%d%d)(%d%d)(%d%d)")
	if t.year then 
		t.hour = '00'; t.min = '00'; t.sec = '00'; return os.time(t)
	end
	return nil, "he.iso2time: invalid format"
end

function he.fget(fname)
    local f = assert(io.open(fname, 'rb'))
    local s = f:read("*a") ;  f:close()
    return s
end

function he.fput(fname, content)
    local f = assert(io.open(fname, 'wb'))
    assert(f:write(content) ); 
	assert(f:flush()) ; f:close()
end

function he.fgetlines(fname)
    local sl = list()
    for s in io.lines(fname) do sl[#sl + 1] = s end
    return sl
end

function he.fputlines(fname, sl, eol)
    -- sl is a string list (with no eol)
    -- put eol between strings (not at end). default is \n.
    eol = eol or '\n'
    local f = io.open(fname, "w")
    local content = table.concat(sl, eol)
    f:write(content)
    f:flush()
    f:close()
end

function he.shell(cmd)
    -- execute cmd; return stdout as a string
    local f = io.popen(cmd) 
    local s = f:read("*a")
    f:close()
    return s
end

function he.shlines(cmd) 
    -- executes cmd return stdout as a list of lines
	-- (remove empty lines at beginning and end of cmd output)
    return he.lines(he.stripnl(he.shell(cmd))) 
end

function he.escape_sh(s)  
    -- escape posix shell special chars: [ ] ( ) ' " \
    -- (works for unix, not windows...)
    return string.gsub(s, "([ %(%)%\\%[%]\"'])", "\\%1")
end


-- small windows/unix dependant utilities

-- path separator
he.pathsep = string.sub(package.config, 1, 1)

-- platform_is_window flag
-- 	beware cygwin!!  pathsep == '/'.  is it considered as windows or linux? 
he.windows = ( string.byte(he.pathsep) == 92)  --'\\'

-- new line
he.newline = he.windows and '\r\n' or '\n'

function he.pnorm(p)
    -- 'normalize a (relative) path according to platform'
    if he.windows then p = string.gsub(p, '/', '\\') end
	return p
end

function he.unorm(p)
    -- 'normalize a (relative) path - convert separators to "/" '
    p = string.gsub(p, '\\', '/')
	return p
end

function he.basename(path, suffix)
	-- works like unix basename.  
	-- if path ends with suffix, it is removed
	-- if suffix is a list, then first matching suffix in list is removed
	local dir, base = path:match("^(.+)/(.*)$")
	if not base then base = path end
	if not suffix then return base end
	suffix = he.endswith(base, suffix)
	if suffix then return string.sub(base, 1, #base - #suffix ) end
	return base
end

function he.dirname(path)
	return path:match("^(.+)/.*$") or ""
end

function he.makepath(dirname, name, ext)
	-- returns a path made with a dirname, a filename and an optional ext.
	-- path uses unix convention (separator is '/')
	-- ext is assumed to contain the dot, ie. makepath('/abc', 'file', '.txt')
	if ext then name = name .. ext end
	if he.endswith(dirname, '/') then
		return dirname .. name
	else
		return dirname .. '/' .. name
	end--if
end

-- generate a tmp file path from a name
--
he.tmpdir = he.windows and os.getenv('TMP') or '/tmp'

function he.ptmp(name) 
	-- return a tmp path - eg on unix,  he.ptmp('xyz') -> /tmp/xyz
	return he.tmpdir .. he.pathsep .. name
end


--- elapsed time since 'he' was loaded (in seconds)
local _he_load_time = os.clock()
function he.elapsed() return (os.clock() - _he_load_time)  end





------------------------------------------------------------------------
-- display / debug functions
------------------------------------------------------------------------

-- display any object

function he.pp(...)
    for i,x in ipairs {...} do
        if type(x) == 'table' then 
            he.printf("pp: %s   metatable: %s",  
						tostring(x), tostring(getmetatable(x)))						
			local kl = he.sortedkeys(x)
            for i,k in ipairs(kl) do
                he.printf("    | %s:  %s", repr(k), repr(x[k]))
            end
        else he.printf("pp: %s", he.repr(x))
        end
    end
end

function he.ppl(lst)  print(he.l2s(lst)) end
function he.ppt(lst)  print(he.t2s(lst)) end
function he.ppk(dic)  print(he.l2s(he.sortedkeys(dic))) end


-- print with a format string
function he.printf(...) print(string.format(...)) end

-- error with a format string
function he.errf(...) error(string.format(...)) end

--- print a separator line, then print arguments
--
he.prsep_ch = '-'  -- character used for separator line
he.prsep_ln = 60  -- length of separator line
--
function he.prsep(...) 
    print(string.rep(he.prsep_ch, he.prsep_ln)) 
	if select('#', ...) > 0  then  print(...)  end
end

-- display elapsed time
function he.print_elapsed(msg) print(msg or 'Elapsed:', he.elapsed())  end



------------------------------------------------------------------------

function he.extend_all()
	-- extend string module with he string functions
    string.startswith  =  he.startswith
    string.endswith  =  he.endswith
    string.split  =  he.split
    string.lines = he.lines
    string.lstrip  =  he.lstrip
    string.rstrip  =  he.rstrip
    string.strip  =  he.strip
    string.stripnl  =  he.stripnl
	-- export he to global env
	_G.he = nil
	_G.he = he
	-- export some he defs to global env
	_G.pp, _G.ppl, _G.ppt = he.pp, he.ppl, he.ppt
	_G.list = he.list
end

-- 110107, hx no longer extends string and globals by default.
-- 110113, he extends string and globals
he.extend_all()

------------------------------------------------------------------------

------------------------------------------------------------------------
-- must return he (new approach with lua 5.2)
-- prevents amalgamation (concatenating modules in a big source file)
-- => an option would be to insert all modules >here<, before 'return he'.


return he 
