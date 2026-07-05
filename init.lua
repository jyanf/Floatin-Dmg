---@module 'Toggler'
local Tg = require("FID_scripts.Toggler")

---@module 'FidShooter'
local Fs = require("FID_scripts.FidShooter")

-- local layout = relative:gsub("%.", "/").."fids.xml"
local layout = "FID_scripts/fidsB.xml"

local iota = function (a1, a2, cb, cbd)
	cb = cb or function (i) return i end
	local ret = {}
	for i=a1,a2,1 do
		table.insert(ret, cb(i, cbd))
	end
	return ret
end
local function clamp(x, l1,l2)
	local max, min = l1>l2 and l1 or l2, l1>l2 and l2 or l1
	return math.min(max, math.max(min, x))
end
---b  _
--  _/    u
---a
local function lerp(a,b,u)
	u = clamp(u, 0,1)
	return a + (b-a)*u
end
---b  |
--  0/1   x
---a|  
local function invlerp(a, x, b)
	return clamp((x - a) / (b - a), 0, 1)
end
local function stageToScreen(pos, edges)
	local W, H = 640, 480
	local x = invlerp(edges[1], pos.x, edges[3]) * W
	local y = invlerp(edges[2], pos.y, edges[4]) * H
	x = clamp(x, 80, W-60)
	y = clamp(y, 80, H-60)
	return soku.Vector2f(x, y)
end

local anim_para = {
	maxlife = 60,-- 总时长（帧）
    fadeBegin = 45,-- 最后多少帧开始淡出

	distance = 40,-- 扩散距离
	drift = 30,--上浮距离
    ease = 4,-- 
    spread = 0.9,-- 角度变化范围
	GOLDEN_ANGLE = 2.39996, --137.507°,
	GOLDEN_RATIO = 0.61803,
}
local myanim_init = function (np,t0)
    np.ox = 0; np.oy = 0
    np.color = 0xffffffff
	local GDA, DIST, RG = anim_para.GOLDEN_ANGLE, anim_para.distance, anim_para.spread
	--
	local a = (t0 * GDA) % (math.pi*2)
    a = a - math.pi/2 -- 主方向朝上
    a = -math.pi/2 + math.sin(a) * RG * math.pi -- 压缩成上半圆附近
	local GOLDEN_RATIO = anim_para.GOLDEN_RATIO
	local r = DIST * math.sqrt((t0 * GOLDEN_RATIO) % 1.0 + 0.5)
	np.dx = math.cos(a) * r
	np.dy = math.sin(a) * r
end
local myanim_proc = function (np,t)
	local LIFE, FADE_BEGIN, EASE = anim_para.maxlife, anim_para.fadeBegin, anim_para.ease
	local u = invlerp(0, t, LIFE)
    local k = 1.0 - (1.0 - u)^EASE
	
    local ox = np.dx * k
    local oy = np.dy * k
	local DRIFT = anim_para.drift
	oy = oy - DRIFT * u
    np.ox = ox; np.oy = oy

    local alpha
    if t < FADE_BEGIN then
        alpha = 0xFF
    else
        local f = invlerp(FADE_BEGIN, t, LIFE)
        alpha = math.floor(255 * (1.0 - f)^EASE)
    end

    np.color = (np.color & 0xFFFFFF) | (alpha << 24)
    return t > LIFE
end

soku.SubscribeSceneChange(function(newsId, scene)
	if(newsId~=soku.Scene.Battle) then return end
	scene.data["toggler"]=Tg(scene)
	scene.renderer.design:loadResource(layout)

	local src1= iota(1,20, function(i, cbd) return cbd:getItemById(i) end, scene.renderer.design)
	local src2= iota(101,120, function(i, cbd) return cbd:getItemById(i) end, scene.renderer.design)
	local src3= iota(201,220, function(i, cbd) return cbd:getItemById(i) end, scene.renderer.design)
	local fids = {}
	local chip = Fs(src1, myanim_init, myanim_proc)
	fids[chip] = function (fid, data)
		if fid:updater()>0 and data.dHPs then
			for i,v in ipairs(data.dHPs) do
				if v<0 and data.redHPs[i]==data.HPs[i] then
					fid:GenInd(data.pos[i].x, data.pos[i].y, v)
				end
			end
		end
	end
	local dmgs = Fs(src2, myanim_init, myanim_proc)
	-- dmgs.maxlife = 90
	-- shoot out common dmg
	fids[dmgs] = function (fid, data)
		--[[ gen test
		if fid:updater()>0 then
			if fid.gtimer%5==0 then
				fid:GenInd(240, 240, fid.gtimer//5)
			end
		end
		--]]
		if fid:updater()>0 and data.dHPs then
			for i,v in ipairs(data.dHPs) do
				if v<0 and data.redHPs[i]~=data.HPs[i] then
					fid:GenInd(data.pos[i].x, data.pos[i].y, v)
				end
			end
		end
	end
	local heal = Fs(src3, nil, nil)
	fids[heal] = function (fid, data)
		if fid:updater()>0 and data.dHPs then
			for i,v in ipairs(data.dHPs) do
				if v>0 and data.redHPs[i]==data.HPs[i] then
					fid:GenInd(data.pos[i].x, data.pos[i].y, v)
				end
			end
		end
	end


	scene.data["fids"]=fids
	return function(s)
		local dat = s.data
		local tg = dat["toggler"]
		--[[
		local state = battle.manager.matchState
		-- local p1, p2 = battle.manager.player1, battle.manager.player2			
		if(state==6 and battle.manager.frameCount==0) then
			tg:disable()
		end
		--]]
			
		if tg:checker() then
			tg:switcher()
		end
		local fids = dat["fids"]

		local p1, p2 = battle.manager.player1, battle.manager.player2
		local redHPs = {
			memory.readshort(p1.ptr+0x498),
			memory.readshort(p2.ptr+0x498)
		}
		local HPs = { p1.hp, p2.hp, }
		if dat.HPs then
			dat.dHPs = {
				HPs[1]-dat.HPs[1],
				HPs[2]-dat.HPs[2],
			}
		end
		dat.HPs = HPs; dat.redHPs = redHPs
		local edges = { memory.readfloat(0x89865c), memory.readfloat(0x898660), memory.readfloat(0x898664), memory.readfloat(0x898668) } --←,↑,→,↓
		dat.pos = {
			stageToScreen(p1.position+soku.Vector2f(0,100), edges), 
			stageToScreen(p2.position+soku.Vector2f(0,100), edges)
		}
		if tg:enabled() then
			for fid, handler in pairs(fids) do
				if handler then
					handler(fid, dat)
				end
			end
		end
		-- return -1
	end
	
end)