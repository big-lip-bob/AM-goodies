local event = require("EventSplitter")

local function safe_get(t,k,...)
	if t then
		if k then
			return safe_get(t[k],...)
		else
			return t
		end
	else
		return t
	end
end

if __SAFE_GAIA_TRACER then
	event:cancel(__SAFE_GAIA_TRACER)
	event:cancel(__SAFE_GAIA_CLICKER)
	__SAFE_GAIA_CLICKER = nil
	__SAFE_GAIA_TRACER = nil
	hud3D.clearAll()
else
	local raytrace,rawGet,getPos,hudBlock,getBlock = rayTrace,rawGet,getPlayerBlockPos,hud3D.newBlock,getBlock
	local tested_blocks = setmetatable({},{__index = function(self,key) self[key] = {}; return self[key] end})
	local falling_blocks = {["minecraft:gravel"]=true,["minecraft:sand"]=true,["minecraft:concrete_powder"]=true}
	local fluid = {["minecraft:water"]=true,["minecraft:flowing_water"]=true}

	local function test_safety(block)
		if not block then return log("BLOCK CANNOT BE NIL: FATAL") end
		local pos = block.pos
		local bx,by,bz = pos[1],pos[2],pos[3]
		local px,py,pz = getPos()
		if by >= py and not tested_blocks[bx][bz] and falling_blocks[safe_get(getBlock(bx,by+1,bz),"id")] then
			local cy = by+1
			local last_id
			repeat
				cy = cy + 1
				last_id = safe_get(getBlock(bx,cy,bz),"id")
			until not falling_blocks[last_id]
			if fluid[last_id] then
				local block = hudBlock(bx,py,bz)
				block.setColor(0xCC0000)
				block.setOpacity(1)
				--block.xray(true)
				block.enableDraw()
				
				local block = hudBlock(bx,cy,bz)
				block.setColor(0xFCEE4B)
				block.setOpacity(1)
				block.xray(true)
				block.enableDraw()
			end
			tested_blocks[bx][bz] = true
		end
	end
	
	__SAFE_GAIA_TRACER = event:listen(function(_,block) -- block sound not be nil
		if not block then return log("BLOCK CANNOT POSSIBLY BE NIL, CHECK THE RAYTRACING DISTANCE") end
		test_safety(block)
	end,"LookAtBlock")
	
	__SAFE_GAIA_CLICKER = event:listen(function()
		local block = raytrace(4.5)
		if not block then return end
		test_safety(block)
	end,"mouse","LMB","down")
end

log("Gaia Sand Gravel Checker is "..(__SAFE_GAIA_TRACER and "on" or "off"))