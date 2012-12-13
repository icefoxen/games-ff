require("ai")
require("console")

-- Class Level
Level = oo.newClass(
   function(self, size)
      local l = self
      l.size = size
      l.size2 = size * size
   end
)

function Level:draw()
   love.graphics.setColor(0, 192, 0)
   local size = self.size
   love.graphics.polygon("line", {-size, -size, size, -size, size, size, -size, size})
end

function Level:update(dt)
end

function Level:withinBounds(x, y)
   return vec.len2(x, y) > self.size2
end

-- Class Gamestate
Gamestate = oo.newClass(
   function(self, world, size)
      self.objs = {}
      self.objsSorted = true
      self.level = Level(500)
      self.cam = camera.new(0, 0, 1.0, 0)
      self.camMode = CAMMODE.Fixed
      self.panX = 0
      self.panY = 0

      -- Physics world
      self.world = world


      self.followObjs = set.new()
      self.selected = set.new()
      self.controlGroups = {set.new(), set.new(), set.new(), set.new(), set.new(), 
			 set.new(), set.new(), set.new(), set.new(), set.new()}

      self.console = Console()
      self.consoleActive = false
   end
)

function Gamestate:addObj(g)
   --table.insert(self.objs, g)
   --self.objs:insert(g)
   table.insert(self.objs, g)
   self.objsSorted = false
end

function Gamestate:delObj(g)
   -- Objects must be sorted if the binary search
   -- is going to work.
   self:sortObjs()
   local idx = binsearch(self.objs, g)
   if idx then
      table.remove(self.objs, idx)
      self.objsSorted = false
   end
end

function Gamestate:sortObjs()
   if self.objsSorted then return
   else 
      table.sort(self.objs)
      self.objsSorted = true
   end
end

function Gamestate:draw()
   self.cam:attach()
   self.level:draw()
   -- We could have a 'dirty' flag on self.objs
   -- that tells whether we should sort it...
   -- but testing has showed that the sort time is
   -- pretty much trivial for upwards of 1500 objects anyway.
   self:sortObjs()
   --for _,g in self.objs:ipairs() do
   for _,g in ipairs(self.objs) do
      if g:isAlive() then
	 g:draw()
      end
   end
   set.iter(
      self.selected, 
      function(g)
	 --print("Flying fuck")
	 --for i,j in pairs(self.selected) do
	 --   print(i,j)
	 --end
	 --print("Fuck flown")
	 local x, y = g:getCoords()
	 love.graphics.setColor(255, 0, 0)
	 love.graphics.circle("line", x, y, 20)

	 -- Hmm now, how exactly do we draw orders?
	 local order = g:currentOrder()
	 if order then
	    local t = order.type
	    if t == ORDER.Move then
	       love.graphics.setColor(0, 255, 0, 192)
	       local dx, dy = order.targetX, order.targetY
	       love.graphics.line(x, y, dx, dy)
	    end
	 end
      end
   )
   self.cam:detach()

   -- Draw console.
   if self.consoleActive then
      love.graphics.setColor(64, 64, 64, 128)
      love.graphics.rectangle("fill", 0, 15, 450, 300)
      love.graphics.setColor(0, 255, 0)
      for k,v in pairs(self.console.scrollback) do
	 local offset = k * 15
	 love.graphics.print(v, 0, offset)
      end
      love.graphics.setColor(255, 255, 255)
      love.graphics.print("> " .. self.console:inputToString() .. "_", 0, 315)
   end
end

GAMETICK = 0
function Gamestate:update(dt)
   GAMETICK = GAMETICK + 1
   if self.camMode == CAMMODE.Follow then
      if set.isEmpty(self.followObjs) then
	 self.camMode = CAMMODE.Fixed
      else
	 self.cam.x, self.cam.y = getAverageCoords(self.followObjs)
	 self.panX = self.cam.x
	 self.panY = self.cam.y
      end
   elseif self.camMode == CAMMODE.Pan then
      local x, y = self.cam.x, self.cam.y
      --print("Panning from ", x, y, " to ", self.panX, self.panY)
      if math.abs(x - self.panX) < 5 and math.abs(y - self.panY) < 5 then
	 self.cam.x = x
	 self.cam.y = y
	 self.camMode = CAMMODE.Fixed
      else
	 -- The 4 is there as a speed modifier.  Higher number = faster pan
	 local xoff = ((self.panX - x) * 4) * dt
	 local yoff = ((self.panY - y) * 4) * dt
	 --print("Panning by ", xoff, yoff)
	 self.cam.x = x + xoff
	 self.cam.y = y + yoff
      end
   end
   -- If self.camMode == CAMMODE.Fixed... then we do nothing.

   self.level:update(dt)
   local deadobjs = {}
   --for i,g in self.objs:ipairs() do
   for i,g in pairs(self.objs) do

      g:update(self, dt)
      if not g:isAlive() then
	 table.insert(deadobjs, g)
      end
   end

   for k,v in pairs(deadobjs) do
      print("Killing ", v)
      local s = self:delObj(v)
      print("Delete returned", s)
      v:die(self)

      -- Need to remove item from selections and groups as well...
      self:deselect(v)
      self:removeFromControlGroups(v)
   end
