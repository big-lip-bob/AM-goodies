ChatLERP = not ChatLERP
if not ChatLERPlocals then
	local function separator(current,next,...)
		if next then
			return current," | ",separator(next,...)
		else
			return current
		end
	end
	local function new_log(...) log(separator(...)) end
	ChatLERPlocals = setmetatable({print = new_log,log = new_log},{__index = _G})
end
if not PCallHelper then
 local log,select = log,select
 function customunpack(iter_cout,striped,...)
  if iter_cout > 1 then -- at 0 it should stop
   return striped," | ",customunpack(iter_cout-1,...)
  else
   return striped
  end
 end
 function PCallHelper(ok,...) if ok then if select("#",...) ~= 0 then log(customunpack(select("#",...),...)) end else log("&6Runtime Error :\n&c" .. (...)) end end
end
log("ChatLERP toggled "..(ChatLERP and 'on' or 'off'))
