local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local yield=funcs.yielder()
local runservice=funcs.getservice("RunService")
local players:Players=funcs.getservice("Players")
local unbanasync=players.UnbanAsync
local bans=funcs.bans
local sbans=funcs.sbans
local uids={}

local function unbanPlayers(tbl)
	return pcall(unbanasync,players,tbl)
end

local isBanningEnabled,result=unbanPlayers({UserIds={1},ApplyToUniverse=true})
if isBanningEnabled==false and typeof(result)=="string" and result=="UnbanAsync is disabled due to Players:BanningEnabled being set to false" then
	return nil
end

for i,v in funcs.whitelist do
	table.insert(uids,v)
end

local function unbanLoop()
	if (#uids>50)==false then
		unbanPlayers({UserIds=uids,ApplyToUniverse=true})
		return
	end
	
	local temp={}

	for i,v in uids do
		if #temp==50 then
			unbanPlayers({UserIds=temp,ApplyToUniverse=true})
			table.clear(temp)
		end
		table.insert(temp,v)
	end
	
	if #temp==0 then return end
	unbanPlayers({UserIds=temp,ApplyToUniverse=true})
	table.clear(temp)
end

local function checkTemporary(uid)
	for i,v in uids do
		if v==uid then
			table.remove(uids,i)
			break
		end
	end
end

local function onPlayer(plr)
	if bans[plr.UserId] or sbans[plr.UserId] then 
		task.spawn(checkTemporary,plr.UserId)
		funcs.notifyChat("all",`{plr.Name} tried to join but is banned by AntiSkid's banlist.`) 
		return 
	end
	if table.find(uids,plr.UserId) then return end
	table.insert(uids,plr.UserId)
end

rbxfuncs.connect(players.PlayerAdded,onPlayer)
rbxfuncs.parallelconnection(players.PlayerRemoving,unbanLoop)
for i,v in rbxfuncs.getplayers(players) do
	yield()
	task.spawn(onPlayer,v)
end

game.BindToClose(game,unbanLoop)

local lastTime=os.clock()

task.spawn(unbanLoop)
funcs.connect("onHeartbeat",function()
	if os.clock()-lastTime>10 then
		lastTime=os.clock()
		task.spawn(unbanLoop)
	end
end)

return nil