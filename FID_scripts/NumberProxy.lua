local np = {}
local function splitDigits(val)
	val = math.abs(math.floor(val))
	local digits = {}
	while val>0 do
		table.insert(digits, 1, val%10)
		val = val//10
	end
	if #digits==0 then
		digits[1]=0
	end
	return #digits, digits
end
---@class NumberProxy
---@field x number
---@field y number
---@field color integer
---@field value number

---@param obj guilib.DesignObject
---@param refiner_cb function
---@return NumberProxy
function np.ctor(obj, refiner_cb)
	-- if type(obj)~="userdata" then return end
	local inst = {
		vhandle=nil,
        object=obj,

		_x=obj.x,
        _y=obj.y,
		_color=0x00FFFFFF,
		ox=0, oy=0,
        refiner = refiner_cb,
	}
	function inst:refresh()
        if self.refiner then
            self:refiner()
        end
		self.object.x = self.ox + self._x
        self.object.y = self.oy + self._y

		self.object:setColor(self._color)
	end
    function inst:setPos(x, y)
        if x then
            self._x = x
        end
        if y then
            self._y = y
        end
        self:refresh()
    end
	function inst:setVal(val)
		if not self.vhandle then
            self.vhandle = self.object:getValueControl()
        end
        self.vhandle.number = val
		self:refresh()
	end
	function inst:setActive(val)
        if val and not self.vhandle then
            self:setVal(0)
        end
        self.object.isActive = val
		self:refresh()
	end
	function inst:setColor(val)
		self._color = val
		self:refresh()
	end
	
	return setmetatable(inst, {
		__index= function(t, key)
			if key=="isActive" then
				return t.object.isActive
			elseif key=="x" then
                return t._x
			elseif key=="y" then
                return t._y
			elseif key=="color" then
				return t._color
			elseif key=="value" then
                return t.vhandle and t.vhandle.number or nil
			else
				return rawget(t, key) -- public
            end
		end,
		__newindex= function(t, key, val)
			if key=="isActive" then
				t:setActive(val)
			elseif key=="x" then
				t:setPos(val, nil)
			elseif key=="y" then
				t:setPos(nil, val)
			elseif key=="color" then
				t:setColor(val)
			elseif key=="value" then
				t:setVal(val)
			else
				rawset(t, key, val) -- public
			end
		end,
	})
end


return setmetatable(np, {
	__call= function(t, obj)
		return t.ctor(obj)
	end,
	
})