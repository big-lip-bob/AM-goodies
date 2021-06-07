local type,select,setmetatable,newMutex = type,select,setmetatable,newMutex

local event = {
	mutex = newMutex("__EVENT-BOB-GLOBAL"),
	listeners = {}
}
event.__index = event
function event:new(mutex_name)
	return setmetatable({
		mutex = newMutex(mutex_name),
		listeners = {}
	},self)
end

--event.__DEBUG = { listeners = listeners }

local function varags_pack(...) return {n = select('#',...),...} end
local function unpack_helper(t,n,m) if n <= m then return t[n],unpack_helper(t,n+1,m) end end
local function varargs_unpack(t) return unpack_helper(t,1,t.n) end

local function equals(a,b) return a == b end
event.type_tests = {
	table = function(t,k) return t[k] end,
	["function"] = function(f,m,...) return f(m,...) end,
	string = equals,boolean = equals,number = equals,
	["nil"] = function() return true end
}
local function no_such_type_filter(t,o) error(("the type %s has no filter | %s - %s"):format(type(t),tostring(t),tostring(o))) end

function event:remove_listeners(i)
	local listeners = self.listeners
	local l = #listeners
	listeners[l].pos = i
	listeners[i] = listeners[l]
	listeners[l] = nil
end


function event:remove_listeners_mutexed(i)
	self.mutex.lock(); self:remove_listeners(i); self.mutex.unlock()
end

function event:insert_listener(thread,...)
	local filter = varags_pack(...)	
	filter.thread = thread
	local pos = #self.listeners + 1
	self.listeners[pos] = filter
	filter.pos = pos
	
	return filter
end


local get_thread,new_thread = thread.current,thread.new

function event:pull(...)
	local self_thread = get_thread()
	
	self.mutex.lock()
	local filter = self:insert_listener(self_thread,...)
	self.mutex.unlock()

	self_thread.pause()
	-- unpaused by manager here
	
	self:remove_listeners_mutexed(filter.pos)
	
	if filter.args then return varargs_unpack(filter.args) end
end

function event:pull_timed(timeout,...)
	local self_thread = get_thread()

	local to_kill = new_thread(function()
		sleep(timeout*1000) -- seconds, fuck Java
		self_thread.unpause()
	end)
	to_kill.start()

	self.mutex.lock()
	local filter = event:insert_listener(self_thread,...)
	self.mutex.unlock()

	self_thread.pause()
	-- unpaused by manager here

	if to_kill.getStatus() == "running" then --[[to_kill.pause();]] to_kill.stop() end
	self:remove_listeners_mutexed(filter.pos)
	
	if filter.args then return varargs_unpack(filter.args) end	
end

function event:pull_after(after,...)
	self.mutex.lock()
	local filter = self:insert_listener(thread,...)
	after()
	self.mutex.unlock()

	self_thread.pause()
	-- unpaused by manager here
	
	self:remove_listeners_mutexed(filter.pos)
	
	if filter.args then return varargs_unpack(filter.args) end
end

function event:pull_timed_after(timeout,after,...)
	local self_thread = get_thread()

	self.mutex.lock()
	local filter = self:insert_listener(self_thread,...)
	after()
	self.mutex.unlock()
	
	local to_kill = new_thread(function()
		sleep(timeout*1000) -- seconds, fuck Java
		if self_thread.getStatus() == "paused" then self_thread.unpause() end
	end)
	to_kill.start()

	self_thread.pause()
	-- unpaused by manager here

	if to_kill.getStatus() == "running" then --[[to_kill.pause();]] to_kill.stop() end
	self:remove_listeners_mutexed(filter.pos)
	
	if filter.args then return varargs_unpack(filter.args) end	
end

function event:listen(callback,...)
	
	self.mutex.lock()
	local filter = self:insert_listener(nil,...)
	local thread = new_thread(function()
		local thread = get_thread() --or thread
		while true do
			thread.pause()
			-- filter.args CANNOT be nil
			self.mutex.lock()
			callback(varargs_unpack(filter.args))
			filter.args = nil
			self.mutex.unlock()
		end
	end)
	filter.thread = thread
	self.mutex.unlock()

	thread.start()
	
	return filter
end

function event:cancel(subscriber)
	subscriber.thread.stop()
	self:remove_listeners_mutexed(subscriber.pos)
end

function event:test_filters(filter,...)
	for i = 1,filter.n do
		local filter = filter[i]
		local arg = select(i,...)
		if not (self.type_tests[type(filter)] or no_such_type_filter)(filter,arg,...) then return false end
	end
	return true
end

function event:push(...)
	if #self.listeners == 0 then return end
	local args = varags_pack(...) -- could be lazyly init but cba
	self.mutex.lock()
	for i = #self.listeners,1,-1 do
		local filter = self.listeners[i]
		if self:test_filters(filter,...) then
			filter.args = args
			if filter.thread.getStatus() == "paused" then
				filter.thread.unpause()
			elseif self.listeners[i].thread.getStatus() == "dead" then
				self:remove_listeners(i)
			end
		end
	end
	self.mutex.unlock()
end

function event:cleanup()
	self.mutex.lock()
	for i = #self.listeners,1,-1 do
		if self.listeners[i].thread.getStatus() == "dead" then
			self:remove_listeners(i)
		end
	end
	self.mutex.unlock()
end

function event:kill_all()
	self.mutex.lock()
	for i = 1,#self.listeners do
		local thread = self.listeners[i].thread
		if thread.getStatus() ~= "dead" then
			thread.stop()
		end
		self.listeners[i] = nil
	end
	self.mutex.unlock()
end

log("&6[EventHandler] Event Handler set up")

return event