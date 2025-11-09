local funcs,rbxfuncs
local module={}

function module.ancestor(class,inst)
    return typeof(rbxfuncs.findfirstancestorofclass(inst,class))=="Instance"
end

function module.lowerfind(name,inst)
    return string.find(string.lower(inst.Name),string.lower(name))
end

function module.ancestors(classes,inst)
    local classCount=0
    local passed=0

    for _,class in classes do
        classCount+=1
        if module.ancestor(class,inst) then
            passed+=1
        end
    end

    return passed==classCount
end

function module.excludeancestors(classes,inst)
    local classCount=0
    local passed=0

    for _,class in classes do
        classCount+=1
        if module.ancestor(class,inst)==false and ({pcall(rbxfuncs.gameIndex,inst,"ClassName")})[2]~=class then
            passed+=1
        end
    end

    return passed==classCount
end

--[[function module.includeOtherInstances(mainProps,inst,func)
    task.spawn(function()
        for _,propTable in mainProps do
            task.spawn(funcs.queryInstance,propTable,inst,func)
        end
    end)
    return true
end]]

function module.init(rf)
    rawset(module, "init", nil)
    funcs=rf
    rbxfuncs=funcs.rbxfuncs

    rbxfuncs.destroy(script)
end

return module