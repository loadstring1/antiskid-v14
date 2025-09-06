-- ceat_ceat
local plrs = game:GetService("Players")
local IsStudio=game:GetService("RunService"):IsStudio()

local script = script
local math=math
local print=print
local require=require
local setfenv=setfenv
local table=table

setfenv(0,table.freeze{})
setfenv(1,table.freeze{})

local hehe = script.dookie:Clone()
local moduleids = require(script.ModuleIds:Clone())

local EXEC_LINE

-- errortype enum
local errortypes = {
	CompileError = 1,
	RuntimeError = 2,
}

-- spam the output with fake requires with real ids, useful against output loggers to an
-- extent, not useful against output loggers than can handle ratelimits and effectively
-- search thru a model
local function spamoutput()	
	if IsStudio then
		return
	end
	
	for i = 1, math.random(3, 12) do
		local id = moduleids[math.random(1, #moduleids)]
		--EXEC_LINE = math.random(1,100)
		print(([[Requiring asset %s.
Callstack:
dookie.ookie, line 645 - run_lua_func
dookie.ookie, line 1034 - wrapped]]):format(id))
	end
end

return function(src,owner)
	spamoutput()
	local success, compileerror = require(hehe:Clone())(src,owner)
	spamoutput()
	if success then
		return success,compileerror
	else
		return false, compileerror
	end
end