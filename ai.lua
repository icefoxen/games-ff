vec = require("hump.vector-light")

require("oo")
require("util")

-- Fuck...
-- Do we have separate AI objects which tell the controller
-- what to do, or does the controller just make its own decisions?
-- Having a high-level "do this, do that" layer separate from a low-level
-- "go here, turn left, fire, turn right, keep going" layer is not necessarily
-- a bad idea...
-- Especially if squadrons are going to be directed by the same AI...
-- Hrmbl.
--
-- However!  Looking at it, if you do that then the current Controller class doesn't
-- actually have any state at all.
--
-- Well, there's gonna be a thing which takes orders, which is going to get the same 
-- types of orders for all ships.  And it is going to do things like notice when orders
-- have been completed or changed.  Then there's going to be something that says
-- how to carry them out, which is very different for all ships.
--
-- Oh gods at some point the computer is going to have to fight back...
-- Shiiiiit.  Hmm.  How is that going to work?
-- Well the computer's ships are no more independant than yours, so...
-- That might actually just not be a problem.  Combination of mission scripting
-- and independant player-like AI; it just chooses ships and gives orders like you.


-- This essentially defines the operations in behavior scripts
-- Steering behaviors and such.
-- This is actually stateless; it doesn't make any decisions on its own.
Steer = {}

function sumSteering(x1, y1, a1, x2, y2, a2)
   -- Ick ick ick
   -- This really sucks.  Unfortunately, it works
   if not x1 then x1 = 0 end
   if not x2 then x2 = 0 end
   if not y1 then y1 = 0 end
   if not y2 then y2 = 0 end
   if not a1 then a1 = 0 end
   if not a2 then a2 = 0 end
   local x = x1+x2
   local y = y1+y2
   local a = a1+a2
   if x == 0 then x = nil end
   if y == 0 then y = nil end
   if a == 0 then a = nil end
   return x, y, a
end

-- Maybe make steer vector and steer angle mutually exclusive?
-- Hrmbl.
-- That means that if you want to make arriveAndFaceDirectionAfterYouGetThere
-- it has to do its own modal thing.
-- Which... is probably best anyway.
-- So, specifying BOTH a steering vector and angle will probably
-- not have desired results!
-- OR, we could just do if the magnitude of the steer vector is small enough.
-- But the magnitude of the steer vector is not necessarily defined!!!
-- XXX: ArriveDamping is not really working right, though I think it is still the right
-- thing in the end...
function Steer.steer(ship, steerVectorX, steerVectorY, steerAngle)
   local x, y = ship:getCoords()
   local steerTolerance = ship.steerTolerance
   
   -- Now generate a vector representing the facing of the ship
   local objTheta = ship:getAngle()
   local fx, fy = math.cos(objTheta), math.sin(objTheta)

   if steerVectorX and steerVectorY then      
      local dx, dy = steerVectorX, steerVectorY

      local separation = angleBetweenVectors(dx, dy, fx, fy)
      local distance2 = vec.len2(dx, dy)
      local damping2 = ship.arriveDamping ^ 2
      local dampingFactor = math.min(distance2 / damping2, 1.0)
      
      -- Will be >1 if separation > steerTolerance, or closer and closer to 0
      -- as it gets below that, resulting in finer and finer turning
      -- Ideally it'd be a sigmoidal function instead of linear, but eh.
      local turnMagnitude = separation / steerTolerance

      if math.abs(turnMagnitude) < 1 then
	 --print("Reduced turning", turnMagnitude)
	 ship.turning = turnMagnitude
	 ship.thrusting = dampingFactor
      else
	 ship.thrusting = 0
	 if turnMagnitude > 1 then
	    ship.turning = 1
	 else
	    ship.turning = -1
	 end
      end
   elseif steerAngle then
      -- We're at the target...
      local sx, sy = angleToVector(steerAngle)
      local separation = angleBetweenVectors(fx, fy, sx, sy)
      local turnMagnitude = separation / steerTolerance

      if turnMagnitude > 1 then
	 ship.turning = 1
      elseif turnMagnitude < -1 then	 
	 ship.turning = -1
      else
	 ship.turning = turnMagnitude
      end
   else
      ship.thrusting = 0
      ship.turning = 0
   end
end


-- Steering behaviors return 3 numbers,
-- the x and y of the steering vector, and the angle to assume
-- once you get there.
-- either of these can be nil.
function Steer.arrive(ship, targetX, targetY)
   local x, y = ship:getCoords()
   local dx, dy = (targetX - x), (targetY - y)
   return dx, dy
