-- Clockabout
--
-- Why should shuffle be the
-- only irregular clock pattern?


local PARTS_PQN = 4    -- This many parts per quarter note before we set another metro
local PULSES_PP = 24 / PARTS_PQN    -- This many pulses per part before we set another metro
local BEATS_PB = 4     -- This many beats per bar
local PULSES_PB = 24 * BEATS_PB    -- Pulses per bar
local TMP_START_TIME = nil


function init()
  g = {
    devices = {}, -- Container for connected midi devices and their data.
                  -- A table with keys: connection, name
                  -- Also allows a 0-indexed "none" device
    vport = 2,       -- MIDI clock out vport (int >= 1)

    bpm = 60,
    bpm_changed = false,

    shape = linear_shape,    -- The shape of our pulses
    pulse_num = 1,    -- Number of next pulse in the bar, from 1, looping at end of bar
    pulse_total = 0,  -- Total pulses we've sent

    key3_hold = false,
    random_note = math.random(48,72),

    metro = null,    -- To be set up further down
  }

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
    -- The metro will update at the next pulse
    g.bpm = x
    g.bpm_changed = true
  end)

  -- Set the metronome going

  TMP_START_TIME = util.time()
  init_metro()

end


-- Set up the metronome according to the bpm and set it going.
-- Inconveniently, the first pulse does not occur immediately -
-- so we add it ourselves.
--
function init_metro()
  g.metro = metro.init(
    send_pulse,  -- Function to call
    (60 / g.bpm) / 24,       -- 24 ppqm called on this interval (seconds)
    PULSES_PP          -- Number of pulses to send before we recalculate
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
  local is_last_pulse = (stage == PULSES_PP)
  if is_last_pulse then

    -- print("Resetting")
    g.metro:stop()
    metro.free(g.metro.id)
    init_metro()
    return

  end

  g.devices[g.vport].connection:clock()
  g.pulse_total = g.pulse_total + 1
  --print(g.pulse_total .. "," .. (util.time() - TMP_START_TIME) .. "," .. g.pulse_num .. "," .. stage)
  g.pulse_num = g.pulse_num + 1
  if (g.pulse_num > PULSES_PB) then
    g.pulse_num = 1
  end

end


-- Time shapes ----------------------------------------------------------

-- Functions are:
--
-- out_time(in_time)
-- Given a time point in the beat, say how that is transformed.
-- Must be strictly monotonically increasing. That is, if
-- b > a then out_time(b) > out_time(a).
--
-- @tparam number  0.0 to 1.0
-- @treturn number  0.0 to 1.0


-- A normal linear clock - one beat

linear_shape = {
  out_time = function(in_time)
    return in_time
  end,
}


-- Basic norns functions ------------------------------------------------


function enc(n,d)
  if n == 3 then
    -- Change MIDI tempo
    params:delta("clockabout_bpm", d)
    redraw()
  end
end


function key(n,z)
  if n == 3 then
    if z == 1 then
      g.devices[g.vport].connection:note_on(g.random_note) -- defaults to velocity 100 on ch 1
      g.key3_hold = true
      redraw()
    elseif z == 0 then
      g.devices[g.vport].connection:note_off(g.random_note)
      g.random_note = math.random(50,70)
      g.key3_hold = false
      redraw()
    end
  end
end


function redraw()
  screen.clear()

  screen.move(0,10)
  screen.text(g.devices[g.vport].name)

  screen.move(0,20)
  screen.text("bpm (E3): " .. params:string("clockabout_bpm"))

  screen.move(0,30)
  if not g.key3_hold then
    screen.text("press K3 to send note " .. g.random_note)
  else
    screen.text("release K3 to end note " .. g.random_note)
  end
  screen.update()
end

