require("ai")
require("oo")

local GS = {}
Arena = {}

function Arena.init()
      local w = love.physics.newWorld(0, 0, true)
      w:setCallbacks(Arena.beginContact)
      GS = Gamestate(w)
      Arena.addShip(GS)
   end

function Arena.update(dt)
   GS.world:update(dt)
   GS:update(dt)
end

function Arena.draw()
   GS:draw()

   local fps = love.timer.getFPS()
   love.graphics.setColor(255, 255, 255)
   love.graphics.print("FPS: " .. fps .. ", objects: " .. #GS.objs, 0, 0)
   --love.graphics.print("FPS: " .. fps .. ", objects: " .. (#GS.objtest), 0, 0)
end

function Arena.keypressed(key, unicode)
   local function toggleConsole()
      GS.consoleActive = not GS.consoleActive
   end
   local function deselectAll()
      GS:deselectAll()
   end
   local function doControlGroup()
      local num = tonumber(key)
      if love.keyboard.isDown("lctrl", "rctrl") then
	 print("Control group bound: " .. num)
	 GS:bindControlGroup(num)
      else
	 print("Control group selected: " .. num)
	 GS:selectControlGroup(num)
      end
   end
   local function panToSelected()
      print("Panning to selection.")
      GS:camPanTo(getAverageCoords(GS.selected))
   end
   local function followSelected()
      print("Following selection.")
      GS:camFollow(GS.selected)
   end
   local function killSelected()
      set.iter(GS.selected,
	       function(g)
		  g.hits = -1
	       end
	    )
   end
   local keyCallbacks = {
      [" "] = deselectAll,
      ["1"] = doControlGroup,
      ["2"] = doControlGroup,
      ["3"] = doControlGroup,
      ["4"] = doControlGroup,
      ["5"] = doControlGroup,
      ["6"] = doControlGroup,
      ["7"] = doControlGroup,
      ["8"] = doControlGroup,
      ["9"] = doControlGroup,
      -- 1 indexing = hate
      --["0"] = doControlGroup,
      ["g"] = panToSelected,
      ["f"] = followSelected,
      ["d"] = killSelected,
      ["a"] = Arena.addShip,
   }
   if key == '`' then
      toggleConsole()
      return
   end
   if GS.consoleActive then
      -- Mongle console
      if key == "return" then
	 GS.console:execInput()
	 GS.console:clearInput()
      elseif key == "backspace" then
	 GS.console:deleteLastInputChar()
      elseif unicode ~= 0 then
	 GS.console:addInput(string.char(unicode))
      end
   else
      -- Actually do game input
      callback = keyCallbacks[key]
      if callback then
	 callback(GS)
      end
   end
end

function Arena.mousepressed(x, y, button)
   --print(button)
   local worldX, worldY = GS.cam:mousepos()
   local o = GS:objWithin(worldX, worldY, 10)
   -- On left click, select thing.
   if button == "l" then
      if o then
	 -- If ctrl is held, add to group
	 if love.keyboard.isDown("rctrl", "lctrl") then
	    GS:selectAdditional(o)
	 else
	    GS:select(o)
	 end
      end
   elseif button == "r" then
      if o then
	 if love.keyboard.isDown("rctrl", "lctrl") then
	    GS:appendOrder(attackOrder(o))
	 else
	    GS:setOrder(attackOrder(o))
	 end
      else
	 if love.keyboard.isDown("rctrl", "lctrl") then
	    GS:appendOrder(moveOrder(worldX, worldY))
	 else
	    GS:setOrder(moveOrder(worldX, worldY))
	 end
      end
   elseif button == "m" then
   elseif button == "wu" then
      GS:camZoom(0.2)
   elseif button == "wd" then
      GS:camZoom(-0.2)
   end
end


function Arena.beginContact(a, b, coll)
   -- Get gameobjects for the collision...
   -- XXX: Make sure nothing will ever hit anything that isn't a GameObj, is
   -- what this comes down to...
   local obja = a:getUserData()
   local objb = b:getUserData()
   if obja and objb then
      obja:collideWith(objb)
      objb:collideWith(obja)
   end
   --x,y = coll:getNormal()
   --print(a:getUserData().." colliding with "..b:getUserData().." with a vector normal of: "..x..", "..y)
end

-- Debug functions
function Arena.addShip()
   local s = LightCarrier(GS, {sphinxBay, delugeBay})
   GS:addObj(s)

   local s = LightCarrier(GS, {sphinxBay, delugeBay})
   GS:addObj(s)
   s.body:setPosition(100, 100)
end