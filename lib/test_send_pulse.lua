-- Testing the critical function within the main code.


require('clockabout')
metro = require('mock_metro')


function test_send_pulse_sends_24_pulses()

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
  local clock_fn = function()
    pulses = pulses + 1
  end

  -- Override the basic send_pulse function

  g.send_pulse_fn = function(stage)
    send_pulse(stage, clock_fn)
  end

  -- This is what happens when we set the metro running via the parameter
  init_first_metro()
  start_metro()

  -- Run the pretend clock for 1 second, with a resolution of 0.01 seconds
  for t = 0, 1.0001, 0.01 do
    _norns.set_time(t)
  end

  lu.assertEquals(pulses, 24)
end
