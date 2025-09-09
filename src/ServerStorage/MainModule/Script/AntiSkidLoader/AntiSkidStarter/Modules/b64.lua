local urlSafe = false

local suffix = "+/"

local b64chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"

local function createBinChar(char)
	local x = string.byte(char)
	local finalString = ""
	for i = 7, 0, -1 do
		local pow = 2 ^ i
		finalString ..= x / pow % 2 >= 1 and 1 or 0
	end
	return finalString
end

local function createB64BinChar(char)
	local x = string.find(b64chars .. suffix, char) - 1
	local finalString = ""
	for i = 5, 0, -1 do
		local pow = 2 ^ i
		finalString ..= x / pow % 2 >= 1 and 1 or 0
	end
	
	return finalString
end

local module = {
	base64Encode = function(text, paddings, urlSafe)
		local result = ""
		local equalsToAdd = 0

		if urlSafe then
			suffix = "-_"
		else
			suffix = "+/"
		end

		for i = 1, #text, 3 do
			-- appending the 3 bytes
			local threeBytes = ""
			for j = 0, 2 do
				if i+j <= #text then
					threeBytes ..= createBinChar(string.sub(text, i+j, i+j))
				else
					equalsToAdd += 1
				end
			end

			-- split the 3 bytes by 6 bits
			for j = 1, #threeBytes, 6 do
				local tet = string.sub(threeBytes, j, j+5)
				local finalTet = tet .. string.rep(0, 6 - #tet)

				-- finalising

				local b64digit = tonumber(finalTet, 2) + 1

				result ..= string.sub(b64chars .. suffix, b64digit, b64digit)
			end
		end

		if paddings then
			for i = 1, equalsToAdd do
				result ..= "="
			end
		end

		return result
	end,
	
	base64Decode = function(text, urlSafe)
		local result = ""

		if urlSafe then
			suffix = "-_"
		else
			suffix = "+/"
		end
		
		for i = 1, #text, 4 do
			-- splitting the 4 b64 chars
			local twentyFourBits = "" 

			-- appending back to 24 bits
			for j = 0, 3 do
				local char = string.sub(text, i+j, i+j)
				if char ~= "" then
					if char ~= "=" then
						twentyFourBits ..= createB64BinChar(char)
					end
				end
			end

			-- splitting the 24 bits by 8 bits (bytes)
			for j = 1, #twentyFourBits, 8 do
				-- appending the bytes
				local byte = string.sub(twentyFourBits, j, j+7)

				if #byte == 8 then
					result ..= string.char(tonumber(byte, 2))
				end
			end
		end

		return result
	end,
	
	generateID = function(chars, urlSafe)
		local result = ""

		if urlSafe then
			suffix = "-_"
		else
			suffix = "+/"
		end
		
		for i = 1, chars do
			local rand = math.random(1, 64)
			
			result ..= string.sub(b64chars .. suffix, rand, rand)
		end
		
		return result
	end,
}

return module