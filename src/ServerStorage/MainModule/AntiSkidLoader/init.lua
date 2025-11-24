--[[
/////////////////////////////////////
AntiSkid made by Coza (same original creator that got banned on his main)
/////////////////////////////////////

Github repo: https://github.com/loadstring1/antiskid-v14

Changelog Archive is at MainModule.CHANGELOG_ARCHIVE
Changelog moved to AntiSkidStarter.Modules.cmdHandler2.cmds.changelog.AntiChangelog
]]

local info=debug.info
local split=string.split
local require=require
local game=game
local table=table
local pcall=pcall
local script=script
local task=task
local setmetatable=setmetatable
local print=print
local setfenv=setfenv

local clone=game.Clone
local service=game.GetService
local setattribute=game.SetAttribute

setfenv(0, table.freeze{})
setfenv(1, table.freeze{})

local run=service(game,"RunService")
local isstudio=run.IsStudio(run)

local org=clone(script.AntiSkidStarter)
local versions=require(clone(script.versions))

local source=split(info(1,"s"),".")[1]

local whichversion=isstudio==false and script.Parent==nil and "Reupload" 
	or source==`required_asset_17833048877` and versions.nightly 
	or source==`required_asset_17744199228` and versions.pnt 
	or source==`required_asset_16534611190` and versions.stable 
	or source==`required_asset_94568974549274` and `{versions.stable}.R1` 
	or isstudio and versions.stable 
	or "Reupload"

if whichversion==versions.nightly or whichversion==versions.pnt then
	task.spawn(pcall,function()
		print(service(game,"MarketplaceService"):GetProductInfo(whichversion==versions.nightly and 17833048877 or 17744199228).Updated)
	end)
end

org.Name = `AntiSkid {whichversion}`
setattribute(org,"version",whichversion)
task.spawn(require,org)
org=nil

local faketbl={}
local meta={}
local frozen=table.freeze{}

function meta:__index()
	return faketbl
end

function meta:__call()end

setmetatable(faketbl,meta)
table.freeze(faketbl)
meta.__metatable=frozen
table.freeze(meta)

return faketbl