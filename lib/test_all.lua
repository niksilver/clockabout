-- To run these tests just go to this directory and run
--
--   lua test_all.lua
--
-- or from the parent directory run
--
--   lua lib/test_all.lua


-- Allow packages to be picked up from both this directory
-- and its parent directory

package.path = package.path .. ";../?.lua;lib/?.lua"


lu = require('luaunit')

require('test_clockabout')
require('test_random_pattern')

os.exit(lu.LuaUnit.run())
