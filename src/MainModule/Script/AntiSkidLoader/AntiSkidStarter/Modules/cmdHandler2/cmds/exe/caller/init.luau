local bind=Instance.new("BindableEvent")
local env=getfenv()

local task=task
local setfenv=setfenv
local pcall=pcall

bind.Event:Connect(function(tbl)
	bind:Destroy()
	
	local binary,err,thing3=tbl.load(tbl.str)
	
	if binary==nil then
		tbl.bind:Fire({false,err})
		return 
	end
	
	local fakescript=Instance.new("Script")
	env.owner=tbl.owner
	fakescript.Enabled=false
	fakescript:Destroy()
	env.script=fakescript
	
	setfenv(0,env)
	setfenv(1,env)
	
	tbl.bind:Fire({pcall(setfenv(binary,env))})
end)

return function(...)
	task.spawn(bind.Fire,bind,...)
end