local event = {} -- require("event") -- OC flashbacks -- now its my turn to write an event library i'm a big boi

local setmetatable,rawget,select,type,get_thread,new_thread,ipairs,pairs,sleep = setmetatable,rawget,select,type,thread.current,thread.new,ipairs,pairs,sleep
local function insert(t,v) t.n = t.n + 1; t[t.n] = v; return t.n end -- capability to initialize N (t.n > #t)
local procreatingMT = {};procreatingMT.__index = function(self,key) self[key] = setmetatable({__PARENT = self,__PARENT_SLOT = key,n = 0},procreatingMT) return self[key] end
local listener = setmetatable({n = 1/0},procreatingMT)
event.__LISTENER = listener -- fuck AM, fuck LuaJava
event.__RESET = function() listener = setmetatable({n = 1/0},procreatingMT) end


local function puller(...)
	local itercount = select("#",...)-- so we end up using __NO_FILTER as storage
	local listener_layer = listener
	for layer = 1,itercount do
		local arg = select(layer,...)
		listener_layer = listener_layer[arg ~= nil and arg or "__NO_FILTER"] -- could use a table or smtg to complelty privatize the no filter
	end
	return listener_layer
end

-- weird champ moment
local function unpackto(t,l,i) if i <= l then return t[i],unpackto(t,l,i+1) end end
local contains = function(t,f) for i = 1,t.n do if t[i] == f then return i end end end
local tr = table.remove
local remove_shift  = function(t,i) if tr(t,i) ~= nil then t.n = t.n - 1;if t.n <= 0 then remove_from_p(t) end end end
local remove_simple,remove_from_p
remove_simple = function(t,k) t[k] = nil; t.n = t.n - 1;if t.n <= 0 then remove_from_p(t) end end
remove_from_p = function(t)   remove_simple(t.__PARENT,t.__PARENT_SLOT) end -- fuckedu p somewhere so using == 0 is not bugproof -> went into negatives
function event.pull(timeout,...) -- filters
	local holding_layer
	local other_thread = get_thread() -- yep
	local to_kill
	if type(timeout) == "number" then
		holding_layer = puller(...)
		to_kill = new_thread(function()
			sleep(timeout*1000)
			local contains_at = contains(holding_layer["__WAITING_THREADS"],other_thread)
			if contains_at then
				remove_shift(holding_layer["__WAITING_THREADS"],contains_at) -- returns thread but i trust other_thraed
				other_thread.unpause()
			end
			if holding_layer["__WAITING_THREADS"].n == 0 then
				remove_from_p(holding_layer,"__WAITING_THREADS")
			end
		end)
		to_kill.start()		
	else -- no timeout argument -> frist argument is part of the filters
		holding_layer = puller(timeout,...)
	end
		
	local pos = insert(holding_layer["__WAITING_THREADS"],other_thread)
	-- oo wtf
	other_thread.pause()
	
	-- getting unpaused by the event listener
	holding_layer["__WAITING_THREADS"][pos] = nil
	-- remove self to prevent waiter thread to kill it but still allow insertion at the end since t is untouched, 
	-- the waiting threads pool sohuld be remvoed anyways by the pusher so t.n doesn't break
	if to_kill then to_kill.stop() end

	local results = rawget(holding_layer,other_thread)
	if results then 
		holding_layer[other_thread] = nil -- holy cleanup
		return unpackto(results,results.n,1)
	end -- else timed out and no result put

end

-- event processor really, push is just an alias for outsiders
local remove_stack,insert_stack = function(t,top) local v = t[top]; t[top] = nil; return v end, function(t,v,top) t[top] = v end
function event.push(...) -- where the fuckfest starts
	
	local args = {...} -- pepe clap ez pack
	args.n = select("#",...)
		
	-- if itercount == 0 then return end -- not happening
	-- using a stack of layers to process
	local layers_to_process = {listener}
	local layers_deepnesses = {1} -- avoiding {layer,deepness} struct -> faster hehe
	local top = 1
	
	repeat -- we dont give a fuck about "event" string thus 2 and the -1 earlier
		local now_layer,deepness = remove_stack(layers_to_process,top),remove_stack(layers_deepnesses,top) -- strip one from the kindastack
		top = top - 1

	
		local waiting_threads = rawget(now_layer,"__WAITING_THREADS")
		if waiting_threads then -- if there are threads waiting
			--log("Event processing")
			--log(waiting_threads)
			for _,thread in ipairs(waiting_threads) do
				now_layer[thread] = args
				--thread.start()
				thread.unpause() -- evil laughter -- https://www.newgrounds.com/audio/listen/841890
			end
		end
		remove_from_p(now_layer["__WAITING_THREADS"])
	
		
		local next_layer = rawget(now_layer,args[deepness])
		--log("lets see ",args[deepness])
		if next_layer then
	
			top = top + 1
			insert_stack(layers_to_process,next_layer,top)
			insert_stack(layers_deepnesses,deepness+1,top)
		end
		local no_filter_layer = rawget(now_layer,"__NO_FILTER")
		if no_filter_layer then
			top = top + 1
			insert_stack(layers_to_process,no_filter_layer,top)
			insert_stack(layers_deepnesses,deepness+1,top)
		end
		
	until top == 0 -- stack is empty, exist
end

local listeners = {}
function event.listen()

end

function event.cancel()

end

return event