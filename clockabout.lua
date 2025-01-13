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

  g.PARTS_PQN = 4    -- This many parts per quarter note before we set another metro
  g.PULSES_PP = 24 / g.PARTS_PQN    -- This many pulses per part before we set another metro
  g.BEATS_PB = 4     -- This many beats per bar
  g.PULSES_PB = 24 * g.BEATS_PB    -- Pulses per bar
  g.TMP_START_TIME = nil

  -- Variables

  g.devices = {}  -- Container for connected midi devices and their data.
                  -- A table with keys: connection, name
                  -- Also allows a 0-indexed "none" device
  g.vport = 2       -- MIDI clock out vport (int >= 1)

  g.bpm = 60

  g.shape = linear_shape     -- The shape of our pulses
  g.pulse_num = 1    -- Number of next pulse in the bar, from 1, looping at end of bar
  g.pulse_total = 0  -- Total pulses we've sent

  g.metro = null    -- To be set up further down

  -- Insert any overrides

  if vars then
    for key, val in pairs(vars) do
      g.key = val
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

  -- Define a parameter for the out vport.

  params:add_option("clockabout_vport", "Port", short_names, g.vport)
  params:set_action("clockabout_vport", function(i)
    g.vport = i
  end)

  -- Our own parameter for the bpm

  params:add_number(
    "clockabout_bpm",
    "BPM",
    30, 300,  -- Min and  max
    g.bpm     -- Default
  )
  params:set_action("clockabout_bpm", function(x)
    -- The metro will update at the next part
    g.bpm = x
  end)

  -- Set the metronome going

  g.TMP_START_TIME = util.time()
  init_metro()

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
  if (g.pulse_num > g.PULSES_PB) then
    g.pulse_num = 1
  end

end


-- Calculate the interval between pulses for the current part.
-- @treturn number  Seconds duration oft interval.
--
function calc_interval()
  local curr_pulse = g.pulse_num - 1
  local end_pulse = curr_pulse + g.PULSES_PP

  -- Get current and end time in the bar, scaled to bar length 1.0

  local curr_scaled_time = curr_pulse / g.PULSES_PB
  local end_scaled_time = end_pulse / g.PULSES_PB

  -- Duration of the part, scaled to bar length 1.0, and then in actual time

  local scaled_part_duration =
    g.shape.transform(end_scaled_time) - g.shape.transform(curr_scaled_time)
  local actual_bar_duration = (60 / g.bpm) * g.BEATS_PB
  local actual_pulse_duration = scaled_part_duration * actual_bar_duration / g.PULSES_PP

  return actual_pulse_duration

end


-- Time shapes ----------------------------------------------------------

-- Functions are:
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
-- set_transform(beats)
--
-- Set the transform() function, given there are `beats` beats per bar.
--
-- @tparam int beats  Number of beats per bar.


-- A normal linear clock. Number of beats per bar doesn't matter.

linear_shape = {
  transform = function(x)
    return x
  end,
}


-- Swing. Input is swing, where 0.5 is 50%.
--[[
    For 75% swing over one beat per bar it looks like this.
    It repeats per beat.

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

swing_shape = {

  -- Currently only working for 1 beat per bar and 75% swing.
  --
  transform = function(x)
    if x < 0.5 then
      local gradient = 0.75 / 0.5
      return x * gradient
    else
      local gradient = 0.25 / 0.5
      return (x - 0.5) * gradient + 0.75
    end
  end
}

swing_shape.set_transform = function(beats)
  local scale = 1/beats

  swing_shape.transform = function(x)
    print("transform:            x = " .. x)

    local offset = math.floor(x / scale) * scale
    local scaled_up_x = (x - offset) * beats
    print("transform: offset      = " .. offset)
    print("transform: scaled_up_x = " .. scaled_up_x)

    if scaled_up_x < 0.5 then
      local gradient = 0.75 / 0.5
      local scaled_up_y = scaled_up_x * gradient
      local y = scaled_up_y / beats + offset
      print("transform: scaled_up_x < 0.5")
      print("transform: gradient    = " .. gradient)
      print("transform: scaled_up_y = " .. scaled_up_y)
      print("transform: y           = " .. y)
      return y
    else
      local gradient = 0.25 / 0.5
      local scaled_up_y = (scaled_up_x - 0.5) * gradient + 0.75
      local y = scaled_up_y / beats + offset
      print("transform: scaled_up_x < 0.5")
      print("transform: gradient    = " .. gradient)
      print("transform: scaled_up_y = " .. scaled_up_y)
      print("transform: y           = " .. y)
      return y
    end

  end
end


-- Basic norns functions ------------------------------------------------


function enc(n, d)
  if n == 3 then
    -- Change MIDI tempo
    params:delta("clockabout_bpm", d)
    redraw()
  end
end


function key(n, z)
end


function redraw()
  screen.clear()

  screen.move(0,10)
  screen.text(g.devices[g.vport].name)

  screen.move(0,20)
  screen.text("bpm (E3): " .. params:string("clockabout_bpm"))

  screen.update()
end

