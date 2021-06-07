local event_handler = require("EventHandler")

local type = type
local per_event = setmetatable({},{__index =
	function(self,key)
		if type(key) ~= "string" then error("The first argument must be a string") end
		self[key] = event_handler:new("__EVENT-SPLITTER="..key)
		return self[key]
	end
})

local event_splitter = {}

function event_splitter:pull(name,...) return per_event[name]:pull(...) end
function event_splitter:pull_timed(timeout,name,...) return per_event[name]:pull_timed(timeout,...) end
function event_splitter:pull_after(after,name,...) return per_event[name]:pull_after(after,...) end
function event_splitter:pull_timed_after(timeout,after,name,...) return per_event[name]:pull_timed_after(timeout,after,...) end

function event_splitter:listen(callback,name,...)
	local subscriber = per_event[name]:listen(...)
	subscriber.event_name = name
	return subscriber
end
function event_splitter:cancel(subscriber)
	per_event[subscriber.event_name]:cancel(subscriber)
end

function event_splitter:push(name,...) per_event[name]:push(...) end

function event_splitter:cleanup(name) per_event[name]:cleanup() end
function event_splitter:kill(name) per_event[name]:killall() end

local pairs = pairs
function event_splitter:cleanup_all() for k,v in pairs(per_event) do v:cleanup() end end
function event_splitter:kill_all() for k,v in pairs(per_event) do v:killall() end end


return event_splitter