-- Clockabout
--
-- Why should shuffle be the
-- only irregular clock pattern?


function init()
  g = {
    devices = {}, -- Container for connected midi devices and their data.
                  -- A table with keys: connection, name
                  -- Also allows a 0-indexed "none" device
    vport = 0,       -- MIDI clock out vport (int >= 1), or 0
    key3_hold = false,
    random_note = math.random(48,72),
  }

  -- Query MIDI vports, connect, collect info, switch off norns's own clock out.
  -- Also add a device 0, which is "none".

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

  g.devices[0] = {
    connection = null,
    name = "none",
    short_name = "none",
  }
  short_names[0] = "none"

  -- Define a parameter for the out vport. Make it 1 if possible, but
  -- beware there may be no devices available.

  params:add_option("clockabout_vport", "Port", short_names, g.vport)
  params:set_action("clockabout_vport", function(i)
    g.vport = i
    -- Temporarily use norns's own MIDI clock
    params:set("clock_midi_out_"..i, 1)
  end)
  if g.devices[1] then
    params:set("clockabout_vport", 1)
  end

end


-- The vport for MIDI clock out.
-- Defaults to null if no clock out, so watch out.
--
function target_vport()
  local vport = null
  for i = 1, 16 do
    local id = "clock_midi_out_" .. i
    if params:get(id) == 1 then
      vport = i
    end
  end

  return vport
end


function enc(n,d)
  if n == 3 then
    -- Change MIDI tempo
    params:delta("clock_tempo", d)
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
  screen.text("bpm (E3): " .. params:string("clock_tempo"))

  screen.move(0,30)
  if not g.key3_hold then
    screen.text("press K3 to send note " .. g.random_note)
  else
    screen.text("release K3 to end note " .. g.random_note)
  end
  screen.update()
end

