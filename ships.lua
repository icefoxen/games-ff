require("objs")
require("resource")

--require("util")
--require("oo")
--require("set")
--require("resource")

--vec = require("hump.vector-light")

DroneBay = oo.inherits(
   CarrierBay, 
   function(self, newShipFunc, parent)
      CarrierBay.constructor(self, newShipFunc, parent)
      print("Drone bay", newShipFunc, parent)

      -- max squadron size
      self.squadronSize = 6
      self.spawnDelay = 10
      self.spawnTimeout = 10
      self.repairRate = 15
   end
)

-- Bay constructors take the carrier for the bay and returns
-- a new CarrierBay object.
function hydraBay(parent)
   return DroneBay(Hydra, parent)
end

function sphinxBay(parent)
   return DroneBay(Sphinx, parent)
end

GunshipBay = oo.inherits(
   CarrierBay, 
   function(self, newShipFunc, parent)
      CarrierBay.constructor(self, newShipFunc, parent)

      -- max squadron size
      self.squadronSize = 3
      self.spawnTimeout = 20
      self.repairRate = 20
   end
)

function heartbreakerBay(parent)
   return GunshipBay(Heartbreaker, parent)
end

function solBay(parent)
   return GunshipBay(Sol, parent)
end

function oswaldBay(parent)
   return GunshipBay(Oswald, parent)
end

MissileBay = oo.inherits(
   CarrierBay, 
   function(self, newShipFunc, parent)
      CarrierBay.constructor(self, newShipFunc, parent)

      -- max squadron size
      self.squadronSize = 6
      self.spawnTimeout = 60
      -- Repairing missiles seems a little redundant
      self.repairRate = 0
   end
)

function waspBay(parent)
   return MissileBay(Wasp, parent)
end

function angelBay(parent)
   return MissileBay(Angel, parent)
end

function terrorBay(parent)
   return MissileBay(Terror, parent)
end

FighterBay = oo.inherits(
   CarrierBay, 
   function(self, newShipFunc, parent)
      CarrierBay.constructor(self, newShipFunc, parent)

      -- max squadron size
      self.squadronSize = 4
      self.spawnTimeout = 15
      self.repairRate = 15
   end
)

function aceBay(parent)
   return FighterBay(Ace, parent)
end

function gunstarBay(parent)
   return FighterBay(Gunstar, parent)
end




-- Silent Nation and Empire frigates work the same I guess.
FrigateBay = oo.inherits(
   CarrierBay, 
   function(self, newShipFunc, parent)
      CarrierBay.constructor(self, newShipFunc, parent)

      -- max squadron size
      self.squadronSize = 1
      self.spawnTimeout = 60
      self.repairRate = 50
   end
)

function lancerBay(parent)
   return FrigateBay(Lancer, parent)
end

function delugeBay(parent)
   return FrigateBay(Deluge, parent)
end

function aegisBay(parent)
   return FrigateBay(Aegis, parent)
end


function phantomBay(parent)
   return FrigateBay(Phantom, parent)
end

function wraithBay(parent)
   return FrigateBay(Wraith, parent)
end

function maximBay(parent)
   return FrigateBay(Maxim, parent)
end


-- Silent Nation Ships
LightCarrier = oo.inherits(
   Carrier, 
   function(self, gs, bays)
      print("Light carrier", bays)
      Carrier.constructor(self, gs, bays)
      self.image = resource.getImage("lightcarrier")

      -- T/W ratio 50
      self.body:setMass(1000)
      self.thrustForce = 50000.0
      self.turnForce = 20000.0
   end
)

MediumCarrier = oo.inherits(
   Carrier, 
   function(self, gs, bays)
      Carrier.constructor(self, gs, bays)

      self.image = resource.getImage("mediumcarrier")

      -- T/W ratio 45
      self.body:setMass(2000)
      self.thrustForce = 90000.0
      self.turnForce = 18000.0
   end
)

HeavyCarrier = oo.inherits(
   Carrier, 
   function(self, gs, bays)
      Carrier.constructor(self, gs, bays)
      self.image = resource.getImage("heavycarrier")

      -- T/W ratio 40
      self.body:setMass(3000)
      self.thrustForce = 240000.0
      self.turnForce = 15000.0
   end
)

-- Swarmers
Hydra = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("hydra")

      -- T/W 200
      self.body:setMass(10)
      self.thrustForce = 2000.0
      self.turnForce = 75000.0
   end
)

Sphinx = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("sphinx")

      -- T/W 180
      self.body:setMass(15)
      self.thrustForce = 2700
      self.turnForce = 68000.0

   end
)

