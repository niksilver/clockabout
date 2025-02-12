--[[
    Swing. Input is swing, where 0.5 is 50%, etc.

    For 75% swing it looks like this. It repeats per beat.

    1.00 +                  ,o
         |               ,-'
         |            ,-'
    0.75 +         o-'
         |        /
         |       /
    0.50 +      /
         |     /
         |   /
    0.25 +  /
         | /
         |/
    0.00 +----+----+----+----+
         0  0.25 0.50 0.75 1.00

--]]

local swing_pattern = {
  name = "Swing",

  -- Specific to this pattern

  swing = 0.60,      -- Default
  inflection = 0.50, -- Default, 0.0 to 1.0

  transform = nil,   -- Set by init_pattern()
}

-- @tparam number swing  Amount of swing, 0.01 to 0.99.
--
swing_pattern.init_pattern = function()

  local swing = swing_pattern.swing
  local inflection = swing_pattern.inflection

  swing_pattern.transform = function(x)

    if x < inflection then
      local gradient = swing / inflection
      local y = x * gradient
      return y
    else
      local gradient = (1-swing) / (1-inflection)
      local y = (x - inflection) * gradient + swing
      return y
    end

  end
end


swing_pattern.init_params = function()
  params:add_number("clockabout_swing_swing",
    "Swing",    -- Name
    1, 99,      -- Min, max
    swing_pattern.swing * 100,  -- Default
    function(param)             -- Formatter
      return string.format('%d%%', param:get())
    end,
    false  -- Wrap?
  )
  params:set_action("clockabout_swing_swing", function(x)
    swing_pattern.swing = x / 100
    swing_pattern.init_pattern()
  end)

  params:add_number("clockabout_swing_inflection",
    "Inflection",  -- Name
    1, 99,         -- Min, max
    swing_pattern.inflection * 100,  -- Default
    function(param)                  -- Formatter
      return string.format('%d%%', param:get())
    end,
    false  -- Wrap?
  )
  params:set_action("clockabout_swing_inflection", function(x)
    swing_pattern.inflection = x / 100
    swing_pattern.init_pattern()
  end)

  return { "clockabout_swing_swing", "clockabout_swing_inflection" }
end


return swing_pattern
