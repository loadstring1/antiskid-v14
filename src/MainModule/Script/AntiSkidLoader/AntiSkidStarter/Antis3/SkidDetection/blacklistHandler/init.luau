local module = {}

for i,v in script.GetChildren(script) do
	module[v.Name]=require(v)
end

return table.freeze(module)