-- Gunships
Heartbreaker = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("heartbreaker")

      -- T/W 130
      self.body:setMass(100)
      self.thrustForce = 130000
      self.turnForce = 60000.0

   end
)

Sol = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("sol")

      -- T/W 110
      self.body:setMass(120)
      self.thrustForce = 13200
      self.turnForce = 52000.0

   end
)

Oswald = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("oswald")

      local mass = 115
      self.body:setMass(mass)
      self.thrustForce = mass * 110
      self.turnForce = 55000.0
   end
)

-- Frigates
Lancer = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("lancer")

      local mass = 650
      self.body:setMass(mass)
      self.thrustForce = mass * 62
      self.turnForce = 28000.0
   end
)

Deluge = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("deluge")

      local mass = 650
      self.body:setMass(mass)
      self.thrustForce = mass * 68
      self.turnForce = 32000.0
   end
)

Aegis = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("aegis")

      local mass = 650
      self.body:setMass(mass)
      self.thrustForce = mass * 68
      self.turnForce = 30000.0
   end
)



-- Imperial ships
Cruiser = oo.inherits(
   Carrier, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("cruiser")

      self.body:setMass(1500)
      self.thrustForce = 60000.0
      self.turnForce = 18000.0
   end
)

BattleCarrier = oo.inherits(
   Carrier, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("battlecarrier")

      self.body:setMass(3000)
      self.thrustForce = 90000.0
      self.turnForce = 16000.0
   end
)

BattleShip = oo.inherits(
   Carrier, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("battleship")
      

      self.body:setMass(4500)
      self.thrustForce = 120000.0
      self.turnForce = 14000.0
   end
)

-- Missiles
Wasp = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("wasp")

      self.body:setMass(10)
      self.thrustForce = 100
      self.turnForce = 40000.0
   end
)

Angel = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("angel")

      self.body:setMass(10)
      self.thrustForce = 120
      self.turnForce = 50000.0
   end
)

Terror = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("terror")

      self.body:setMass(20)
      self.thrustForce = 160
      self.turnForce = 35000.0

   end
)

-- Fighters
Ace = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("ace")

      self.body:setMass(75)
      self.thrustForce = 700
      self.turnForce = 60000.0
   end
)

Gunstar = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("gunstar")

      self.body:setMass(85)
      self.thrustForce = 850
      self.turnForce = 65000.0
   end
)

-- Frigates
Phantom = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("phantom")

      self.body:setMass(750)
      self.thrustForce = 5000
      self.turnForce = 32000.0
   end
)

Wraith = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("wraith")

      self.body:setMass(750)
      self.thrustForce = 5000
      self.turnForce = 30000.0
   end
)

Maxim = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("maxim")

      self.body:setMass(800)
      self.thrustForce = 5000
      self.turnForce = 26000.0
   end
)



-- Other ships
-- Fighters
LightFighter = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(50)
      self.thrustForce = 550
      self.turnForce = 60000.0
   end
)

HeavyFighter = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(60)
      self.thrustForce = 550
      self.turnForce = 60000.0
   end
)

AssaultFighter = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(65)
      self.thrustForce = 550
      self.turnForce = 60000.0
   end
)

Shuttle = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(60)
      self.thrustForce = 500
      self.turnForce = 60000.0
   end
)

-- Corvettes
BlockadeRunner = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(120)
      self.thrustForce = 800
      self.turnForce = 60000.0
   end
)

CustomsCutter = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(130)
      self.thrustForce = 800
      self.turnForce = 60000.0
   end
)

SmallTransport = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(180)
      self.thrustForce = 800
      self.turnForce = 60000.0
   end
)

-- Frigates
PirateFrigate = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(500)
      self.thrustForce = 3000
      self.turnForce = 60000.0
   end
)

PatrolShip = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(500)
      self.thrustForce = 3000
      self.turnForce = 60000.0
   end
)

LargeTransport = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(800)
      self.thrustForce = 3000
      self.turnForce = 60000.0
   end
)

-- Big shit
Superfreighter = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(5000)
      self.thrustForce = 10000
      self.turnForce = 60000.0
   end
)

QShip = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(3000)
      self.thrustForce = 10000
      self.turnForce = 60000.0
   end
)

AlienShip = oo.inherits(
   Escort, 
   function(self, gs, parentBay)
      Escort.constructor(self, gs, parentBay)
      self.image = resource.getImage("")

      self.body:setMass(2000)
      self.thrustForce = 10000
      self.turnForce = 60000.0
   end
)
