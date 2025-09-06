local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local players=funcs.getservice("Players")
local backupCache pcall(function()
	backupCache=handler.cmds.backupgui.guiCache
end)

task.delay(1,function()
	if typeof(backupCache)=="table" then return end
	backupCache=handler.cmds.backupgui.guiCache
end)

module.name="restoregui"
module.description="Restore every gui that was inside of your PlayerGui"
module.aliases=table.freeze{"rgui"}
module.plrReq=true
module.multiTask=true

function module.f(data)
	if data.plr==nil then return end

	local playerGui=rbxfuncs.findfirstchildofclass(data.plr,"PlayerGui")
	if playerGui==nil then 
		funcs.notifyChat(data.plr,"Unable to restore guis. You don't have a playergui.")	
		return
	end

	local guis=backupCache[data.plr.UserId]
	
	if guis==nil or #guis==0 then
		funcs.notifyChat(data.plr,"You don't have a backup. (no guis to restore)")
		return
	end
	
	for i,v in rbxfuncs.getchildren(playerGui) do
		if funcs.CheckInstance(v)==false then continue end
		if funcs.isAntiSkidGUI(v) then continue end
		pcall(rbxfuncs.destroy,v)
	end
	
	for i,v in guis do
		if v.Archivable==false then v.Archivable=true end
		local success,cloned=pcall(rbxfuncs.clone,v)

		if success==false then continue end
		cloned.Parent=playerGui
	end

	funcs.notifyChat(data.plr,"Successfully restored guis back inside your PlayerGui.")
end

return module