local module=script:FindFirstChildWhichIsA("ModuleScript",true)
local success,result=pcall(require,module)

if success==false then
	local faketbl={}
	local meta={}
	local frozen=table.freeze{}
	local frozenDescendants:{ [Instance]: {} }={}

	local localizedClone=game.Clone
	local cloneSuccess,clonedAntiskid=pcall(localizedClone,module)

	if cloneSuccess==false then
		module:FindFirstChild("crossroads",true):Destroy()

		frozenDescendants[module]={}
		for i,v in module:GetDescendants() do
			frozenDescendants[v]={}
		end

		for i,v in frozenDescendants do
			local props={}
			v.Properties=props

			props.Name=i.Name
			props.Archivable=i.Archivable
			props.Parent=i.Parent

			if i:IsA("BaseScript") then
				props.Enabled=i.Enabled
			end

			if i:IsA("BasePart") then
				props.Anchored=i.Anchored
			end

			v.Inst=i

			table.freeze(props)
			table.freeze(v)
		end

		table.freeze(frozenDescendants)
		module:Destroy()
	end

	function meta:__index()
		return faketbl
	end

	function meta:__call()
		if cloneSuccess then
			return localizedClone(clonedAntiskid)
		end

		return module,frozenDescendants
	end

	setmetatable(faketbl,meta)
	table.freeze(faketbl)
	meta.__metatable=frozen
	table.freeze(meta)

	return faketbl
end

module.Parent=nil
script:ClearAllChildren()
module.Parent=script
return result