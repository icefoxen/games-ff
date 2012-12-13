-- A set that cannot contain duplicate items

set = {}

function set.contains(s, itm)
   return s[itm]
end

function set.add(s, itm)
   s[itm] = true
end


function set.remove(s, itm)
   s[itm] = nil
end

function set.addTable(s, itms)
   for o, _ in pairs(itms) do
      set.add(s, o)
   end
end

function set.iter(s, fun)
   for o, _ in pairs(s) do
      --print(o)
      fun(o)
   end
end

function set.count(s)
   local i = 0
   for o, _ in pairs(s) do
      i = i + 1
   end
   return i
end

-- Bwahahahahaha
function set.isEmpty(s)
   for o, _ in pairs(s) do
      return false
   end
   return true
end

function set.addSet(s1, s2)
   set.iter(s2,
	    function(itm)
	       set.add(s1, itm)
	    end
	 )
end

function set.toTable(s)
   local i = {}
   set.iter(s,
	    function(itm)
	       table.append(i, itm)
	    end
	 )
   return i
end

function set.tostring(s)
   local accm = {"Set {"}
   set.iter(
      s,
      function(itm)
	 table.insert(accm, tostring(itm))
      end
   )
   table.insert(accm, "}")
   return table.concat(accm, " ")
end

local setMT = {
   __tostring = set.tostring
}

function set.new()
   local s = {}
   setmetatable(s, setMT)
   return s
end



-- XXX: Needs an iterator...
-- Or a metamethod. __pairs