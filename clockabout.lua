-- Clockabout
--
-- Why should shuffle be the
-- only irregular clock pattern?

function init()
  g = {
    midi_device = {}, -- container for connected midi devices
    midi_device_names = {},
    key3_hold = false,
    random_note = math.random(48,72),
  }

  for i = 1,#midi.vports do -- query all ports
    g.midi_device[i] = midi.connect(i) -- connect each device
    table.insert( -- register its name:
      g.midi_device_names, -- table to insert to
      "port "..i..": "..util.trim_string_to_width(g.midi_device[i].name,80) -- value to insert
    )
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
      local vport = target_vport()
      g.midi_device[vport]:note_on(g.random_note) -- defaults to velocity 100 on ch 1
      g.key3_hold = true
      redraw()
    elseif z == 0 then
      local vport = target_vport()
      g.midi_device[vport]:note_off(g.random_note)
      g.random_note = math.random(50,70)
      g.key3_hold = false
      redraw()
    end
  end
end

function redraw()
  screen.clear()

  local vport = target_vport()
  local name = vport and g.midi_device_names[vport] or "none"
  screen.move(0,10)
  screen.text(name)

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

