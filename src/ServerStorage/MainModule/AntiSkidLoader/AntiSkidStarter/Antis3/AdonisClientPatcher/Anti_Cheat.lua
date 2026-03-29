--!nolint

-- patched and modified to remove anti exploit - ONLY FOR SB USE DON'T USE IN REGULAR GAMES LOL

script.Archivable = false
task.spawn(function()
	if not game:GetService("RunService"):IsStudio() then
		script.Name = "\n\n\n\n\n\n\n\nModuleScript"
	end
end)

GetEnv = nil

local print=print

return function(Vargs)
    print("adonis anti cheat disabled by antiskid v14 - IF YOU OWN THIS GAME AND ITS NOT MEANT TO RUN SERVERSIDED CODE IMMEDIATELY SHUTDOWN THIS SERVER AND CHECK YOUR GAME FOR POSSIBLE BACKDOORS THIS SCRIPT ISN'T MEANT TO RUN IN REGULAR GAMES THIS SCRIPT ONLY RUNS IN SERVERSIDE EXECUTOR GAMES WHERE DEVELOPERS GIVE SERVERSIDE EXECUTION INTENTIONALLY TO EVERYONE")

	local client, service = Vargs.Client, Vargs.Service
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
	local UI = client.UI;
	local Anti = client.Anti;
	local Variables = client.Variables;
	local Process = client.Process;
	local Detected = Anti.Detected;

	getfenv().client = nil
	getfenv().service = nil
	getfenv().script = nil
	script.Parent = nil

	local Detectors = {
		Speed = function(data)
		end;

		AntiAntiIdle = function(data)
		end;

		HumanoidState = function()
			wait(1)
		end;

		AntiCoreGui = function()
			return
		end,

		MainDetection = function()
		end
	}

	for k, v in pairs(Detectors) do
		Anti.AddDetector(k, v)
	end

	do
		local meta = service.MetaFunc
		local track = meta(service.TrackTask)
		local opcall = meta(pcall)
		local oWait = meta(wait)
		local time = meta(time)
		local oldName = ""
		local violations = 0

		track("Thread: Anti Cheat tamper check", meta(function()end))
	end
end
