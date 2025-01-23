--[[
    Random. Random (increasing) points, joined by straight lines.

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
    Values m, c, and min are held in a table.
    Of the points, the first is expected to be at (0,0) and the
    last one is expected to be at (1.0, 1.0)

--]]


random_pattern = {
  name = "Random",

  -- Specific to this pattern

  points = 3,  -- Number of points

  transform = nil,  -- Set by init_pattern()

  algebra = {},  -- Described above
}


random_pattern.init_pattern = function()

  local points = random_pattern.points

  -- Get random points x,y in order
  local xs, ys = random_pattern_generate_points(points)

  random_pattern.transform = function(x)
  end

end


-- Generate a number of random x,y points between 0 and 1.0.
-- They must all be in order, starting from 0, ending with 1.0,
-- and all be separated by at least 0.05.
--
-- @tparam int points  The number of points to generate, >= 2.
-- @treturn table  Values of x in order.
-- @treturn table  Values of y in order.
--
function random_pattern_generate_points(points)

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
