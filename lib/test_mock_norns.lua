-- Testing our mock norns code.


require('mock_norns')


-- We'll put these tests in a table to be able to use setUp() / tearDown()

TestMockNorns = {

  test_norns_variable_is_populated = function()
    lu.assertNotNil(_norns)
  end,


  test_can_set_the_time = function()

    _norns.set_time(10)
    lu.assertEquals(_norns.time, 10)

    _norns.set_time(11)
    lu.assertEquals(_norns.time, 11)
  end,


  test_can_increment_the_time = function()

    _norns.set_time(10)
    lu.assertEquals(_norns.time, 10)

    _norns.inc_time(1)
    lu.assertEquals(_norns.time, 11)
  end,

}
