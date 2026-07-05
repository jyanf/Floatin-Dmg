local relative = ... and (...):gsub("Toggler$", "") or ""
local HotKey= 0x42	--F8
local Tg = {
    display = false,
}
---@param scene guilib.Scene
function Tg.constructor(scene)
    local new = {
        scene=scene,
        keydown = false,
    }
    function new:enabled()
        return self.scene.renderer.isActive
    end
    function new:checker()
        local lastk = self.keydown
        self.keydown = memory.readbytes(0x8a01b8 + HotKey, 1)=="\x80"--soku.checkFKey(HotKey)
        if(self.keydown and lastk==false) then
            return true
        end
        return false
    end
    function new:switcher()
        self.scene.renderer.isActive = not self.scene.renderer.isActive
        Tg.display = self.scene.renderer.isActive
    end
    function new:disable()
        --db.display = false
        self.scene.renderer.isActive = false
    end
    scene.renderer.isActive = Tg.display
    return new
end

return setmetatable(Tg, {
	__call= function(t, ...)
		return t.constructor(...)
	end,
})