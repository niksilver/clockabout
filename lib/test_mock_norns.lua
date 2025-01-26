-- Testing our mock norns code.


require('mock_norns')


-- We'll put these tests in a table to be able to use setUp() / tearDown()

TestMockNorns = {

  setUp = function()
    _norns_init()
  end,


  test_norns_variable_is_populated = function()
    lu.assertNotNil(_norns)
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


  test_can_start_run_and_stop_a_metro = function()
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

  end

}
