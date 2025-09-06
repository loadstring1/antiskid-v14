local module = {}
local handler=require(script.Parent.Parent)
local funcs=handler.funcs

module.name="notif"
module.aliases=table.freeze{}
module.description="Turn on/off antiskid notifications"
module.multiTask=true
module.plrReq=true

function module.f(data)
	if funcs.reggedGuis[data.plr.UserId]==nil then
		funcs.CreateGUI({plr=data.plr,ignore=true})
		funcs.notify({plr=data.plr,msg="This is test notification. This means you re-enabled your notifications successfully."})
		handler.notifyChat(data.plr,"You re-enabled your notifications successfully.")
		return
	end
	funcs.RemoveGUI({plr=data.plr,unreg=true})
	handler.notifyChat(data.plr,"You won't be notified anymore.")
end

return module