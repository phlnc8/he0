-- hxzip_test.lua


require 'he'
require 'hefs'
require 'hezip'

--~ pp(hxfs)
local app, join = he.app, he.join
local strip = he.strip
local hefs = he.fs
local sep, resep = hefs.sep, hefs.resep
local win = test_windows

local hezip = he.zip

-- test setup
local tmp = he.ptmp('hezip')
if hefs.isdir(tmp) then hefs.rmdir(tmp) end
assert(hefs.mkdir(tmp))
hefs.pushd(tmp)
assert(hefs.mkdir('d'))
hefs.pushd('d')
he.fput('bef', 'hello bef')
he.fput('ab', 'hello ab')
hefs.popd()

--
local r, r2

-- zip
r = hezip.zip('d')
r = hezip.zip('d', 'd2.zip')

-- ziplist
r = hezip.ziplist('d.zip')
r2 = hezip.ziplist('d2.zip')
--~ pp(r, #r)
assert(he.equal(r, r2))
assert(#r == 2)
assert(string.find(r[1], '8 d/ab$'))

-- unzip
assert(hefs.rmdir('d'))
r = hezip.unzip('d2.zip')
--~ pp(r)
r = hezip.unzip('d.zip', 'd3')
assert(hefs.fsize(he.pnorm('d/ab')) == 8)
assert(hefs.fsize(he.pnorm('d3/d/bef')) == 9)
--

hefs.popd()
hefs.rmdir(tmp)
