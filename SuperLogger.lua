local function customunpack(striped,...)
 if select("#",stripped,...) > 1 then
  return striped," | ",customunpack(...)
 else return striped end
end

log(customunpack(...))
