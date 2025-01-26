-- Testing our mock norns code.

require('mock_norns')

function test_norns_variable_is_populated()
  lu.assertNotNil(_norns)
end
