local antis3=require(script.Parent)
local funcs,rbxfuncs=antis3.funcs,antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient==false then return nil end

local startergui=funcs.getservice("StarterGui")
local getcore=startergui.GetCore
local getcoreguienabled=startergui.GetCoreGuiEnabled
local setcore=startergui.SetCore
local setcoreguienabled=startergui.SetCoreGuiEnabled

local function onheart()
	local isCoreEnabled,isTopBarEnabled
	
	pcall(function()
		isCoreEnabled = getcoreguienabled(startergui,Enum.CoreGuiType.All)
		isTopBarEnabled = getcore(startergui,"TopbarEnabled")
	end)
	
	if isCoreEnabled == false then
		setcoreguienabled(startergui,Enum.CoreGuiType.All,true)
	end
	if isTopBarEnabled == false then
		setcore(startergui,"TopbarEnabled",true)
	end
	
	pcall(setcore,startergui,"ResetButtonCallback",true)
end


rbxfuncs.connectparallel("onHeartbeat",onheart)
funcs.connect("onHeartbeat",onheart)

antis3.warner(script.Name)

return nil