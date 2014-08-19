------------------------------------------------------------------------
-- setup paths -- for quick testing. comment out for regular test harness
--~ local X = '/f/f/lua'
--~ local X = '../..'
--~ local flib = 'X/he2/tests/?.lua;X/he2/?.lua;X/lua51/lib/?.lua'
--~ flib = flib:gsub('X', X) 
--~ if _VERSION == 'Lua 5.2' then
--~ 	flib = flib:gsub('lua51', 'lua52')
--~ end
--~ package.path = flib
--~ package.cpath = flib:gsub('?.lua', '?.so') 
------------------------------------------------------------------------

do -- he core unit tests
------------------------------------------------------------------------

--~ require 'hetpaths'  -- set test paths

require 'he'
assert(he)
--~ assert(not string.split)
--~ he.extend_all()
assert(string.split)

--
local a, b, c, d, f, k, l, s, t, u, v, x, y

-- test string functions

assert(he.startswith('123 456', ''))
assert(he.startswith('123 456', '12'))
assert(not he.startswith('123 456', '.*'))
assert(he.endswith('123 456', ''))
assert(he.endswith('123 456', '56'))
assert(he.endswith('123 456', '123 456'))
assert(not he.endswith('123 456', '0123 456'))
assert(not he.endswith('123 456', '.*'))