end

function Steer.seek(ship, targetX, targetY)
   local x, y = ship:getCoords()
   local dx, dy = vec.sub(targetX, targetY, x, y)
   --print(dx, dy)
   return dx, dy
end

function Steer.stop(ship)
   return nil, nil, nil
end

function Steer.avoid(ship, targetX, targetY)
   local x, y = ship:getCoords()
   local dx, dy = vec.sub(targetX, targetY, x, y)
   return -dx, -dy
end

-- Just keeps distance from the target
-- XXX: It would work WAY better by casting a ray between the ships,
-- finding the point along it that is at the ideal range, and then
-- just arriving there.
--
-- Actually, this way DOES avoid a vec.normalize()...
function Steer.maintainRange(ship, targetX, targetY, distance, slop)
   local x, y = ship:getCoords()
   --local dirX, dirY = vec.sub(targetX, targetY, x, y)
   local dirX, dirY = vec.sub(x, y, targetX, targetY)
   local nx, ny = vec.normalize(dirX, dirY)
   local sx, sy = vec.mul(distance, nx, ny)
   local tx, ty = vec.add(targetX, targetY, sx, sy)
   return Steer.arrive(ship, tx, ty)
end

-- This moves around the target to, for instance, stay on the left side of it.
-- ...this is actually easier with a distance too...
-- It actually doesn't make much sense otherwise, because you could just
-- cast a ray out from the target angle and make a ray _|_ to it that intersects
-- the ship, and go there... which is silly.
function Steer.maintainRangeAndAngle(ship, targetX, targetY, distance, targetAngle)
   local dirX, dirY = angleToVector(targetAngle)
   local offsetX, offsetY = vec.mul(distance, dirX, dirY)
   local tx, ty = vec.add(targetX, targetY, offsetX, offsetY)
   return Steer.arrive(ship, tx, ty)
end

-- Turn to face something without moving
function Steer.faceToward(ship, targetX, targetY)
   local x, y = ship:getCoords()
   local dx, dy = vec.sub(x, y, targetX, targetY)
   return nil, nil, vectorToAngle(dx, dy)
end

function Steer.faceAway(ship, targetX, targetY)
   local x, y = ship:getCoords()
   local dx, dy = vec.sub(targetX, targetY, x, y)
   return nil, nil, vectorToAngle(dx, dy)
end



Maneuver = oo.newClass(
   function(self, ship)
      self.ship = ship
      self.target = {}
      self.targetX = 0
      self.targetY = 0
      self.targetAngle = math.random() * TWOPI
      self.targetRange = 150
      self.maneuver = self.doNothing
   end
)

function Maneuver:update(gs, dt)
   self:maneuver(gs)
end

function Maneuver:doNothing(gs)
   local x, y, a = Steer.stop()
   Steer.steer(self.ship, x, y, a)
end

function Maneuver:retreat(gs)
   local mothership = self.ship:parentShip()
   local x, y = mothership:getCoords()
   local sx, sy, sa = Steer.arrive(self.ship, x, y)
   Steer.steer(self.ship, sx, sy, sa)

   local mx, my = mothership:getCoords()
   local lx, ly = self.ship:getCoords()
   local dist = vec.dist(mx, my, lx, ly)
   local bay = self.ship:parentBay()
   if dist <= bay.recoverRange then
      bay:recoverShip(gs, self.ship)
      self.maneuver = self.doNothing
   end
end

function Maneuver:travel(gs)
   local sx, sy, sa = Steer.arrive(self.ship, self.targetX, self.targetY)
   Steer.steer(self.ship, sx, sy, sa)
end

function Maneuver:formation(gs)
   local targetX, targetY = self.target:getCoords()
   local targetAngle = self.target:getAngle() + self.targetAngle
   local sx, sy, sa = Steer.maintainRangeAndAngle(
      self.ship, self.targetX, self.targetY, self.targetRange, targetAngle)
   Steer.steer(self.ship, sx, sy, sa)
end

