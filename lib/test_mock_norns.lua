-- Testing our mock norns code.


require('clockabout')
require('mock_metro')


-- We'll put these tests in a table to be able to use setUp() / tearDown()

TestMockMetro = {

  setUp = function()
    _norns_init()
  end,


  test_norns_variable_is_populated = function()
    lu.assertNotNil(_norns)
  end,


  test_norns_can_set_time_on_unstarted_metro = function()
    _norns.metro_set_time(7, 1)  -- Some metro #7
  end,


  test_can_set_the_time = function()

    lu.assertEquals(_norns.time, 0)

    _norns.set_time(10)
    lu.assertEquals(_norns.time, 10)

    _norns.set_time(11)
    lu.assertEquals(_norns.time, 11)
  end,


  test_can_increment_the_time = function()

    lu.assertEquals(_norns.time, 0)

    _norns.set_time(10)
    lu.assertEquals(_norns.time, 10)

    _norns.inc_time(1)
    lu.assertEquals(_norns.time, 11)
  end,


  test_can_start_and_run_a_metro = function()
    _norns.set_time(100)

    -- Start metro #11 that runs exactly three times, once every 0.5 seconds.
    -- We'll record how many times it ticks at each stage.

    local ticks = { 0, 0, 0 }
    _norns.metro = function(id, stage)
      if id == 11 then
        ticks[stage] = ticks[stage] + 1
      end
    end

    local m = _norns.metros[11]

    lu.assertEquals(m.is_running, false)

    _norns.metro_start(11, 0.5, 3, 1)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, {0, 0, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, {0, 0, 0 })

    _norns.inc_time(0.25)  -- At start + 0.5 seconds, should trigger for first time
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, {1, 0, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, {1, 0, 0 })

    _norns.inc_time(0.25)  -- At start + 1.0 seconds, should trigger for second time
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, {1, 1, 0 })

    _norns.inc_time(0.25)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, {1, 1, 0 })

    _norns.inc_time(0.25)  -- At start + 1.5 seconds, should trigger for final time
    lu.assertEquals(m.is_running, false)
    lu.assertEquals(ticks, {1, 1, 1 })

    lu.assertEquals(_norns.time, 100 + 1.5)

    -- If time continues we shouldn't trigger any more events

    _norns.inc_time(0.25)
    _norns.inc_time(0.25)
    lu.assertEquals(m.is_running, false)
    lu.assertEquals(ticks, {1, 1, 1 })

  end,


  test_can_set_norns_time = function()
    _norns.set_time(50)

    -- Start metro #6 that runs exactly two times, once every second.

    local ticks = { 0, 0 }
    _norns.metro = function(id, stage)
      if id == 6 then
        ticks[stage] = ticks[stage] + 1
      end
    end

    local m = _norns.metros[6]

    lu.assertEquals(m.is_running, false)

    _norns.metro_start(6, 1.0, 2, 1)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 0, 0 })

    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 50 + 0.50)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 0, 0 })

    _norns.inc_time(0.50)  -- At start + 1.0 seconds, should trigger for first time
    lu.assertEquals(_norns.time, 50 + 1.0)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 1, 0 })

    -- Now set the time (delay) to two seconds. It should trigger at second start + 3.
    _norns.metro_set_time(6, 2.0)

    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 50 + 1.5)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 1, 0 })

    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 50 + 2.0)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 1, 0 })

    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 50 + 2.5)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 1, 0 })

    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 50 + 3.0)     -- At the third second, event should trigger...
    lu.assertEquals(m.is_running, false)  -- ...and metro should stop running.
    lu.assertEquals(ticks, { 1, 1 })

    -- Continue moving through time, events should no longer trigger

    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 50 + 5.5)
    lu.assertEquals(m.is_running, false)  -- ...and metro should stop running.
    lu.assertEquals(ticks, { 1, 1 })

  end,


  test_can_stop_a_metro = function()
    _norns.set_time(33)

    -- Start metro #7 that runs exactly two times, once every second.
    -- We'll stop it before the second tick.

    local ticks = { 0, 0 }
    _norns.metro = function(id, stage)
      if id == 7 then
        ticks[stage] = ticks[stage] + 1
      end
    end

    local m = _norns.metros[7]

    lu.assertEquals(m.is_running, false)

    _norns.metro_start(7, 1.0, 2, 1)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 0, 0 })

    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 33 + 0.50)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 0, 0 })

    _norns.inc_time(0.50)  -- At start + 1.0 seconds, should trigger for first time
    lu.assertEquals(_norns.time, 33 + 1.0)
    lu.assertEquals(m.is_running, true)
    lu.assertEquals(ticks, { 1, 0 })

    _norns.metro_stop(7)  -- Stop the metro!

    -- Continue moving through time, events should no longer trigger

    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    _norns.inc_time(0.50)
    lu.assertEquals(_norns.time, 33 + 3.5)
    lu.assertEquals(m.is_running, false)  -- ...and metro should stop running.
    lu.assertEquals(ticks, { 1, 0 })

  end,

}
