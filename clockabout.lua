-- Clockabout
--
-- Why should shuffle be the
-- only irregular clock pattern?


g = {}    -- Global values


-- Set global values and return them as a table.
-- These are in their own function so we can set them up and reset them in unit tests.
--
-- @tparam table vars  Optional table of names/values to set, if not the defaults.
-- @treturn table  Names and values.
--
function init_globals(vars)
  local g = {}

  -- Constants

  g.PARTS_PQN = 4    -- This many parts per quarter note - number of regular metros in a quarter note
  g.PULSES_PP = 24 / g.PARTS_PQN    -- This many pulses per part before we set another metro
  g.TMP_START_TIME = nil

  -- Variables

  g.devices = {}  -- Container for connected midi devices and their data.
                  -- A table with keys: connection, name
                  -- Also allows a 0-indexed "none" device
  g.vport = 2       -- MIDI clock out vport (int >= 1)

  g.bpm = 60

  g.pattern = linear_pattern    -- The pattern of our pulses
  g.patterns = {                -- All the patterns
    linear_pattern,
    swing_pattern,
  }
  g.pattern_params = {}  --  Map from pattern number to its params. Set up later.

  g.pulse_num = 1    -- Number of next pulse in the bar, from 1, looping at end of bar
  g.pulse_total = 0  -- Total pulses we've sent

  g.metro = null    -- To be set up further down

  -- Insert any overrides

  if vars then
    for key, val in pairs(vars) do
      g[key] = val
    end
  end

  return g
end


function init()

  g = init_globals()

  -- Query MIDI vports, connect, collect info, switch off norns's own clock out.

  local short_names = {}
  for i = 1, #midi.vports do
    local conn = midi.connect(i)
    local name = "Port " ..i.. ": " .. util.trim_string_to_width(conn.name, 80)
    local short_name = i.. ": " .. util.trim_string_to_width(conn.name, 100)

    g.devices[i] = {
      connection = conn,
      name = name,
    }
    table.insert(short_names, short_name)

    params:set("clock_midi_out_"..i, 0)
  end

  -- Parameter menu separator

  params:add_separator("clockabout", "Clockabout")

  -- Parameter for the out vport.

  params:add_option("clockabout_vport", "Port", short_names, g.vport)
  params:set_action("clockabout_vport", function(i)
    g.vport = i
  end)

  -- Our own parameter for the bpm

  params:add_number(
    "clockabout_bpm",
    "BPM",
    10, 300,  -- Min and  max
    g.bpm     -- Default
  )
  params:set_action("clockabout_bpm", function(x)
    -- The metro will update at the next part
    g.bpm = x
  end)

  -- Parameter for the selected pattern

  local pats = {}
  for i, pattern in pairs(g.patterns) do
    table.insert(pats, pattern.name)
  end

  params:add_option("clockabout_pattern", "Pattern", pats, 1)
  params:set_action("clockabout_pattern", function(i)
    g.pattern = g.patterns[i]
    show_hide_pattern_params(i)
    g.pattern.init_pattern()
  end)

  -- Parameters for the each of the patterns

  for i, pattern in pairs(g.patterns) do
    table.insert(g.pattern_params, pattern.init_params())
  end

  show_hide_pattern_params(params:get("clockabout_pattern"))

  -- Initialise the current pattern

  g.pattern.init_pattern()

  -- Set the metronome going

  g.TMP_START_TIME = util.time()
  init_metro()

end


-- Show the parameters for a given pattern, and hide the rest.
-- @tparam int show_pat  Pattern number whose params we want to show.
--
function show_hide_pattern_params(show_pat)

  for pat = 1, #g.patterns do
    for param, name in pairs(g.pattern_params[pat]) do
      if pat == show_pat then
        params:show(name)
      else
        params:hide(name)
      end
    end
  end

  _menu.rebuild_params()
end


-- Set up the metronome according to the bpm and set it going.
-- Inconveniently, the first pulse does not occur immediately -
-- so we add it ourselves.
--
function init_metro()
  g.metro = metro.init(
    send_pulse,  -- Function to call
    calc_interval(),
    g.PULSES_PP    -- Number of pulses to send before we recalculate
  )
  g.metro:start()
  send_pulse(0)
end


