local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

if funcs.isClient then rbxfuncs.destroy(script); return nil end

local stuff={}

for i,v in script:GetChildren() do
    v.Parent=nil
    stuff[v.Name]=v
end

rbxfuncs.destroy(script)

local IS_PATCHED=false

funcs.connect("OnInstance",function(inst)
    if inst.ClassName=="LocalScript" and inst.Name=="ClientMover" and rbxfuncs.findfirstancestorofclass(inst,"ScreenGui") then
        inst.Enabled=false

        local client=inst.Parent:FindFirstChild("Client") or nil
        local core=client and client:FindFirstChild("Core") or nil
        local plugins=client and client:FindFirstChild("Plugins") or nil

        local anti=core and core:FindFirstChild("Anti") or nil
        local anticheat=plugins and plugins:FindFirstChild("Anti_Cheat") or nil

        if anti and anticheat then
            funcs.softdestroy(anti)
            funcs.softdestroy(anticheat)

            rbxfuncs.clone(stuff.Anti).Parent=core
            rbxfuncs.clone(stuff.Anti_Cheat).Parent=plugins

            if IS_PATCHED==false then
                IS_PATCHED=true
                funcs.notify({msg="Adonis anti client exploit has been blocked because its unnecessary bloat in require games."})
            end
        end

        inst.Enabled=true
    end
end)

return nil