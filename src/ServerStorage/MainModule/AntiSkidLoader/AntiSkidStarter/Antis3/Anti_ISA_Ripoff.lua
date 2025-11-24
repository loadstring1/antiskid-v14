local antis3=require(script.Parent)
local funcs,rbxfuncs=antis3.funcs,antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient==false then return nil end

local soundservice=funcs.getservice("SoundService")
local yield=funcs.yielder()

local function detectRipOff(inst)
	if inst.ClassName~="Sound" then return end
	if inst.SoundId~="rbxassetid://8765309012" then return end
	funcs.softdestroy(inst)
end


rbxfuncs.parallelconnection(soundservice.DescendantAdded,detectRipOff)
for i,v in rbxfuncs.getdescendants(soundservice) do
	task.spawn(detectRipOff,v)
	yield()
end

antis3.warner(script.Name)

return nil