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


require('test_mock_norns')
require('test_mock_metro')
require('test_send_pulse')

require('test_linear_pattern')
require('test_swing_pattern')
require('test_superellipse_pattern')
require('test_random_pattern')

os.exit(lu.LuaUnit.run())
