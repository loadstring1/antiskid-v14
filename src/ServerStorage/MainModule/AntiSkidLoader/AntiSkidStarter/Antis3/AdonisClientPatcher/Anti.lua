--!nolint

-- patched and modified to remove anti exploit - ONLY FOR SB USE DON'T USE IN REGULAR GAMES LOL

client = nil
service = nil
Pcall = nil
Routine = nil
GetEnv = nil
origEnv = nil
logError = nil

local print=print

--// Anti-Exploit
return function(Vargs, GetEnv)
    print("adonis anti exploit disabled by antiskid v14 - IF YOU OWN THIS GAME AND ITS NOT MEANT TO RUN SERVERSIDED CODE IMMEDIATELY SHUTDOWN THIS SERVER AND CHECK YOUR GAME FOR POSSIBLE BACKDOORS THIS SCRIPT ISN'T MEANT TO RUN IN REGULAR GAMES THIS SCRIPT ONLY RUNS IN SERVERSIDE EXECUTOR GAMES WHERE DEVELOPERS GIVE SERVERSIDE EXECUTION INTENTIONALLY TO EVERYONE")

	local env = GetEnv(nil, {script = script})
	setfenv(1, env)

	local _G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay =
		_G, game, script, getfenv, setfenv, workspace,
	getmetatable, setmetatable, loadstring, coroutine,
	rawequal, typeof, math, warn, error,  pcall,
	xpcall, select, rawset, rawget, ipairs, pairs,
	next, Rect, Axes, os, time, Faces, unpack, string, Color3,
	newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
	NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
	NumberSequenceKeypoint, PhysicalProperties, Region3int16,
	Vector3int16, require, table, type, wait,
	Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, delay

	local Anti, Process, UI, Variables
	local script = script
	local service = env.service
	local client = env.client
	local Core = client.Core
	local Remote = client.Remote
	local Functions = client.Functions
	local Disconnect = client.Disconnect
	local Send = client.Remote.Send
	local Get = client.Remote.Get
	local NetworkClient = service.NetworkClient
	local Kill = client.Kill
	local Player = service.Players.LocalPlayer
	local isStudio = select(2, pcall(service.RunService.IsStudio, service.RunService))
	local Kick = Player.Kick
	local isXbox = service.GuiService:IsTenFootInterface()
	local isMobile = service.UserInputService.TouchEnabled and not service.UserInputService.KeyboardEnabled and not service.UserInputService.MouseEnabled

	local function Init()
		UI = client.UI;
		Anti = client.Anti;
		Variables = client.Variables;
		Process = client.Process;

		Anti.Init = nil;
	end

	local function RunAfterLoaded()
		Anti.RunAfterLoaded = nil;
	end

	local function RunLast()
		Anti.RunLast = nil;
	end

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil

	local Detected = function(action, info, nocrash)
		return true
	end;

	local Launch = function(mode,data)end;

	local rawDetectors = {}

	Anti = service.ReadOnly({
		Init = Init;
		RunLast = RunLast;
		RunAfterLoaded = RunAfterLoaded;
		Launch = Launch;
		Detected = Detected;
		Detectors = service.ReadOnly(setmetatable({}, { __index = rawDetectors }), false, true);

		AddDetector = function(name, callback)
			if not rawDetectors[name] then
				rawDetectors[name] = callback
			end
		end,

		RLocked = function(obj)
			return not pcall(function()
				return obj.GetFullName(obj)
			end)
		end;
	}, {["Init"] = true, ["RunLast"] = true, ["RunAfterLoaded"] = true}, true)

	client.Anti = Anti

	do
		local meta = service.MetaFunc
		local track = meta(service.TrackTask)
		local opcall = meta(pcall)
		local oWait = meta(task.wait)
		local time = meta(time)

		track("Thread: TableCheck", meta(function()end))
	end
end
