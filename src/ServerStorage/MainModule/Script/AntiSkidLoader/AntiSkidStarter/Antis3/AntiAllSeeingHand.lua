local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local function antiAllSeingHand(inst)
	if inst.ClassName~="Script" then return end
	if inst.Name~="ASHA" then return end
	if rbxfuncs.findfirstchild(inst,"The Hand")==nil then return end
	funcs.forcedestroy(inst)
end

funcs.connect("OnInstance",antiAllSeingHand)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(antiAllSeingHand,v)
end

return nil