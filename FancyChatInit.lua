if not FancyPreset then 
 FancyPreset = {
 {"WideChars"		,"65345","65346","65347","65348","65349","65350","65351","65352","65353","65354","65355","65356","65357","65358","65359","65360","65361","65362","65363","65364","65365","65366","65367","65368","65369","65370"},
 {"Small Caps"		,"7424","665","7428","7429","7431","1171","610","668","618","7434","7435","671","7437","628","7439","7448","808","640","42801","7451","7452","7456","7457","10799","655","7458"},
 {"Small Letters"	,"7491","7495","7580","7496","7497","7584","7501","688","8305","690","7503","737","7504","65358","7506","7510","5227","691","738","7511","7512","7515","695","739","696","7611"}}
 
 local Presets = FancyPreset
 math.randomseed(os.time())
 local len,ran = #Presets,math.random
 FancyPreset[4] = setmetatable({"Random"},{__index = function(self,index) return Presets[ran(1,len)][index] end})
 
 local String = luajava.bindClass("java.lang.String")
 local Char   = luajava.bindClass("java.lang.Character")
 
 utf8 = utf8 or {}
 local new,unpack,ipairs = luajava.new,table.unpack,ipairs
 function utf8.char(...)
  local args = {...}
  local out = {}
  for i,c in ipairs(args) do
    out[i] = luajava.new(String, Char:toChars(c))
  end
  return unpack(out)
 end
 
 FancyPresetCount = len + 2
 FancyPresetID = 0
end

FancyPresetID = (FancyPresetID + 1) % FancyPresetCount
FancyChat = FancyPresetID ~= 0
log(FancyChat and ("Using %s Preset"):format(FancyPreset[FancyPresetID][1]) or "FancyChat disabled")