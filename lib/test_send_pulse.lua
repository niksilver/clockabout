-- Testing the critical function within the main code.


local c               = require('core')
local linear_pattern  = require('linear_pattern')
local swing_pattern   = require('swing_pattern')
local random_pattern  = require('random_pattern')
local log             = require('log')

metro = require('mock_metro')

c.log.suppress_n = true

-- Dummy function to cover for global redraw() which needs to be
-- referenced in the main code.
--
function redraw() end


-- We'll put these tests in a table to be able to use setUp() / tearDown()


TestSendPulse = {


  setUp = function()
    -- Save various functions which may be mocked and which will
    -- need to be restored

    TestSendPulse.redraw               = c.redraw
    TestSendPulse.pulse_interval       = c.pulse_interval
    TestSendPulse.set_metro_running_param = c.set_metro_running_param

    -- We don't want to be redrawing in our tests

    c.redraw = function() end

    -- Free up all the metros

    metro.free_all()
  end,


  tearDown = function()
    -- Restore the saved functions

    c.redraw               = TestSendPulse.redraw
    c.pulse_interval       = TestSendPulse.pulse_interval
    c.set_metro_running_param = TestSendPulse.set_metro_running_param
  end,


  test_send_pulse_sends_25_pulses_when_60_bpm = function()

    -- Should send 25 pulses per beat at 60 bpm
    -- because it's 24 per beat, but we're also including
    -- a pulse at second 0.

    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = linear_pattern,
      pattern_length = 1,
    })

    local pulses = 0

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

    -- Start the pulses and run the pretend clock for 1 second,
    -- with a resolution of 0.001 seconds.

    c.start_pulses()

    for t = 0, 1.005, 0.001 do
      _norns.set_time(t)
    end

    lu.assertEquals(pulses, 25)
  end,


  test_sends_pulses_according_to_swing = function()
    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = swing_pattern,
      pattern_length = 1,
    })

    swing_pattern.swing = 0.25
    swing_pattern.inflection = 0.50
    swing_pattern.init_pattern()

    local pulses = 0

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

    -- Override the basic connection object

    c.g.connection = {
      clock = function(self)
        pulses = pulses + 1
      end,

      start = function(self) end,

      stop = function(self) end,
    }

    -- When we start the pulses and move through time we should get
    -- 13 pulses in the first 0.25 seconds, and the rest
    -- in the remaining time. We'll allow some time overrun to cater
    -- for imperfections in the small steps and precision errors.
    --
    -- Remember: 25 pulses in total, because there's one each at 0.0 and 1.0 seconds.

    c.start_pulses()

    for t = 0.0001, 0.2505, 0.0001 do -- Start running time from after second 0.
      _norns.set_time(t)
    end
    lu.assertEquals(pulses, 13)

    for t = 0.2506, 1.0005, 0.0001 do -- Continue the clock
      _norns.set_time(t)
    end
    lu.assertEquals(pulses, 25)

  end,


  test_sends_pulses_according_to_swing_over_3_beats = function()
    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = swing_pattern,
      pattern_length = 3,
    })

    swing_pattern.swing = 0.25
    swing_pattern.inflection = 0.50
    swing_pattern.init_pattern()

    local pulses = 0

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

    -- When we start the pulses and move through time we should get
    -- 3*12+1 pulses in the first 3*0.25 seconds, and the rest
    -- in the remaining time. We'll allow some time overrun to cater
    -- for imperfections in the small steps and precision errors.
    --
    -- Remember: 3*24+1 pulses in total, because there's one each at 0.0 and 1.0 seconds.

    c.start_pulses()

    for t = 0.0001, 3*0.2502, 0.0001 do -- Start running time from after second 0.
      _norns.set_time(t)
    end
    lu.assertEquals(pulses, 3*12+1)

    for t = 3*0.2502, 3*1.0005, 0.0001 do -- Continue the clock
      _norns.set_time(t)
    end
    lu.assertEquals(pulses, 3*24+1)

  end,


  test_pattern_can_regenerate_after_end_of_pattern = function()
    -- Make our own pattern, like random, but with our own regenerate()
    -- which checks that it's been called

    local regenerate_called = false

    local our_pattern = {}
    for k, v in pairs(random_pattern) do
      our_pattern[k] = random_pattern[k]
    end

    our_pattern.regenerate = function()
      regenerate_called = true
    end

    -- Now run the metros as usual

    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = our_pattern,
      pattern_length = 1,
    })

    our_pattern.init_pattern()

    local pulses = 0

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }

    -- Just to be sure, check we get 25 pulses.

    c.start_pulses()

    for t = 0.0001, 1.0005, 0.0001 do -- Start running time from after second 0.
      _norns.set_time(t)
    end
    lu.assertEquals(pulses, 25)

    -- Now the real test.

    lu.assertEquals(regenerate_called, true)

  end,


  test_first_pulse_of_pattern_starts_regularly = function()
    -- The first pulse should always be on the beat. E.g. with 60 bpm
    -- those first pulses should be 1 second apart.

    -- Run the metros as usual, and capture when the first pulse happens.

    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = random_pattern,
      pattern_length = 1,
    })

    random_pattern.init_pattern()

    local pulses = 0
    local pulse_times = {}

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {

          clock = function(self)
            pulses = pulses + 1
            if (pulses-1) % 24 == 0 then
              local idx = (pulses // 24) + 1
              pulse_times[idx] = _norns.time
            end
          end,

          start = function(self) end,

          stop = function(self) end,
        }
      }
    }
    -- Run the metro for a bit over 5 'seconds', which will mean six first-pulses,
    -- at seconds 0, 1, 2, 3, 4, 5.

    c.start_pulses()

    for t = 0.0001, 5.1, 0.0001 do
      _norns.set_time(t)
    end

    -- Now see what we've got

    lu.assertEquals(#pulse_times, 6)

    for i = 1, #pulse_times-1 do
      local time1 = pulse_times[i]
      local time2 = pulse_times[i+1]
      lu.assertAlmostEquals(time2 - time1, 1.0, 0.01)
    end

  end,


  test_can_cycle_through_many_metros = function()
    -- Just to see if we're using the Metro module correctly.
    -- Can we use > 36 metros without a problem?

    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = linear_pattern,
      pattern_length = 1,
    })

    local pulses = 0

    -- Override the basic connection object

    c.g.connection = {
      clock = function(self) end,
      start = function(self) end,
      stop = function(self) end,
    }

    -- If we assume 4 metros per second (1 beat/sec at 60 bpm)
    -- then 12 seconds takes us through 48 metros.

    c.start_pulses()

    for t = 0, 12, 0.001 do
      _norns.set_time(t)
    end

  end,


  test_parts_are_at_correct_points = function()
    -- When we calculate the pulse intervals for each part, those parts
    -- should be each start at the correct point.

    -- Run the metros as usual, and capture when the first pulse happens.

    _norns.init()
    metro.init_module()

    c.init_globals({
      PULSES_PP = 4,  -- We set this to be sure, for calculations further down.
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = random_pattern,
      pattern_length = 1,
    })

    random_pattern.init_pattern()

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {
          clock = function(self) end,
          start = function(self) end,
          stop = function(self) end,
        }
      }
    }

    -- Wrap the pulse_interval() function to check that we're making
    -- our calculations from the correct points. The tearDown() function
    -- will restore our override.

    local from_pulse = {}
    local orig_pulse_interval = c.pulse_interval

    c.pulse_interval = function(pulse_num, beat_num)
      from_pulse[#from_pulse+1] = pulse_num
      return orig_pulse_interval(pulse_num, beat_num)
    end

    c.start_pulses()

    for t = 0.0001, 5.1, 0.0001 do
      _norns.set_time(t)
    end

    -- Now see what we've got

    -- Initial pulse should be manually sent from start_pulses
    lu.assertEquals(from_pulse[1],  1)  -- First interval should be calculated from 1 to 5
    lu.assertEquals(from_pulse[2],  5)  -- Next interval should be calculated from 5 to 9
    lu.assertEquals(from_pulse[3],  9)  -- Next interval should be calculated from 9 to 13
    lu.assertEquals(from_pulse[4], 13)  -- Next interval should be calculated from 13 to 17
    lu.assertEquals(from_pulse[5], 17)  -- Next interval should be calculated from 17 to 21
    lu.assertEquals(from_pulse[6], 21)  -- Next interval should be calculated from 21 to 25

    -- Then again for the second beat
    lu.assertEquals(from_pulse[7],   1)  -- First interval should be calculated from 1 to 5
    lu.assertEquals(from_pulse[8],   5)  -- Next interval should be calculated from 5 to 9
    lu.assertEquals(from_pulse[9],   9)  -- Next interval should be calculated from 9 to 13
    lu.assertEquals(from_pulse[10], 13)  -- Next interval should be calculated from 13 to 17
    lu.assertEquals(from_pulse[11], 17)  -- Next interval should be calculated from 17 to 21
    lu.assertEquals(from_pulse[12], 21)  -- Next interval should be calculated from 21 to 25

  end,


  test_send_pulse_can_handle_no_metros_available = function()

    -- Some basic initialisation.

    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = linear_pattern,
      pattern_length = 1,

      metro_running = 1,
    })

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {
          clock = function(self) end,
          start = function(self) end,
          stop = function(self) end,
        }
      }
    }

    -- Let's mock the action to stop the metros, so we can check it's called correctly

    local metro_running_value = 'Not called yet!'
    c.set_metro_running_param = function(x)
      metro_running_value = x
    end

    -- Exhaust our metros

    for i = 1, #metro.available do
      metro.init(nil, 1, -1)
    end

    -- Now we should start our pulses and fail gracefully

    c.start_pulses()

    -- Check we've taken action to stop the metro

    lu.assertEquals(metro_running_value, 0)

  end,


  test_send_pulse_can_handle_only_one_metro_available = function()

    -- Some basic initialisation.

    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = linear_pattern,
      pattern_length = 1,

      metro_running = 1,
    })

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {
          clock = function(self) end,
          start = function(self) end,
          stop = function(self) end,
        }
      }
    }

    -- Let's mock the action to stop the metros, so we can check it's called correctly

    local metro_running_value = 'Not called yet!'
    c.set_metro_running_param = function(x)
      metro_running_value = x
      if x == 0 then metro.free_all() end
    end

    -- Exhaust our metros but one

    local m = nil
    for i = 1, #metro.available do
      m = metro.init(nil, 1, -1)
    end
    metro.free(m.id)

    -- Now we should start our pulses, send some, and fail gracefully

    c.start_pulses()

    for t = 0, 1.005, 0.001 do
      _norns.set_time(t)
    end

    -- Check we've taken action to stop the metro

    lu.assertEquals(metro_running_value, 0)

  end,


  test_send_pulse_can_handle_pattern_length_being_reduced = function()
    -- The bug being tested here is that as pattern length is reduced,
    -- if the pulse is towards the end of the beat then the x value
    -- sent to the transform() function will given as > 1.
    -- The random pattern in particular will throw an error.
    -- We'll have a random pattern of 16 points over 16 beats so that
    -- we're more likely to get an error when we're almost at the end
    -- of the 16 beats and then reduce the pattern length back to 1.

    _norns.init()
    metro.init_module()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = random_pattern,
      pattern_length = 16,
    })

    local saved_points = random_pattern.points
    random_pattern.points = 16
    random_pattern.init_pattern()
    random_pattern.points = saved_points

    local pulses = 0

    -- Create a mock connection in a mock MIDI device

    c.g.devices = {
      {
        name = 'Mock device',

        active = 1,

        connection = {
          clock = function(self) end,
          start = function(self) end,
          stop = function(self) end,
        }
      }
    }

    -- We'll start the pattern, which is intended to run over 16 seconds (16 beats).
    -- Then after 15 seconds we'll reduce the pattern length to 1 beat.

    c.start_pulses()

    for t = 0.001, 15.000, 0.001 do
      _norns.set_time(t)
    end

    c.set_pattern_length(1)

    for t = 15.000, 16.000, 0.001 do
      _norns.set_time(t)
    end

    -- All is well if we reach this point without an error

  end,


  test_set_pattern_length = function()

    c.init_globals({
      pulse_num = 1,
      beat_num = 1,
      bpm = 60,

      pattern = linear_pattern,
      pattern_length = 4,
    })

    -- If we're at beat 3 out 4, and we reduce our pattern length
    -- then we should be within the new pattern length.

    c.g.pattern_length = 4
    c.g.beat_num       = 3
    c.g.pulse_num      = 11  -- Some arbitrary value which shouldn't change
    c.set_pattern_length(1)
    lu.assertEquals(c.g.pattern_length, 1)
    lu.assertEquals(c.g.beat_num      , 1)
    lu.assertEquals(c.g.pulse_num     , 11)

    -- If we're at beat 6 out 6, and we reduce our pattern length
    -- then we should be within the new pattern length.

    c.g.pattern_length = 6
    c.g.beat_num       = 6
    c.g.pulse_num      = 8  -- Some arbitrary value which shouldn't change
    c.set_pattern_length(4)
    lu.assertEquals(c.g.pattern_length, 4)
    lu.assertEquals(c.g.beat_num      , 4)
    lu.assertEquals(c.g.pulse_num     , 8)

    -- If we keep our pattern length the same then the beat number
    -- shouldn't change either.

    c.g.pattern_length = 3
    c.g.beat_num       = 3
    c.g.pulse_num      = 7  -- Some arbitrary value which shouldn't change
    c.set_pattern_length(3)
    lu.assertEquals(c.g.pattern_length, 3)
    lu.assertEquals(c.g.beat_num      , 3)
    lu.assertEquals(c.g.pulse_num     , 7)

    -- If we increase our pattern length the same then the beat number
    -- shouldn't change.

    c.g.pattern_length = 8
    c.g.beat_num       = 3
    c.g.pulse_num      = 10  -- Some arbitrary value which shouldn't change
    c.set_pattern_length(8)
    lu.assertEquals(c.g.pattern_length, 8)
    lu.assertEquals(c.g.beat_num      , 3)
    lu.assertEquals(c.g.pulse_num     , 10)

  end,

}
