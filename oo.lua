oo = {}

function oo.newClass(constructor)
   local class = {}
   local class_mt = {
      __index = class,
      __tostring = function(self)
		      if self.tostring then
			 return self:tostring()
		      else
			 return "Object"
		      end
		   end
   }
   
   class.constructor = constructor
   
   -- Create a new instance of A just by calling 'a = A{ ... }'
   local mt = {
      __call = function(self, ...)
		  local obj = {}
		  setmetatable(obj, class_mt)
		  self.constructor(obj, ...)
		  return obj
	       end,
      __tostring = function(self) return "Class" end
      
   }
   setmetatable(class, mt)
   
   return class
end

function oo.inherits(baseClass, constructor)
   local newclass = {}
   local class_mt = {__index = newclass}
   newclass.constructor = constructor
   
   --function newclass.create()
   --	local inst = {}
   --	setmetatable(inst, class_mt)
   --	return inst
   --end
   
   local mt = {
      __call = function(self, ...)
		  local obj = {}
		  setmetatable(obj, class_mt)
		  self.constructor(obj, ...)
		  return obj
	       end,
      __tostring = function() return "Class" end
   }
   if baseClass then
      mt.__index = baseClass
   end
   setmetatable(newclass, mt)
   
   return newclass
end
