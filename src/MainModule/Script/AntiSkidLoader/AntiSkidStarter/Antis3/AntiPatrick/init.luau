local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local yield=funcs.yielder()
local soundservice=funcs.getservice("SoundService")
local lighting=funcs.getservice("Lighting")

local function isPatrick(inst)
	return inst.ClassName=="Script" and inst.Name=="Giver" and inst.Parent and inst.Parent.ClassName=="MeshPart" and inst.Parent.MeshId=="rbxassetid://455783801"
end

local function onInstance(inst)
	if isPatrick(inst)==false then return end
	
	funcs.softdestroy(rbxfuncs.findfirstancestorofclass(inst,"Model"))
	funcs.softdestroy(inst)
	
	lighting.TimeOfDay=14
	lighting.Ambient=Color3.fromRGB(138, 138, 138)
	lighting.OutdoorAmbient=Color3.fromRGB(128, 128, 128)
	pcall(rbxfuncs.clear,lighting)
	
	for i,v in rbxfuncs.getchildren(soundservice) do
		yield()
		if funcs.CheckInstance(v)==false then continue end
		if v.ClassName~="Sound" then continue end
		if v.SoundId~="rbxassetid://7816195044" and v.SoundId~="rbxassetid://9046435309" then continue end
		funcs.softdestroy(v)
	end
	
	if funcs.canNotify("antipatrick") then funcs.notify({msg="Removed patrick script"}) end
end

funcs.connect("OnInstance",onInstance)
for i,v in rbxfuncs.getdescendants(game) do
	yield()
	task.spawn(onInstance,v)
end

return nil