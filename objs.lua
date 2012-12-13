require("util")
require("oo")
require("set")
require("resource")
require("ai")

vec = require("hump.vector-light")


-- Class Gameobj
-- We use the index to ensure things always sort to the same order,
-- so they will never flicker atop and beneath each other.
GameObj = oo.newClass(
   function(self, gs)
      self.idx = getIndex()
      self.z = ZORDER.Misc
      --print(self:tostring())
      self.body = love.physics.newBody(gs.world, 0, 0, "dynamic")
      self.shape = love.physics.newRectangleShape(15, 10)
      self.fixture = love.physics.newFixture(self.body, self.shape)
      self.fixture:setUserData(self)
      self.fixture:setSensor(true)

      self.collisionMasks = {}
      self.collisionCategories = {}
      
      self.maxHits = 10
      self.hits = self.maxHits

      self.image = resource.getImage("gameobj")
      self.selectable = true

      local mt = getmetatable(self)
      mt.__lt = GameObj.zLt
      --mt.__le = GameObj.zLe
      mt.__eq = GameObj.eq
      mt.__tostring = GameObj.tostring
      setmetatable(self, mt)
   end
)

function GameObj.zLt(g1, g2)
   -- It took me hours of work to realize that this was incorrect,
   -- and (g1.z < g2.z) should really be <=.
   -- :-(
   return (g1.z <= g2.z) and (g1.idx < g2.idx)
end


--function GameObj.zLe(g1, g2)
--   return (g1.z <= g2.z) and (g1.idx <= g2.idx)
--end


function GameObj.eq(g1, g2)
   return g1.idx == g2.idx
end

function GameObj:tostring()
   return string.format("Game obj %d:%d", self.z, self.idx)
end

function GameObj:draw()
   local x, y = self:getCoords()
   --x = x - (self.image:getWidth() / 2)
   --y = y - (self.image:getHeight() / 2)
   local r = self:getAngle()
   
   love.graphics.setColor(255, 255, 255, 255)
   love.graphics.draw(self.image, x, y, r, 1, 1, 
		      (self.image:getWidth() / 2), (self.image:getHeight() / 2)
		   )
   self:drawBoundingBox()
end

function GameObj:drawBoundingBox()
   love.graphics.setColor(255, 255, 255)
   love.graphics.polygon("line", self.body:getWorldPoints(self.shape:getPoints()))
end

function GameObj:update(gs, dt)
end

function GameObj:damage(amount)
   self.hits = self.hits - amount
end

function GameObj:isAlive()
   return self.hits > 0
end

function GameObj:die(gs)
   print("Dying:", self)
   -- Destroys the fixture and shape, too!  :D
   self.body:destroy()
   --self.shape:destroy()
   --self.fixture:destroy()
end

function GameObj:applyImpulse(x, y)
   self.body:applyLinearImpulse(x, y)
   --self.body:applyForce(x, y)
end

function GameObj:getCoords()
   --if self.hits > 0 then
      return self.body:getX(), self.body:getY()
   --else
      --return 0, 0
   --end
end

function GameObj:setCoords(x,y)
   self.body:setX(x)
   self.body:setY(y)
end

function GameObj:getAngle()
      return self.body:getAngle()
end

function GameObj:setAngle(a)
   self.body:setAngle(a)
end

function GameObj:collideWith(gobj)
   print("Collided with:", tostring(gobj))
end

function GameObj:disablePhysics()
   --self.body:setX(math.huge)
   --self.body:setY(math.huge)
   self.collisionMasks = {self.fixture:getMask()}
   self.collisionCategories = {self.fixture:getCategory()}

   -- XXX: This might be wossname hurgle burgle
   -- Or, get turned back on upon update somehow.
   -- According to Box2D, it SHOULD only be turned on when
   -- something hits it.  Which it won't, because of the line after.
   -- ...uhhh.  Except when something hits it, which is exactly what 
   -- we don't want to happen.
   -- Ooooor, we could just move the object OFF INTO HYPERSPACE, but...
   -- This _sort of_ works I think.  Hmm.
   self.body:setAwake(false)
   self.fixture:setMask()
   self.fixture:setCategory()
end

function GameObj:enablePhysics()
   self.fixture:setMask(unpack(self.collisionMasks))
   self.fixture:setCategory(unpack(self.collisionCategories))
   self.body:setAwake(true)
end

function GameObj:closerThan(obj, dist)
   local x, y = self:getCoords()
   local ox, oy = obj:getCoords()
   return vectorsWithin(dist, x, y, ox, oy)
end

function GameObj:furtherThan(obj, dist)
   return not GameObj:closerThan(obj, dist)
end




-- Class Ship
Ship = oo.inherits(
   GameObj, 
   function(self, gs)
      GameObj.constructor(self, gs)
      self.body:setMass(5)
      self.body:setLinearDamping(1.0)
      self.body:setAngularDamping(10.0)
      self.fixture:setCategory(COLL.Ship)
      -- Won't collide with ships, will collide with other things
      self.fixture:setMask(COLL.Ship)
      --print(self.fixture:getCategory())
      
      self.thrustForce = 600.0
      self.turnForce = 20000.0
      -- 0 for 'off', 1 for 'full speed'
      self.thrusting = 0
      -- 0 for 'off', -1 for turning right, 1 for turning left
      self.turning = 0

      self.ai = StrategicAI(self)
      
      self.image = resource.getImage("ship")
      --self.gun = Weapon(Shot, 1.0, 50, 0)
      self.weapons = {}
      self.turrets = {}
      self.firing = false

      -- Steering constants
      self.steerTolerance = PIOVERFOUR
      self.arriveDamping = 150
      self.weaponLongRange = 120
      self.weaponMediumRange = 120
      self.weaponShortRange = 120
      

      --[[
      if math.random() > 0 then
	 self:disablePhysics()
	 print("Physics off!")
      else
	 print("Physics on!")
      end
]]--

      self:addWeapon(Weapon(Shot, 1.0, 50, 0))
   end
)

function Ship:tostring()
   return string.format("Ship %d:%d", self.z, self.idx)
end

function Ship:addWeapon(weapon)
   table.insert(self.weapons, weapon)
end

function Ship:addTurret(weapon)
   table.insert(self.turrets, weapon)
end

function Ship:thrust(dt)
   local thrust = self.thrustForce * dt * self.thrusting
   local x,y = vec.rotate(self.body:getAngle(), thrust, 0)
   
   self:applyImpulse(x,y)
end

function Ship:turn(dt)
   self.body:applyTorque(self.turnForce * dt * self.turning)
end

function Ship:update(gs, dt)
   --print(self.fixture:getMask())
   --self.body:setAwake(self.active)
   self.ai:update(gs, dt)

   self:thrust(dt)
   self:turn(dt)

   for _, w in pairs(self.weapons) do
      w:update(dt)
   end
   for _, w in pairs(self.turrets) do
      w:update(dt)
   end

   for _, w in pairs(self.turrets) do
      w:fire(gs, self)
   end

   if self.firing then
      for _, w in pairs(self.weapons) do
	 w:fire(gs, self)
      end
   end
end


function Ship:tostring()
   return string.format("Ship %d:%d", self.z, self.idx)
end

function Ship:die(gs)
   GameObj.die(self, gs)
end

-- These dummy functions are a bit of a hack,
-- but are handy to have so escorts can have
-- the same order interface as carriers, they
-- just have no power to add or modify orders.
function Ship:addOrder(order)
end

function Ship:currentOrder()
   return nil
end

function Ship:nextOrder()
end

function Ship:clearOrders()
end


Carrier = oo.inherits(
   Ship, 
   function(self, gs, bayConstructors)
      print("Carrier", bays)
      Ship.constructor(self, gs)
      self.bays = {}
      self.z = ZORDER.Carrier

      for _, bayCon in pairs(bayConstructors) do
	 table.insert(self.bays, bayCon(self))
      end

      self.orders = {}
   end
)

function Carrier:tostring()
   return string.format("Carrier %d:%d", self.z, self.idx)
end

function Carrier:update(gs, dt)
   Ship.update(self, gs, dt)

   -- This doesn't really need to be done each frame
   -- !Remember! to adjust dt if this is the case!
   for _,bay in pairs(self.bays) do
      bay:update(gs, dt)
   end
end

function Carrier:addOrder(order)
   table.insert(self.orders, order)
end

function Carrier:currentOrder()
   return self.orders[1]
end

function Carrier:nextOrder()
   table.remove(self.orders, 1)
end

function Carrier:clearOrders()
   self.orders = {}
end


Escort = oo.inherits(
   Ship, 
   function(self, gs, parentBay)
      Ship.constructor(self, gs)
      self.parentBay = parentBay
      -- XXX: Doesn't seem to work for some reason.
      self.z = ZORDER.Misc
   end
)

function Escort:tostring()
   return string.format("Escort %d:%d", self.z, self.idx)
end

-- When an escort dies, it has to let its parent know.
function Escort:die(gs)
   Ship.die(self, gs)
   self.parentBay:removeShip(self)
end


-- Escorts don't get orders, they recieve them from their carrier bays.
function Escort:currentOrder()
   return self.parentBay:currentOrder()
end

function Escort:parentShip()
   return self.parentBay.parent
end

function Escort:parentBay()
   return self.parentBay
end

-- Class carrierbay
CarrierBay = oo.newClass(
   function(self, newShipFunc, parent)
      print("Carrier bay", newShipFunc, parent)
      self.squadron = set.new()
      -- max squadron size
      self.squadronSize = 0
      -- current squadron size
      self.squadronCount = 0
      self.spawnDelay = 0
      self.spawnTimeout = 0
      self.parent = parent
      self.newShipFunc = newShipFunc

      self.repairingShips = set.new()
      self.repairRate = 0

      self.recoverRange = 50

      self.shipsReadyForLaunch = {}
   end
)


function CarrierBay:tostring()
   return string.format("Carrier bay on %s", self.parent)
end

-- These functions manipulate the squadron list
-- but make no assumptions about whether the ship is in space,
-- in the repair bay, or ready to launch
function CarrierBay:addShip(ship)
   set.add(self.squadron, ship)
   self.squadronCount = self.squadronCount + 1
end

function CarrierBay:addNewShip(gs)
   print(self.parent)
   print(self.newShipFunc)
   local ship = self.newShipFunc(gs, self)
   self:addShip(ship)
   return ship
end

function CarrierBay:removeShip(ship)
   set.remove(self.squadron, ship)
   self.squadronCount = self.squadronCount - 1
end



-- Carrier bays dispatch orders to their child squadron
-- from the carrier
function CarrierBay:currentOrder()
   return self.parent:currentOrder()
end

function CarrierBay:update(gs, dt)
   -- Spawn new ships if possible
   self.spawnTimeout = self.spawnTimeout - dt
   if self.squadronCount < self.squadronSize and
      self.spawnTimeout < 0 then
      print("Spawning new ship")
      local newship = self:addNewShip(gs)
      self:readyToLaunch(newship)
      self.spawnTimeout = self.spawnDelay
   end

   set.iter(self.repairingShips,
	    function(ship)
	       ship.hits = ship.hits + (self.repairRate * dt)
	       if ship.hits > ship.maxHits then
		  ship.hits = ship.maxHits
		  self:repairsDone(ship)
	       end
	    end
	 )

   -- XXX:
   -- Having ships launch instantly is not necessarily a good idea.
   -- But for now it works.
   self:launchShips(gs)
end

-- Should have shiny effects
function CarrierBay:launchShips(gs)
   for _,v in pairs(self.shipsReadyForLaunch) do
      print("Launching ship")
      local x, y = self.parent:getCoords()
      v:enablePhysics()
      v:setCoords(x, y)
      v:setAngle(self.parent:getAngle())
      gs:addObj(v)
   end
   self.shipsReadyForLaunch = {}
end

-- Should have shiny effects
-- XXX: Oh shit, it needs to remove the ship from the physics engine too...
-- Could put it to sleep and set it to be in no collision categories, but
-- then putting it BACK into the right collision categories sounds annoying...
function CarrierBay:recoverShip(gs, ship)
   ship:disablePhysics()
   gs:delObj(ship)
   set.add(self.repairingShips, ship)
end

function CarrierBay:repairsDone(ship)
   set.remove(self.repairingShips, ship)
   self:readyToLaunch(ship)
end

function CarrierBay:readyToLaunch(ship)
   table.insert(self.shipsReadyForLaunch, ship)
end


-- Class Weapon
Weapon = oo.newClass(
   function(self, shottype, refire, x, y)
      self.shot = shottype
      self.refireRate = refire
      self.refire = 0.0
      self.offsetX = x or 0
      self.offsetY = y or 0
   end
)

function Weapon:tostring()
   return string.format("Weapon of type on %s", self.shottype)
end

-- XXX: Should this take the gameobj and gamestate as well,
-- the weapon has a firing flag, and just fire when it can?
-- Makes a bit more sense than having the controller continually
-- calling fire() even when it doesn't do anything...
function Weapon:update(dt)
   self.refire = self.refire - dt      
end

function Weapon:fire(gs, firingShip)
   if self.refire < 0 then
      local x, y = firingShip:getCoords()
      local angle = firingShip:getAngle()
      local ax, ay = vec.rotate(angle, self.offsetX, self.offsetY)
      local shot = self.shot(gs, x + ax, y + ay, angle)
      gs:addObj(shot)
      self.refire = self.refireRate
   end
end

-- Class Turret
-- Oooog... turrets need to target independantly...
Turret = oo.inherits(
   Weapon, 
   function(self, shottype, refire, x, y)
      Weapon.constructor(self, shottype, refire, x, y)
      self.turretPosX = 0
      self.turretPosY = 0
      --self.turretDefaultFacing = 0
      self.turretFacing = 0
      self.turretTurnRate = 0
      self.target = nil
      self.accuracy = 0
   end
)

function Turret:tostring()
   return string.format("Turret of type on %s", self.shottype)
end


function Turret:update(dt, gs)
   self.refire = self.refire - dt
   if self.target then
      -- If target is out of range, forget about it
      -- Else, try to turn towards target, start firing when close
   else
      -- Look for targets
   end
end

function Turret:fire(gs, firingShip)
   if self.refire < 0 then
      local x, y = firingShip:getCoords()
      local angle = firingShip:getAngle()
      local ax, ay = vec.rotate(angle, self.offsetX, self.offsetY)
      local shot = self.shot(x + ax, y + ay, angle)
      gs:addObj(shot)
      self.refire = self.refireRate
   end
end

-- Class Shot
Shot = oo.inherits(
   GameObj, 
   function(self, gs, x, y, angle)
      GameObj.constructor(self, gs)
      self.body:setPosition(x, y)
      self.body:setAngle(angle)
      local vel = 150
      local vx, vy = vec.rotate(angle, vel, 0)
      self.body:setLinearVelocity(vx, vy)

      self.fixture:setCategory(COLL.Shot)
      -- Won't collide with shots, will collide with other things
      self.fixture:setMask(COLL.Shot)

      self.lifetime = 2.0
      self.damage = 5
   end
)

function Shot:tostring()
   return string.format("Shot")
end


function Shot:update(gs, dt)
   self.lifetime = self.lifetime - dt
   if self.lifetime < 0 then
      self.hits = -1
   end
end

function Shot:collideWith(gobj)
   gobj:damage(self.damage)
   self.hits = -1
end

function Shot:tostring()
   return string.format("Shot %d:%d", self.z, self.idx)
end

function Shot:die(gs)
   GameObj.die(self, gs)
   --print("Shot dying")
end

