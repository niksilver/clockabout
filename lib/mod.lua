-- Clockabout - the mod


local mod = require('core/mods')            -- norns' mod functionality
local c   = require('clockabout/lib/core')  -- Clockabout's core functionality
local log = require('clockabout/lib/log')


local api = {
  -- If this file is executed as a mod (rather than just required) then
  -- there will be a key/value pair here of
  -- mod_running = true
}


local m = {

  -- Called when we enter the mod's own screen
  init = function()
    log.s('Clockabout init: Enter  - - - - - - - - - - - - - - - - -')
  end,


  -- Called when we exit the mod's own screen
  deinit = function()
    log.s('Clockabout deinit: Enter  - - - - - - - - - - - - - - - - -')
  end,


  key = function(n, z)
    log.s('Clockabout key: Enter  - - - - - - - - - - - - - - - - -')
    -- For the mod, K2 will exit the screen
    if n == 2 and z == 1 then
      mod.menu.exit()
    end
  end,


  enc = function() end,


  redraw = function()
    screen.clear()
    screen.level(15)

    screen.move(64, 8)
    screen.text_center("Clockabout will start with")
    screen.move(64, 16)
    screen.text_center("any script, then use the")
    screen.move(64, 24)
    screen.text_center("the PARAMETERS menu.")
    screen.move(64, 48)
    screen.text_center("Please press K2")

    screen.update()
  end
}


-- Only try to register things if this file is beign executed as
-- a mod (rather than required by the main script)

if mod.this_name then

  mod.menu.register(mod.this_name, m)

  mod.hook.register("system_post_startup", "Clockabout post-startup", function()
    log.s('Clockabout post-startup: Enter  - - - - - - - - - - - - - - - - -')
    api.mod_running = true
  end)

  mod.hook.register("script_pre_init", "Clockabout pre-init", function()
    log.s('Clockabout pre-init: Enter  - - - - - - - - - - - - - - - - -')
  end)


  -- When a scipt finishes its initialisation, but before it starts
  --
  mod.hook.register("script_post_init", "Clockabout post-init", function()
    log.s('Clockabout post-init: Enter  - - - - - - - - - - - - - - - - -')
    c.init({ENV = 'mod'})
  end)

  mod.hook.register("script_post_cleanup", "Clockabout post-cleanup", function()
    log.s('Clockabout post-cleanup: Enter  - - - - - - - - - - - - - - - - -')
  end)

end


return api
