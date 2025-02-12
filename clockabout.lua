-- Clockabout
--
-- Why should swing be the
-- only non-linear clock pattern?
--
-- E1: Select pattern
-- E2: Change BPM
-- E3: Pattern-specific param
-- K1+E3: Second pattern param
-- K3: Start/stop clock
--
-- Version 0.9.0


local c = require('clockabout/lib/core')


init = function()
  c.init({ENV = 'script'})
end


-- Basic norns functions ------------------------------------------------


enc = c.enc


key = c.key


redraw = c.redraw
