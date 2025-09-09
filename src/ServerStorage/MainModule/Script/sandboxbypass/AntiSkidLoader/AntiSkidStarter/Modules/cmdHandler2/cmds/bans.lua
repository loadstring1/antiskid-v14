--TODO: make this command actually work lol

local module = {}
local handler=require(script.Parent.Parent)
local funcs=handler.funcs
local rbxfuncs=funcs.rbxfuncs

module.name="bans"
module.aliases=table.freeze{}
module.plrReq=true

function module.f(data)
	print(game.Name,"before")
	local s=game.Changed:Wait()
	print(s,"game.Changed")
	print(game[s])
end

return module