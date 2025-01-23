-- Clockabout
--
-- Why should shuffle be the
-- only irregular clock pattern?
--
-- E1: Select pattern
-- E2: Change BPM
-- E3: Pattern-specific param
-- K1+E3: Second pattern param
-- K3: Start/stop metro


math.randomseed(os.time())

linear_pattern = require('lib/linear_pattern')
swing_pattern = require('lib/swing_pattern')
superellipse_pattern = require('lib/superellipse_pattern')


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

  g.PULSES_PP = 6    -- This many pulses per part before we set another metro

  -- Variables

  g.devices = {}  -- Container for connected midi devices and their data.
                  -- A table with keys: connection, name
                  -- Also allows a 0-indexed "none" device
  g.vport = 2       -- MIDI clock out vport (int >= 1)

  g.bpm = 60  -- Also a menu parameter

  g.pattern = linear_pattern    -- The pattern of our pulses
  g.patterns = {                -- All the patterns
    linear_pattern,
    swing_pattern,
    superellipse_pattern,
  }
  g.pattern_params = {}  --  Map from pattern number to its params. Set up later.
  g.pattern_length = 1   -- Number of beats in the pattern

  g.shift = false    -- If K1 is pressed

  g.pulse_num = 1    -- Number of next pulse in the bar, from 1, looping at end of bar
  g.pulse_total = 0  -- Total pulses we've sent

  g.beat_num = 1     -- Current beat num (might be pending its first pulse),
                     -- up to the number of beats in the pattern (pattern length).
                     -- Note: 1-indexed.

  g.metro = nil      -- Current metro
  g.metros = {}      -- We'll swap between metros 1 and 2
  g.metro_num = nil  -- Our current metro num - 1 or 2. Not the metro's id
  g.metro_running = 0  -- Note: 0 or 1. Also a menu parameter

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

  -- Our own parameter for whether the metro is running

  params:add_binary("clockabout_metro_running", "Metro running?", "toggle", g.metro_running)
  params:set_action("clockabout_metro_running", function(x)
    g.metro_running = x
    if g.metro_running == 1 then
      init_first_metro()
      start_metro()
    else
      cancel_both_metros()
      g.pulse_num = 1
      g.beat_num = 1
    end
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

  -- Parameter for how many beats the pattern lasts for

  params:add_number("clockabout_pattern_length",
    "Pattern length",    -- Name
    1, 16,  -- Min, max
    1,      -- Default
    function(param)             -- Formatter
      local v = param:get()
      local plural = v > 1 and 's' or ''
      return string.format(v .. ' beat' .. plural)
    end,
    false  -- Wrap?
  )
  params:set_action("clockabout_pattern_length", function(x)
    g.pattern_length = x
  end)

  -- Initialise the current pattern

  g.pattern.init_pattern()

  -- Set the metronome going

  params:set("clockabout_metro_running", 1)

end


function log(msg, ...)
  if not(g.log_init_time) then
    g.log_init_time = util.time()
  end

  local time = util.time() - g.log_init_time

  print(time .. ',' .. string.format(msg, table.unpack({...})))
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


-- Set up the the first metro only. Doesn't start it.
--
function init_first_metro()
  if g.metro == nil then

    -- Metro 1 starts at the current pulse num
    g.metros[1] = metro.init(
      send_pulse,  -- Function to call
      pulse_interval(g.pulse_num, g.beat_num),  -- Time between pulses
      g.PULSES_PP      -- Number of pulses to send before we recalculate
    )

    -- Identify current metro

    g.metro = g.metros[1]
    g.metro_num = 1

  else
    error("Attempt to init already-init'ed metro")
  end
end


-- Start the current metro running.
--
function start_metro()
  g.metro:start()
end


-- Cancel the metronomes.
--
function cancel_both_metros()
  if g.metros[1] then
    metro.free(g.metros[1].id)
  end
  if g.metros[2] then
    metro.free(g.metros[2].id)
  end
  g.metro = nil
  g.metro_num = nil
  g.metro_running = 0

  g.pulse_num = 1
  g.beat_num = 1
end


-- Send a MIDI clock pulse.
-- If it's the last in the part, recalculate and reset the metro for the next part.
-- @tparam int stage  The stage of this pulse. Normally counts
--    from 1, but we insert our own 0.
--
function send_pulse(stage)

  g.devices[g.vport].connection:clock()
  g.pulse_total = g.pulse_total + 1

  if stage == 1 then

    -- Prepare next metro
    local next_metro_num = 3 - g.metro_num
    if g.metros[next_metro_num] then
      metro.free(g.metros[next_metro_num].id)
    end

    -- Next metro will follow on from this one
    local follow_on_pulse_num = g.pulse_num + g.PULSES_PP
    local beat_num = g.beat_num

    if follow_on_pulse_num > 24 then
      follow_on_pulse_num = 1
      if beat_num > g.pattern_length then
        beat_num = 1
      end
    end
    g.metros[next_metro_num] = metro.init(
      send_pulse,
      pulse_interval(follow_on_pulse_num, beat_num),
      g.PULSES_PP
    )

  elseif stage == g.PULSES_PP then
    -- Switch metro
    g.metro_num = 3 - g.metro_num
    g.metro = g.metros[g.metro_num]
    g.metro:start()
  end

  g.pulse_num = g.pulse_num + 1

  if (g.pulse_num > 24) then
    g.pulse_num = 1

    g.beat_num = g.beat_num + 1
    if g.beat_num > g.pattern_length then
      g.beat_num = 1
    end
  end

end


-- Calculate the interval between pulses for the current part.
-- @tparam pulse_num  The pulse number of the start of the part (1-24).
-- @tparam beat_num  The beat number of the pulse.
-- @treturn number  Seconds duration of interval.
--
function pulse_interval(pulse_num, beat_num)

  -- Initially, we assume the pattern is just one beat (24 pulses) long

  local curr_pulse = pulse_num - 1
  local end_pulse = curr_pulse + g.PULSES_PP

  -- Get current and end time in the bar, scaled to beat length 1.0

  local curr_scaled_time = curr_pulse / 24
  local end_scaled_time = end_pulse / 24

  -- We'll scale it again, according to how many beats in the pattern
  -- (pattern length) and which beat we're in.

  curr_scaled_time = (curr_scaled_time + (beat_num - 1)) / g.pattern_length
  end_scaled_time = (end_scaled_time + (beat_num - 1)) / g.pattern_length

  -- Duration of the part, scaled to bar length 1.0, and then in actual time

  local proportional_part_duration =
    g.pattern.transform(end_scaled_time) - g.pattern.transform(curr_scaled_time)
  local scale = proportional_part_duration / (end_scaled_time - curr_scaled_time)
  local std_beat_interval = 60 / g.bpm
  local std_pulse_interval = std_beat_interval / 24
  local actual_pulse_interval = std_pulse_interval * scale

  return actual_pulse_interval

end




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

-- Basic norns functions ------------------------------------------------


function enc(n, d)
  if n == 1 then

    -- Change the pattern
    params:delta("clockabout_pattern", d)
    redraw()

  elseif n == 2 then

    -- Change MIDI tempo
    params:delta("clockabout_bpm", d)
    redraw()

  elseif n==3 and not(g.shift) and #current_params() >= 1 then

    -- Change first pattern-specific value
    local param_name = current_params()[1]
    local param = params:lookup_param(param_name)
    param:delta(d)
    redraw()

  elseif n == 3 and g.shift and #current_params() >= 2 then

    -- Change second pattern-specific value
    local param_name = current_params()[2]
    local param = params:lookup_param(param_name)
    param:delta(d)
    redraw()

  end
end


function key(n, z)
  if n == 1 then
    g.shift = (z == 1)
    redraw()
  end

  if n == 3 and z == 1 then
    params:set("clockabout_metro_running", 1 - g.metro_running)
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


function redraw()
  screen.clear()

  screen.level(2)
  draw_pattern()

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

  if #current_params() >= 2 and g.shift then
    -- Pattern-specific value
    screen.move(0,40)
    local param_name = current_params()[2]
    local param = params:lookup_param(param_name)
    screen.text(param.name .. ": " .. params:string(param_name))
  end

  if g.metro_running == 0 then
      screen.move(64, 48)
      screen.text_center("STOPPED")
  end

  screen.update()
end

-- Draw the pattern on the screen
--
function draw_pattern()
  screen.move(0, 63)
  screen.line_width(1)

  for x = 0.0, 1.025, 0.025 do

    if x > 1 then  -- Deal with arithmetic imprecision
      x = 1
    end

    local y = g.pattern.transform(x)
    local screen_x = x * 127
    local screen_y = 63 - (g.pattern.transform(x) * 48)
    screen.line(screen_x, screen_y)

  end

  screen.stroke()
end

