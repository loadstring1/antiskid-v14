local module = {}
local handler=require(script.Parent.Parent)
local funcs=handler.funcs

module.name="notif"
module.aliases=table.freeze{}
module.description="Enables or disables antiskid notifications if you already have them enabled"
module.multiTask=true
module.plrReq=true

function module.f(data)
	if funcs.reggedGuis[data.plr.UserId]==nil then
		if table.find(funcs.reggedPlrs,data.plr.UserId)==nil then
			table.insert(funcs.reggedPlrs,data.plr.UserId)
		end

		funcs.CreateGUI({plr=data.plr})
		funcs.notify({plr=data.plr,msg=`{handler.name} successfully loaded.\nHey you can always help me improve this script on my public repo. (check AntiSkidLoader in source code)`})
		handler.notifyChat(data.plr,"You opted in for notifications successfully.")
		return
	end
	funcs.RemoveGUI({plr=data.plr,unreg=true})
	handler.notifyChat(data.plr,"You opted out of notifications.")
end

return module