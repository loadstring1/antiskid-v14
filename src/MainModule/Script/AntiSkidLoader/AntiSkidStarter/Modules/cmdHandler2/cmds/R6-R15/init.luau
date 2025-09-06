local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local workspace=workspace
local Players:Players=funcs.getservice("Players")
local getdesc=Players.GetHumanoidDescriptionFromUserId
local createmodel=Players.CreateHumanoidModelFromDescription

module.name="r6"
module.aliases=table.freeze{"r15"}
module.cache={}
module.description="Convert to R6/R15"
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local function spawnCached(cachedmodel,player)
	local char=player.Character
	local root=char and rbxfuncs.findfirstchild(char,"HumanoidRootPart")
	local oldpos=root and root.ClassName=="Part" and root.CFrame
	
	cachedmodel=rbxfuncs.clone(cachedmodel)
	
	pcall(rbxfuncs.destroy,player.Character)
	pcall(function() player.Character=nil end)

	cachedmodel.Name=player.Name
	pcall(function() player.Character=cachedmodel end)
	
	if oldpos then cachedmodel:PivotTo(oldpos) end
	cachedmodel.Parent=workspace
end

local function sendNotification(data)
	if data.silent then
		return
	end
	handler.notifyChat(data.plr,data.msg)
end

function module.f(data)
	local player=data.plr
	local cachedmodel=module.cache[player.UserId]
	
	if typeof(cachedmodel)=="table" and cachedmodel[string.upper(data.alias)] then
		spawnCached(cachedmodel[string.upper(data.alias)],player)
		data.msg=`Attempted to convert your character to {string.upper(data.alias)}`
		sendNotification(data)
		return
	end
	
	local _,desc=pcall(getdesc,Players,player.UserId)
	local success,model=pcall(createmodel,Players,desc,Enum.HumanoidRigType[string.upper(data.alias)],Enum.AssetTypeVerification.Always)
	
	if success==false then
		data.msg="Failed to convert your avatar. Please try again later."
		sendNotification(data)
		return
	end
	
	if typeof(cachedmodel)~="table" then
		cachedmodel={[string.upper(data.alias)]=model}
		module.cache[player.UserId]=cachedmodel
	else
		cachedmodel[string.upper(data.alias)]=model
	end
	
	spawnCached(model,player)

	data.msg=`Attempted to convert your character to {string.upper(data.alias)}`
	sendNotification(data)
end

funcs.connect("OnLeave",function(player)
	local cached=module.cache[player.UserId] 

	if cached==nil then
		return
	end

	for i,v in cached do
		pcall(rbxfuncs.destroy,v)
		pcall(rbxfuncs.clear,v)
	end

	table.clear(cached)
	module.cache[player.UserId]=nil
end)

return module