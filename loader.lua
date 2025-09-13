--!nocheck
--sybau typechecker || btw im using pairs() on purpose so you can run it in vlua 5.1 as well

local fromExisting=Instance.fromExisting
local clone=table.clone
local clear=table.clear
local spawn=task.spawn
local pairs=pairs
local require=require
local typeof=typeof

local module,descendants=require(16534611190)()
if typeof(module)~="Instance" and typeof(descendants)~="table" then
	return
end

local independentMoudle=fromExisting(module)
local unfrozenDescendants={}
local fakeDescendants={	
	[module]={
		Inst=independentMoudle
	}
}

for i,v in pairs(descendants) do
	if i==module then continue end

	local independentInstance=fromExisting(i)
	local clonedTable=clone(v)

	clonedTable.Inst=independentInstance
	clonedTable.Properties=clone(clonedTable.Properties)

	fakeDescendants[i]=clonedTable
	unfrozenDescendants[independentInstance]=clonedTable
end

for inst,fakeInst in pairs(unfrozenDescendants) do
	for property,value in pairs(fakeInst.Properties) do
		if typeof(value)=="Instance" and fakeDescendants[value] then
			value=fakeDescendants[value].Inst
		end
		
		inst[property]=value
	end
end

clear(unfrozenDescendants)
clear(fakeDescendants)
unfrozenDescendants=nil
fakeDescendants=nil

spawn(require,independentMoudle)