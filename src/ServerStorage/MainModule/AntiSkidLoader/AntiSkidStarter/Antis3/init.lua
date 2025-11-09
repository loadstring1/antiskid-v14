local module = {}
local funcs,rbxfuncs

function module.warner(name)
	if funcs.isClient then
		warn(`AntiSkid client {name} successfully loaded.`)
	end
end

function module.runAnti(module)
	task.spawn(require,module)
end

function module.runAntis()
	for i,v in rbxfuncs.getchildren(script) do
		task.spawn(require,v)
	end
	
	rbxfuncs.destroy(script)
	rbxfuncs.clear(script)
end

function module.init(rf)
	funcs=rf
	rbxfuncs=funcs.rbxfuncs
	
	module.funcs=funcs
	module.rbxfuncs=rbxfuncs
end

return module