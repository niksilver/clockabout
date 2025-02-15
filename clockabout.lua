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


local c       = require('clockabout/lib/core')
local log     = require('clockabout/lib/log')
local mod_api = require('clockabout/lib/mod')
log.s('Clockabout script mod_api = %s  - - - - - - - - - - - - -', tostring(mod_api))


init = function()
  if mod_api.mod_running then
    log.s('Clockabout.init() using mod\'s globals  - - - - - - - - - - - - -')
    c.g = mod_api.g
  else
    log.s('Clockabout.init() will run as a script  - - - - - - - - - - - - -')
    c.init({ENV = 'script'})
  end
end


-- Basic norns functions ------------------------------------------------


enc = c.enc


key = c.key


redraw = c.redraw
