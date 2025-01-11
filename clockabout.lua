-- Clockabout
--
-- Why should shuffle be the
-- only irregular clock pattern?

function init()
  g = {
    devices = {}, -- Container for connected midi devices and their data
                  -- A table with keys: connection, name
    vport = 1,  -- MIDI clock out
    key3_hold = false,
    random_note = math.random(48,72),
  }

  -- Query MIDI vports, connect and collect info

  for i = 1,#midi.vports do
    local conn = midi.connect(i)
    g.devices[i] = {
      connection = conn,
      name = "port "..i..": "..util.trim_string_to_width(conn.name,80),
    }
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
      g.devices[vport].connection:note_on(g.random_note) -- defaults to velocity 100 on ch 1
      g.key3_hold = true
      redraw()
    elseif z == 0 then
      local vport = target_vport()
      g.devices[vport].connection:note_off(g.random_note)
      g.random_note = math.random(50,70)
      g.key3_hold = false
      redraw()
    end
  end
end

function redraw()
  screen.clear()

  local vport = target_vport()
  local name = vport and g.devices[vport].name or "none"
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

