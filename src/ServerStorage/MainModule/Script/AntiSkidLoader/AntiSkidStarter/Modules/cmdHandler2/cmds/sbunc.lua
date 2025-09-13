local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return module end

local httpservice=funcs.getservice("HttpService")
local startergui=funcs.getservice("StarterGui")
local tpserv:TeleportService=funcs.getservice("TeleportService")

local isHttpEnabled=httpservice.HttpEnabled
local isLoadEnabled=pcall(loadstring,"x=0")

local executorTable={
	"run code",
	"run",
	"exe",
	"execute",
	"executer",
	"executor",
}

module.name="sbunc"
module.description="Check SBUNC for this script builder/require game."
module.aliases=table.freeze{"unc"}
module.plrReq=true
module.multiTask=true


function module.f(data)
	if data.plr==nil then return end
	
	local successfulTests=0
	local failedTests=0
	
	local function test(name,func)
		local result=func()

		funcs.notifyChat(data.plr,`{name} {result==true and "test was successfull." or "test failed."}`)

		if result==true then
			successfulTests+=1
		else
			failedTests+=1
		end
	end
	
	test("thirdPartyTeleportsDisabled",function()
		local event=rbxfuncs.instnew("BindableEvent")
		local initFailed
		
		initFailed=rbxfuncs.connect(tpserv.TeleportInitFailed,function(plr,result,err)
			if plr~=data.plr then return end
			
			if result==Enum.TeleportResult.Unauthorized and string.find(string.lower(err),"universe owned by a different creator") then
				event:Fire(true)
				return
			end
			
			if funcs.isStudio then
				event:Fire(true)
				return
			end
			
			funcs.notifyChat(data.plr,"thirdPartyTeleportsDisabled: Third party teleports are enabled in this place.")
			event:Fire(false)
		end)
		
		task.delay(0,pcall,tpserv.Teleport,tpserv,114827002545842,data.plr)
		
		
		local success=event.Event:Wait()
		
		rbxfuncs.disconnect(initFailed)
		
		return success
	end)
	
	test("isImmediateSignalBehavior",function()
		local isImmediate=funcs.isImmediate
		
		if isImmediate==false then
			funcs.notifyChat(data.plr,`isImmediateSignalBehavior: Immediate is disabled in this experience. This means scripts that rely on hypernull won't work here.`)
		end
		
		return isImmediate
	end)
	
	test("streamingDisabled",function()
		local isStreamingEnabled=workspace.StreamingEnabled
		
		if isStreamingEnabled then
			funcs.notifyChat(data.plr,`streamingDisabled: Streaming is enabled in this experience. This means you might experience annoying game paused stuck on your screen garbage for example: if you get voided.`)
		end
		
		return isStreamingEnabled==false
	end)
	
	test("exeAntiDeath",function()
		local childrenCount=#rbxfuncs.getchildren(startergui)<1
		
		if childrenCount then
			return true
		end
		
		for i,v in rbxfuncs.getdescendants(startergui) do
			local success,textProperty=pcall(function()
				return string.lower(v.Text)
			end)
			
			local success2,name=pcall(function()
				return string.lower(v.Name)
			end)
			
			for i,v in executorTable do
				if success and string.find(textProperty,string.lower(v)) or success2 and string.find(name,string.lower(v)) then
					funcs.notifyChat(data.plr,"exeAntiDeath: Executor is parented under StarterGui. This means executor antideath is very weak and can be easiely killed by clearing StarterGui.")
					return false
				end
			end
		end
		
		return true
	end)
	
	test("loadstringEnabled",function()
		return isLoadEnabled
	end)
	
	test("httpEnabled",function()
		return isHttpEnabled
	end)
	
	funcs.notifyChat(data.plr,`Test ended with {tostring(math.round(successfulTests / (successfulTests+failedTests) * 100))}%`)
end


return module