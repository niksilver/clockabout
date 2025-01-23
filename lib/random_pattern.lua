--[[
    Random. Random (increasing) points, joined by straight lines.
    Of the points, the first is expected to be at (0,0) and the
    last one is expected to be at (1.0, 1.0)

    1.00 +                         ,-o
         |                    __,-'
         |                __-'
    0.75 +              o'
         |             /
         |            /
    0.50 +           /
         |       ___o
         |   o--'
    0.25 +  /
         | /
         |/
    0.00 +------+------+------+------+
         0     0.25   0.50   0.75   1.00

    Each line segment is represented by a line y = mx + c.
    Its starting point is a min value for x.
    Values m, c, and min_x are held in a table, which is indexed
    in order of min_x.

--]]


random_pattern = {
  name = "Random",

  -- Specific to this pattern

  points = 3,  -- Number of points

  transform = nil,  -- Set by init_pattern()

  algebra = {},  -- Indexed 1,2,3,... in order of x.
                 -- Table keys x, m, c, min_x.
                 -- The last index (min_x = 1) are almost arbitrary.
}


random_pattern.init_pattern = function()

  local points = random_pattern.points

  -- Get random points x,y in order
  local x, y = random_pattern.generate_points(points)
  random_pattern.algebra = random_pattern.calculate_algebra(x, y)

end


-- Generate a number of random x,y points between 0 and 1.0.
-- They must all be in order, starting from 0, ending with 1.0,
-- and all be separated by at least 0.05.
--
-- @tparam int points  The number of points to generate, >= 2.
-- @treturn table  Values of x in order.
-- @treturn table  Values of y in order.
--
random_pattern.generate_points = function(points)

  local x, y

  for count = 1, 2 do  -- Do this for x and y

    -- Keep trying until all the numbers are far enough apart

    local p, all_good
    repeat

      all_good = true

      -- Create ordered list from 0.0 to 1.0 with random points between
      p = { 0, 1 }
      for i = 2, points-1 do
        p[#p+1] = math.random()
      end
      table.sort(p)

      -- Make sure they're far enough apart
      local prev = 0
      for i = 2, points do
        if p[i] - prev < 0.05 then
          all_good = false
        end
      end

    until all_good

    if count == 1 then
      x = p
    else
      y = p
    end

  end  -- count for both x and y

  return x, y
end


-- Create the algebraic values of m, c, start_x for each of the points.
-- Does not actually set the algebra field of the random pattern.
--
-- @tparam table x  The list of x values, in order, from 0.0 to 1.1.
-- @tparam table y  The list of y values, in order, from 0.0 to 1.1.
--
-- @treturn table  Table of values for each point. The table is indexed
--     1,2,3,... in order of x. Table keys are x, m, c, min_x.
--     Entries for the last index (min_x = 1) are almost arbitrary.
--
random_pattern.calculate_algebra = function(x, y)
  local alg = {}

  for i = 1, #x-1 do
    local x0 = x[i]
    local y0 = y[i]
    local x1 = x[i+1]
    local y1 = y[i+1]

    -- y = mx + c, therefore c = y - mx

    local m = (y1 - y0) / (x1 - x0)
    local c = y0 - m * x0

    alg[i] = {
      start_x = x0,
      m = m,
      c = c,
    }
  end

  -- Put in the semi-arbitrary values for (1.0, 1.0)

  alg[#x] = {
    start_x = 1.0,
    m = 1,
    c = 0,
  }

  return alg
end


-- The standard transform function.
--
random_pattern.transform = function(x)
  local prev_alg = random_pattern.algebra[1]

  for i = 2, #random_pattern.algebra do

    local alg = random_pattern.algebra[i]
    if alg.start_x >= x then
      -- We've gone beyond the relevant segment
      return prev_alg.m * x + prev_alg.c
    end

    -- Get ready to move onto the next segment
    prev_alg = alg
  end

  error('No segment found for x = ' .. x)
end


random_pattern.init_params = function()
  params:add_number("clockabout_random_points",
    "Points",    -- Name
    2, 8,   -- Min, max
    3,      -- Default
    function(param)    -- Formatter
      return tostring(param:get(x))
    end,
    false   -- Wrap?
  )
  params:set_action("clockabout_random_points", function(x)
    random_pattern.points = x
    random_pattern.init_pattern()
  end)

  return { "clockabout_random_points" }
end


return random_pattern
