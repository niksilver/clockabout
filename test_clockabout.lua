-- To run these tests just run
-- lua test_clockabout.lua

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

  local pulses_per_beat = (60 / g.bpm) / 24 * g.BEATS_PB

  lu.assertAlmostEquals( calc_interval(), pulses_per_beat / g.PARTS_PQN, 0.01 )
end

function test_calc_interval_60_bpm_in_middle_of_bar()
  g = init_globals({
    bpm = 60,
    pulse_num = 17,
    pulse_total = 16 + 96,
  })

  local pulses_per_beat = (60 / g.bpm) / 24 * g.BEATS_PB

  lu.assertAlmostEquals( calc_interval(), pulses_per_beat / g.PARTS_PQN, 0.01 )
end

function test_calc_interval_60_bpm_in_middle_of_bar_3_beats_per_bar()
  g = init_globals({
    BEATS_PB = 3,
    bpm = 60,
    pulse_num = 17,
    pulse_total = 16 + 96,
  })

  local pulses_per_beat = (60 / g.bpm) / 24 * g.BEATS_PB

  lu.assertAlmostEquals( calc_interval(), pulses_per_beat / g.PARTS_PQN, 0.01 )
end

function test_calc_interval_120_bpm()
  g = init_globals({
    bpm = 120,
    pulse_num = 1,
    pulse_total = 0,
  })

  local pulses_per_beat = (60 / g.bpm) / 24 * g.BEATS_PB

  lu.assertAlmostEquals( calc_interval(), pulses_per_beat / g.PARTS_PQN, 0.01 )
end

-- transform for swing shape -------------------------------------

function test_transform_for_swing_shape_1_beat_per_bar_50pc_swing()
  swing_shape.set_transform(1, 0.50)

  lu.assertAlmostEquals( swing_shape.transform(0.00), 0,    0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25), 0.25, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50), 0.50, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.75), 0.75, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00), 1.0,  0.001 )
end

function test_transform_for_swing_shape_1_beat_per_bar_75pc_swing()
  swing_shape.set_transform(1, 0.75)

  lu.assertAlmostEquals( swing_shape.transform(0.00), 0,     0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25), 0.375, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50), 0.75,  0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.75), 0.875, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00), 1.0,   0.001 )
end

function test_transform_for_swing_shape_3_beats_per_bar_75pc_swing()
  swing_shape.set_transform(3, 0.75)

  -- The swing across the whole bar with 3 beats per bar is just
  -- like the swing when it's 1 beat per bar except that it's
  -- scaled down and repeated, and each repeat is offset.
  -- So we'll repeat the tests above (3 times), but with some translation.

  local scale = 1/3

  local x_offset = 0
  local y_offset = 0

  lu.assertAlmostEquals( swing_shape.transform(0.00 * scale + x_offset), 0     * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25 * scale + x_offset), 0.375 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50 * scale + x_offset), 0.75  * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.75 * scale + x_offset), 0.875 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00 * scale + x_offset), 1.0   * scale + y_offset, 0.001 )

  local x_offset = 1/3
  local y_offset = 1/3

  lu.assertAlmostEquals( swing_shape.transform(0.00 * scale + x_offset), 0     * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25 * scale + x_offset), 0.375 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50 * scale + x_offset), 0.75  * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.75 * scale + x_offset), 0.875 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00 * scale + x_offset), 1.0   * scale + y_offset, 0.001 )

  local x_offset = 2/3
  local y_offset = 2/3

  lu.assertAlmostEquals( swing_shape.transform(0.00 * scale + x_offset), 0     * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25 * scale + x_offset), 0.375 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50 * scale + x_offset), 0.75  * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.75 * scale + x_offset), 0.875 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00 * scale + x_offset), 1.0   * scale + y_offset, 0.001 )

end

function test_transform_for_swing_shape_1_beat_per_bar_10pc_swing()
  swing_shape.set_transform(1, 0.10)

  lu.assertAlmostEquals( swing_shape.transform(0.00), 0,    0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25), 0.05, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50), 0.10, 0.001 )
  local y = (0.9/0.5) * 0.25 + 0.1
  lu.assertAlmostEquals( swing_shape.transform(0.75), y,    0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00), 1.0,  0.001 )
end

function test_transform_for_swing_shape_4_beats_per_bar_10pc_swing()
  swing_shape.set_transform(4, 0.10)

  -- The swing across the whole bar with 4 beats per bar is just
  -- like the swing when it's 1 beat per bar except that it's
  -- scaled down and repeated, and each repeat is offset.
  -- So we'll repeat the tests above (3 times), but with some translation.

  local scale = 1/4

  local x_offset = 0
  local y_offset = 0

  lu.assertAlmostEquals( swing_shape.transform(0.00 * scale + x_offset), 0    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25 * scale + x_offset), 0.05 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50 * scale + x_offset), 0.10 * scale + y_offset, 0.001 )
  local y = (0.9/0.5) * 0.25 + 0.1
  lu.assertAlmostEquals( swing_shape.transform(0.75 * scale + x_offset), y    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00 * scale + x_offset), 1.0  * scale + y_offset, 0.001 )

  local x_offset = 1/4
  local y_offset = 1/4

  lu.assertAlmostEquals( swing_shape.transform(0.00 * scale + x_offset), 0    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25 * scale + x_offset), 0.05 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50 * scale + x_offset), 0.10 * scale + y_offset, 0.001 )
  local y = (0.9/0.5) * 0.25 + 0.1
  lu.assertAlmostEquals( swing_shape.transform(0.75 * scale + x_offset), y    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00 * scale + x_offset), 1.0  * scale + y_offset, 0.001 )

  local x_offset = 2/4
  local y_offset = 2/4

  lu.assertAlmostEquals( swing_shape.transform(0.00 * scale + x_offset), 0    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25 * scale + x_offset), 0.05 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50 * scale + x_offset), 0.10 * scale + y_offset, 0.001 )
  local y = (0.9/0.5) * 0.25 + 0.1
  lu.assertAlmostEquals( swing_shape.transform(0.75 * scale + x_offset), y    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00 * scale + x_offset), 1.0  * scale + y_offset, 0.001 )

  local x_offset = 3/4
  local y_offset = 3/4

  lu.assertAlmostEquals( swing_shape.transform(0.00 * scale + x_offset), 0    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.25 * scale + x_offset), 0.05 * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(0.50 * scale + x_offset), 0.10 * scale + y_offset, 0.001 )
  local y = (0.9/0.5) * 0.25 + 0.1
  lu.assertAlmostEquals( swing_shape.transform(0.75 * scale + x_offset), y    * scale + y_offset, 0.001 )
  lu.assertAlmostEquals( swing_shape.transform(1.00 * scale + x_offset), 1.0  * scale + y_offset, 0.001 )

end

os.exit( lu.LuaUnit.run() )
