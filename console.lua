-- Noodling around with a debug console...
require("oo")

Console = oo.newClass(
   function(self)
      self.scrollback = {}
      self.maxScrollback = 20
      self.width = 80
      self.inputBuffer = {}
   end
)

function Console:addOutput(string, prefix)
   if not prefix then
      prefix = ""
   end
   local len = #string
   local counted = 1
   local prefixlen = #prefix
   local chunksize = self.width - prefixlen
   while counted < len do
      local s = prefix .. string.sub(string, counted, counted + chunksize)
      table.insert(self.scrollback, s)
      counted = counted + chunksize
   end
   self:limitScrollback()
end

-- Slow, but effective.
function Console:limitScrollback()
   while #self.scrollback > self.maxScrollback do
      table.remove(self.scrollback, 1)
   end
end


function Console:exec(string)
   local thunk, error = loadstring(string)
   if not thunk then
      self:addOutput(error, "Error> ")
   else
      local succeeded, results = pcall(thunk)
      if succeeded then
	 self:addOutput(tostring(results), "> ")
      else
	 self:addOutput(tostring(results), "Error> ")
      end
   end
end



function Console:execString(string)
   self:addOutput(string, "< ")
   self:exec(string)
end

function Console:addInput(str)
   table.insert(self.inputBuffer, str)
end

function Console:deleteLastInputChar()
   table.remove(self.inputBuffer)
end

function Console:inputToString()
   return table.concat(self.inputBuffer)
end

function Console:clearInput()
   self.inputBuffer = {}
end

function Console:execInput()
   local str = self:inputToString()
   self:execString(str)
end

function Console:dump()
   for _, j in ipairs(self.scrollback) do
      print(j)
   end
   print("Input buffer: ", self:inputToString())
end