-- Send a MIDI clock pulse.
-- If it's the last in the part, recalculate and reset the metro for the next part.
-- @tparam int stage  The stage of this pulse. Normally counts
--    from 1, but we insert our own 0.
--
function send_pulse(stage)
  local is_last_pulse = (stage == g.PULSES_PP)
  if is_last_pulse then

    -- print("Resetting")
    g.metro:stop()
    metro.free(g.metro.id)
    init_metro()
    return

  end

  g.devices[g.vport].connection:clock()
  g.pulse_total = g.pulse_total + 1
  --print(g.pulse_total .. "," .. (util.time() - g.TMP_START_TIME) .. "," .. g.pulse_num .. "," .. stage)
  g.pulse_num = g.pulse_num + 1
  if (g.pulse_num > 24) then
    g.pulse_num = 1
  end

end


-- Calculate the interval between pulses for the current part.
-- @treturn number  Seconds duration oft interval.
--
function calc_interval()
  local curr_pulse = g.pulse_num - 1
  local end_pulse = curr_pulse + g.PULSES_PP

  -- Get current and end time in the bar, scaled to beat length 1.0

  local curr_scaled_time = curr_pulse / 24
  local end_scaled_time = end_pulse / 24

  -- Duration of the part, scaled to bar length 1.0, and then in actual time

  local proportional_part_duration =
    g.pattern.transform(end_scaled_time) - g.pattern.transform(curr_scaled_time)
  local scale = proportional_part_duration / (end_scaled_time - curr_scaled_time)
  local std_beat_duration = 60 / g.bpm
  local std_pulse_duration = std_beat_duration / 24
  local actual_pulse_duration = std_pulse_duration * scale

  return actual_pulse_duration

end


-- Time patterns ----------------------------------------------------------

-- Fields and functions are:
--
-- name
--
-- @field name  Short string name of the pattern.
--
--
-- init_params()
--
-- Create and initialise menu parameters specific to this pattern..
--
-- @treturn table  A list of the parameter names added.
--
--
-- transform(x)
--
-- Given a time point in the bar, say when that should actually occur.
-- Must be strictly monotonically increasing. That is, if
-- b > a then transform(b) > transform(a).
-- Also we must have transform(0.0) == 0.0 and transform(1.0) == 1.0.
--
-- @tparam number x  The original point in the bar, 0.0 to 1.0.
-- @treturn number  Which point in the bar it should be occur, 0.0 to 1.0.
--
--
-- init_pattern()
--
-- Do anything needed whenever the pattern becomes the current one. This may
-- mean setting the transform() function.


-- A normal linear clock. Number of beats per bar and param value don't matter.

linear_pattern = {
  name = "Linear",

  transform = function(x, v)
    return x
  end,

  init_params = function()
    return {}
  end,

  init_pattern = function()
  end,
}


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

swing_pattern = {
  name = "Swing",

  -- Specific to this pattern

  swing = 0.60,  -- Default

  transform = nil,  -- Set by init_pattern()
}

-- @tparam number swing  Amount of swing, 0.01 to 0.99.
--
swing_pattern.init_pattern = function()

  local swing = swing_pattern.swing

  swing_pattern.transform = function(x)

    if x < 0.5 then
      local gradient = swing / 0.5
      local y = x * gradient
      return y
    else
      local gradient = (1-swing) / 0.5
      local y = (x - 0.5) * gradient + swing
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

  return { "clockabout_swing_swing" }
end


-- Basic norns functions ------------------------------------------------


function enc(n, d)
  if n == 1 then
    params:delta("clockabout_pattern", d)
    redraw()
  elseif n == 2 then
    -- Change MIDI tempo
    params:delta("clockabout_bpm", d)
    redraw()
  elseif n==3 and #current_params() >= 1 then
    -- Change pattern-specific value
    local param_name = current_params()[1]
    local param = params:lookup_param(param_name)
    param:delta(d)
    redraw()
  end
end


-- Params for the current pattern.
-- @treturn table  Table of param names.
--
function current_params()
  local pattern_idx = params:get("clockabout_pattern")
  return g.pattern_params[pattern_idx]
end


function key(n, z)
end


function redraw()
  screen.clear()
  screen.level(15)

  screen.move(0,10)
  screen.text(params:string("clockabout_pattern"))

  screen.move(0,20)
  screen.text("BPM: " .. params:string("clockabout_bpm"))

  if #current_params() >= 1 then
    -- Pattern-specific value
    screen.move(0,30)
    local param_name = current_params()[1]
    local param = params:lookup_param(param_name)
    screen.text(param.name .. ": " .. params:string(param_name))
  end

  screen.level(2)
  draw_pattern()

  screen.update()
end

-- Draw the pattern on the screen
--
function draw_pattern()
  screen.move(0, 63)
  screen.line_width(1)

  for x = 0.0, 1.0, 0.025 do
    screen_x = x * 127
    screen_y = 63 - (g.pattern.transform(x) * 48)
    screen.line(screen_x, screen_y)
  end

  screen.stroke()
end

