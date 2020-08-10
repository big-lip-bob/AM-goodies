skinState = skinState and not skinState or not getSettings().minecraft.getSkinCustomization("hat")

local states = {"hat","jacket","left leg","right leg","left arm","right arm","cape"}

local state = skinState
local CS = customizeSkin
for i = 1,#states do
 CS(states[i],state)
end

