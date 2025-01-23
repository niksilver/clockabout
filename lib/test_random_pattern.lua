-- These tests need to be run from test_all.lua, as that will also
-- set up the packages correctly.


require('clockabout')


g = {}


---- Testing the random pattern ----------------------------

function test_random_pattern_generate_points()

  -- Must generate the correct number of points

  local x, y

  x, y = random_pattern_generate_points(2)
  lu.assertEquals(#x, 2)
  lu.assertEquals(#y, 2)

  x, y = random_pattern_generate_points(3)
  lu.assertEquals(#x, 3)
  lu.assertEquals(#y, 3)

  x, y = random_pattern_generate_points(5)
  lu.assertEquals(#x, 5)
  lu.assertEquals(#y, 5)

  -- Points must be in order and must be at least 0.05 apart.
  -- We'll try it many times, because points are random.

  for tries = 1, 1000 do
    local points = tries % 8 + 2  -- At least 2 points
    x, y = random_pattern_generate_points(points)

    -- Test both x and y
    for _, p in ipairs({x, y}) do

      -- Put the series of points into a string for debugging
      local series = '\n{ ' .. table.concat(p, '\n  ') .. ' }'

      -- First point must always be (0,0)
      lu.assertEquals(p[1], 0, 'Testing for initial 0 in ' .. series)

      local previous = 0
      for i = 2, #p do
        local v = p[i]
        lu.assertTrue(previous < v, 'Testing seq p['..i..'] = '..v..' in '..series)
        lu.assertTrue(v - previous >= 0.05, 'Testing gap p['..i..'] = '..v..' in '..series)
      end

      -- And the last point must be at (1.0, 1.0)
      lu.assertEquals(p[#p], 1, 'Testing for final 1.0 in ' .. series)

    end
  end

end
