-- To run these tests just run
-- lua test_clockabout.lua

lu = require('luaunit')
require('clockabout')

g = {}

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

os.exit( lu.LuaUnit.run() )
