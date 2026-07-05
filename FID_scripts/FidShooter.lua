-- local relative = ... and (...):gsub(".init$", "").."." or ""
local relative = ... and (...):gsub("FidShooter$", "") or ""

local G_BATTLE_COUNTER = 0x8985d8

-- local Capacity = 5
local MaxLife = 120
local function anim_init(np, t0)
	np.ox = 0; np.oy = 0
	np.color = 0xFFFFFFFF
end
local function anim_onproc(np, t)
	--pos
	local ox,oy = 0,0
	oy = oy + -3*t 

	np.ox = ox; np.oy = oy;
	--opa
	local o = math.max(0, math.floor((1-t/50)*0xFF));
	np.color = ((np.color & 0xFFFFFF) + (o<<24));

	return false
end


---@module 'NumberProxy'
local Np = require(relative.."NumberProxy")

---@module 'lqueue'
local Bq = require(relative.."lqueue")

local Fs = {}

---@param objs guilib.DesignObject[]
function Fs.constructor(objs, ainit, aproc)
	local new = {
		---
		qidle = nil, qused = nil,
		gtimer = -1,
		maxlife = MaxLife,
		---
		anim_init = ainit or anim_init,
		anim_onproc = aproc or anim_onproc,
	}
	---[[load buffer numbers
	local Capacity = #objs
	new.qidle = Bq:new(Capacity)
	new.qused = Bq:new(Capacity)
	for k, v in ipairs(objs) do
		new.qidle:push(Np(v))
	end
	function new:qpush(direction)
		local pop = direction and Bq.rpop or Bq.pop
		local push = direction and Bq.rpush or Bq.push
		local np = pop(new.qidle)
		if not np then -- renew old ones 
			np = pop(new.qused)
		end
		if np then
			push(new.qused, np)
		end
		return np
	end
	function new:qpop(direction)
		local pop = direction and Bq.rpop or Bq.pop
		local push = direction and Bq.rpush or Bq.push
		local np = pop(new.qused)
		if np then
			push(new.qidle, np)
		end
		return np
	end
	--]]
	---[[anim
	function new:GenInd(x, y, dmg)
		local ind = self:qpush()
		if not ind then return end
		ind._t0 = self.gtimer;
		self.anim_init(ind, self.gtimer)
		ind:setPos(x,y)
		ind.value = dmg
		ind.isActive = true
	end
	function new:updater()
		local timer = self.gtimer
		self.gtimer = memory.readint(G_BATTLE_COUNTER)--thanks hagb~~
		if self.gtimer<timer then -- rollbacked
			--clear?
			for k,np in self.qused:ritems() do
				local t = self.gtimer - np._t0
				if t<0 or t>self.maxlife or self.anim_onproc(np, t) then
					self:qpop(true).isActive = false
				end
			end
		elseif self.gtimer>timer then -- advanced
			for k,np in self.qused:items() do
				local t = self.gtimer - np._t0
				if t<0 or t>self.maxlife or self.anim_onproc(np, t) then
					self:qpop().isActive = false
				end
			end
		else -- paused
			-- return nil
		end
		return self.gtimer-timer
	end
	--]]

	return new
end
return setmetatable(Fs, {
	__call= function(t, ...)
		return t.constructor(...)
	end,
})