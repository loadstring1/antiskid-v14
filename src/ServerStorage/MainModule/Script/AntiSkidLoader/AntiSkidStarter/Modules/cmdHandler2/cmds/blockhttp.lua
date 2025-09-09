local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
local yield=funcs.yielder()

module.name="blockhttp"
module.aliases=table.freeze{"bh","stophttp","killhttp","disablehttp"}
module.description="Stops http requests permanently"

local isBlocking=false
local http=funcs.getservice("HttpService")
local getasync=http.GetAsync
local requestasync=http.RequestAsync
local postasync=http.PostAsync

rbxfuncs.destroy(script)

function module.f(data)
	if isBlocking then
		handler.notifyChat(data.plr,"HTTP requests are already blocked.")
		return
	end 
	
	if http.HttpEnabled==false then
		handler.notifyChat(data.plr,"HTTP requests are already disabled by game developer.")
		return
	end
	
	isBlocking=true
	
	task.spawn(function()
		local function spam()
			task.spawn(pcall,getasync,http,"http://example.org")
			task.spawn(pcall,postasync,http,"http://example.org","test",Enum.HttpContentType.TextPlain)
			task.spawn(pcall,requestasync,http,{Url="http://example.org",Method="GET"})
			task.spawn(pcall,requestasync,http,{Url="http://example.org",Method="POST",Headers={["Content-Type"]="text/plain"},Body="test"})
		end
		rbxfuncs.connect(funcs.getservice("RunService").Heartbeat,spam)
		
		while yield()==nil do
			task.spawn(spam)
		end
	end)
	
	handler.notifyChat("all","HTTP requests successfully blocked")
end

return module