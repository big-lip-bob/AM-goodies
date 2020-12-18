	local event = {}

	local mutex = newMutex("__EVENT_HANDLER_BOB")

	local listeners = {}
	--event.__DEBUG = { listeners = listeners }

	local type,select = type,select

	local function varags_pack(...) return {n=select('#',...),...} end
	local function unpack_helper(t,n,m) if n <= m then return t[n],unpack_helper(t,n+1,m) end end
	local function varargs_unpack(t) return unpack_helper(t,1,t.n) end

	local function equals(a,b) return a == b end
	local type_tests = {
		table = function(t,k) return t[k] end,
		["function"] = function(f,m) return f(m) end,
		string = equals,boolean = equals,number = equals,
		["nil"] = function() return true end
	}
	local function no_such_type_filter(t,o) error(("the type %s has no filter | %s - %s"):format(type(t),tostring(t),tostring(o))) end

	local function remove_listeners(i)
		local l = #listeners
		listeners[l].pos = i
		listeners[i] = listeners[l]
		listeners[l] = nil
	end

	local get_thread,new_thread = thread.current,thread.new
	function event.pull(timeout,...) -- filters
		local self_thread = get_thread() -- yep
		local filter,to_kill
		if type(timeout) == "number" then
			filter = varags_pack(...) -- register thread as waiting for event
			to_kill = new_thread(function() -- register a killer thread after the timeout delay
				sleep(timeout*1000) -- seconds cause fuck Java
				self_thread.unpause()
			end)
			to_kill.start()
		else -- no timeout argument -> frist argument is part of the filters
			filter = varags_pack(timeout,...)
		end
		
		filter.thread = self_thread
		local pos = #listeners+1
		listeners[pos] = filter
		filter.pos = pos

		self_thread.pause()
		-- unpaused by manager here
		-- stop the thread that's meant to resume
		if to_kill and to.kill_getStatus() == "running" then --[[to_kill.pause();]] to_kill.stop() end -- pausing then stopping doesn't prevent that shitty error fuck
		mutex.lock(); remove_listeners(filter.pos); mutex.unlock() -- remove itself from the listeners
		
		if filter.args then
			return varargs_unpack(filter.args)
		end
		
	end

	local min = math.min
	local function test_filters(filter,...)
		for i = 1,min(filter.n,select('#',...)) do
			local filter = filter[i]
			local arg = select(i,...)
			if not (type_tests[type(filter)] or no_such_type_filter)(filter,arg,...) then return false end
		end
		return true
	end

	function event.push(...) -- traverse the listeners and pop all threads that match the filter
		local args = varags_pack(...) -- could be done later but then a check is needed to be done, it is more expensive if there aren't any consumers for it
		mutex.lock()
		for i = #listeners,1,-1 do
			local filter = listeners[i]
			if test_filters(filter,...) then
				filter.args = args
				if filter.thread.getStatus() == "paused" then -- debugging cause wtf
					filter.thread.unpause()
				else -- unpaused by someone else or at worst even fucking crashed in its sleep (yes)
					log("Unexpected : Thread wasn't in paused status but remained in the listeners list")
					log(filter.thread.getStatus())
					remove_listeners(i)
				end
			end
		end
		mutex.unlock()
	end

	return event
