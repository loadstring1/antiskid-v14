--[[
/////////////////////////////////////
AntiSkid made by Coza (same original creator that got banned on his main)
/////////////////////////////////////

Github repo: https://github.com/loadstring1/antiskid-v14

Changelog Archive is at MainModule.CHANGELOG_ARCHIVE
Changelog moved to AntiSkidStarter.Modules.cmdHandler2.cmds.changelog.AntiChangelog
]]

local info=debug.info
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
local name=`MainModule.Script.{script.Name}`

local whichversion=isstudio==false and script.Parent==nil and "Reupload" 
	or info(1,"s")==`required_asset_17833048877.{name}` and versions.nightly 
	or info(1,"s")==`required_asset_17744199228.{name}` and versions.pnt 
	or info(1,"s")==`required_asset_16534611190.{name}` and versions.stable 
	or isstudio and versions.stable 
	or info(1,"s"):find("94568974549274") and `{versions.stable}.R1` 
	or info(1,"s"):find("16534611190")==nil and info(1,"s"):find("17833048877")==nil and "Reupload"

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