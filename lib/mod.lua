-- Clockabout - the mod


local mod = require('core/mods')            -- norns' mod functionality
local c   = require('clockabout/lib/core')  -- Clockabout's core functionality
local log = require('clockabout/lib/log')

local run_once = false

local m = {

  -- Called when we enter the mod's own screen
  init = function()
    log.s('Clockabout init: Enter')
    if not(run_once) then
      c.init({ENV = 'mod'})
      run_once = true
    end
  end,


  -- Called when we exit the mod's own screen
  deinit = function() end,


  key = function(n, z)
    -- For the mod, K2 will exit the screen
    if n == 2 and c.g.ENV == 'mod' then
      mod.menu.exit()
    end
  end,


  enc = function() end,


  redraw = function()
    screen.clear()
    screen.level(15)

    screen.move(64, 16)
    screen.text_center("Clockabout now available")
    screen.move(64, 24)
    screen.text_center("in the PARAMETERS menu")
    screen.move(64, 48)
    screen.text_center("Please press K2")

    screen.update()
  end
}

mod.menu.register(mod.this_name, m)

mod.hook.register("system_post_startup", "Clockabout post-startup", function()
  log.s('Clockabout post-startup: Enter')
  params:print()
end)

mod.hook.register("script_pre_init", "Clockabout pre-init", function()
  log.s('Clockabout pre-init: Enter')
end)
