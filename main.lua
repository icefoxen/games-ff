require("util")
require("objs")
require("gamestate")
require("ships")

require("oo")
require("set")

vec = require("hump.vector-light")
camera = require("hump.camera")

require("arenamode")


-- * Okay.  First we need a scrollable camera.
-- * Then we need to be able to click on a gameobj and give it an order.
-- * Then we need to have a ship move to a given point.
-- * Then we need to be able to highlight and group multiple gameobjs...
-- * Then we need to have a ship draw a sprite.
-- * Then we need ships able to fire shots
-- * Then we need to have different collision groups for ships, bullets, etc.
-- * Then we need ships able to get hurt and die
-- * Then make it handle it right when selected objects die
-- * Then we need to fix object selection and make unselectable objects.
-- * Then we need to make it have Z ordering
-- Then we need to have different kinds of ships.
-- Then we need to make rotation and thrust actually have vaguely appropriate values for thrust and momentum
-- and generally figure out scale.
-- Then we need to make some different kinds of weapons
-- Then we need some shiny particle effects for thrust, damage, and death
-- Then we need some sort of animations
-- Then we need to get rid of walls and just not be able to give orders or scroll out there.
-- Then we need to draw levels, as well as some GUI giving data on
-- selected ships
-- Then we need to make tostring() work properly for all objects.
-- Then we need to have carriers build fighters and order them around.
-- Then we need to have fighters do some amount of swarming and formations
-- Then we need to be able to bandbox ships, bandbox-attack, queue up orders, etc...
-- Then we need to draw order lines for ships
-- Then we need some AI capable of fighting back.
-- Then we need level with events, dialog, etc.  Starts you with a fixed selection of ships.
-- Then we need a title screen, level selection, level progression.
-- Oh gods, animations.
-- Being able to abstract factions away a little bit might be nice... color mask, collision mask...
-- 
-- Okay, there are a few main approaches:
-- Ships, AI, weapons, commands, etc...
-- Levels, game framework, menus, GUI, etc...
-- Graphics, art, effects, etc...
-- 
-- Okay, what I really need right now is to make it so that you can have a debug arena.
-- This arena should be able to spawn things, change what teams things are on, and so on.
-- A Lua debug console would be nice too.  loadstring() is what you want there.

function setMode(mode)
   if mode.init then mode.init() end
   love.update = mode.update
   love.draw = mode.draw
   love.keypressed = mode.keypressed
   love.mousepressed = mode.mousepressed
end


function love.load()
   love.graphics.setMode(WIDTH, HEIGHT, false, false, 1)
   setMode(Arena)

   local pix = [[
	 vec4 effect(vec4 color, Image texture, vec2 texcoords, vec2 screencoords) {
	    //return vec4(sin(screencoords.x + time*5), cos(screencoords.y + time*5), 0, 1);
	    return Texel(texture, texcoords);
	 }
   ]]
   pe = love.graphics.newPixelEffect(pix)
   love.graphics.setPixelEffect(pe)
end
