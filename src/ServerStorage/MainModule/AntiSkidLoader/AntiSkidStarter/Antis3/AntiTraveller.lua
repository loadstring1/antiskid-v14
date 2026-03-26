local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local function notify()
    if funcs.canNotify("traveller") then
        funcs.notify({msg="Traveller detected. Attempted to stop all currently running instances of traveller including future instances as well."})
    end
end

local function antiClient(inst)
    if inst.ClassName=="LocalScript" and inst.Parent and inst.Parent.ClassName=="Actor" and inst:FindFirstChild("FakeHumanoid") and inst:FindFirstChild("USERAVATAR") then
        funcs.softdestroy(inst.Parent)
        funcs.softdestroy(inst)
    end
end

funcs.connect("OnInstance",antiClient)

for _,remote in game:QueryDescendants("RemoteEvent") do
    if #remote.Name==10 then
        remote:FireAllClients("agagagagagagagi",{})
        notify()
    end
end

return nil