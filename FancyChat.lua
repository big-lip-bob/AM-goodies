local _,_,text = ...

if not FancyChat then return text end

local Preset = FancyPreset[FancyPresetID]
local char = string.char
local utf8 = utf8.char
for i = 1+1,26+1 do
 local sub = utf8(Preset[i])
 text = text:gsub(char(63+i),sub)
 text = text:gsub(char(95+i),sub)
end

return text