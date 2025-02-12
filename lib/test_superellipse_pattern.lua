-- These tests need to be run from test_all.lua, as that will also
-- set up the packages correctly.


local c                    = require('core')
local superellipse_pattern = require('superellipse_pattern')


g = {}


-- pulse_interval for superellipse pattern -------------------------------------


function test_pulse_interval_superellipse_60_bpm_power_2()
  c.init_globals({
    bpm = 60,
    pattern = superellipse_pattern,
    pattern_length = 1,
  })
  local g = c.g  -- For convenience

  superellipse_pattern.power = 2.00
  superellipse_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1

  -- No special scaling needed

  local scale = 1

  -- Count our assertions, because they're in if statements and we may
  -- erroneously miss some

  local assertion_count = 0

  -- Expected values below are from calculations in Excel

  local time = 0

  for next_pulse = 1, 24, g.PULSES_PP do
    local interval = c.pulse_interval(next_pulse, g.beat_num)
    for pulse = next_pulse, (next_pulse + g.PULSES_PP - 1) do

      time = time + interval

      -- At the quarter-way point

      if beat == 1 and pulse == 6 then
        lu.assertAlmostEquals( time, 0.6614 * scale, 0.01 )
        assertion_count = assertion_count + 1
      end

      -- At the half way point

      if beat == 1 and pulse == 12 then
        lu.assertAlmostEquals( time, 0.8660 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

      -- At the three-quarter-way point

      if beat == 1 and pulse == 18 then
        lu.assertAlmostEquals( time, 0.9682 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

    end
  end

  -- lu.assertEquals(assertion_count, 3)

  lu.assertAlmostEquals( time, 1.0 * scale, 0.001 )

end


function test_pulse_interval_superellipse_60_bpm_power_0_5()
  c.init_globals({
    bpm = 60,
    pattern = superellipse_pattern,
    pattern_length = 1,
  })
  local g = c.g  -- For convenience

  superellipse_pattern.power = 0.50
  superellipse_pattern.init_pattern()

  g.beat_num = 1
  g.pulse_num = 1

  -- No special scaling needed

  local scale = 1

  -- Count our assertions, because they're in if statements and we may
  -- erroneously miss some

  local assertion_count = 0

  -- Expected values below are from calculations in Excel

  local time = 0

  for next_pulse = 1, 24, g.PULSES_PP do
    local interval = c.pulse_interval(next_pulse, g.beat_num)
    for pulse = next_pulse, (next_pulse + g.PULSES_PP - 1) do

      time = time + interval

      -- At the quarter-way point

      if beat == 1 and pulse == 6 then
        lu.assertAlmostEquals( time, 0.0179 * scale, 0.01 )
        assertion_count = assertion_count + 1
      end

      -- At the half way point

      if beat == 1 and pulse == 12 then
        lu.assertAlmostEquals( time, 0.0858 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

      -- At the three-quarter-way point

      if beat == 1 and pulse == 18 then
        lu.assertAlmostEquals( time, 0.25 * scale, 0.001 )
        assertion_count = assertion_count + 1
      end

    end
  end

  -- lu.assertEquals(assertion_count, 3)

  lu.assertAlmostEquals( time, 1.0 * scale, 0.001 )

end

