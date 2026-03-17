local module = {}
local handler=require(script.Parent.Parent)
local funcs,rbxfuncs=handler.funcs,handler.rbxfuncs

if funcs.isClient then rbxfuncs.destroy(script); return module end

module.name="sign"
module.aliases={"signchat"}
module.description="Gives you a sign that you can type on"
module.multiTask=true
module.plrReq=true

local sign=script.Sign:Clone()
rbxfuncs.destroy(script)

for _,object in sign:GetDescendants() do
    if object.ClassName=="Script" or object.ClassName=="LocalScript" then
        object.Enabled=true
    end
end

function module.f(data)
	local backpack=rbxfuncs.findfirstchildofclass(data.plr, "Backpack")
    if backpack==nil then
        funcs.forceRespawn(data.plr)
        return
    end

    sign:Clone().Parent=backpack
end

return module