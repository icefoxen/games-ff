-- Has various utility functions, as well as some global 
-- values and constants and such.

WIDTH = 800
HEIGHT = 600

TWOPI = math.pi * 2
PIOVERTWO = math.pi / 2
PIOVERFOUR = math.pi / 4

function enum(x)
   local t = {}
   for i,j in pairs(x) do
      t[j] = i
   end
   return t
end

-- Collision categories
COLL = enum{
   "Ship",
   "Shot",
   "Missile",
}

local INDEX = 0
function getIndex()
   INDEX = INDEX + 1
   return INDEX
end


-- Team enums
TEAM = enum{
   "Player",
   "Enemy1",
}

ALIGNMENT = enum{
   "Player",
   "Ally",
   "Neutral",
   "Enemy"
}

-- Z ordering constants.  Higher values cover lower ones.
ZORDER = enum{
   "Background",
   "Misc",
   "Shot",
   "Escort",
   "Carrier",
}



CAMMODE = enum{
   "Fixed",
   "Follow",
   "Pan"
}

-- We can follow multiple objects by getting the average
-- coordinates of them.
function getAverageCoords(objs)
   --print(self.followObjs, type(self.followObjs))
   local x, y = 0, 0
   -- Fuck me with a rake, you can't GET the size of 
   -- a non-array table out of Lua.
   -- At least we have closures, I guess?
   local objcount = 0

   set.iter(
      objs, 
      function(o)
	 -- This check probably _shouldn't_ be necessary, but...
	 objcount = objcount + 1
	 local ox, oy = o:getCoords()
	 x = x + ox
	 y = y + oy

      end
   )

   if objcount == 0 then
      return 0, 0
   end

   x = x / objcount
   y = y / objcount
   --print("Average coords: ", x, y)
   return x, y
end

-- A binary search that returns the array index of
-- the item, or nil for not found.
-- Dragon code.  *_*
function binsearch(list, elt)                                           
   local a, b = 1, #list                                                
   while a <= b do                                                      
      local mid = math.floor((a + b) / 2)                               
      local probe = list[mid]                                           
      if probe == elt then return mid                                   
      elseif probe < elt then a = mid + 1                               
      else b = mid - 1                                                  
      end                                                               
   end
   return nil
end       

function angleBetweenVectors(x1, y1, x2, y2)
   local separation = math.atan2(y1, x1) - math.atan2(y2, x2)
   if separation < -math.pi then
      separation = separation + TWOPI
   elseif separation > math.pi then
      separation = separation - TWOPI
   end
   return separation
end

function vectorToAngle(x, y)
   return math.atan2(y, x)
end

function angleToVector(angle)
   local x = math.cos(angle)
   local y = math.sin(angle)
   return x, y
end

-- Returns true if the two vectors are within distance d of each other
function vectorsWithin(d, x1, y1, x2, y2)
   local dx, dy = vec.sub(x1, y1, x2, y2)
   local d2 = d * d
   local l2 = vec.len2(dx, dy)
   return d2 >= l2
end

function dump(table)
   for i,j in pairs(table) do
      print(i, "=", j)
   end
end