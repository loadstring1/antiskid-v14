local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

local lighting=funcs.getservice("Lighting")

module.name="resetlighting"
module.aliases=table.freeze{"rl"}
module.description="Reset skybox and lighting"
module.supportClient=true

rbxfuncs.destroy(script)

function module.f(data)
	if data.plr~=nil and handler.checkCooldown(module.name,5) then
		handler.notifyChat(data.plr,"Cooldown 5 seconds")
		return
	end
	if funcs.isClient==false then handler.remoteComms.invokeClients({method="runCommand",cmdName="resetlighting",data={}}) end
	
	lighting.Ambient=Color3.fromRGB(138,138,138)
	lighting.Brightness=2
	lighting.ColorShift_Bottom=Color3.fromRGB(0,0,0)
	lighting.ColorShift_Top=Color3.fromRGB(0,0,0)
	lighting.EnvironmentDiffuseScale=0
	lighting.EnvironmentSpecularScale=0
	lighting.GlobalShadows=true
	lighting.OutdoorAmbient=Color3.fromRGB(128,128,128)
	lighting.ShadowSoftness=0.2
	lighting.ClockTime=14
	lighting.GeographicLatitude=41.733
	lighting.ExposureCompensation=0
	lighting.FogColor=Color3.fromRGB(192,192,192)
	lighting.FogEnd=100000
	lighting.FogStart=0
	pcall(rbxfuncs.clear,lighting)
	
	handler.notifyChat("all","Lighting has been reset.")
end

return module