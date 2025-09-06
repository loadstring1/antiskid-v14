local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs
if funcs.isClient then return module end

local pcall=pcall
local load=loadstring
local require=require
local setfenv=setfenv
local table=table
local script=script
local task=task
local newproxy=newproxy
local typeof=typeof
local print=print

setfenv(0,table.freeze{})
setfenv(1,table.freeze{})

local isloadEnabled=pcall(load,"x=1")

local offline=require(rbxfuncs.clone(script.fse))
local caller=rbxfuncs.clone(script.caller)

module.name="exe"
module.aliases=table.freeze{"executor","execute","executer","ls","skibidi","lol","axe"}
module.description="Runs custom lua code"
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)
rbxfuncs.clear(script)

local runners={}

function runners.onsuccess(plr)
	funcs.notifyChat(plr,`Your script has been ran successfully.`)
end

function runners.onerror(plr,msg)
	funcs.notifyChat(plr,`Your script errored\nError message: {msg}`)
end

function runners.enabled(combined,owner)
	local cloned=require(rbxfuncs.clone(caller))
	local bind=rbxfuncs.instnew("BindableEvent")
	
	rbxfuncs.connect(bind.Event,function(tbl)
		local success,err=tbl[1],tbl[2]
		
		if success==false then
			runners.onerror(owner,typeof(err)=="string" and err or "unknown error")
			return
		end
		
		runners.onsuccess(owner)
	end)
	
	cloned({load=load,owner=owner,str=combined,bind=bind})
end

function runners.disabled(combined,data)
	local success,thread,selfdestruct=pcall(offline,combined,data.plr)
	
	if typeof(thread)=="table" then
		success=thread[1]
		selfdestruct=thread[2]
	end
	
	if success==false or thread==false then
		runners.onerror(data.plr,typeof(selfdestruct)=="string" and selfdestruct or "unknown error")
		return
	end
	
	if thread then
		task.delay(10,function()
			if selfdestruct==nil then return end
			task.spawn(selfdestruct,newproxy)
		end)
		runners.onsuccess(data.plr)
	end
end

function module.f(data)
	local combined=table.concat(data.args," ")

	if combined~="" and typeof(combined)=="string" then
		funcs.notifyChat(data.plr,`Attempting to run your script...`)
		if isloadEnabled==false then
			runners.disabled(combined,data)
			return
		end
		
		combined=`--not today\n{combined}`
		runners.enabled(combined,data.plr)
	else
		funcs.notifyChat(data.plr,`Incorrect usage!\nCorrect usage:\n{data.syntax}exe print("hello world")`)
	end
end

return module