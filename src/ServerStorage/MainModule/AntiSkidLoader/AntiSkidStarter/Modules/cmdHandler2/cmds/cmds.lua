local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

module.name="cmds"
module.aliases={"commands"}
module.description="Shows commands"
module.multiTask=true
module.supportClient=true

rbxfuncs.destroy(script)

function module.f(data)
	local cmdlist="Commands list:"
	
	for i,v in handler.cmds do
		if v.description then
			if funcs.isClient and v.onlyClient~=true then continue end
			cmdlist=`{cmdlist}\n{data.syntax}{v.name}{#v.aliases>0 and ` ({table.concat(v.aliases,", ")}) ` or ` `}- {v.description}`
		end
	end
	
	if funcs.isClient then handler.notifyChat(cmdlist) return end
	handler.notifyChat(data.plr,cmdlist)
	funcs.remoteComms.invokeClient(data.plr,{method="runCommand",cmdName="cmds",data=data})
end

return module