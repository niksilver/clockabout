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


-- Use our own 'include', for when this is tested outside of norns.
include = include and include or require

local m = include('lib/mod')


init = m.init


-- Basic norns functions ------------------------------------------------


enc = m.enc


key = m.key


redraw = m.redraw
