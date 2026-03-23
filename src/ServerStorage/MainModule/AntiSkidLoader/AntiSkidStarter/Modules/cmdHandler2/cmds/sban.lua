local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local versionn=handler.name

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local Players:Players=funcs.getservice("Players")

module.name="sban"
module.aliases=table.freeze{"serverban","baba"}
module.description="temporarily bans someone only from this server"
module.multiTask=true
module.plrReq=true
module.whitelistOnly=true


local function kickBannedPerson(plr)
	if funcs.sbans[plr.UserId]==nil then return end
	pcall(plr.Kick,plr,`Server banned by {versionn}\nReason: {funcs.sbans[plr.UserId]}`)
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

	if #reason==0 then
		reason="Unknown reason."
	end
	
	if doesExist==nil then
		local success2,returner=getplayerFromAPI(success and uid or toServerBan)
		local username=typeof(returner)=="string" and returner or toServerBan
		uid=typeof(returner)=="number" and returner or uid
		
		if success2==false or typeof(uid)~="number" then
			funcs.notifyChat(data.plr,`Failed to ban {toServerBan}\nError: {tostring(returner)}`)
			return
		end
		
		if addToBans(uid,reason)==false then funcs.notifyChat(data.plr,`Unable to ban whitelisted individual. {username} ({tostring(uid)})`); return end
		funcs.notifyChat(data.plr,`Banned {username} ({tostring(uid)}) successfully.`)
		return
	end
	
	if addToBans(doesExist.UserId,reason)==false then funcs.notifyChat(data.plr,`Unable to ban whitelisted individual. {doesExist.Name} ({tostring(doesExist.UserId)})`); return end
	pcall(doesExist.Kick,doesExist,`Server banned by {versionn}\nReason: {reason}`)
	funcs.notifyChat(data.plr,`Banned {doesExist.Name} ({tostring(doesExist.UserId)}) successfully.`)
end


return module