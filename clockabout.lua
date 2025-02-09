-- Clockabout
--
-- Why should swing be the
-- only non-linear clock pattern?
--
-- E1: Select pattern
-- E2: Change BPM
-- E3: Pattern-specific param
-- K1+E3: Second pattern param
-- K3: Start/stop clock


-- Use our own 'include', for when this is tested outside of norns.
include = include and include or require

log                         = include('lib/log')

linear_pattern              = include('lib/linear_pattern')
swing_pattern               = include('lib/swing_pattern')
superellipse_pattern        = include('lib/superellipse_pattern')
double_superellipse_pattern = include('lib/double_superellipse_pattern')
random_pattern              = include('lib/random_pattern')


g = {}    -- Global values


-- Define global values and return them as a table. Does not set any global vars.
-- These are in their own function so we can set them up and reset them in unit tests.
--
-- @tparam table vars  Optional table of names/values to set, if not the defaults.
-- @treturn table  Names and values.
--
function init_globals(vars)
  local g = {}

  -- Constant

  g.PULSES_PP = 4    -- This many pulses per part before we set another metro

  -- Variables

  g.initialised = false  -- Used to manage the order of triggering param actions

  g.devices = {}  -- Container for connected midi devices and their data.
                  -- A table with keys: connection, name, active (0 or 1)
  g.connection = nil  -- The MIDI connection object to the current device.
                      -- We override this in tests. Must implement these
                      -- functions:
                      -- clock(self)
                      -- start(self)
                      -- stop(self)

  g.bpm = 60  -- Also a menu parameter

  g.pattern = swing_pattern     -- The pattern of our pulses, initial value
  g.patterns = {                -- All the patterns
    swing_pattern,
    superellipse_pattern,
    double_superellipse_pattern,
    random_pattern,
    linear_pattern,
  }
  g.pattern_params = {}          --  Map from pattern number to its params. Set up later.
  g.pattern_length = 1           -- Number of beats in the pattern
  g.pattern_needs_redraw = false -- True if the pattern needs to be redrawn.

  g.shift = false    -- If K1 is pressed

  g.pulse_num = 1    -- Number of next pulse in the bar, from 1, looping at end of bar

  g.beat_num = 1     -- Current beat num (might be pending its first pulse),
                     -- up to the number of beats in the pattern (pattern length).
                     -- Note: 1-indexed.

  g.metro = nil      -- Current metro
  g.metros = {}      -- We'll swap between metros 1 and 2
  g.metro_num = nil  -- Our current metro num - 1 or 2. Not the metro's id
  g.metro_running = 1  -- Note: 0 or 1. Also a menu parameter

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

  local default_vport = 2
  local short_names = {}

  for i = 1, #midi.vports do
    local conn = midi.connect(i)
    local name = "Port " ..i.. ": " .. util.trim_string_to_width(conn.name, 80)
    local short_name = i.. ": " .. util.trim_string_to_width(conn.name, 100)

    g.devices[i] = {
      connection = conn,
      name = name,
      active = as_int(i == default_vport),  -- Must be 0 or 1 for params module.
    }
    table.insert(short_names, short_name)

    params:set("clock_midi_out_"..i, 0)
  end

  -- Parameter menu separator

  params:add_separator("clockabout", "Clockabout")

  -- Parameter for whether to send to single vport or many

  params:add_option("clockabout_vport_selection", "Port selection", {"Single", "Multi"}, 1)
  params:set_action("clockabout_vport_selection", function(i)
    -- If we're returning to single selection, set the individual
    -- vport params accordingly
    if i == 1 then
      params:lookup_param("clockabout_vport"):bang()
    end

    show_hide_vport_params()
  end)

  -- Parameter for the out vport.

  params:add_option("clockabout_vport", "Port", short_names, default_vport)
  params:set_action("clockabout_vport", function(i)
    for idx, device in pairs(g.devices) do
      local val = as_int(idx == i)
      device.active = val
      -- Set the individual param, too, but silently
      params:set(vport_active_id(idx), val, true)
    end
  end)

  -- Parameter for each out vport individually - in a group

  params:add_group("clockabout_vport_group", "Ports", #g.devices)

  for i, dev in ipairs(g.devices) do
    local id = vport_active_id(i)
    params:add_binary(id, dev.name, "toggle", dev.active)
    params:set_action(id, toggle_vport_fn(i))
  end

  -- Show the correct vport params

  show_hide_vport_params()

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

  params:add_binary("clockabout_metro_running", "Running?", "toggle", g.metro_running)
  params:set_action("clockabout_metro_running", function(x)

    -- If we're still initialising, don't let the initial param loading
    -- action this. We'll do it at the end.
    if not(g.initialised) then
      return
    end

    g.metro_running = x
    if g.metro_running == 1 then

      start_pulses()
      start_active_connections()

    else

      cancel_both_metros()
      stop_all_connections()
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

  -- Final touches:
  --   - Load the last paramset, if any. That will also bang all
  --     the parameters.
  --   - Set the metronome going, if it should be

  params:default()
  g.initialised = true
  params:lookup_param("clockabout_metro_running"):bang()

end


-- Express a boolean as an int (0 or 1).
--
function as_int(b)
  return b and 1 or 0
end


-- Show the parameters to select vports.
--
function show_hide_vport_params()
  local selection_style = params:get("clockabout_vport_selection")
  if selection_style == 1 then

    -- Single selection
    params:show("clockabout_vport")
    params:hide("clockabout_vport_group")

  else

    -- Multi selection
    params:hide("clockabout_vport")
    params:show("clockabout_vport_group")

  end

  _menu.rebuild_params()
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


-- The param id for whether a given vport is active.
-- @tparam int i  The vport number (from 1).
-- @treturn string  The param id.
--
function vport_active_id(i)
  return "clockabout_vport_" .. i .. "_active"
end

-- Respond to a single vport being toggled on or off for MIDI out.
-- If we're only selecting one vport at a time then we'll also need
-- to make sure any others are toggled accordingly.
-- @tparam int i  The vport number (from 1).
-- @tparam int val  The new value, 0 or 1.
--
function toggle_vport(i, val)
  local id = vport_active_id(i)
  params:set(id, val)
  g.devices[i].active = val
end


-- Return the a toogle_port function for a given vport.
-- @tparam int i  The vport (from 1).
-- @treturn func  A function that will take one value, and set the
--   vport's value to that.
--
function toggle_vport_fn(i)
  return function(val)
    toggle_vport(i, val)

    -- If we're toggling on, the single vport param should be
    -- updated to track that (but silently)

    if val == 1 then
      params:set("clockabout_vport", i, true)
    end

  end
end


-- Send MIDI stop to all connections, whether marked active or not.
--
function stop_all_connections()
  for idx, device in pairs(g.devices) do
    device.connection:stop()
  end
end


-- Send MIDI start to all active connections.
--
function start_active_connections()
  for idx, device in pairs(g.devices) do
    if device.active == 1 then
      device.connection:start()
    end
  end
end


-- Start sending the pulses. Uses global g.connection to know where
-- to send to.
--
function start_pulses()
  init_first_metro()
  start_active_connections()
  start_metro()
end


-- Send MIDI clock message to active connections.
--
function clock_to_active_connections()
  for idx, device in pairs(g.devices) do
    if device.active == 1 then
      device.connection:clock()
    end
  end
end


-- Set up the the first metro only. Doesn't start it.
--
function init_first_metro()
  if g.metro ~= nil then
    return
  end

  -- Metro 1 starts at the current pulse num
  g.metros[1] = metro.init(
    send_pulse,  -- Function to call
    pulse_interval(g.pulse_num, g.beat_num),  -- Time between pulses
    g.PULSES_PP  -- Number of pulses to send before we recalculate
  )

  -- Identify current metro

  g.metro = g.metros[1]
  g.metro_num = 1

end


-- Start the first metro running.
--
function start_metro()
  g.metro:start()
  clock_to_active_connections()
  g.pulse_num = g.pulse_num + 1
end


-- Cancel the metronomes.
--
function cancel_both_metros()
  if g.metros[1] then metro.free(g.metros[1].id) end
  if g.metros[2] then metro.free(g.metros[2].id) end

  g.metro = nil
  g.metro_num = nil
  g.metro_running = 0

  g.pulse_num = 1
  g.beat_num = 1
end


-- Send a MIDI clock pulse.
-- If it's the last in the part, recalculate and reset the metro for the next part.
-- @tparam int stage  The stage of this pulse, from 1.
--
--[[
    For simplicity, suppose there are 8 pulses per quarter note, and 4 pulses
    per part. And suppose we want have a swing pattern. Then we want this:

    Time                                   /
      ^                                   o
      |                                  /
      |                                 /
      |                                /
      |                             _ o
      |                         _ o
      |                     _ o       :
      |                 _ o
      |               o               :
      |              /
      |             /                 :
      |            /  :
      |           o                   :
      |          /    :
      |         /                     :
      |        /      :
      |       o                       :
      |      /        :
      |     /                         :
      |    /          :
      |   o                           :
      |  /            :
      | /                             :
      |/              :
      o---+---+---+---+---+---+---+---+---+------->  Beat number
      1   2   3   4   5   6   7   8   1   2...

      |   |           |   |           |
      |   |           |   |           |_ Second metro's last beat, triggers next
      |   |           |   |
      |   |           |   |_ Second metro's first beat
      |   |           |
      |   |           |_ First metro's last beat, triggers second metro
      |   |
      |   |_ First metro's first beat
      |
      |_ Forced (manual) first beat, outside of this function.
         Triggers first metro.

--]]
function send_pulse(stage)

  clock_to_active_connections()

  -- We do these things at different stages so that there isn't a lot of
  -- work all in the final stage of a metro, which may cause a delay.

  if stage == 1 then

    -- Free up the next metro

    local next_metro_num = 3 - g.metro_num
    if g.metros[next_metro_num] then
      metro.free(g.metros[next_metro_num].id)
    end

  elseif stage == g.PULSES_PP - 1 then

    -- Almost (not quite) at the end of the part - prepare next metro

    local next_metro_num = 3 - g.metro_num
    local next_pulse_num, next_beat_num, _ = advance_pulse(g.pulse_num + 1)
    local interval = pulse_interval(next_pulse_num, next_beat_num)

    g.metros[next_metro_num] = metro.init(
      send_pulse,
      interval,
      g.PULSES_PP
    )

  elseif stage == g.PULSES_PP then

    -- At the end of the part - start the next metro

    -- Now switch to the new metro
    local next_metro_num = 3 - g.metro_num
    g.metro_num = next_metro_num
    g.metro = g.metros[g.metro_num]
    g.metro:start()

    -- If it's the end of pattern, we may need to regenerate the next one
    local _, _, end_of_pattern = advance_pulse(g.pulse_num + g.PULSES_PP)
    if end_of_pattern and g.pattern.regenerate then
      g.pattern.regenerate()
      g.pattern_needs_redraw = true
    end

  end

  g.pulse_num, g.beat_num, _ = advance_pulse(g.pulse_num + 1)

  if g.pulse_num == 1 and g.pattern_needs_redraw then
    redraw()
    g.pattern_needs_redraw = false
  end

end


-- Return values if we would advance the pulse number.
-- @tparam int pulse_num  The new pulse number. It may be more than 24.
-- @treturn int  The new pulse number, wrapped if it was more than 24.
-- @treturn int  The new beat number, which may have wrapped back to 1.
--     This reads from `g.beat_num`.
-- @treturn bool  If it was the end of the pattern and we wrapped the beat num.
--     This reads from `g.pattern_length`.
--
function advance_pulse(pulse_num)
  local beat_num = g.beat_num
  local wrapped = false

  if (pulse_num > 24) then
    -- At the end of the beat

    pulse_num = 1

    beat_num = g.beat_num + 1
    if beat_num > g.pattern_length then
      -- At the end of the pattern
      beat_num = 1
      wrapped = true
    end
  end

  return pulse_num, beat_num, wrapped
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

  for x = 0.0, 1.01, 0.01 do

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

