-- To run these tests just go to this directory and run
-- lua test_clockabout.lua
-- or from the parent directory run
-- lua lib/test_clockabout.lua

-- Allow packages to be picked up from both this directory
-- and its parent directory

package.path = package.path .. ";../?.lua;lib/?.lua"

lu = require('luaunit')
require('clockabout')

g = {}

-- calc_interval for linear shape -------------------------------------

function test_calc_interval_60_bpm()
  g = init_globals({
    bpm = 60,
    pulse_num = 1,
    pulse_total = 0,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(), expected_interval, 0.01 )
end

function test_calc_interval_60_bpm_in_middle_of_bar()
  g = init_globals({
    bpm = 60,
    pulse_num = 17,
    pulse_total = 16 + 96,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(), expected_interval, 0.01 )
end

function test_calc_interval_60_bpm_in_middle_of_bar_3_beats_per_bar()
  g = init_globals({
    bpm = 60,
    pulse_num = 17,
    pulse_total = 16 + 96,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(), expected_interval, 0.01 )
end

function test_calc_interval_120_bpm()
  g = init_globals({
    bpm = 120,
    pulse_num = 1,
    pulse_total = 0,
  })

  local beat_dur_sec = 60 / g.bpm
  local expected_interval = beat_dur_sec / 24

  lu.assertAlmostEquals( calc_interval(), expected_interval, 0.01 )
end

-- transform for swing shape -------------------------------------

function test_transform_for_swing_shape_50pc_swing()
  swing_shape.set_transform(0.50)

  lu.assertAlmostEquals( swing_shape.transform(0.00), 0,    0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25), 0.25, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50), 0.50, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.75), 0.75, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00), 1.0,  0.001 )
end

function test_transform_for_swing_shape_75pc_swing()
  swing_shape.set_transform(0.75)

  lu.assertAlmostEquals( swing_shape.transform(0.00), 0,     0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25), 0.375, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50), 0.75,  0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.75), 0.875, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00), 1.0,   0.001 )
end

function test_transform_for_swing_shape_10pc_swing()
  swing_shape.set_transform(0.10)

  lu.assertAlmostEquals( swing_shape.transform(0.00), 0,    0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25), 0.05, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50), 0.10, 0.001 )
  local y = (0.9/0.5) * 0.25 + 0.1
  lu.assertAlmostEquals( swing_shape.transform(0.75), y,    0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00), 1.0,  0.001 )
end

-- calc_interval for swing shape -------------------------------------

--[[function test_calc_interval_swing_60_bpm_in_middle_of_bar_4_beats_per_bar()
  g = init_globals({
    bpm = 60,
  })

  local pulses_per_beat = (60 / g.bpm) / 24 * g.beats_pb


  -- Assume we're 70% into the fifth bar.
  -- We rely on the transform() function, as we've tested that above.

  g.pulse_num = math.floor(0.70 * 96) + 1
  g.pulse_total = 5 * 96 + g.pulse_num - 1

  swing_shape.set_transform(4, 0.10)

  y_start = swing_shape.transform((g.pulse_num-1) / 96)
  y_end = swing_shape.transform((g.pulse_num-1 + g.PULSES_PP) / 96)

  lu.assertAlmostEquals( calc_interval(), y_end - y_start, 0.01 )
end--]]

os.exit( lu.LuaUnit.run() )
