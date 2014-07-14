local _M = {}
local mt = { __index = _M }

function _M.new()
  return setmetatable({ t = {} }, mt)
end

function _M.push(self, item)
  table.insert(self.t, item)
end

function _M.pop(self)
  return table.remove(self.t)
end

function _M.peek(self)
  return self.t[#self.t]
end

return _M
