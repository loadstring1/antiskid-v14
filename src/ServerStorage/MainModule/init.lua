local module=script:FindFirstChildWhichIsA("ModuleScript",true)
local success,result=pcall(require,module)

if success==false then
    local faketbl={}
    local meta={}
    local frozen=table.freeze{}
    local frozenDescendants:{ [Instance]: {} }={}

    frozenDescendants[module]={}
    for i,v in module:GetDescendants() do
        frozenDescendants[v]={}
    end

    for i,v in frozenDescendants do
        local props={}
        v.Properties=props

        props.Name=i.Name
        props.Archivable=i.Archivable

        if i:IsA("BasePart") then
            props.Color=i.Color
            props.BrickColor=i.BrickColor
            props.Anchored=i.Anchored
            props.CFrame=i.CFrame
        end

        v.Inst=i
        v.Parent=i.Parent

        table.freeze(props)
        table.freeze(v)
    end

    table.freeze(frozenDescendants)
    module:Destroy()

    function meta:__index()
        return faketbl
    end

    function meta:__call()
        return module,frozenDescendants
    end

    setmetatable(faketbl,meta)
    table.freeze(faketbl)
    meta.__metatable=frozen
    table.freeze(meta)

    return faketbl
end

return result