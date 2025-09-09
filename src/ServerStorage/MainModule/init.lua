local module=script:FindFirstChildWhichIsA("ModuleScript",true)
local success,result=pcall(require,module)

if success==false then
    local faketbl={}
    local meta={}
    local frozen=table.freeze{}

    module.Parent=nil

    function meta:__index()
        return faketbl
    end

    function meta:__call()
        return module
    end

    setmetatable(faketbl,meta)
    table.freeze(faketbl)
    meta.__metatable=frozen
    table.freeze(meta)

    return faketbl
end

return result