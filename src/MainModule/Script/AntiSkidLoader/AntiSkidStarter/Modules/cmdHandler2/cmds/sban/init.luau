local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local versionn=handler.name

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local Players:Players=funcs.getservice("Players")

module.name="sban"
module.aliases=table.freeze{"serverban","baba"}
module.multiTask=true
module.plrReq=true


local function kickBannedPerson(plr)
	if funcs.sbans[plr.UserId]==nil then return end
	pcall(plr.Kick,plr,`Server banned by AntiSkid {versionn}\nReason: {funcs.sbans[plr.UserId]}`)
end

rbxfuncs.connect(Players.PlayerAdded,kickBannedPerson)

local function getplayerFromAPI(object)
	if typeof(object)=="string" then
		return pcall(function()
			return Players:GetUserIdFromNameAsync(object)
		end)
	end
	
	return pcall(function()
		return Players:GetNameFromUserIdAsync(object)
	end)
end

local function checkIfExists(object)
	if typeof(object)=="string" then
		for i,v in Players:GetPlayers() do
			if string.find(string.lower(v.Name),string.lower(object)) or string.find(string.lower(v.DisplayName),string.lower(object)) then
				return v
			end	
		end
		
		return nil
	end
	
	for i,v in Players:GetPlayers() do
		if v.UserId==object then
			return v
		end
	end
	
	return nil
end

local function addToBans(uid,reason)
	if table.find(funcs.whitelist,uid) then return false end
	funcs.sbans[uid]=reason
	return true
end


function module.f(data)
	if data.plr==nil then return end
	if table.find(funcs.whitelist,data.plr.UserId)==nil then
		funcs.notifyChat(data.plr,"You are not whitelisted - Conajwyżej możesz mi jaja polizać")
		return
	end
	
	local args=data.args
	if #args==0 then
		funcs.notifyChat(data.plr,"No arguments.")
		return
	end
	
	local toServerBan=args[1]
	table.remove(args,1)
	local success,uid=pcall(tonumber,toServerBan)
	local doesExist=checkIfExists(success and uid or toServerBan)
	local reason=table.concat(args," ")
	
	if doesExist==nil then
		local success,returner=getplayerFromAPI(success and uid or toServerBan)
		
		if success==false then
			funcs.notifyChat(data.plr,`Failed to ban {toServerBan}\nError: {tostring(returner)}`)
			return
		end
		
		if typeof(returner)=="string" then
			if addToBans(uid,reason)==false then funcs.notifyChat(data.plr,`Unable to ban whitelisted individual. {returner} ({tostring(uid)})`) return end
			funcs.notifyChat(data.plr,`Banned {returner} ({tostring(uid)}) successfully.`)
			return
		end
		
		if typeof(returner)=="number" then
			if addToBans(returner,reason)==false then funcs.notifyChat(data.plr,`Unable to ban whitelisted individual. {toServerBan} ({tostring(returner)})`) return end
			funcs.notifyChat(data.plr,`Banned {toServerBan} ({tostring(returner)}) successfully.`)
			return	
		end
		
		funcs.notifyChat(data.plr,`Failed to ban {toServerBan}\nError 1: {tostring(returner)}`)
		return
	end
	
	if addToBans(doesExist.UserId,reason)==false then funcs.notifyChat(data.plr,`Unable to ban whitelisted individual. {doesExist.Name} {tostring(doesExist.UserId)}`) return end
	pcall(doesExist.Kick,doesExist,`Server banned by AntiSkid {versionn}\nReason: {reason}`)
	
	funcs.notifyChat(data.plr,`Banned {doesExist.Name} ({tostring(doesExist.UserId)}) successfully.`)
end


return module