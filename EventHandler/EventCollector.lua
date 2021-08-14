local type, select, setmetatable = type, select, setmetatable
local getThread, newThread = thread.current, thread.new -- revamp this too at some point

local timer = require("timer")

local newInstance = luajava.newInstance
--local newAtomicBool = function(init) newInstance("java.util.concurrent.atomic.AtomicBoolean", init) end -- https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/atomic/AtomicBoolean.html
local newAtomicLong = function(init) return newInstance("java.util.concurrent.atomic.AtomicLong", init) end -- https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/atomic/AtomicLong.html
local newWeakRef = function(value) return newInstance("java.lang.ref.WeakReference", init) end -- https://docs.oracle.com/javase/8/docs/api/java/lang/ref/WeakReference.html

local function newInit(self, ...)
	local new = setmetatable({}, self)
	self.init(new, ...)
	return new
end

local event = { new = newInit } -- head
event.__index = event

local function garbage_collector(reference)
	return function()
		local self = getThread()
		while true do
			self.pause() -- unpaused by a notify
			local last_alive, next = reference, reference.head
			while next do
				if next:isWhite() then
					last_alive, next = next, next.head
				else
					next = next.head
					while next and not next:isWhite() do next = next.head end
					last_alive.head, last_alive = next, next
				end
			end
		end
	end
end

function event:init()
	-- self.head_index = nil
	local thread = newThread(garbage_collector(self))
	self.collector = thread
	thread.start()
end
event:init() -- make so the class is an instance by initing uppon itself

function event:collect()
	if self.collector.getStatus() ~= "paused" then return end
	self.collector.unpause()
end

local function varags_packer(...) return { n = select('#', ...), ... } end
local function varargs_unpacker_inner(t, n, m) if n <= m then return t[n], varargs_unpacker_inner(t, n+1, m) end end
local function varargs_unpacker(t) return varargs_unpacker_inner(t, 1, t.n) end

local function equals(a, b) return a == b end
event.type_tests = { -- global to all handlers by defualt
	table = function(t, k) return t[k] end,
	["function"] = function(f, m, ...) return f(m, ...) end,
	string = equals, boolean = equals, number = equals,
	["nil"] = function() return true end
}

local function no_such_type_filter(t, o) error(("the type %s has no filter | %s - %s"):format(type(t), tostring(t), tostring(o))) end

-- this whole idea revolves around the fact that table references are atomic, fuck LuaJ if they're not

-- once nodes die they cannot come back to life
local nodeBase = { new = newInit }
nodeBase.__index = nodeBase
function nodeBase:init(...)
	-- self.queue = {} -- willl reuse the same table, numeric indices are unused so that'll be put to use
	self.tail_index = newAtomicLong(0) -- made it thread friendly huh
	self.head_index = newAtomicLong(0)
	
	self.filters = varags_packer(...)
end
function nodeBase:isWhite() return error("this method shouldn't be accesible!!!") and true end
function nodeBase:isBlack() return not self:isWhite() end
function nodeBase:push(args) self[self.head_index:incrementAndGet()] = args end
function nodeBase:pop()
	-- if not self:canPop() then error("no element to pop") -- not concurency safe
	local index = self.tail_index:incrementAndGet() -- unique
	local args = self[index] or error("cannot possibly be nil") -- the thread will be unpaused when the head will be set so it doesnt matter
	self[index] = nil
	return args
end
function nodeBase:canPop() return self.tail_index:get() < self.head_index:get() end
local function markGray() return false end -- not true, replaces node.isWhite call and calls cleaner uppon them nodes
function nodeBase:markGray() node.isWhite = markGray end
function nodeBase:next() return self.head:get() end

local nodeChecked = setmetatable({ new = newInit }, nodeBase)
nodeChecked.__index = nodeChecked
function nodeChecked:init(...)
	nodeBase.init(self, ...)
	self.alive = true
end
function nodeChecked:isWhite() return self.alive end -- no need for atomicity
function nodeChecked:canPop() return self:isWhite() and self.tail_index:get() < self.head_index:get() end

local nodeNTimes = setmetatable({ new = newInit }, nodeBase)
nodeNTimes.__index = nodeNTimes
function nodeNTimes:init(n, ...)
	nodeBase.init(self, ...)
	self.limit = n
end
function nodeNTimes:isWhite() return self.head_index:get() < self.limit end

local nodeOnce = function(...) return nodeNTimes:new(1, ...) end

function event.insert_node_front(into, node)
	-- order matters, A LOT so i wont risk the a, b = b, a syntax
	node.head = newWeakRef(into.head)
	into.head = node
end

function event:pull(...)
	
	local node = nodeOnce(...)
	local thread = getThread()
	node.thread = thread

	self:insert_node_front(node)
	if node.tail:get() == 0 then thread.pause() end -- not yet to be unpaused
	
	-- unpaused by pushers
	
	return varargs_unpacker(node[1] or error("puller's result cannot remain empty"))
