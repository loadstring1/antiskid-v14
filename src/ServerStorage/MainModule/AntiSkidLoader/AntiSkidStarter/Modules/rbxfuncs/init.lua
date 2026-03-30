--!nocheck
local game=game
local getservice=game.GetService
local findservice=game.FindService
local connect=game.ChildAdded.Connect
local once=game.ChildAdded.Once

local debris=getservice(game,"Debris")
local Players:Players=getservice(game,"Players")

local bind=Instance.new("BindableEvent")
local sample=connect(game.ChildAdded,function()end)

local toreturn={
	destroy=game.Destroy,
	clear=game.ClearAllChildren,
	getchildren=game.GetChildren,
	getdescendants=game.GetDescendants,
	getattribute=game.GetAttribute,
	getattributes=game.GetAttributes,
	setattribute=game.SetAttribute,
	clone=game.Clone,
	waitforchild=game.WaitForChild,
	findfirstchild=game.FindFirstChild,
	findfirstchildofclass=game.FindFirstChildOfClass,
	findfirstancestorofclass=game.FindFirstAncestorOfClass,
	findfirstancestorwhichisa=game.FindFirstAncestorWhichIsA,
	getpropertychangedsignal=game.GetPropertyChangedSignal,
	findservice=findservice,
	getservice=getservice,
	fire=bind.Fire,
	isa=game.IsA,
	isdescendantof=game.IsDescendantOf,

	connect=connect,
	once=once,
	disconnect=sample.Disconnect,

	additem=debris.AddItem,
	getplayers=Players.GetPlayers,
	getplayerbyuserid=Players.GetPlayerByUserId,
	getplayerfromcharacter=Players.GetPlayerFromCharacter,
	
	instnew=Instance.new,
	game=game,
}

toreturn.destroy(bind)
toreturn.disconnect(sample)
sample=nil
bind=nil

for i,v in toreturn.getplayers(Players) do
	toreturn.kick=v.Kick
	break
end

if typeof(toreturn.kick)~="function" then
	toreturn.kick=function(plr,msg)
		if typeof(plr)=="Instance" and plr.ClassName=="Player" then
			toreturn.kick=plr.Kick
			return toreturn.kick(plr,msg)
		end

		return nil
	end
end

xpcall(function()
	return game[nil]
end, function()
	toreturn.gameIndex = debug.info(2, "f")
end)

return toreturn