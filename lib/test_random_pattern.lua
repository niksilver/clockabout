-- These tests need to be run from test_all.lua, as that will also
-- set up the packages correctly.


local m = require('mod')


g = {}


---- Testing initial points in the random pattern ----------------------------


function test_random_pattern_generate_points()

  -- Must generate the correct number of points

  local x, y

  x, y = random_pattern.generate_points(2)
  lu.assertEquals(#x, 2)
  lu.assertEquals(#y, 2)

  x, y = random_pattern.generate_points(3)
  lu.assertEquals(#x, 3)
  lu.assertEquals(#y, 3)

  x, y = random_pattern.generate_points(5)
  lu.assertEquals(#x, 5)
  lu.assertEquals(#y, 5)

  -- Points must be in order and must be at least 0.05 apart.
  -- We'll try it many times, because points are random.

  for tries = 1, 1000 do
    local points = tries % 8 + 2  -- At least 2 points
    x, y = random_pattern.generate_points(points)

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


---- Testing calculations for line segments ----------------------------


function test_random_pattern_algebra()
  local x = { 0, 0.2, 0.8, 1.0 }
  local y = { 0, 0.2, 0.9, 1.0 }

  random_pattern.points = 4
  local algebra = random_pattern.calculate_algebra(x, y)

  -- Sanity check - there should be four sets of variables.

  lu.assertEquals(#algebra, 4)

  -- Point 1, from (0, 0) to (0.2, 0.2)

  local coeff, f

  coeff = algebra[1]
  lu.assertEquals( coeff.start_x, 0)
  lu.assertEquals( coeff.m,       1.0)
  lu.assertEquals( coeff.c,       0.0)

  f = function(x) return coeff.m * x + coeff.c end

  lu.assertAlmostEquals( f(0.0), 0.0, 0.001)
  lu.assertAlmostEquals( f(0.2), 0.2, 0.001)

  -- Point 2, from (0.2, 0.2) to (0.8, 0.9)

  coeff = algebra[2]
  lu.assertAlmostEquals( coeff.start_x, 0.2,                       0.001)
  lu.assertAlmostEquals( coeff.m,       (0.9 - 0.2) / (0.8 - 0.2), 0.001)

  f = function(x) return coeff.m * x + coeff.c end

  lu.assertAlmostEquals( f(0.2), 0.2, 0.001)
  lu.assertAlmostEquals( f(0.8), 0.9, 0.001)

  -- Point 3, from (0.8, 0.9) to (1.0, 1.0)

  coeff = algebra[3]
  lu.assertAlmostEquals( coeff.start_x, 0.8,                       0.001)
  lu.assertAlmostEquals( coeff.m,       (1.0 - 0.9) / (1.0 - 0.8), 0.001)

  f = function(x) return coeff.m * x + coeff.c end

  lu.assertEquals( f(0.8), 0.9 )
  lu.assertEquals( f(1.0), 1.0 )

  -- Point 4, from (1.0, 1.0) just has to have usable values

  coeff = algebra[4]
  lu.assertAlmostEquals( coeff.start_x, 1.0,                       0.001)

  f = function(x) return coeff.m * x + coeff.c end

  lu.assertEquals( f(1.0), 1.0 )
end


---- Testing transform() in the random pattern ----------------------------

function test_random_pattern_transform()

  -- Horrible overriding of a function just to force results we expect.
  -- We'll force particular 'random' points for testing.

  local save_fn = random_pattern.generate_points
  random_pattern.generate_points = function()
    return { 0, 0.2, 0.8, 1.0 },
           { 0, 0.2, 0.9, 1.0 }
  end
  random_pattern.init_pattern()
  random_pattern.generate_points = saved_fn

  -- Point 1, from (0, 0) to (0.2, 0.2)

  local x0 = 0.0
  local x1 = 0.2
  local y0 = random_pattern.transform(x0)
  local y1 = random_pattern.transform(x1)
  local x_mid = 0.1
  local y_mid = random_pattern.transform(x_mid)
  lu.assertAlmostEquals( y0, 0.0, 0.001)
  lu.assertAlmostEquals( y1, 0.2, 0.001)
  lu.assertAlmostEquals( y_mid, 0.1, 0.001)

  -- Point 2, from (0.2, 0.2) to (0.8, 0.9)

  x0 = 0.2
  x1 = 0.8
  y0 = random_pattern.transform(x0)
  y1 = random_pattern.transform(x1)
  x_mid = 0.5
  y_mid = random_pattern.transform(x_mid)
  lu.assertAlmostEquals( y0, 0.2, 0.001)
  lu.assertAlmostEquals( y1, 0.9, 0.001)
  lu.assertAlmostEquals( y_mid, (y0 + y1)/2, 0.001)

  -- Point 3, from (0.8, 0.9) to (1.0, 1.0)

  x0 = 0.8
  x1 = 1.0
  y0 = random_pattern.transform(x0)
  y1 = random_pattern.transform(x1)
  x_mid = 0.9
  y_mid = random_pattern.transform(x_mid)
  lu.assertAlmostEquals( y0, 0.9, 0.001)
  lu.assertAlmostEquals( y1, 1.0, 0.001)
  lu.assertAlmostEquals( y_mid, (y0 + y1)/2, 0.001)

  -- Point 4 just has to work for (1.0, 1.0)

  x0 = 1.0
  y0 = random_pattern.transform(x0)
  lu.assertAlmostEquals( y0, 1.0, 0.001)

end