end

function event:pull_timed(duration, ...)	
	
	local node = nodeOnce(...)
	local thread = getThread()
	node.thread = thread

	self:insert_node_front(node)
	local handle = timer:after(duration, thread.unpause)
	if node.tail:get() == 0 then thread.pause() end -- extremly rare concurency issue
	-- unpaused by pusher
	
	handle:cancel()
	
	if filter.args then return varargs_unpacker(node[1] or error("puller's result cannot remain empty")) end	
end

function event:pull_after(after, ...)
	
	local node = nodeOnce()
	local thread = getThread()
	node.thread = thread

	self:insert_node_front(node)
	if node.tail:get() == 0 then thread.pause() end -- not yet to be unpaused
	
	-- unpaused by pushers
	
	return varargs_unpacker(node[1] or error("puller's result cannot remain empty"))
end

function event:pull_timed_after(duration, after, ...)
	
	local node = nodeOnce()
	local thread = getThread()
	node.thread = thread

	self:insert_node_front(node)
	local handle = timer:after(duration, thread.unpause)
	after() -- dont make this take obnoxiously long
	if node.tail:get() == 0 then thread.pause() end -- not yet to be unpaused
	
	-- unpaused by pusher
	
	hanlde:cancel()
	
	if filter.args then return varargs_unpacker(node[1] or error("puller's result cannot remain empty")) end	
end

function event:listen(callback, ...)

	local node = nodeChecked:new(...)
	local thread = newThread(function()
		local thread = getThread()
		while not node:isBlack() do
			while node:canPop() do
				callback(varargs_unpacker(node:pop()))
			end
			thread.pause()
		end
		node:markGray()
	end)
	node.thread = thread
	thread.start()
	self:insert_node_front(node)
	
	return filter
end
function event:listen_while(duration, callback, ...)

	local node = nodeChecked:new(...)
	local handle
	local thread = newThread(function()
		local thread = getThread()
		while not node:isBlack() do
			while node:canPop() do
				callback(varargs_unpacker(node:pop()))
			end
			thread.pause()
		end
		node:markGray()
		handle:cancel()
	end)
	node.thread = thread
	thread.start()
	local handle = timer:after(duration, thread.unpause)
	self:insert_node_front(node)
	
	return filter
end

function event:listen_at_most(times, callback, ...)
	
	-- if times < 1 then error("Cannot listen less than one time") end
	local node = nodeNTimes:new(times, ...)
	local thread = newThread(function()
		local thread = getThread()
		while not node:isBlack() do
			while node:canPop() do
				callback(varargs_unpacker(node:pop()))
			end
			thread.pause()
		end
		node:markGray()
	end)
	node.thread = thread
	thread.start()
	self:insert_node_front(node)
	
	return filter
end

function event:listen_while_at_most(duration, times, callback, ...)
	
	local node = nodeNTimes:new(times, ...)
	local handle
	local thread = newThread(function()
		local thread = getThread()
		while not node:isBlack() do
			while node:canPop() do
				callback(varargs_unpacker(node:pop()))
			end
			thread.pause()
		end
		node:markGray()
		handle:cancel()
	end)
	node.thread = thread
	thread.start()
	local handle = timer:after(duration, thread.unpause)
	self:insert_node_front(node)
	
	return filter
end

function event:cancel(node)	node:markGray() end

function event:test_filters(filters, from, ...)
	for i = from, filters.n do
		local filter = filters[i]
		local arg = select(i, ...)
		if not (self.type_tests[type(filter)] or no_such_type_filter)(filter,arg, ...) then return false end
	end
	return true
end

function event:push(...) return self:push_from_nth_arg(1, ...) end
function event:push_from_nth_arg(from, ...)
	local packed, needs_collection -- lazily initialized + marker to notify collector thread
	local node = self.head
	while node do
		if node:isWhite() then -- first, faillible check, more of a hint
			if self:test_filters(node.filters, from, ...) then
				if node:isWhite() then -- if its still active
					if not packed then packed = varags_packer(...) end
					node:push(packed)
					if node.thread.getStatus() == "paused" then node.thread.unpause() end
					if not needs_collection and node:isBlack() then needs_collection = true end
				end
			end
		end
		node = node:next() -- next
	end
	if needs_collection then self:collect() end
end

local isStopped = { done = true, crash = true, }
function event:cleanup()

	local node = self.head
	
	while node do
		if isStopped[node.thread.getStatus()] then node:markGray() end
		node = node:next()
	end

	self:collect()
end

function event:kill_all()
	
	local node = self.head
	self.head = nil -- he he boi
	
	while node do
		if not isStopped[node.thread.getStatus()] then thread.stop() end
		node = node:next()
	end

end

function event:destroy()
	self:kill_all()
	self.collector.stop()
end

log("&6[EventHandler] Event Handler set up")

return event