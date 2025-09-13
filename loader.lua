local fromExisting=Instance.fromExisting
local clone=table.clone
local clear=table.clear
local require=require
local task=task
local typeof=typeof
local print=print

local module,descendants=require(17833048877)()
if typeof(module)~="Instance" and typeof(descendants)~="table" then
	print("antiskid loaded without backup method LOL",module,descendants)
	return
end

local independentMoudle=fromExisting(module)
local unfrozenDescendants={}
local fakeDescendants={	
	[module]={
		Inst=independentMoudle
	}
}

print(independentMoudle,"independent module")
print(module,"dependent module")

for i,v in descendants do
	if i==module then continue end

	local independentInstance=fromExisting(i)
	local clonedTable=clone(v)

	clonedTable.Inst=independentInstance
	clonedTable.Properties=clone(clonedTable.Properties)

	fakeDescendants[i]=clonedTable
	unfrozenDescendants[independentInstance]=clonedTable
end

for inst,fakeInst in unfrozenDescendants do
	for property,value in fakeInst.Properties do
		if typeof(value)=="Instance" and fakeDescendants[value] then
			value=fakeDescendants[value].Inst
		end
		
		inst[property]=value
	end
end

print("clearing")

clear(unfrozenDescendants)
clear(fakeDescendants)

print("cleared and running antiskid")

task.spawn(require,independentMoudle)

print(#independentMoudle:GetChildren(),"op")
print(#module:GetChildren(),"so good")