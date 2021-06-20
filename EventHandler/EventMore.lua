local event = require("EventSplitter")

local new_thread = thread.new
-- Setup Tick and Frame Events
local isBaritone = false
if isBaritone then
	-- also adds Chunk Events and other Baritone specific Events
	require("EventBaritone")
else
	local waitTick,runOnMC,void = waitTick,runOnMC,function() end
	new_thread(function() while true do runOnMC(void) event:push("Frame") end end).start()
	new_thread(function() while true do waitTick()    event:push("Tick")  end end).start()
end

local abs = math.abs
local epsilon = 0.001
local function floateaeps(f,...)
	if f then
		return abs(f) < epsilon and floateaeps(...)
	else return true end
end
local function intzero(i,...)
	if i then
		return i == 0 and intzero(...)
	else return true end
end

do
	
	local getPitchYaw
	-- Setup Look, Move and MoveBlock Events
	if __GAME_VERSION == "1.12.2" then
		-- thread safe variant without risk of crashing
		local minecraft = luajava.bindClass("com.theincgi.advancedMacros.AdvancedMacros"):getMinecraft()
		function getPitchYaw()
			-- field_71439_g player
			-- func_189653_aC getPitchYaw -> Vec2f
			-- (field_189982_i,field_189983_j) (x,y)
			local vec2 = minecraft.field_71439_g:func_189653_aC()
			return vec2.field_189982_i,vec2.field_189983_j
		end
	else
		local getPlayer,runOnMC = getPlayer,runOnMC
		function getPitchYaw()
			local player = runOnMC(getPlayer) -- If not sync, then concurency crash
			return player.pitch,player.yaw
		end
	end

	_G.getPitchYaw = getPitchYaw

	local op,oy = getPitchYaw()
	new_thread(function() while true do
		event:pull("Frame")
		local cp,cy = getPitchYaw()
		local dp,dy = cp-op,cy-oy
		if not floateaeps(dp,dy) then
			event:push("Look", cp,cy, dp,dy)
		end
		op,oy = cp,cy
	end end).start()
	
	local ox,oy,oz = 0/0,0/0,0/0 -- Yes
	new_thread(function() while true do
		event:pull("Frame") -- Has to be bound to frame, not look, no guarantee block in front doesn;t diseapear / apear
		local block = rayTrace(4.5)
		if block then
			local pos = block.pos
			local cx,cy,cz = pos[1],pos[2],pos[3]
			local dx,dy,dz = cx-ox,cy-oy,cz-oz
			if intzero(dx,dy,dz) then
				event:push("LookAtBlock", block, ox,oy,oz)
			end
			ox,oy,oz = cx,cy,cz
		end
	end end).start()

end


do
	local function registerPos(getPos,cmpfn,name)
		local ox,oy,oz = getPos()
		new_thread(function() while true do
			event:pull("Frame")
			local cx,cy,cz = getPos()
			local dx,dy,dz = cx-ox,cy-oy,cz-oz
			if not cmpfn(dx,dy,dz) then
				event:push(name, cx,cy,cz, dx,dy,dz)
			end
			ox,oy,oz = cx,cy,cz
		end end).start()
	end
	registerPos(getPlayerPos,floateaeps,"Move") registerPos(getPlayerBlockPos,intzero,"MoveBlock")
end

return { override_event = function(new_event) event = new_event end }