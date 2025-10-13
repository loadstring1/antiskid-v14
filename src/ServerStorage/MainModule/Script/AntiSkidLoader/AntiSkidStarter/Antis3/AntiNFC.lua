local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient==false then return nil end

local yield=funcs.yielder()

local function DescendantAdded(inst)
    if (inst.ClassName=="ScreenGui" and inst.Name=="NFChat")==false then return end
    funcs.softdestroy(inst)
end

rbxfuncs.connect(game.DescendantAdded,DescendantAdded)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(DescendantAdded,v)
	yield()
end

antis3.warner(script.Name)

return nil