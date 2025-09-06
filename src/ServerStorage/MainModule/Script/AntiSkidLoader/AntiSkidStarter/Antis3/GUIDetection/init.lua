local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs
local yield=funcs.yielder()
local textbl=require(script.textBlacklist)

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local function wipe(tbl)
	for i,v in tbl do
		if v.ClassName=="ScreenGui" or v.ClassName=="GuiMain" then
			pcall(rbxfuncs.clear,v)
			continue
		end
		
		funcs.softdestroy(v)
		yield()
	end
end

local function checkBlacklist(inst,blname)
	local unzalgo=inst.Text
	if string.match(unzalgo,"[\194-\244][\128-\191]*") ~= nil then
		unzalgo=string.gsub(unzalgo,"[\194-\244][\128-\191]*", "")
	end
	
	for i,v in textbl[blname] do
		if string.find(string.lower(inst.Text),v) then
			return true,v,inst.Text
		elseif string.find(string.lower(unzalgo),v) then 
			return true,v,unzalgo
		end
		yield()
	end	
	
	return false
end

local function onInstance(inst)
	local classname=inst.ClassName
	
	if classname=="Folder" and inst.Name=="k00per" then
		funcs.softdestroy(inst)
		return
	end
	
	if classname~="TextLabel" and classname~="TextButton" then return end
	
	local plr=rbxfuncs.findfirstancestorofclass(inst,"Player")
	local gui=rbxfuncs.findfirstancestorofclass(inst,"ScreenGui") or rbxfuncs.findfirstancestorofclass(inst,"GuiMain") or nil
	local scr=rbxfuncs.findfirstancestorofclass(inst,"Script")
	
	local isFlagged,flaggedText,flaggedText1=checkBlacklist(inst,"trigger")
	
	if isFlagged then
		wipe({scr,gui,inst})
		if plr and funcs.canNotify(plr) then 
			funcs.notify({msg=`Removed skid gui from {plr.Name}{plr.Name~=plr.DisplayName and ` - {plr.DisplayName}` or ``}`}) 
			funcs.notifyChat("all",`Removed {flaggedText} - {flaggedText1} from {plr.Name}/{tostring(plr.UserId)}`)	
		end
		return
	end
	
	if checkBlacklist(inst,"del") then wipe({scr,gui,inst})end
end

rbxfuncs.connect(game.DescendantAdded,function(inst)
	if inst.ClassName~="ScreenGui" then yield() return end
	if inst.Name~="SupMaFellas" then yield() return end
	funcs.softdestroy(inst)
end)

funcs.connect("OnInstance",onInstance)
for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(onInstance,v)
	yield()
end

return nil