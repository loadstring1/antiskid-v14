local game=game
local pcall=pcall
local service=game.GetService
local instnew=Instance.new

if pcall(service,game,"RunService")==false then
	return false
end

if pcall(service,game,"Workspace")==false then
	return false
end

if pcall(instnew,"Hint")==false  then
	return false
end

return true