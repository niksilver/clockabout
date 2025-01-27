-- Testing the critical function within the main code.


require('clockabout')
metro = require('mock_metro')


function test_send_pulse_sends_25_pulses_when_60_bpm()
  -- Should send 25 pulses per beat at 60 bpm
  -- because it's 24 per beat, but we're also including
  -- a pulse at second 0.

  _norns.init()
  metro.init_module()

  g = init_globals({
    pulse_num = 1,
    beat_num = 1,
    bpm = 60,

    pattern = linear_pattern,
    pattern_length = 1,
  })

  local pulses = 0

  -- Override the basic connection object

  g.connection = {
    clock = function(self)
      pulses = pulses + 1
    end,

    start = function(self) end,

    stop = function(self) end,
  }

  -- This is what happens when we set the metro running via the parameter

  start_pulses()

  -- Run the pretend clock for 1 second, with a resolution of 0.01 seconds
  for t = 0, 1.0001, 0.01 do
    _norns.set_time(t)
  end

  lu.assertEquals(pulses, 25)
end
