local compile = require(script:WaitForChild("pookie"))
local createExecutable = require(script:WaitForChild("ookie"))
local env=getfenv()

local setfenv=setfenv
local task=task

local function real(source,owner)
	local executable
	local name = "compiled-lua"
	
	local selfdestruct=createExecutable("g")

	local scr=Instance.new("Script")
	env.owner=owner
	env.script=scr
	scr.Enabled=false
	scr:Destroy()

	local ran, failureReason = pcall(function()
		local compiledBytecode = compile(source, name)
		executable = createExecutable(compiledBytecode, env)
	end)
	
	setfenv(0,env)
	setfenv(1,env)
	
	if executable==nil then return nil,failureReason end
	
	if ran then
		return {pcall(setfenv(executable,env))},selfdestruct
	end
	return nil, failureReason	
end

return real