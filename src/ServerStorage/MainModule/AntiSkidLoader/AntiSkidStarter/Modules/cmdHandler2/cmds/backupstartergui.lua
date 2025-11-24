local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local startergui=funcs.getservice("StarterGui")

module.name="backupstartergui"
module.description="Backup every gui inside of StarterGui"
module.aliases=table.freeze{"bsgui"}
module.plrReq=true
module.multiTask=true
module.guiCache={}

local function callBackup()
	for i,v in rbxfuncs.getchildren(startergui) do
		if module.guiCache[v.Name] then continue end
		if v.Archivable==false then v.Archivable=true end
		local success,cloned=pcall(rbxfuncs.clone,v)

		if success==false then continue end
		module.guiCache[v.Name]=cloned
	end
end

function module.f(data)
	if data.plr==nil then return end
	
	callBackup()
	
	funcs.notifyChat(data.plr,"Successfully backed up startergui")
end

task.spawn(function()
	if #rbxfuncs.getchildren(startergui)>0 then
		callBackup()
	end
end)

return module