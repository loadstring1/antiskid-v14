local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local startergui=funcs.getservice("StarterGui")
local players=funcs.getservice("Players")
local backupCache; pcall(function()
	backupCache=handler.cmds.backupstartergui.guiCache
end)

task.delay(1,function()
	if typeof(backupCache)=="table" then return end
	backupCache=handler.cmds.backupstartergui.guiCache
end)

module.name="restorestartergui"
module.description="Restore every gui inside of StarterGui"
module.aliases=table.freeze{"rsgui"}
module.plrReq=true
module.multiTask=true

function module.f(data)
	if data.plr==nil then return end
	
	local howmuch=0
	for i,v in backupCache do howmuch+=1; break end
	
	if howmuch==0 then
		funcs.notifyChat(data.plr,"There is no backup of StarterGui (no guis to restore)")
		return
	end
	
	pcall(rbxfuncs.clear,startergui)
	for i,v in backupCache do
		if v.Archivable==false then v.Archivable=true end
		local success,cloned=pcall(rbxfuncs.clone,v)

		if success==false then continue end
		
		if cloned.ClassName=="ScreenGui" or cloned.ClassName=="GuiMain" then
			task.spawn(function()
				for i,v in rbxfuncs.getplayers(players) do
					local plrgui=rbxfuncs.findfirstchildofclass(v,"PlayerGui")
					if plrgui==nil then continue end
					
					local doesExist=rbxfuncs.findfirstchild(plrgui,cloned.Name)
					if doesExist then pcall(rbxfuncs.destroy,doesExist) end
					
					rbxfuncs.clone(cloned).Parent=plrgui
				end
			end)
		end
		
		cloned.Parent=startergui
	end

	funcs.notifyChat(data.plr,"Successfully restored guis in startergui")
end

return module