s = 'ab=c\tde   f==' --do not change it!!
l = he.split(s,'='); --pprl(l)
assert(l[1] == 'ab')
assert(l[3] == '')
assert(l[4] == '')
l = he.split(s); --pprl(l)
assert (#l == 3 and l[3] == 'f==')
l = he.split(s, nil, 1); 
assert(#l == 2 and l[2]=='de   f==')
l = he.split(s, '=', 2); 
assert(#l == 3 and l[3]=='=')
s = '\tabc  \r\n  '
assert(he.strip(s) == 'abc') 
assert(he.rstrip(s) == '\tabc')
assert(he.lstrip(s) == 'abc  \r\n  ')
assert(he.lstrip('\r\r\n\na') == 'a')

------------------------------------------------------------------------
-- test list functions
--~ list = he.list --110113 list defined in globals by he.
a = {'hello', 22}
b = {'hello', 22} --do not change a and b!!
--contains
assert(list.has(a,22) and not list.has(a,33))
--equal
assert(a ~= b)
assert(he.equal(a, b))
-- extend
list.extend(a, b); assert(a[3] == 'hello')
--filter, map
c = list.map(a, function(x) return type(x) == 'string' and x end)
assert(c[2] == 'hello')
d = list.map(c, function(x) return x..' bob' end)
assert(c[2] == 'hello' and d[2] == 'hello bob')
c = {} --map on empty list
d = list.map(c, function(x) return x..' bob' end)
assert(#d == 0)
d = list.map(c, function(x) return type(x) == 'string' and x end)
assert(#d == 0)
-- table funcs
a = {'a', 'b', 123}
assert(list.join(a, '') == 'ab123' and list.join(a, '/') == 'a/b/123')
list.app(a, 1); assert(a[4]==1)
table.insert(a, 2, 99); assert(a[1]=='a' and a[2]==99 and a[5]==1)
table.remove(a, 2); assert(a[1]=='a' and a[2]=='b')
a = {9,3,5,1}; table.sort(a); assert(he.equal(a, {1,3,5,9}))
a = {}; table.sort(a); assert(he.equal(a, {}))
a = {}; list.app(a, 11); assert(a[1]==11)
list.app(a, 22); assert(a[2]==22)
-- any_elem, all_elems
a = {9,3,5,1}
assert(list.find_elem(a, function(v) return v==5 end))
assert(list.all_elems(a, function(v) return v<55 end))
assert(not list.find_elem(a, function(x) return type(x)=='string' end))
-- list iterator elems()
b = {} ; for e in list.elems(a) do list.app(b, e) end ;  assert(he.equal(a,b))
-- "list of objs" functions
t = list()
t:app{key=222, name='vic', age=33}
t:app{key='u111', name='paul', age=47}
t:app{key=333, name='mary', age=12}
b = t:filter(he.testf, 'name', he.iseq, 'mary')
assert(#b == 1 and b[1].age == 12)
b = t:filter(he.testf, 'name', string.match, '.*a');  assert(#b == 2 and b[1].age == 47) 
b = t:sorted(he.reccmp'name') ; assert(#b == 3 and b[3].age == 33)
b = t:map(function(e) return e.age * 2 end) ; assert(b[3] == 24)

------------------------------------------------------------------------
-- test table functions

t = {}
assert(he.incr(t, 'x') == 1)
assert(he.incr(t, 'x') == 2)
assert(he.incr(t, 'x', 3) == 5)
d = {}; 
d.x=1; assert(d['x'] == 1)
assert(he.incr(d, 'x')==2 and d.x == 2)
d = {x=1, y=2}
assert(he.count(d)==2)
assert(d.x==1 and d.y==2)
assert(he.equal(list.sorted(he.keys(d)), {'x', 'y'}))
assert(he.equal(he.sortedkeys(d), {'x', 'y'}))
assert(he.equal(list.sorted(he.tmapl(d)), {1, 2}))
assert(he.equal(he.list{'y'}, he.keys(d, function(v) return v==2 end)))
assert(he.equal(he.list{1}, he.tmapl(d, function(k,v) return k<'xzz' and v end)))
assert(he.count(d, function(v) return v==1 end), 1)
assert(he.count(d, function(v) return v>10 end), 0)

-- he.update()
d = {a=11, b=22};  he.update(d, {c=33, b=99})
assert(he.count(d) == 3 and d.a == 11 and d.b == 99 and d.c == 33)
assert(he.equal(d, he.update(d, {})))
assert(he.equal(d, he.update(d, d)))

-- he.tmap() -- dont modify 'd' above!
k,v = he.testv('a', 11, he.isin, {5, 10, 15}); assert(k==nil and v==nil)
k,v = he.testv('a', 10, he.isin, {5, 10, 15}); assert(k=='a' and v==10)
k,v = he.testk('a', 11, he.isin, {5, 'a', 15}); assert(k=='a' and v==11)
t = he.tmap(d, he.testv, he.isbw, 20, 40)
assert(he.equal(t, {c=33}))

t = list()
t:app{key=222, name='vic', age=33}
t:app{key='u111', name='paul', age=47}
t:app{key=333, name='mary', age=12}
b = he.tmap(t, he.testv, he.testf, 'age', he.isbw, nil, 40)
assert(he.count(b) == 2)
list.sort(t, he.reccmpany('name'))
b = he.tmapl(t, function(k,v) return v.name end)
assert(he.equal(b, {'mary', 'paul', 'vic'}))
list.sort(t, he.reccmp('age'))
b = he.tmapl(t, function(k,v) return v.name end)
assert(he.equal(b, {'mary', 'vic', 'paul'}))
--~ he.ppl(t)


------------------------------------------------------------------------
-- test misc functions
-- repr
assert(he.repr(123) == [[123]])
assert(he.repr(123) == [[123]])
assert(he.repr('hello') == [["hello"]])
assert(he.startswith(he.repr{}, '"table: '))
-- clone
t = {x=11, y=22}; u = he.clone(t)
for k,v in pairs(t) do assert(u[k] == v) end 
assert(u ~= v); 
t = {11,22,33}; u = he.clone(t)
for k,v in pairs(t) do assert(u[k] == v) end 
assert(u ~= v)
-- equal
a = {}; b = {};  assert(he.equal(a,b))
a = {}; b = {1};  assert(not he.equal(a,b))
a = {x=11, y=22}; b = {y=22, x=11};  assert(he.equal(a,b))
-- sorted
t = {9,3,27}
assert(list.sorted(t)[2] == 9 and t[2] == 3)
-- n2s
assert(he.n2s(123)=='123')
assert(he.n2s(1234)=='1,234')
assert(he.n2s(1234.668, '%9.2f')=='  1,234.67')

--pattern
assert(he.escape_re('a.b')=='a%.b')
--shescape -- esc [ ] ( ) ' " \  and sp
assert(he.escape_sh([[a=("b")]])==[[a=\(\"b\"\)]])
assert(he.escape_sh([[a ['b']\]])==[[a\ \[\'b\'\]\\]])

-- serialize, deserialize
x={}; assert(he.equal(x, he.deserialize(he.serialize(x))))
x=list(); assert(he.equal(x, he.deserialize(he.serialize(x))))
x=123; assert(he.equal(x, he.deserialize(he.serialize(x))))
x=true; assert(he.equal(x, he.deserialize(he.serialize(x))))
x=false; assert(he.equal(x, he.deserialize(he.serialize(x))))
x='a'; assert(he.equal(x, he.deserialize(he.serialize(x))))
x={}; assert(he.equal(x, he.deserialize(he.serialize(x))))
x={'a'}; assert(he.equal(x, he.deserialize(he.serialize(x))))
x = {[11]='a\nb', [22]={hop=2233, list{2226, 2227}}}
assert(he.equal(x, he.deserialize(he.serialize(x))))


------------------------------------------------------------------------
-- test file and os functions
-- isodate, isodate11
assert(string.match(he.isodate(),  -- eg. 20090707T133128
            "^%d%d%d%d%d%d%d%dT%d%d%d%d%d%d$"))
assert(string.match(he.isodate19(),  -- eg. 2009-07-07 13:31:28
            "^%d%d%d%d%-%d%d%-%d%d %d%d:%d%d:%d%d$"))
assert(string.match(he.isodate11(), 
            "^%d%d%d%d%d%d_%d%d%d%d$"))
x = os.time()
assert(x == he.iso2time(he.isodate(x)))
assert(he.isodate(x):startswith("20" .. he.isodate11(x):gsub('_', 'T')))

assert(he.isodate(he.iso2time("20090707T133128")) == "20090707T133128")
assert(he.isodate(he.iso2time("20090707_133128")) == "20090707T133128")
assert(he.isodate(he.iso2time("20090707_1331")) == "20090707T133100")
assert(he.isodate(he.iso2time("20090707-1331")) == "20090707T133100")
assert(he.isodate(he.iso2time("20090707")) == "20090707T000000")

local test_tmpdir = he.tmpdir

local fn = he.ptmp('he_test_file.txt')
he.fput(fn, 'hello'); x = he.fget(fn); assert(x == 'hello')

------------------------------------------------------------------------
-- shell, shlines, environ -- assume execute in dir where hx_test is.
if he.windows then
--~     print('Platform is Windows.')
    x = he.shell('dir /B ' .. test_tmpdir .. '\\he_test_file.t*')
    assert(he.split(x)[1]:endswith('he_test_file.txt'))
    x = he.shlines('dir /B ' .. test_tmpdir .. '\\he_test_file.t*')
    assert(x[1]:endswith('he_test_file.txt'))
--~     x = he.environ()
--~     assert(x["PROMPT"] == "$P$G")    
else -- assume linux
--~     print('Platform is Linux.')
    x = he.shell('ls -1 ' .. test_tmpdir .. '/he_test_file.t*')
    assert(he.split(x)[1]:endswith('he_test_file.txt'))
    x = he.shlines('ls -1 ' .. test_tmpdir .. '/he_test_file.t*')
    assert(x[1]:endswith('he_test_file.txt'))

-- removed environ(), 130324 
--~     x = he.environ()
-- assume env var SHELL is defined and is /bin/bash
--~ 	print(x["SHELL"] )
--~ 	print(os.getenv"SHELL")
--~     assert(x["SHELL"] == "/bin/bash")    
end -- if 

------------------------------------------------------------------------
-- test classes and objects
--    130323 'class' simplification' !!
c = he.class()
function c:init(val)  self.a = val ; return self end
function c:get() return self.a end
x = c():init('hello')
assert(x:get() == 'hello')
assert(getmetatable(x) == c)
assert(getmetatable(c) == he.class)
d = he.class(c)
--
local fifo = he.class()
function fifo:push(x) table.insert(self, 1, x) end
function fifo:pop() return table.remove(self) end
local f = fifo(); f:push(11); f:push(22); assert(f:pop() == 11)

------------------------------------------------------------------------
-- test list objects
a = list(); assert(#a == 0)
a = list{}; assert(#a == 0)
a = list{11,33,22}; assert(#a == 3)
b = list()
--~ pp('list', list)
--~ pp('a', a)
for i,v in ipairs(a:sorted()) do 
	b:app(v) 
end
assert(b:join('') == "112233")

-- test list-based set functions
a = list();  b = a:uniq();  assert(b:equal{})
a = list{11,22,11,11,33,11,22,22}
b = a:uniq();  assert(b:equal{11, 22, 33})
b:uapp(55) ; b:uapp(66) ; b:uapp(66) ; b:uapp(55) ; 
assert(b:equal{11, 22, 33, 55, 66})
b:uextend{11,11,66,66,11};  assert(b:equal{11, 22, 33, 55, 66})
b:uextend{};  assert(b:equal{11, 22, 33, 55, 66})
a:urem(22);  assert(a:equal{11,11,11,33,11,22,22})
b:urem(77);  assert(b:equal{11, 22, 33, 55, 66})

------------------------------------------------------------------------
-- test table functions and list  objects
a = {}; assert(he.count(a) == 0)
a.x = 11; a.y = 22; assert(he.count(a) == 2)
assert(he.count(a, function(v) return v>15 end) == 1)
assert(he.count(a, function(v) return list.has({11,22}, v) end) == 2)
assert(he.count(a, function(v) return list.has({22, 'y'}, v) end) == 1)
assert(he.count(a, function(v) return list.has({'a', 'y'}, v) end) == 0)

b = list(); for k,v in pairs(a) do b:app(k) end
assert(b:has('x') and b:has('y'))
b = list(); for i,k in ipairs(list(he.keys(a))) do b:app(k) end
assert(b:has('x') and b:has('y'))
b = list(); for i,k in ipairs(he.sortedkeys(a)) do b:app(k) end
assert(b:join('') == "xy")
b = list(); for i,k in ipairs(he.sortedkeys(a)) do b:app(a[k]) end
assert(b:join('') == "1122")
-- 
-- l2s, t2s
l = {1,2}
d = {a=11, b='bb'}
assert(he.l2s(l) == "{1, 2}")
assert(he.t2s(d) == '{["a"]=11, ["b"]="bb"}')

------------------------------------------------------------------------
do -- parse functions

local eq  = he.equal

-- parse_string()
local pat = "^(.-)|(.-)|(.-)$"
local s = "aa|b|c"
local fnt = {'f1', 'f2', 'f3'}
t = he.parse_string(s, pat); 
assert(eq(t, {'aa', 'b', 'c'}))
t = he.parse_string(s, pat, fnt)
assert(eq(t, {f1='aa', f2='b', f3='c'}))
t = he.parse_string(s, pat, {'f1', 'f2'})
assert(eq(t, {f1='aa', f2='b'}))
assert(not he.parse_string('NOMATCH', pat))

-- parse_lines()
local ll = list{"aa|b|zz", "NOMATCH", "d|e|f"}
local rl = he.parse_lines(ll, pat)
--~ print(he.t2s(rl))
assert(eq(rl, {{'aa', 'b', 'zz'}, {'d', 'e', 'f'}}))
assert(not he.parse_lines(ll, pat, {mustmatch=1}))
local rl = he.parse_lines(ll, pat, {names=fnt})
--~ print(he.t2s(rl))
assert(eq(rl, {{f1='aa', f2='b', f3='zz'}, {f1='d', f2='e', f3='f'}}))


end -- parse functions

------------------------------------------------------------------------
--  set class and unit tests removed, he07, 120313

------------------------------------------------------------------------
--~ pp(he)

end -- ut_he