-- XXX: This doesn't make you turn to face the target correctly,
-- Because you never _fully_ arrive to the desired point!
-- On the whole, the numbers governing arrival rate and slop and stuff
-- are quite bananas and need fixing.
function Maneuver:standoffAttack(gs)
   local x, y = self.target:getCoords()
   local sx, sy, sa = Steer.maintainRange(
      self.ship, x, y, self.targetRange, 50)
   local fx, fy, fa = Steer.faceToward(self.ship, x, y)
   local rx, ry, ra = sumSteering(sx, sy, sa, fx, fy, fa)
   Steer.steer(self.ship, rx, ry, ra)

   -- XXX: This should ideally wait until you're actually facing the
   -- target...
   if self.ship:closerThan(self.target, self.ship.weaponLongRange) then
      self.ship.firing = true
   else
      self.ship.firing = false
   end
end

function Maneuver:circleAttack(gs)
end

function Maneuver:stationaryAttack(gs)
end

function Maneuver:flankAttack(gs)
end

function Maneuver:dogfightAttack(gs)
end

function Maneuver:slashAttack(gs)
end


function Maneuver:setDoNothing()
   self.maneuver = self.doNothing
end


function Maneuver:setRetreat()
   self.maneuver = self.retreat
end


function Maneuver:setTravel(tx, ty)
   self.maneuver = self.travel
   self.targetX = tx
   self.targetY = ty
end

function Maneuver:setFormation(t)
   self.maneuver = self.formation
   self.target = t
end

function Maneuver:setStandoffAttack(t)
   self.maneuver = self.standoffAttack
   self.target = t
end

function Maneuver:setCircleAttack(t)
   self.maneuver = self.circleAttack
   self.target = t
end

function Maneuver:setStationaryAttack(t)
   self.maneuver = self.stationaryAttack
   self.target = t
end

function Maneuver:setFlankAttack(t)
   self.maneuver = self.flankAttack
   self.target = t
end

function Maneuver:setDogfightAttack(t)
   self.maneuver = self.dogfightAttack
   self.target = t
end

function Maneuver:setSlashAttack(t)
   self.maneuver = self.Attack
   self.target = t
end


-- The tactics AI is going to be different for every ship role,
-- if not every ship...
TACTICALORDERS = enum{
   "Idle",
   "Retreat",
   "Move",
   "Attack",
   "Formation",
}


SHIPTYPE = enum{
   "Small_AF",  -- Antifighter
   "Small_AC",  -- Anti-capital
   "Small_G",   -- Generalist
   "Medium_AF",
   "Medium_AC",
   "Medium_G",
   "Large_AF",
   "Large_AC",
   "Large_G",
   "Huge", -- All huge ships are generalists
}


TacticalAI = oo.newClass(
   function(self, ship)
      self.ship = ship
      self.state = TACTICALORDERS.Idle
      self.target = {}
      self.targetX = 0
      self.targetY = 0
      self.m = Maneuver(ship)
   end
)

function TacticalAI:setIdle()
   self.state = TACTICALORDERS.Idle
end

function TacticalAI:setAttack(target)
   self.state = TACTICALORDERS.Attack
   self.target = target
end

function TacticalAI:setRetreat()
   self.state = TACTICALORDERS.Retreat
end

function TacticalAI:setMove(targetX, targetY)
   self.state = TACTICALORDERS.Move
   self.targetX = targetX
   self.targetY = targetY
end

function TacticalAI:setFormation(target)
   self.state = TACTICALORDERS.Formation
   self.target = target
end

function TacticalAI:update(gs, dt)
   if self.state == TACTICALORDERS.Idle then
      self:idle(gs)
   elseif self.state == TACTICALORDERS.Attack then
      self:attack(gs)
   elseif self.state == TACTICALORDERS.Retreat then
      self:retreat(gs)
   elseif self.state == TACTICALORDERS.Move then
      self:move(gs)
   elseif self.state == TACTICALORDERS.Formation then
      self:formation(gs)
   end
   self.m:update(gs, dt)
end

function TacticalAI:idle(gs)
   self.m:setDoNothing()
end

function TacticalAI:attack(gs)
   self.m:setStandoffAttack(self.target)
end

function TacticalAI:retreat(gs)
   self.m:setRetreat()
end

function TacticalAI:move(gs)
   self.m:setTravel(self.targetX, self.targetY)
end

function TacticalAI:formation(gs)
   self.m:setFormation(self.target)
end


HydraAI = oo.inherits(
   TacticalAI,
   function(self, ship)
      TacticalAI.constructor(self, ship)
   end
)

