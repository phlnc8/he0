-- ut_zen - he.zen unit tests

require 'hezen'
local zen = he.zen

--~ pp(_G)
--~ he.pp(zen)
--
local function s2hex(s)
    local byte = string.byte
	local strf = he.strf
    local t = he.list()
    for i = 1, #s do t[i] = strf("%02X", byte(s, i)) end
    return t:join("")
end

local et, k, data, dighex, x, y
------------------------------------
-- checksums
-- crc32 removed from zlib, 100904 to reduce luazen size.
--~ 	-- crc32  (src eg. http://www.lammertbies.nl/comm/info/crc-calculation.html)
--~ 	assert(zen.crc32("") == 0x00000000)
--~ 	assert(zen.crc32("abc") == 0X352441C2)
--~ 	assert(zen.crc32('1234567890') == 0x261DAEE5)
--
-- adler32
assert(zen.adler32("\000\001\002\003") == 0x000e0007)
assert(zen.adler32("Mark Adler") == 0x13070394)
assert(zen.adler32('\017\034\051') == 0x00AD0067)
--~ pp(strf('%08X', zen.adler32("\x00\x01\x02\x03")))
------------------------------------
-- rc4, rc4raw
assert(zen.rc4("", 'key') == "")
assert(zen.rc4raw("", 'key') == "")
assert(zen.rc4(zen.rc4('hello', 'key'), 'key') == 'hello')
assert(zen.rc4raw(zen.rc4raw('hello', 'key'), 'key') == 'hello')
-- rc4 wikipedia test
et = zen.rc4raw('Plaintext', 'Key')
assert(s2hex(et) == 'BBF316E8D940AF0AD3')
et = zen.rc4raw('pedia', 'Wiki')
assert(s2hex(et) == '1021BF0420')
et = zen.rc4raw('Attack at dawn', 'Secret')
assert(s2hex(et) == '45A01F645FC35B383552544B9BF5')
------------------------------------
-- md5
assert(s2hex(zen.md5('')) == 'D41D8CD98F00B204E9800998ECF8427E')
assert(s2hex(zen.md5('abc')) == '900150983CD24FB0D6963F7D28E17F72')
------------------------------------
-- sha1
--~ pp(s2hex(zen.sha1('')))
assert(s2hex(zen.sha1('')) == 
		'DA39A3EE5E6B4B0D3255BFEF95601890AFD80709')
assert(s2hex(zen.sha1('The quick brown fox jumps over the lazy dog')) ==
		'2FD4E1C67A2D28FCED849EE1BB76E7391B93EB12')
------------------------------------
-- hmac - tests vectors from rfc2202
-- hmac_md5
k = string.rep('\011', 16);  data = "Hi There"
dighex = '9294727A3638BB1C13F48EF8158BFC9D'
assert(s2hex(zen.hmac_md5(data, k)) == dighex)
-- \xAA =  \170    -  \xDD = \221   -   no \x.. in lua 5.1.4
k = string.rep('\170', 16);  data = string.rep('\221', 50)
dighex = '56BE34521D144C88DBB8C733F0E8B3F6'
assert(s2hex(zen.hmac_md5(data, k)) == dighex)
-- hmac_sha1
k = string.rep('\011', 20);  data = "Hi There"
dighex = 'B617318655057264E28BC0B6FB378C8EF146BE00'
assert(s2hex(zen.hmac_sha1(data, k)) == dighex)
k = string.rep('\170', 20);  data = string.rep('\221', 50)
dighex = '125D7342B9AC11CD91A39AF48AA17B4F63F175D3'
assert(s2hex(zen.hmac_sha1(data, k)) == dighex)
------------------------------------
-- base64
x = 'Hello, Base64!'
assert(zen.b64decode(zen.b64encode(x)) == x)
x = string.rep('a', 301)
--~ 	print(zen.b64encode(x))
assert(zen.b64decode(zen.b64encode(x)) == x)
------------------------------------
-- zlib zip, unzip
x = 'Hello, Base64!aaaaa'
--~ 	pp(#x, zen.zip(x))
assert(zen.unzip(zen.zip(x)) == x)
x = 'aaaaaaaaaaaa'
--~ 	pp(zen.zip(x))

assert(zen.unzip(zen.zip(x)) == x)	
x = string.rep('a', 301)
y = zen.zip(x)
--~ 	print('#y', #y)
assert(zen.unzip(y) == x)
assert(zen.unzip(zen.zip(x)) == x)

