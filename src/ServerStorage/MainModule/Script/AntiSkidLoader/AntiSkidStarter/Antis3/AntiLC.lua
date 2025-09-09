local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local yield=funcs.yielder()
local players=funcs.getservice("Players")


local blacklist={
	Folder={
		"DarkMegaGunnModel",
		"MegaGunnModel",
		"efEfeeEcFfEfeeEFeCstSfEefEfeeEcFfEfeeEFeCstSfEefEfeeEcFfEfeeEFeCstSfE",
	},
	ScreenGui={
		"beerub",
		"supbro",
		"09r9m4rxmx0emie09riemx3k029rei240r09r9m4rxmx0emie09riemx3k029rei240r09r9m4rxmx0emie09riemx3k029rei24",
	}
}

local function antilc(inst)
	local classname,name=inst.ClassName,inst.Name
	
	if blacklist[classname]==nil then
		yield()
		return
	end
	
	local serverside,clientside=rbxfuncs.findfirstancestorofclass(inst,"Script"),rbxfuncs.findfirstancestorofclass(inst,"LocalScript")
	local model=serverside and rbxfuncs.findfirstancestorofclass(serverside,"Model")
	if model and model.Parent then model=model.Parent end
	local plr=rbxfuncs.getplayerfromcharacter(players,model)
	
	for i,v in blacklist[classname] do
		if name==v then
			funcs.softdestroy(serverside)
			funcs.softdestroy(clientside)
			if funcs.canNotify("antilc")==false then break end
			funcs.notify({msg=plr==nil and "Attempted to block lighting cannon" or `Detected {plr.Name}{plr.Name~=plr.DisplayName and ` - {plr.DisplayName}` or ``} trying to run lighting cannon`})
			break
		end
		yield()
	end
end

rbxfuncs.connect(game.DescendantAdded,antilc)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(antilc,v)
	yield()
end

return nil