-- Okay, we have the TacticsAI which sets what the ship
-- is actually doing, and then we have the Steer which
-- actually does it.
-- States for the Steer are attacking, escorting, travelling,
-- fleeing, doing nothing, firing from fixed position.
-- Thing is that 'attacking' can be broken down into several things:
-- stand-off-and-plink, circle-strafe, flank (try to get to the sides/
-- behind always), dogfight (try to out-turn the enemy, occasionally
-- changing direction), slashing attack...
-- You could also 
-- The TacticsAI is same for each ship class, the Steer
-- is, at least, different for fighters, drones, frigates, etc.
-- Steer should be able to do sphere formation...



-- Player orders
ORDER = enum{
   "Move",
   "Attack",
   "AttackTowards",
   "Defend",
   "DefendArea",
}

function moveOrder(x, y)
   return {
      type = ORDER.Move,
      targetX = x,
      targetY = y,
   }
end

function attackOrder(t)
   return {
      type = ORDER.Attack,
      target = t,
   }
end

function attackTowardsOrder(x, y)
   return {
      type = ORDER.AttackTowards,
      targetX = x,
      targetY = y,
   }
end

function defendOrder(t)
   return {
      type = ORDER.Defend,
      target = t,
   }
end

function defendAreaOrder(x, y)
   return {
      type = ORDER.DefendArea,
      targetX = x,
      targetY = y,
   }
end

CONTROLMODE = enum{
   "Aggressive",
   "Neutral",
   "Cautious",
}


function findNearestBestTarget()
end

function findWeakestTarget()
end


-- The tactical AI turns player orders into specific orders.
StrategicAI = oo.newClass(
   function(self, ship, tacticsai)
      self.ship = ship
      --self.tactics = tacticsai
      self.tactics = TacticalAI(ship)
      -- These should be different for each ship...
      -- How close you must aim towards your target before starting to thrust.
      --self.steerTolerance = PIOVERFOUR / 2
      -- How close you must be to your target before starting to reduce thrust
      self.arriveDamping = 150
      -- How close it has to be to the target before a move order is considered done
      self.moveThreshold = 40
      
   end
)

-- On carriers, currentOrder() returns the order the carrier has.
-- On escorts, currentOrder() returns the order from the carrier bay,
-- which is currently the same as the carrier.
-- Thus, only carriers actually recieve orders from the player.
--
-- However, this StrategicAI really only works for carriers at the moment.
-- XXX: Should it only bother informing the TacticalAI when things _change_?
-- Hmm.
function StrategicAI:update(gs, dt)
   local order = self.ship:currentOrder()
   if order then
      if order.type == ORDER.Move then
	 self.tactics:setMove(order.targetX, order.targetY)
	 local x, y = self.ship:getCoords()
	 if vec.dist(x, y, order.targetX, order.targetY) < self.moveThreshold then
	    self.ship:nextOrder()
	 end
      elseif order.type == ORDER.Attack then
	 local target = order.target
	 local x, y = target:getCoords()
	 self.tactics:setAttack(target)
      end
   else
      self.tactics:setIdle()
   end
   self.tactics:update(gs, dt)
end



AggressiveAI = oo.inherits(
   StrategicAI,
   function(self, ship)
   end
)

-- This function also needs to handle events like health going below threshold,
-- squadron being damaged, ship recieving damage, etc.
function AggressiveAI:update(gs, dt)
   local order = self.ship:currentOrder()
   if order then
      if order.type == ORDER.Move then
	 -- If there is a target in range, set state to attack.
	 -- Otherwise, move toward destination
	 -- If at destination, order complete
      elseif order.type == ORDER.Attack then
	 -- If it has a target, set state to attack
	 -- Otherwise, find weakest target in range and set state to attack
	 -- Otherwise, order complete
      elseif order.type == ORDER.AttackTowards then
	 -- If it has a target, set state to attack
	 -- Otherwise, find weakest target in range and set state to attack
	 -- Otherwise, move towards destination
	 -- If at destination, order complete
      elseif order.type == ORDER.Defend then
	 -- If it has a target, set state to attack
	 -- Otherwise, look for target nearest guarded ship and set state to attack
	 -- Otherwise, escort guarded ship
      elseif order.type == ORDER.DefendArea then
	 -- If it has a target, set state to attack
	 -- Otherwise, look for target nearest guarded ship and set state to attack
	 -- Otherwise, patrol given area
      end
   else
      -- If there is a target in range, set state to attack.
      -- Otherwise, set state to stop, since no orders
   end
end


NeutralAI = oo.inherits(
   StrategicAI,
   function(self, ship)
   end
)

CautiousAI = oo.inherits(
   StrategicAI,
   function(self, ship)
   end
)
