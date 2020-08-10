if Tunneling then
	Tunneling.stop()
	Tunneling = nil
	attack(1)
	return log("Tunneler has been deactivated")
else
	Tunneling = thread.current()
	log("Tunneler has been activated")
end

local drc = require("direction")

local direction = drc.clamp()
local isZ,isN = drc.isZisN(direction)
local inv = openInventory() -- returns the handlers (doesn't open inv)
local lookAt,forward,look,getBlock,getPos,getBlockPos,getSlot,AbRe,setHotbar,use,waitTick,shift_click,attack,sleep,swapHand,sleep,type,faceTo,close,floor,open,path,date = lookAt,forward,look,getBlock,getPlayerPos,getPlayerBlockPos,inv.getSlot,drc.absolute_relative,setHotbar,use,waitTick,inv.quick,attack,sleep,swapHand,sleep,type,drc.faceTo,inv.close,floor,io.open,(filesystem.getMacrosAddress().."\\LootChests.txt"),os.date
do local x,y,z = getBlockPos(); require("MovPacket")(x+.5,y,z+.5) end
local function waitTicks(n) for i = 1,n or 1 do waitTick() end end
local function acces_helper(t,a,...) if type(t) == "table" and t[a] then return acces_helper(t[a],...) else return t end end
local liquids = {["minecraft:lava"]=true,["minecraft:water"]=true,["minecraft:cobweb"]=true}
local function breakCheck(block)
	if block then
		if not block.id:find("air") then
			if not liquids[block.id] then
				return true
			end
		end
	end
end
local swapHandBlocks = {["minecraft:gravel"]=true,["minecraft:dirt"]=true}
local sleeptime = 10 -- ms
local function breakBlock(x,y,z)
	lookAt(x+.5,y+.5,z+.5)
	local swap -- swap if the block were mining requires so
	if swapHandBlocks[getBlock(x,y,z).id] then swap = true; swapHand() end

	while breakCheck(getBlock(x,y,z)) do
		attack(sleeptime*2)
		sleep(sleeptime)
	end

	if swap then swapHand() end
end
while true do -- its getting stopped anyways
	-- get coords
	local bx,by,bz = getBlockPos() -- (needed for most routines)
	--#log("got pos")
	
	-- detect liquids, pesky shit
	for dz = -2,2 do for dy = -2,2 do for dx = 2,3 do
		if liquids[acces_helper(getBlock(AbRe(isZ,isN,bx,by+1,bz,dx,dy,dz)),"id")] then
			-- liquids are scary, abort
			playSound("doot.wav").loop(3-1) log("&6Liquids ew") Tunneling = false; return
		end
	end end end
	--#log("no liquids")
			
	-- check for a free item slot
	local invFree
	for i = 35,9,-1 do
		if not getSlot(i) then invFree = true break end
	end
	-- check if the inventory has space
	if not invFree then -- if not
		-- check if the player has a chest
		local hasChest
		for i = 36,44 do
			local item = getSlot(i)
			if item and item.id == "minecraft:chest" then
				hasChest = true
				local cx,cy,cz = AbRe(isZ,isN,bx+.5,by,bz+.5,-2,0,0)
				lookAt(cx,cy,cz)
				setHotbar(i-35) -- (1-9)
				use(1) -- place the chest
				waitTicks(10) -- TODO : use EventHandler -- event.pull("GUIOpened","minecraft:chest") or wahtever
				use(1) -- open it
				waitTicks(10)
				for i = 1+27,27+27 do
					shift_click(i) -- quickly deposit in chest
					waitTicks(2)
				end
				local file = open(path,"a")
				if file then
				file.write(("%d-%d-%d | %s\n"):format(floor(cx),floor(cy),floor(cz),date("%x %X")))
				file.close()
				else playSound("PINGAS.wav").loop(3-1) log("&4Could log the chest location") Tunneling = false; return end
				waitTicks(10)
				close()
				waitTicks(10)
			end
		end
		if not hasChest then -- if the inv is full and there's no chest to dump it, stop and report trough pingases
			playSound("PINGAS.wav").loop(3-1) log("&4No more inv space") Tunneling = false; return
		end
	end
	--#log("inv is free")
	
	-- recalibrate facing direction
	faceTo(direction)
	
	-- select the pickaxe (should be done in breakblock ultimately but who cares)
	local hasPick
	for i = 36,44 do
		local item = getSlot(i)
		if item and item.id:find("pickaxe") then
			setHotbar(i-36); hasPick = true; break
		end
	end
	if not hasPick then playSound("PINGAS.wav").loop(3-1) log("&aNo Pickaxe") Tunneling = false; return end
	--#log("got pick")
	
	-- check the blocks in front
	for mz = -1,1 do for my = 2,0,-1 do
		local tx,ty,tz = AbRe(isZ,isN,bx,by,bz,2,my,mz)
		if breakCheck(getBlock(tx,ty,tz)) then
			--local b = hud3D.newBlock();b.setPos(tx,ty,tz);b.enableDraw()
			breakBlock(tx,ty,tz)
			--b.disableDraw();b.destroy()
		end
	end end
	--#log("got all blocks mined")
	
	-- recalibrate facing direction
	faceTo(direction)
	
	-- check the blocks under for safety
	for mz = -1,1 do
		if not breakCheck(getBlock(AbRe(isZ,isN,bx,by,bz,2,-1,mz))) then playSound("PINGAS.wav").loop(1-1) log("&cUnsafe walking space") Tunneling = false; return end
	end
	--#log("safe path")
	
	local goal = (isZ and bz or bx) + .5 + (isN and -1 or 1)
	forward(-1)
	repeat
		local x,y,z = getPos()
		local tracked = isZ and z or x
	until (isN and goal < tracked or goal > tracked)
	forward(1)
	
end