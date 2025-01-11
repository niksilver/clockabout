-- Clockabout

function init()
  midi_device = {} -- container for connected midi devices
  midi_device_names = {}
  target = 1
  key3_hold = false
  random_note = math.random(48,72)

  for i = 1,#midi.vports do -- query all ports
    midi_device[i] = midi.connect(i) -- connect each device
    table.insert( -- register its name:
      midi_device_names, -- table to insert to
      "port "..i..": "..util.trim_string_to_width(midi_device[i].name,80) -- value to insert
    )
  end

  params:add_option("midi target", "midi target",midi_device_names,1)
  params:set_action("midi target", function(x) target = x end)
end

function enc(n,d)
  if n == 2 then
    if #midi_device > 0 then
      params:delta("midi target",d)
      redraw()
    end
  end
end

function key(n,z)
  if n == 3 then
    if z == 1 then
      midi_device[target]:note_on(random_note) -- defaults to velocity 100 on ch 1
      key3_hold = true
      redraw()
    elseif z == 0 then
      midi_device[target]:note_off(random_note)
      random_note = math.random(50,70)
      key3_hold = false
      redraw()
    end
  end
end

function redraw()
  screen.clear()
  screen.move(0,10)
  screen.text(params:string("midi target"))
  screen.move(0,30)
  if not key3_hold then
    screen.text("press K3 to send note "..random_note)
  else
    screen.text("release K3 to end note "..random_note)
  end
  screen.update()
end

