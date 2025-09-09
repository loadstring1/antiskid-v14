local game=game
local getservice=game.GetService
local findservice=game.FindService
local connect=game.ChildAdded.Connect

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
	local temp
	temp=toreturn.connect(Players.PlayerAdded,function(plr)
		if temp==nil then return end
		toreturn.kick=plr.Kick
		toreturn.disconnect(temp)
		temp=nil
	end)
end

xpcall(function()
	return game[{}]
end, function()
	toreturn.gameIndex = debug.info(2, "f")
end)

function toreturn.init(funcs)
	toreturn.init=nil
	
	if funcs.isClient and toreturn.findfirstchildofclass(script,"Actor")==nil then return toreturn end
	require(script.act.parallel).init(funcs,toreturn)
	
	return toreturn
end

return toreturn