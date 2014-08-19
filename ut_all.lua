--[[ 

ut_all.lua - test all he modules

130323 - adapted to he082
120508 - adapted to he080
120403 - added ut_helu.
120322 - adapted to flattened he filetree, simplified he.
110804 - removed test_norm, tmppath (replaced w func tions in he)
110801 - set tests moved to ut_he
110616 - simplified. removed path/cpath definition
110202 - moved test dir out of he submodules dir.  added stx.	
110123 - fixed path/cpath for lib51/52
110113 - creation (combine hxlibs test_setup and test_all)

]]

-- require 'strict' -- doesnt work well with he globals :-(

print 'ut_all.lua, 130323'
------------------------------------------------------------------------
-- setup paths

local win = (string.byte(package.config) == 92)
package.path = win and '.\\?.lua' or './?.lua'
--~ package.cpath = '.\\?.dll'

_he_paths_set_ = 1

------------------------------------------------------------------------
-- test utilities

function test_pass(name)
    print(string.format('%-20s  OK', name))
end

function test_do(name, no_pcall_flag)
    local r, msg
    if test_pcall_flag and not no_pcall_flag then
        r, msg = pcall(require, name)
        if r then test_pass(name)
        else
            print(string.format('%-20s  FAILED', name))
            print(msg)
        end
    else
		(assert(loadfile(name .. '.lua')))()
        test_pass(name)
--~ 		print(he.elapsed())
    end
end

------------------------------------------------------------------------
-- Execute the tests
------------------------------------------------------------------------

test_pcall_flag = true		-- continue even if a test fails.
test_pcall_flag = false  	-- stop at first error

-- display some context
print('Current dir:') ; io.output():flush() ; os.execute('cd')
print('Lua path:', package.path)
print('Lua cpath:', package.cpath)

-- keep a copy of globals to detect if anything is added or modified 
--     by he* modules
local orig_globals = {}
for k,v in pairs(_G)  do orig_globals[k] = v  end


local start_time = os.clock()

test_do( 'ut_he' )
--~ test_do( 'ut_helu' )
test_do( 'ut_hefs' )
test_do( 'ut_hecsv' )
test_do( 'ut_hezip' )
test_do( 'ut_hezen' )
--~ test_do( 'ut_hestx' )
--~ test_do( 'ut_stxh' )
--~ test_do( 'ut_stxnorm' )
--~ test_do( 'ut_hsqlite' )


print('Elapsed:', os.clock() - start_time)
------------------------------------------------------------------------

-- print objects added to or modified in global env by the execution of tests
local ks = he.sortedkeys(_G)
for i,k in ipairs(ks) do
	if orig_globals[k] == nil then
		print('Added to _G:', k)
	elseif  orig_globals[k] ~= _G[k] then
		print('Modified in  _G:', k)
	end
end
--~ pp(_G)
