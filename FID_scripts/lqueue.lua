local function _prev(ind, cap)
    if cap then
        return (ind - 2) % cap + 1
    else
        return ind - 1
    end
end
local function _next(ind, cap)
    if cap then
        return ind % cap + 1
    else
        return ind + 1
    end
end

---@class utils.LoopQueue
---@field data table
---@field head integer
---@field tail integer
---@field size integer
---@field capacity integer
local Queue = {}
Queue.__index = Queue

---ctor
---@param capacity integer|nil
---@return utils.LoopQueue
function Queue:new(capacity)
    return setmetatable({
        data = {},
        head = 1,
        tail = 1,
        size = 0,
        capacity = capacity,
    }, Queue)
end

function Queue:push(value)
    if self.capacity and self.size == self.capacity then
        return false
    end
    self.data[self.tail] = value
    self.tail = _next(self.tail, self.capacity)
    self.size = self.size + 1
    return true
end

function Queue:pop()
    if self.size == 0 then
        return nil
    end
    local value = self.data[self.head]
    self.data[self.head] = nil
    self.head = _next(self.head, self.capacity)

    self.size = self.size - 1
    if self.size == 0 and not self.capacity then --reset index
        self.head = 1
        self.tail = 1
    end
    return value
end

function Queue:peek()
    if self.size == 0 then
        return nil
    end
    return self.data[self.head]
end

function Queue:rpush(value)
    if self.capacity and self.size == self.capacity then
        return false
    end
    self.head = _prev(self.head, self.capacity)
    self.data[self.head] = value
    self.size = self.size + 1
    return true
end

function Queue:rpop()
    if self.size == 0 then
        return nil
    end
    self.tail = _prev(self.tail, self.capacity)
    local value = self.data[self.tail]
    self.data[self.tail] = nil
    self.size = self.size - 1
    if self.size == 0 and not self.capacity then
        self.head = 1
        self.tail = 1
    end
    return value
end

function Queue:rpeek()
    if self.size == 0 then
        return nil
    end
    return self.data[_prev(self.tail, self.capacity)]
end

function Queue:empty()
    return self.size == 0
end
function Queue:full()
    return self.capacity and self.size == self.capacity
end

function Queue:items()
    local count = 0
    local size = self.size
    local index = self.head
    local capacity = self.capacity
    local data = self.data

    return function()
        if count >= size then
            return nil
        end
        count = count + 1
        local value = data[index]
        index = _next(index, capacity)

        return value and count or nil, value
    end
end
function Queue:ritems()
    local count = 0
    local size = self.size
    local index = self.tail
    local capacity = self.capacity
    local data = self.data

    return function()
        if count >= size then
            return nil
        end
        count = count + 1
        index = _prev(index, capacity)
        local value = data[index]

        return value and count or nil, value
    end
end

return setmetatable(Queue,{
    __call = function (t, capacity)
        return t:new(capacity)
    end
})