-- hxfs unit tests

require 'hefs'
--~ pp(_G)
--~ pp(hxfs)

local app, join = list.app, list.join
local hefs = he.fs
local sep, resep = hefs.sep, hefs.resep

if he.windows then -- test windows path functions
    -- psplit
    assert(he.equal(hefs.psplit('ab'), {'ab'}))
    assert(he.equal(hefs.psplit('\\ab'), {'\\', 'ab'}))
    assert(he.equal(hefs.psplit('\\ab\\cd\\'), {'\\', 'ab', 'cd'}))
    assert(join(hefs.psplit('q:\\ab\\cd'), '')=='q:abcd')
    assert(join(hefs.psplit('\\ab\\cd'), '')=='\\abcd')
    assert(join(hefs.psplit('ab\\cd'), '')=='abcd')
    -- psplitdir, psplitext
    assert(he.equal({hefs.psplitdir('\\a\\b\\')}, {'\\a', 'b'}))
    assert(he.equal({hefs.psplitdir('a')}, {'', 'a'}))
    assert(he.equal({hefs.psplitdir('\\a')}, {'\\', 'a'}))
    assert(he.equal({hefs.psplitdir('\\')}, {'', '\\'}))
    assert(he.equal({hefs.psplitext('a')}, {'a', ''}))
    assert(he.equal({hefs.psplitext('a.b')}, {'a', 'b'}))
    assert(he.equal({hefs.psplitext('a.b.c')}, {'a.b', 'c'}))
    assert(he.equal({hefs.psplitext('a.b\\c')}, {'a.b\\c', ''}))
    assert(he.equal({hefs.psplitext('a.b\\c.d')}, {'a.b\\c', 'd'}))
    assert(he.equal({hefs.psplitext('e:\\a.b\\c.d')}, {'e:\\a.b\\c', 'd'}))
    assert(he.equal({hefs.psplitext('.a.b\\c')}, {'.a.b\\c', ''}))
    assert(he.equal({hefs.psplitext('.a')}, {'.a', ''}))
    assert(he.equal({hefs.psplitext('.a.b')}, {'.a', 'b'}))
    -- pabs
    assert(hefs.pabs('ef\\')==hefs.currentdir()..'\\ef')
    assert(hefs.pabs('\\ef')==hefs.currentdir():sub(1,2)..'\\ef')
    assert(hefs.pabs('r:\\gh', 'q:\\ab')=='r:\\gh')
    assert(hefs.pabs('\\gh', 'q:\\ab')=='q:\\gh')
    assert(hefs.pabs('gh', 'q:\\ab')=='q:\\ab\\gh')
    assert(hefs.pabs('gh\\', 'ab\\')=='ab\\gh')
    assert(hefs.pabs('gh', 'ab')=='ab\\gh')
    -- pnorm
    assert(hefs.pnorm('a\\b/c')=='a\\b\\c')
    assert(hefs.pnormw('/a/b/c/')=='\\a\\b\\c\\')
    -- pjoin
    assert(hefs.pjoin{}=='')
    assert(hefs.pjoin{'\\'}=='\\')
    assert(hefs.pjoin{'\\', 'a'}=='\\a')
    assert(hefs.pjoin{'a','b'}=='a\\b')
    assert(hefs.pjoin{'a\\','b\\'}=='a\\b')
    assert(hefs.pjoin(hefs.psplit('q:\\ab\\cd\\'))=='q:\\ab\\cd')
    assert(hefs.pjoin(hefs.psplit('\\ab\\cd'))=='\\ab\\cd')
    assert(hefs.pjoin(hefs.psplit('ab\\cd'))=='ab\\cd')
    --
else -- test unix path functions
    -- psplit
    assert(he.equal(hefs.psplit('ab'), {'ab'}))
    assert(he.equal(hefs.psplit('/ab'), {'/', 'ab'}))
    assert(he.equal(hefs.psplit('/ab/cd/'), {'/', 'ab', 'cd'}))
    assert(join(hefs.psplit('/ab/cd'), '')=='/abcd')
    assert(join(hefs.psplit('ab/cd'), '')=='abcd')
    -- psplitdir, psplitext
    assert(he.equal({hefs.psplitdir('/a/b/')}, {'/a', 'b'}))
    assert(he.equal({hefs.psplitdir('a')}, {'', 'a'}))
    assert(he.equal({hefs.psplitdir('/a')}, {'/', 'a'}))
    assert(he.equal({hefs.psplitdir('/')}, {'', '/'}))
    assert(he.equal({hefs.psplitext('a')}, {'a', ''}))
    assert(he.equal({hefs.psplitext('a.b')}, {'a', 'b'}))
    assert(he.equal({hefs.psplitext('a.b.c')}, {'a.b', 'c'}))
    assert(he.equal({hefs.psplitext('a.b/c')}, {'a.b/c', ''}))
    assert(he.equal({hefs.psplitext('a.b/c.d')}, {'a.b/c', 'd'}))
    assert(he.equal({hefs.psplitext('.a.b/c')}, {'.a.b/c', ''}))
    assert(he.equal({hefs.psplitext('.a')}, {'.a', ''}))
    assert(he.equal({hefs.psplitext('.a.b')}, {'.a', 'b'}))
    -- pabs
    assert(hefs.pabs('ef/')==hefs.currentdir()..'/ef')
    assert(hefs.pabs('/ef')=='/ef')
    assert(hefs.pabs('gh', '/ab')=='/ab/gh')
    assert(hefs.pabs('gh/', 'ab/')=='ab/gh')
    assert(hefs.pabs('gh', 'ab')=='ab/gh')
    -- pnorm
    assert(hefs.pnorm('a\\b/c')=='a/b/c')
    assert(hefs.pnormu('\\a\\b\\c/')=='/a/b/c/')
    -- pjoin
    assert(hefs.pjoin{}=='')
    assert(hefs.pjoin{'/'}=='/')
    assert(hefs.pjoin{'/', 'a'}=='/a')
    assert(hefs.pjoin{'a','b'}=='a/b')
    assert(hefs.pjoin{'a/','b/'}=='a/b')
    assert(hefs.pjoin(hefs.psplit('/ab/cd'))=='/ab/cd')
    assert(hefs.pjoin(hefs.psplit('ab/cd'))=='ab/cd')
    --
end -- windows or unix path
--
local test_tmpdir
-- make a tmp dir (dont write data in source tree...)
local tmp = he.ptmp('hxfs')
if hefs.isdir(tmp) then hefs.rmdir(tmp) end
assert(hefs.mkdir(tmp))
--

assert(hefs.isdir(tmp))
local b=false; 
for x in hefs.dir(he.tmpdir) do b = b or x=='hxfs' end
assert(b)
assert(list.has(hefs.dirs(he.tmpdir), tmp))

local ph = hefs.pjoin{tmp, 'hello.txt'}
local t = os.time()
he.fput(ph, 'hello')
--~ print(hefs.fmod(ph), t)
assert(math.abs(hefs.fmod(ph) - t) < 3)
assert(hefs.fsize(ph) == 5)
local thdir = tmp
local pl = hefs.files(thdir)

assert(pl[1]==ph and #pl==1)
local curdir = hefs.currentdir()
hefs.pushd(tmp) 
assert(hefs.currentdir() == tmp)
assert(hefs.fexists('hello.txt'))

assert(list.find_elem(hefs.findfiles(), 
		function(e) return string.match(e, 'hello%.txt') end))
--~ print(hefs.rmdir('test'))
hefs.popd()
assert(hefs.currentdir() == curdir)
