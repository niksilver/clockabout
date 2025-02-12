
-- Double superellipse, from
-- See https://en.wikipedia.org/wiki/Superellipse


local double_superellipse_pattern = {
  name = "Double superellipse",

  -- Specific to this pattern

  power = 0.70,       -- Degree of curve. Default
  inflection = 0.50,  -- Where the bend occurs

  transform = nil,  -- Set by init_pattern()
}


double_superellipse_pattern.init_pattern = function()

  local n = double_superellipse_pattern.power
  local infl = double_superellipse_pattern.inflection
  local ii = 1 - infl

  double_superellipse_pattern.transform = function(x)
    if x <= infl then

      -- Translate x, calculate y, translate y
      local xtr = x / infl
      local y = (1 - xtr^n) ^ (1/n)
      local ytr = infl * (1-y)
      return ytr

    else

      -- Translate x, calculate y, translate y
      local xtr = (1-x) / ii
      local y = (1 - xtr^n) ^ (1/n)
      local ytr = 1 - (1-y)*ii
      return ytr

    end
  end

end


double_superellipse_pattern.init_params = function()
  params:add_taper("clockabout_double_superellipse_power",
    "Power",    -- Name
    0.5, 2.5,   -- Min, max
    double_superellipse_pattern.power,  -- Default
    0,          -- k
    ''          -- Units
  )
  params:set_action("clockabout_double_superellipse_power", function(x)
    double_superellipse_pattern.power = x
    double_superellipse_pattern.init_pattern()
  end)

  params:add_number("clockabout_double_superellipse_inflection",
    "Inflection",  -- Name
    1, 99,         -- Min, max
    double_superellipse_pattern.inflection * 100,  -- Default
    function(param)                                -- Formatter
      return string.format('%d%%', param:get())
    end,
    false  -- Wrap?
  )
  params:set_action("clockabout_double_superellipse_inflection", function(x)
    double_superellipse_pattern.inflection = x / 100
    double_superellipse_pattern.init_pattern()
  end)

  return { "clockabout_double_superellipse_power", "clockabout_double_superellipse_inflection" }
end


return double_superellipse_pattern
