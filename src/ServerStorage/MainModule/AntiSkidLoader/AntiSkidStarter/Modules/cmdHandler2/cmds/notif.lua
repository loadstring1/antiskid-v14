local module = {}
local handler=require(script.Parent.Parent)
local funcs=handler.funcs

module.name="notif"
module.aliases=table.freeze{}
module.description="Enables or disables antiskid notifications if you already have them enabled"
module.multiTask=true
module.plrReq=true

function module.f(data)
	if table.find(funcs.reggedPlrs,data.plr.UserId)==nil then
		table.insert(funcs.reggedPlrs,data.plr.UserId)

		funcs.remoteComms.invokeClient(data.plr,{method="setRegistered",regged=true})
		task.wait(0.2)
		funcs.notify({plr=data.plr,msg=`{handler.name} successfully loaded.\nHey you can always help me improve this script on my public repo. (check AntiSkidLoader in source code)`})
		
		handler.notifyChat(data.plr,"You opted in for notifications successfully.")
		return
	end
	
	table.remove(funcs.reggedPlrs,table.find(funcs.reggedPlrs,data.plr.UserId))
	funcs.remoteComms.invokeClient(data.plr,{method="setRegistered",regged=false})
	handler.notifyChat(data.plr,"You opted out of notifications.")
end

return module