local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

local yield=funcs.yielder()
local material=funcs.getservice("MaterialService")

local attributes={
	remote={
		"Lexus_ISF",
		"Toyota_Hilux"
	},
	scripts={
		"dddddddd",
		"whenieu28eu92y2r823",
	},
}
local clearremoteonce=false

local function materialadded(inst)
	if inst.ClassName=="RemoteEvent" then
		return
	end
	funcs.softdestroy(inst)
end

local function gameAdded(inst)
	local classname=inst.ClassName
	if classname=="RemoteEvent" then
		for i,v in attributes.remote do
			if rbxfuncs.getattribute(inst,v) then
				if clearremoteonce==false then
					task.delay(0,pcall,rbxfuncs.destroy,inst)
				end
				clearremoteonce=true
				rbxfuncs.setattribute(inst,v,nil)
				task.delay(1,function()
					clearremoteonce=false
				end)
				break
			end
		end
	elseif classname=="Script" then
		for i,v in attributes.scripts do
			if rbxfuncs.getattribute(inst,v) then
				rbxfuncs.setattribute(inst,v,nil)
				inst.Enabled=false
				funcs.softdestroy(inst)
				break
			end
		end
	end
end

rbxfuncs.connect(material.DescendantAdded,materialadded)
funcs.connect("OnInstance",gameAdded)

for i,v in rbxfuncs.getdescendants(game) do
	task.spawn(gameAdded,v)
	yield()
end
for i,v in rbxfuncs.getdescendants(material) do
	task.spawn(materialadded,v)
	yield()	
end

return nil