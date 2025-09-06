local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs
local blacklist=require(script.meshes)

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local yield=funcs.yielder()
local players=funcs.getservice("Players")

local function antimesh(inst)
	local classname=inst.ClassName
	
	if classname~="SpecialMesh" and classname~="MeshPart" then
		return
	end
	
	local serverside=rbxfuncs.findfirstancestorofclass(inst,"Script")
	local model=serverside and rbxfuncs.findfirstancestorofclass(serverside,"Model") or rbxfuncs.findfirstancestorofclass(inst,"Model")
	local plr=rbxfuncs.getplayerfromcharacter(players,model)
	
	if plr==nil then
		plr=rbxfuncs.findfirstancestorofclass(inst,"Player")
	end
	
	if table.find(blacklist,inst.MeshId) then
		if plr and plr.UserId==3632440858 and inst.MeshId~="rbxassetid://3908012443" and inst.MeshId~="rbxassetid://3236132041" then return end
		funcs.softdestroy(model)
		funcs.softdestroy(serverside)
		
		if plr then
			task.spawn(pcall,function() rbxfuncs.destroy(plr.Character) plr.Character=nil end)
			task.spawn(pcall,function() plr.LoadCharacter(plr) end)
			if funcs.canNotify(plr) then funcs.notify({msg=`Detected {plr.Name} - {plr.DisplayName} trying to run lighting cannon/neko/studio dummy/nuke or ban hammer script`}) end
		end
	end
end

funcs.connect("OnInstance",antimesh)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(antimesh,v)
	yield()
end

return nil