-- ut_csv - he.csv unit tests

require 'hecsv'
--
assert(he.csv)
--
local parse = he.csv.parse
--
assert(parse(''):equal{{""}})
assert(parse(','):equal{{"", ""}})
assert(parse('a'):equal{{"a"}})
assert(parse('a,'):equal{{"a", ""}})
assert(parse('a   ,  b'):equal{{"a   ", "  b"}})
assert(parse(' , , \n '):equal{{" ", " ", " "}, {" "}})
assert(parse(',a,,'):equal{{"", "a", "", ""}})
assert(parse(',a,,b'):equal{{"", "a", "", "b"}})
assert(parse('a,\r\n'):equal{{"a", ""}, {""}})
assert(parse('a,\r\n,'):equal{{"a", ""}, {"", ""}})
assert(parse('a,\r\n,b'):equal{{"a", ""}, {"", "b"}})
assert(parse('a\n\nb'):equal{{"a"}, {""}, {"b"}})
assert(parse(',\n\n,,'):equal{{"", ""}, {""}, {"", "", ""}})
assert(parse('\n\n'):equal{{""}, {""}, {""}})
assert(parse('"a"'):equal{{"a"}})
assert(parse('"a",'):equal{{"a", ""}})
assert(parse('"",'):equal{{"", ""}})
assert(parse('"",""'):equal{{"", ""}})
assert(parse('",","\n"'):equal{{",", "\n"}})
assert(parse('","\n"\n"'):equal{{","}, {"\n"}})
assert(parse('a"b,c'):equal{{"a\"b", "c"}})
assert(parse('a"b",c'):equal{{"a\"b\"", "c"}})
assert(parse('a"b"",c'):equal{{"a\"b\"\"", "c"}})
assert(not pcall(parse, '"'))
assert(not pcall(parse, '"a,b'))
assert(not pcall(parse, '"a\nb'))
assert(not pcall(parse, 'a\n"b'))

