-- Superellipse, which is just a smooth curve.
-- See https://en.wikipedia.org/wiki/Superellipse


superellipse_pattern = {
  name = "Superellipse",

  -- Specific to this pattern

  power = 0.70,  -- Degree of curve. Default

  transform = nil,  -- Set by init_pattern()
}


superellipse_pattern.init_pattern = function()

  local power = superellipse_pattern.power

  superellipse_pattern.transform = function(x)
    return (1 - (1-x)^power) ^ (1/power)
  end

end


superellipse_pattern.init_params = function()
  params:add_taper("clockabout_superellipse_power",
    "Power",    -- Name
    0.5, 2.5,   -- Min, max
    superellipse_pattern.power,  -- Default
    0,          -- k
    ''          -- Units
  )
  params:set_action("clockabout_superellipse_power", function(x)
    superellipse_pattern.power = x
    superellipse_pattern.init_pattern()
  end)

  return { "clockabout_superellipse_power" }
end


return superellipse_pattern
