local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

module.name="clearcache"
module.aliases=table.freeze{"clrch"}
module.description="Clear cache in R6 and R15"
module.multiTask=true
module.plrReq=true

rbxfuncs.destroy(script)

function module.f(data)
	local cache=handler.cmds.r6.cache[data.plr.UserId]
	
	if cache==nil then
		handler.notifyChat(data.plr,"There is no cache of your avatar.")
		return
	end
	
	for i,v in cache do
		funcs.softdestroy(v)
	end
	
	table.clear(cache)
	handler.cmds.r6.cache[data.plr.UserId]=nil
	
	handler.notifyChat(data.plr,"Cache cleared.")
end

return module