local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local noob=rbxfuncs.clone(script.Noob)
local currentlySpawnedDummies={}

rbxfuncs.destroy(script)

module.name="dummy"
module.aliases=table.freeze{"d"}
module.plrReq=true
module.multiTask=true
module.description="Spawns dummy"

function module.f(data)
	local char:Model=data.plr.Character
	local cframe=char and char:GetPivot() or nil
	local amount=tonumber(data.args[1]) or 1
	
	if cframe==nil then return end	
	if amount>100 then amount=100 end
	
	local dummiesleft=0	
	for i,v in currentlySpawnedDummies do
		if rbxfuncs.isdescendantof(v,workspace)==false then
			pcall(rbxfuncs.destroy,v)
			task.delay(0,pcall,rbxfuncs.destroy,v)
			table.remove(currentlySpawnedDummies,table.find(currentlySpawnedDummies,v))
			continue
		end
		dummiesleft+=1
	end
	
	if dummiesleft>300 then
		for i,v in currentlySpawnedDummies do
			pcall(rbxfuncs.destroy,v)
			task.delay(0,pcall,rbxfuncs.destroy,v)
		end
		
		table.clear(currentlySpawnedDummies)
	end
	
	for i=1,amount do
		local dummy=rbxfuncs.clone(noob)
		table.insert(currentlySpawnedDummies,dummy)
		
		dummy.Parent=workspace
		dummy:PivotTo(cframe)
	end
	
	funcs.notifyChat(data.plr,`Spawned {amount} dummies successfully.`)
end

return module