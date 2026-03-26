--!nocheck
local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

local fakeAnti=script.ANTI
fakeAnti.Parent=nil
fakeAnti:SetAttribute("source","ok")

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local pcall=pcall
local setfenv=setfenv
local rawset=rawset
local rawget=rawget
local typeof=typeof
local table=table
local game=game
local task=task
local require=require

setfenv(1,table.freeze{})

local REJOIN_ONCE=false
local teleportservice=funcs.getservice("TeleportService")
local players=funcs.getservice("Players")

rbxfuncs.connect(funcs.getservice("ScriptContext").Error,function(msg,stack,instLeak)
	if typeof(instLeak)~="Instance"
		or instLeak.ClassName~="Script" 
		or instLeak.Name~="main"
		or instLeak:FindFirstChild("core")==nil
		or instLeak:FindFirstChild("core"):FindFirstChild("autorun")==nil then 
		return 
	end
	
	local core=instLeak.core
	local autorun=core.autorun
	
	pcall(function()
		autorun.clientmanager.client.osreclientmain.autorun["anti game break"]:Destroy()
	end)

	pcall(function() 
		local previousAnti=autorun["id blacklist"].ANTI
		if previousAnti:GetAttribute("source")=="ok" then return end

		local hooked=fakeAnti:Clone()
		
		for i,v in previousAnti:GetChildren() do
			v.Parent=hooked
		end

		previousAnti.Parent=nil
		hooked.Parent=autorun["id blacklist"]

		funcs.softdestroy(previousAnti)
	end)
	
	local osre_config=core:FindFirstChild("settings")
	local services=core:FindFirstChild("services")
	
	if services==nil or services.ClassName~="ModuleScript" 
		or osre_config==nil or osre_config.ClassName~="ModuleScript"
	then
		return
	end
	
    task.spawn(function()
        require(services).Players={
            GetDescendants=function()
                return{}
            end,
            GetPlayers=function()
                return{}
            end,
            PlayerAdded={
                Connect=function()end,
            }
        }
	
        local realConfig=require(osre_config)

        realConfig.whitelist.enabled=false
        realConfig.logging.enabled=false
        realConfig.logging.onlog=nil
    end)
	
	if REJOIN_ONCE then return end
	REJOIN_ONCE=true

    task.wait(5)
	
	for _,player in rbxfuncs.getplayers(players) do
		task.spawn(function()
			teleportservice:TeleportToPlaceInstance(game.PlaceId,game.JobId,player)
		end)
	end

    task.delay(10,function()
        funcs.notify({msg="every OSRE anti that shutdowns server has been disabled."})
        funcs.notifyChat("all","every OSRE anti that shutdowns server has been disabled.")
    end)
end)

return nil