end

function Gamestate:camPanTo(x,y)
   self.camMode = CAMMODE.Pan
   self.panX = x
   self.panY = y
end

function Gamestate:camPanToObjs(objs)
end

function Gamestate:camFollow(objs)
   self.camMode = CAMMODE.Follow
   --print("Setting followObjs to ", objs, "length " .. #objs)
   self.followObjs = objs
end

function Gamestate:camZoom(amount)
   self.cam.zoom = self.cam.zoom + amount
   -- Set some bounds on this...
   self.cam.zoom = math.max(self.cam.zoom, 0.3)
   self.cam.zoom = math.min(self.cam.zoom, 2.0)
   --print("Zoom: " .. self.cam.zoom)
end

function Gamestate:deselectAll()
   self.selected = set.new()
end

function Gamestate:deselect(obj)
   set.remove(self.selected, obj)
end

function Gamestate:select(obj)
   if obj.selectable then
      self.selected = set.new()
      set.add(self.selected, obj)
   end
end

function Gamestate:selectGroup(objs)
   self.selected = set.new()
   set.addTable(self.selected, objs)
end

function Gamestate:selectAdditional(obj)
   if obj.selectable then
      set.add(self.selected, obj)
   end
end

-- Bind selected units to the given control groups
function Gamestate:bindControlGroup(num)
   --print("Selected items")
   for i,j in pairs(self.selected) do
      --print(i,j)
   end
   self.controlGroups[num] = set.new()
   set.addSet(self.controlGroups[num], self.selected)
   self:printControlGroups()
end

function Gamestate:selectControlGroup(num)
   self:printControlGroups()
   self:selectGroup(self.controlGroups[num])
end

-- Removes an object from all control groups
function Gamestate:removeFromControlGroups(obj)
   for _, group in pairs(self.controlGroups) do
      set.remove(group, obj)
   end
end

function Gamestate:printControlGroups()
   local n = 1
   for _, i in pairs(self.controlGroups) do
      print("Control group " .. n)
      n = n + 1
      set.iter(i, print)
   end
end

--[[
I need to select an object by clicking on it.
I can either iterate through all the objects and test each one...  
Or I can tell the physics engine to get me the physics object I click on and use a
slightly-suspicious hook to attach the game object to the physics object, with Fixture:setUserData
Or I can do something silly like writing a quadtree in Lua.  

Option 3 is a bad one.
Start with 1.
2 is probably the best one because we hit the bounding box...

Or we could dispense with this entirely and just use bounding spheres, a la Gamestate:objWithin.
Which really works pretty well, though it does iterate through all objects.
]]--

function Gamestate:objAt(x,y)
end

function Gamestate:objWithin(x, y, dist)
   print("Checking for object at", x, y)
   local item = nil
   local f = function(fixture)
		item = fixture
		return false
	     end
   self.world:queryBoundingBox(x, y, x+dist, y+dist, f)
   if item then
      --print("Obj within: ", item)
      return item:getUserData()
   else
      --print("Nothing there")
      return nil
   end
   --[[
   local x1 = x - dist
   local x2 = x + dist
   local y1 = y - dist
   local y2 = y + dist
   --for _,o in pairs(self.objs) do
   for _, o in self.objs:ipairs() do
      local x, y = o:getCoords()
      if (x1 < x) and (x2 > x) and (y1 < y) and (y2 > y) then
	 return o
      end
   end
   return nil
]]--
end

function Gamestate:objsInBox(x1, y1, x2, y2)
end

function Gamestate:setOrder(order)
   set.iter(
      self.selected,
      function(o)
	 if o.ai then
	    o:clearOrders()
	    o:addOrder(order)
	 end
      end
   )
end

function Gamestate:appendOrder(order)
   set.iter(
      self.selected,
      function(o)
	 if o.ai then
	    o:addOrder(order)
	 end
      end
   )
end

