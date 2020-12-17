local _,_, line = ...
if ChatLERP then

 local ok,chunk = load(line,"BobREPL","t",ChatLERPlocals)
 if ok then
  PCallHelper(pcall(ok))
 else
  ok,nchunk = load("return " .. line,"BobREPL","t",ChatLERPlocals)
  if ok then
   PCallHelper(pcall(ok))
  else
   log("&c"..(chunk or nchunk))
  end
 end
 
 
else
 return line
end
