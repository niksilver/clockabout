-- Linear pattern. But below is how we define time patterns generally.


-- Time patterns ----------------------------------------------------------

-- Fields and functions are:

-- name
--
-- @tfield string name  Short string name of the pattern.


-- init_params()
--
-- Create and initialise menu parameters specific to this pattern..
--
-- @treturn table  A list of the parameter names added.


-- transform(x)
--
-- Given a time point in the bar, say when that should actually occur.
-- Must be strictly monotonically increasing. That is, if
-- b > a then transform(b) > transform(a).
-- Also we must have transform(0.0) == 0.0 and transform(1.0) == 1.0.
--
-- @tparam number x  The original point in the bar, 0.0 to 1.0.
-- @treturn number  Which point in the bar it should be occur, 0.0 to 1.0.


-- init_pattern()
--
-- Do anything needed whenever the pattern becomes the current one. This may
-- mean setting the transform() function.


-- regenerate()
--
-- Called just before the pattern repeats, giving the pattern a change to
-- change. May be nil. If it's not nil then the screen will redraw shortly
-- after it's called.


-- A normal linear clock. Number of beats per bar and param value don't matter.

local linear_pattern = {
  name = "Linear",

  transform = function(x)
    return x
  end,

  init_params = function()
    return {}
  end,

  init_pattern = function()
  end,
}


return linear_pattern
