local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local players=funcs.getservice("Players")

module.name="backupgui"
module.description="Backup every gui inside of your PlayerGui"
module.aliases=table.freeze{"bgui"}
module.plrReq=true
module.multiTask=true
module.guiCache={}

function module.f(data)
	if data.plr==nil then return end
	
	local playerGui=rbxfuncs.findfirstchildofclass(data.plr,"PlayerGui")
	if playerGui==nil then 
		funcs.notifyChat(data.plr,"Unable to backup guis. You don't have a playergui.")	
		return
	end
	
	local guis={}
	
	for i,v in rbxfuncs.getchildren(playerGui) do
		if funcs.CheckInstance(v)==false then continue end
		if funcs.isAntiSkidGUI(v) then continue end
		if v.Archivable==false then v.Archivable=true end
		local success,cloned=pcall(rbxfuncs.clone,v)
		
		if success==false then continue end
		table.insert(guis,cloned)
	end
	
	module.guiCache[data.plr.UserId]=guis
	funcs.notifyChat(data.plr,"Successfully backed up guis inside your PlayerGui.")
end

rbxfuncs.parallelconnection(players.PlayerRemoving,function(plr)
	local cache=module.guiCache[plr.UserId]
	if typeof(cache)~="table" then return end
	
	for i,v in cache do
		pcall(rbxfuncs.destroy,v)
	end
	table.clear(cache)
	module.guiCache[plr.UserId]=nil
end)

return module