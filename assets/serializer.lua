--!native
--!optimize 2
--!nocheck
--!nolint

-- localize luau api functions for faster access, avoid having to invoke the internal metamethods to fetch a function like "new" from Instance (Instance.new)
local Instance_new = Instance.new
local table_insert = table.insert
local table_create = table.create
local string_format = string.format
local buffer_tostring = buffer.tostring
local buffer_fromstring = buffer.fromstring
local table_clear = table.clear
local debug_info = debug.info
local os_clock = os.clock
local typeof = typeof
local type = type
local pcall = pcall
local print = print
local warn = warn
local error = error
local select = select
local pairs = pairs
local ipairs = ipairs
local rawset=rawset
local setmetatable=setmetatable
local game=game
local buffer=buffer
local string=string
local script=script
local vector=vector
local CFrame=CFrame
local Vector2=Vector2
local Enum=Enum
local Vector3=Vector3
local BrickColor=BrickColor
local Color3=Color3
local ColorSequence=ColorSequence
local ColorSequenceKeypoint=ColorSequenceKeypoint
local math=math
local UDim=UDim
local UDim2=UDim2
local Content=Content
local Font=Font
local DateTime=DateTime
local NumberRange=NumberRange
local NumberSequence=NumberSequence
local NumberSequenceKeypoint=NumberSequenceKeypoint
local PhysicalProperties=PhysicalProperties
local Rect=Rect
local Ray=Ray
local table=table

local NULL = nil
local EMPTY_TABLE = {}

local AssetService = game:GetService("AssetService")
local ReflectionServiceWrapper = (function()
    -- TODO: replace with ReflectionService when available

    local HttpService = game:GetService("HttpService")
    local RawApiDump
    local IsApiInitialized = false
    local Classes = {}
    local DefaultProperties = {}

    local function loadUntilCached()
        local success,result=pcall(function()
            return HttpService:GetAsync("https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/refs/heads/roblox/API-Dump.json")
        end)

        if success and result then
            RawApiDump=result
            return
        end

        task.wait()
        return loadUntilCached()
    end

    loadUntilCached()

    DefaultProperties.InitializeApiDump = function()
        local Decoded = HttpService:JSONDecode(RawApiDump)
        local DecodedClasses = Decoded.Classes
        
        for Position, Class in pairs(DecodedClasses) do
            local Tags = Class.Tags
            local Members = Class.Members
            local ClassName = Class.Name
            
            -- filter out services
            if Tags then
                for _, Tag in pairs(Tags) do
                    if Tag == "Service" then
                        DecodedClasses[Position] = nil
                        continue
                    end
                end
            end
            
            -- filter out properties locked behind capabilities, filter out members that are not properties, filter out hidden properties, etc
            if Members then
                for MemberPosition, Property in pairs(Members) do
                    local Type = Property.MemberType
                    local Tags = Property.Tags
                    local Name = Property.Name
                    local NameFirstLetter = Name:sub(1, 1)
                    local Security = Property.Security
                    local SecurityType = type(Security)
                    
                    if Type ~= "Property" then
                        Members[MemberPosition] = nil
                        continue
                    end
                    
                    if Tags then
                        for _, Tag in pairs(Tags) do
                            if Tag == "NotScriptable" or Tag == "ReadOnly" then
                                Members[MemberPosition] = nil
                                continue
                            end
                        end
                    end
                    
                    -- filter out legacy property references
                    if NameFirstLetter == NameFirstLetter:lower() then
                        Members[MemberPosition] = nil
                        continue
                    end
                    
                    if SecurityType == "string" then
                        if Security ~= "None" then
                            Members[MemberPosition] = nil
                            continue
                        end
                    elseif SecurityType == "table" then
                        if Security.Read ~= "None" then -- we will include properties that can be read but not written
                            Members[MemberPosition] = nil
                            continue
                        end
                    end
                end
            end
        end
        
        for _, Class in pairs(DecodedClasses) do
            local Superclass = Class.Superclass
            local Members = Class.Members
            local ClassName = Class.Name
            
            Classes[ClassName] = {
                Superclass = Superclass,
                Members = Members
            }
        end
        
        IsApiInitialized = true
        
        return true
    end

    DefaultProperties.IsApiInitialized = function()
        return IsApiInitialized
    end

    DefaultProperties.GetPropertiesOfClass = function(ClassName)
        local Properties = {}
        local IterateThroughProperties
        
        IterateThroughProperties = function(ClassName)
            local ClassInfo = Classes[ClassName]
            
            if ClassInfo then
                local Members = ClassInfo.Members
                local Superclass = ClassInfo.Superclass

                for Position, Property in pairs(Members) do
                    local Name = Property.Name
                    
                    if not table.find(Properties, Name) then -- todo: dont use table.find and table.insert
                        table.insert(Properties, Name)
                    end
                end
                
                if Superclass then
                    IterateThroughProperties(Superclass)
                end
            end
        end
        
        IterateThroughProperties(ClassName)
        
        return Properties
    end

    DefaultProperties.GetClasses = function()
        return Classes
    end

    return DefaultProperties
end)()

local BufferEncoder = (function()
    local Settings=(function()
        return {
            color3always6bytes = false;
            rbxenum_behavior = "full" :: "full" | "compact";

            serverclientsyncing = false;
            sanitize_nanandinf = false;
        }
    end)()

    local Enums=(function()
        local RS = game:GetService("RunService")

        local SyncingEnabled = Settings.serverclientsyncing
        local IsSyncOrigin = if SyncingEnabled then RS:IsServer() else true

        local nametovalue: {[string]: any} = {}
        local bytetovalue: {[number]: any} = {
            [2] = true,
            [3] = false,
            [102] = "",
            [103] = 0,
            [104] = 1,
            [105] = -1,
            [106] = if Settings.sanitize_nanandinf then 0 else math.huge,
            [107] = if Settings.sanitize_nanandinf then 0 else -math.huge,
            [108] = if Settings.sanitize_nanandinf then 0 else 0 / 0,
        }

        local valuetobyte: {[any]: number} = {
            [true] = 2,
            [false] = 3,
            [""] = 102,
            [0] = 103,
            [1] = 104,
            [-1] = 105,
            [math.huge] = 106,
            [-math.huge] = 107,
            -- no nan since nan will error if in table
        }

        local freebytes
        local currentposition = 0

        local function sanitizename(name)
            if type(name) ~= "string" then
                error(`expected name to be a string, got {typeof(name)}`, 0)
            end
            if name == "" then
                error("name should not be an empty string", 0)
            end

            return string.gsub(name, "[^%w_]", "_") -- turn everything that isnt %w and _ into _
        end

        -- Removes the value associated with 'name' from byte registry.
        local function removename(name: string)
            name = sanitizename(name)

            local value = nametovalue[name]

            if value then
                local oldbyte = valuetobyte[value]
                valuetobyte[value] = nil

                if bytetovalue[oldbyte] == value then
                    bytetovalue[oldbyte] = nil
                end

                if IsSyncOrigin then
                    table.insert(freebytes, oldbyte)
                    nametovalue[name] = nil -- not done on client because this is called whenever the attribute is changed, and current value is needed
                    
                    if SyncingEnabled then
                        script:SetAttribute(name, nil)
                    end
                end
            end
        end

        if not IsSyncOrigin then
            local function attributechanged(name, byte)
                removename(name)

                byte = byte or script:GetAttribute(name)

                if byte then
                    local value = nametovalue[name]

                    if not value then
                        value = newproxy()
                        nametovalue[name] = value
                    end

                    valuetobyte[value] = byte
                    bytetovalue[byte] = value
                else
                    nametovalue[name] = nil
                end
            end

            script.AttributeChanged:Connect(attributechanged)
            for name, value in script:GetAttributes() do
                attributechanged(name, value)
            end
        else
            freebytes = {}
        end

        return {
            bytetovalue = bytetovalue,
            nametovalue = nametovalue,

            valuetobyte = valuetobyte,

            --[[
            Assigns 2 bytes to the name and returns the value that is encoded as the byte.
            Registered names are synced from server to client.
            ]]
            register = function(name: string, predefined: any?): any
                name = sanitizename(name)

                if valuetobyte[predefined] then
                    error(`cannot define {name} with the value {predefined} as the value is already defined`, 0)
                end

                if nametovalue[name] then
                    if predefined then
                        local oldvalue = nametovalue[name]
                        local byte = valuetobyte[oldvalue]

                        nametovalue[name] = predefined

                        if byte then
                            valuetobyte[oldvalue] = nil
                            valuetobyte[predefined] = byte
                            bytetovalue[byte] = predefined
                        end
                    end

                    return nametovalue[name]
                end

                local v = predefined or newproxy()

                if IsSyncOrigin then
                    local byte = table.remove(freebytes)

                    if not byte then
                        byte = currentposition - 1
                        currentposition = byte
                    end

                    nametovalue[name] = v
                    valuetobyte[v] = byte
                    bytetovalue[byte] = v

                    if SyncingEnabled then
                        script:SetAttribute(name, byte)
                    end
                else
                    nametovalue[name] = v
                end

                return v
            end,

            remove = removename,
        }
    end)()

    local Miscellaneous=(function()
        local floatencoder = (function()
            local function readf16(buff: buffer, cursor: number): number
                local n: number = buffer.readu16(buff, cursor)
                local mantissa: number, exponent: number, sign: number = bit32.extract(n, 0, 10), 
                                                                        bit32.extract(n, 10, 5), 
                                                                        bit32.extract(n, 15, 1)

                if mantissa == 0b0000000000 then
                    if exponent == 0b00000 then return 0
                    elseif exponent == 0b11111 then 
                        return if sign == 1 then -math.huge else math.huge 
                    end
                elseif exponent == 0b11111 then return 0/0 end 
                
                local value: number = ((mantissa / 1024) + 1) * 2 ^ (exponent - 15)

                if sign == 1 then return -value end 
                return value
            end

            local function writef16(buff: buffer, cursor: number, value: number): ()
                if value == 0 then buffer.writeu16(buff, cursor, 0)
                elseif value >= 65520 then buffer.writeu16(buff, cursor, 0b0_11111_0000000000)
                elseif value <= -65520 then buffer.writeu16(buff, cursor, 0b1_11111_0000000000)
                elseif value ~= value then buffer.writeu16(buff, cursor, 0b0_11111_0000000001)
                else
                    local sign: number = 0

                    if value < 0 then 
                        sign = 1 
                        value = -value 
                    end

                    local mantissa: number, exponent: number = math.frexp(value)
                    if exponent < -14 then -- safeguard against tiny exponents like -20
                        buffer.writeu16(buff, cursor, 0)
                        return 
                    end

                    buffer.writeu16(buff, cursor, bit32.bor((mantissa * 2048 - 1023.5), (exponent + 14) * 2^10, (sign) * 2^15))
                end
            end


            return {
                writef16 = writef16;
                readf16 = readf16;
            }
        end)()

        local SanitizingEnabled = Settings.sanitize_nanandinf

        local FP_EPSILON = 1e-6
        local I16_PRECISION = 32767                 -- int16 range { -32,786, 32,767 }
        local BUFF_CFRAME_SIZE = (3*4) + (1 + 3*2)  -- i.e. 3x f32, 1x u8 and 3x i16

        local cframe_ToAxisAngle = CFrame.identity.ToAxisAngle

        local function getNormalisedQuaternion(cframe: CFrame)
            local axis_shadowed, angle = cframe_ToAxisAngle(cframe)
            local ha = angle / 2

            local axis: vector = if vector.magnitude(axis_shadowed) > FP_EPSILON then vector.normalize(axis_shadowed) else (Vector3.xAxis :: any)
            axis *= math.sin(ha)
            
            local w = math.cos(ha)
            local length = math.sqrt(vector.dot(axis, axis) + w*w)
            
            if length < FP_EPSILON then 
                return 0, 0, 0, 1 
            end
            
            axis /= length
            return axis.x, axis.y, axis.z, w / length
        end

        local function compressQuaternion(cframe)
            local qx, qy, qz, qw = getNormalisedQuaternion(cframe)

            local index = -1
            local value = -math.huge

            local sign
            for i = 1, 4, 1 do
                local val = select(i, qx, qy, qz, qw)
                local abs = math.abs(val)
                if abs > value then
                    index = i
                    value = abs
                    sign = val
                end
            end
            sign = sign >= 0 and 1 or -1

            local v0, v1, v2
            if index == 1 then
                v0 = math.floor(qy * sign * I16_PRECISION + 0.5)
                v1 = math.floor(qz * sign * I16_PRECISION + 0.5)
                v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
            elseif index == 2 then
                v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
                v1 = math.floor(qz * sign * I16_PRECISION + 0.5)
                v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
            elseif index == 3 then
                v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
                v1 = math.floor(qy * sign * I16_PRECISION + 0.5)
                v2 = math.floor(qw * sign * I16_PRECISION + 0.5)
            elseif index == 4 then
                v0 = math.floor(qx * sign * I16_PRECISION + 0.5)
                v1 = math.floor(qy * sign * I16_PRECISION + 0.5)
                v2 = math.floor(qz * sign * I16_PRECISION + 0.5)
            end

            return index, v0, v1, v2
        end

        local function decompressQuaternion(index, v0, v1, v2)
            v0 /= I16_PRECISION
            v1 /= I16_PRECISION
            v2 /= I16_PRECISION

            local d = math.sqrt(1 - (v0*v0 + v1*v1 + v2*v2))
            if index == 1 then
                return d, v0, v1, v2
            elseif index == 2 then
                return v0, d, v1, v2
            elseif index == 3 then
                return v0, v1, d, v2
            end

            return v0, v1, v2, d
        end

        local function write(buf: buffer, offset: number, input: CFrame)
            local pos = input.Position

            buffer.writef32(buf, offset, pos.X)
            buffer.writef32(buf, offset + 4, pos.Y)
            buffer.writef32(buf, offset + 8, pos.Z)

            local qi, q0, q1, q2 = compressQuaternion(input)
            buffer.writeu8(buf, offset + 12, qi)
            buffer.writei16(buf, offset + 13, q0)
            buffer.writei16(buf, offset + 15, q1)
            buffer.writei16(buf, offset + 17, q2)
        end

        local function read(buf: buffer, byte: number, offset: number): (CFrame, number)
            local x = buffer.readf32(buf, offset)
            local y = buffer.readf32(buf, offset + 4)
            local z = buffer.readf32(buf, offset + 8)

            if SanitizingEnabled then
                if (x / x) ~= 1 then x = 0 end
                if (y / y) ~= 1 then y = 0 end
                if (z / z) ~= 1 then z = 0 end
            end

            local qi = buffer.readu8(buf, offset + 12)
            local q0 = buffer.readi16(buf, offset + 13)
            local q1 = buffer.readi16(buf, offset + 15)
            local q2 = buffer.readi16(buf, offset + 17)

            local qx, qy, qz, qw = decompressQuaternion(qi, q0, q1, q2)
            return CFrame.new(x, y, z, qx, qy, qz, qw), offset + BUFF_CFRAME_SIZE
        end

        return {
            readCFrame = read,
            writeCFrame = write,

            cframesize = BUFF_CFRAME_SIZE,
            
            writef16 = floatencoder.writef16;
            readf16 = floatencoder.readf16;
        }
    end)()

    local RbxEnumEncoder=(function()
        local RS = game:GetService("RunService")

        local enumitem_to_type = {}
        local enumitem_to_value = {}


        local exposed = {
            enumitem_to_type = enumitem_to_type;
            enumitem_to_value = enumitem_to_value;
        }

        for _, enum in Enum:GetEnums() do 
            local n = tostring(enum)

            enumitem_to_type[enum] = n
            
            for _, enumitem in enum:GetEnumItems() do 
                enumitem_to_type[enumitem] = n
                enumitem_to_value[enumitem] = enumitem.Value 
            end
        end

        -- encode enums as <19> <u8 length> <string>
        -- encode enumitems as <20> <u8 length> <string> <u16 value>
        if Settings.rbxenum_behavior == "full" then
            local nametoenum = {}
            for _, v in Enum:GetEnums() do
                nametoenum[tostring(v)] = v
            end
            -- this is to avoid erroring due to version mismatch when decoding

            local enum_FromValue = (Enum.Material :: any).FromValue

            @native
            function exposed.encodeEnum(buf: buffer, offset: number, enum: Enum): number
                local name = enumitem_to_type[enum]
                local length = #name

                buffer.writeu8(buf, offset, length); offset += 1
                buffer.writestring(buf, offset, name)

                return offset + length
            end

            @native
            function exposed.encodeEnumItem(buf: buffer, offset: number, enumitem: EnumItem): number
                offset = exposed.encodeEnum(buf, offset, enumitem :: any)
                buffer.writeu16(buf, offset, enumitem_to_value[enumitem])

                return offset + 2
            end

            @native
            function exposed.decodeEnum(buf: buffer, byte: number, cursor: number): (Enum, number, boolean?)
                local length = buffer.readu8(buf, cursor); cursor += 1
                local name = buffer.readstring(buf, cursor, length)

                return nametoenum[name], cursor + length, true
            end

            @native
            function exposed.decodeEnumItem(buf: buffer, byte: number, cursor: number): (EnumItem, number, boolean?)
                local enum, newcursor = exposed.decodeEnum(buf, byte, cursor)
                local value = buffer.readu16(buf, newcursor)

                return enum and enum_FromValue(enum, value), newcursor + 2, true
            end

            -- encode enums as <19> <u16 index>
            -- encode enumitems as <20> <u16 index>
            -- syncing table between client & server is necessary to avoid issues due to version mismatch
        elseif Settings.rbxenum_behavior == "compact" then
            local enumarray: { Enum } = {}
            local enumitemarray: { EnumItem } = {}
            local valuelookup: { [any]: number } = {}

            local SyncingEnabled = Settings.serverclientsyncing
            local IsSyncOrigin = if SyncingEnabled then RS:IsServer() else true

            if IsSyncOrigin then
                local tosend1, tosend2

                if SyncingEnabled then
                    tosend1, tosend2 = {}, {}
                    local request: RemoteFunction = script:FindFirstChild("request")
            
                    if request == nil then
                        request = Instance.new("RemoteFunction")
                        request.Name = "request"
                        request.Parent = script
                    end

                    request.OnServerInvoke = function(player, v)
                        return tosend1, tosend2
                    end
                else 
                    tosend1, tosend2 = nil, nil
                end

                do
                    -- using tostring on index because the enum/enumitem may not exist
                    -- which will lead to gaps getting created when syncing

                    local enum_i, enumitem_i = 0, 0
                    for _, k in Enum:GetEnums() do
                        enum_i += 1
                        enumarray[enum_i] = k
                        valuelookup[k] = enum_i

                        if tosend1 then tosend1[tostring(enum_i)] = k end

                        for _, v in k:GetEnumItems() do
                            enumitem_i += 1
                            enumitemarray[enumitem_i] = v
                            valuelookup[v] = enumitem_i

                            if tosend2 then tosend2[tostring(enumitem_i)] = v end
                        end
                    end
                end
            else
                task.spawn(function()
                    local request = script:WaitForChild("request")

                    local function addtoarray(toarray, fromdict, todict)
                        local lastnum = 0
                        
                        for k, v in fromdict do
                            k = tonumber(k)
                            toarray[k] = v
                            valuelookup[v] = k

                            lastnum = math.max(lastnum, k)
                        end

                        -- fill gaps
                        for i = 1, lastnum do
                            if toarray[i] == nil then toarray[i] = false end
                        end
                    end

                    while true do
                        local success, r1, r2 = pcall(request.InvokeServer, request)

                        if success and r1 and r2 then
                            addtoarray(enumarray, r1)
                            addtoarray(enumitemarray, r2)

                            break
                        else
                            task.wait(3)
                        end
                    end
                end)
            end

            @native
            function exposed.encodeEnum(buf: buffer, offset: number, value: Enum): number
                local position = valuelookup[value]
                buffer.writeu16(buf, offset, position or 0) 

                return offset + 2
            end

            exposed.encodeEnumItem = (exposed.encodeEnum :: any) :: (buf: buffer, offset: number, value: EnumItem) -> number

            @native
            function exposed.decodeEnum(buf: buffer, byte: number, cursor: number): (Enum, number)
                local position = buffer.readu16(buf, cursor)
                return enumarray[position], cursor + 2
            end

            @native
            function exposed.decodeEnumItem(buf: buffer, byte: number, cursor: number): (EnumItem, number)
                local position = buffer.readu16(buf, cursor)
                return enumitemarray[position], cursor + 2
            end
        else
            error(`{Settings.rbxenum_behavior} is not a valid enum encoding behavior, options are ('full', 'compact')`, 0)
        end

        return exposed
    end)()

    local ReadDatatypes=(function()
        local bytetofunction = {}
        local bytetodatatype = {}

        local cachedTables={
            ["BrickColor"]=(function()
                local brickcolorbyte = 30

                return {
                    [brickcolorbyte] = @native function(buff: buffer, byte: number, cursor: number): (BrickColor, number)
                        return BrickColor.new(buffer.readu16(buff, cursor)), cursor + 2
                    end;
                }
            end)(),
            ["CFrame"]=(function()
                local cframebyte = 17

                return {
                    [cframebyte] = Miscellaneous.readCFrame
                
                }
            end)(),
            ["Color3"]=(function()
                local color3always6bytes = Settings.color3always6bytes
                local readf16 = Miscellaneous.readf16

                local u8colorbyte = 23
                local f16colorbyte = 24

                local writebytesign

                return {
                    [u8colorbyte] = @native function(buff: buffer, byte: number, cursor: number): (Color3, number)
                        local r, g, b = buffer.readu8(buff, cursor), buffer.readu8(buff, cursor + 1), buffer.readu8(buff, cursor + 2)
                        return Color3.fromRGB(r, g, b), cursor + 3
                    end;

                    [f16colorbyte] = @native function(buff: buffer, byte: number, cursor: number): (Color3, number)
                        local r, g, b = readf16(buff, cursor), readf16(buff, cursor + 2), readf16(buff, cursor + 4)
                        return Color3.new(r, g, b), cursor + 6
                    end;
                }
            end)(),
            ["ColorSequence"]=(function()
                local colorbyte = 25
                local uI16_max = (2 ^ 16) - 1

                return {            
                    [colorbyte] = @native function(buff: buffer, byte: number, cursor: number): (ColorSequence, number)
                        local length = buffer.readu8(buff, cursor); cursor += 1
                        local tbl = table.create(length)

                        for i = 1, length do 
                            local time = math.clamp(buffer.readu16(buff, cursor) / uI16_max, 0, 1)
                            local r, g, b = buffer.readu8(buff, cursor + 2), buffer.readu8(buff, cursor + 3), buffer.readu8(buff, cursor + 4); cursor += 5
                        
                            tbl[i] = ColorSequenceKeypoint.new(time, Color3.fromRGB(r, g, b))
                        end
                        
                        return ColorSequence.new(tbl), cursor
                    end;
                }
            end)(),
            ["ContentAndFont"]=(function()
                local contentbyte = 33
                local fontbyte = 34
                local writebytesign

                local FromValue = (Enum.FontWeight :: any).FromValue -- localizing it to silence errors 😭

                return {
                    [contentbyte] = @native function(buff: buffer, byte: number, cursor: number): (Content, number)
                        local length = buffer.readu8(buff, cursor); cursor += 1

                        if length == 0 then 
                            return Content.none, cursor
                        elseif length == 1 then
                            local num = buffer.readf64(buff, cursor)
                            return Content.fromAssetId(num), cursor + 8
                        else
                            length -= 1
                            
                            local uri = buffer.readstring(buff, cursor, length)
                            return Content.fromUri(uri), cursor + length
                        end
                    end;

                    [fontbyte] = @native function(buff: buffer, byte: number, cursor: number): (Font, number)
                        local length = buffer.readu8(buff, cursor); cursor += 1

                        if length == 0 then 
                            local num = buffer.readf64(buff, cursor); cursor += 8

                            local weightv, stylev = buffer.readu16(buff, cursor), buffer.readu8(buff, cursor + 2)
                            return Font.fromId(num, FromValue(Enum.FontWeight, weightv), FromValue(Enum.FontStyle, stylev)), cursor + 3
                        else
                            length -= 1
                            local familyname = buffer.readstring(buff, cursor, length); cursor += length
                            if familyname == "" then familyname = "Arimo" end 

                            local weightv, stylev = buffer.readu16(buff, cursor), buffer.readu8(buff, cursor + 2)
                            -- not using FromName because familyname can be empty
                            return Font.new(`rbxasset://fonts/families/{familyname}.json`, FromValue(Enum.FontWeight, weightv), FromValue(Enum.FontStyle, stylev)), cursor + 3
                        end
                    end;
                }
            end)(),
            ["DateTime"]=(function()
                local datetimebyte = 35

                return {
                    [datetimebyte] = @native function(buff: buffer, byte: number, cursor: number): (DateTime, number)
                        local unixmillis = buffer.readf64(buff, cursor)
                        return DateTime.fromUnixTimestampMillis(unixmillis), cursor + 8
                    end;
                }
            end)(),
            ["EnumAndEnumItem"]=(function()
                local enumbyte = 19
                local enumitembyte = 20

                return {
                    [enumbyte] = RbxEnumEncoder.decodeEnum;
                    [enumitembyte] = RbxEnumEncoder.decodeEnumItem;
                }
            end)(),
            ["NumberRange"]=(function()
                local numberbyte = 21

                return {
                    [numberbyte] = @native function(buff: buffer, byte: number, cursor: number): (NumberRange, number)
                        local min = buffer.readf32(buff, cursor)
                        local max = buffer.readf32(buff, cursor + 4)

                        return NumberRange.new(min, max), cursor + 8
                    end;
                }
            end)(),
            ["NumberSequence"]=(function()
                local readf16 = Miscellaneous.readf16

                local numberbyte = 22
                local writebytesign

                local uI16_max = (2 ^ 16) - 1

                return {            
                    [numberbyte] = @native function(buff: buffer, byte: number, cursor: number): (NumberSequence, number)
                        local length = buffer.readu8(buff, cursor); cursor += 1
                        local tbl = table.create(length)
                        
                        for i = 1, length do 
                            local time = math.clamp(buffer.readu16(buff, cursor) / uI16_max, 0, 1)
                            local value = buffer.readf32(buff, cursor + 2)
                            local envelope = readf16(buff, cursor + 6); cursor += 8
                            
                            tbl[i] = NumberSequenceKeypoint.new(time, value, envelope)
                        end
                        
                        return NumberSequence.new(tbl), cursor
                    end;
                }
            end)(),
            ["PhysicalProperties"]=(function()
                local physpropsbyte = 29
                return {
                    [physpropsbyte] = @native function(buff: buffer, byte: number, cursor: number): (PhysicalProperties, number)
                        local Density = buffer.readf32(buff, cursor)
                        local Friction = buffer.readf32(buff, cursor + 4)
                        local Elasticity = buffer.readf32(buff, cursor + 8)
                        local FrictionWeight = buffer.readf32(buff, cursor + 12)
                        local ElasticityWeight = buffer.readf32(buff, cursor + 16)
                        
                        return PhysicalProperties.new(Density, Friction, Elasticity, FrictionWeight, ElasticityWeight),
                            cursor + 20
                    end;
                }
            end)(),
            ["Ray"]=(function()
                local SanitizingEnabled = Settings.sanitize_nanandinf
                local raybyte = 18

                return {
                    [raybyte] = @native function(buff: buffer, byte: number, cursor: number): (Ray, number)
                        local ox = buffer.readf32(buff, cursor); cursor += 4
                        local oy = buffer.readf32(buff, cursor); cursor += 4
                        local oz = buffer.readf32(buff, cursor); cursor += 4
                        local dx = buffer.readf32(buff, cursor); cursor += 4
                        local dy = buffer.readf32(buff, cursor); cursor += 4
                        local dz = buffer.readf32(buff, cursor); cursor += 4

                        if SanitizingEnabled then
                            if (ox / ox) ~= 1 then ox = 0 end
                            if (oy / oy) ~= 1 then oy = 0 end
                            if (oz / oz) ~= 1 then oz = 0 end
                            if (dx / dx) ~= 1 then dx = 0 end
                            if (dy / dy) ~= 1 then dy = 0 end
                            if (dz / dz) ~= 1 then dz = 0 end
                        end

                        return Ray.new(Vector3.new(ox, oy, oz), Vector3.new(dx, dy, dz)), cursor
                    end;
                }
            end)(),
            ["Rect"]=(function()
                local rectbyte = 28

                return {
                    [rectbyte] = @native function(buff: buffer, byte: number, cursor: number): (Rect, number)
                        local xmin = buffer.readf32(buff, cursor)
                        local ymin = buffer.readf32(buff, cursor + 4)
                        local xmax = buffer.readf32(buff, cursor + 8)
                        local ymax = buffer.readf32(buff, cursor + 12)

                        return Rect.new(xmin, ymin, xmax, ymax), cursor + 16
                    end;
                }
            end)(),
            ["UDim"]=(function()
                local udimbyte = 26

                return {
                    [udimbyte] = @native function(buff: buffer, byte: number, cursor: number): (UDim, number)
                        local scale = buffer.readf32(buff, cursor)
                        local offset = buffer.readi32(buff, cursor + 4)

                        return UDim.new(scale, offset), cursor + 8
                    end;
                }
            end)(),
            ["UDim2"]=(function()
                local udim2byte = 27

                return {
                    [udim2byte] = @native function(buff: buffer, byte: number, cursor: number): (UDim2, number)
                        local xscale = buffer.readf32(buff, cursor)
                        local xoffset = buffer.readi32(buff, cursor + 4)
                        local yscale = buffer.readf32(buff, cursor + 8)
                        local yoffset = buffer.readi32(buff, cursor + 12)
                        
                        return UDim2.new(xscale, xoffset, yscale, yoffset), cursor + 16
                    end;
                }
            end)(),
            ["Vector2"]=(function()
                local SanitizingEnabled = Settings.sanitize_nanandinf

                local vectorbyte = 16
                local vectorint16byte = 32

                return {
                    [vectorbyte] = @native function(buff: buffer, byte: number, cursor: number): (Vector2, number)
                        local x = buffer.readf32(buff, cursor)
                        local y = buffer.readf32(buff, cursor + 4)

                        if SanitizingEnabled then
                            if (x / x) ~= 1 then x = 0 end
                            if (y / y) ~= 1 then y = 0 end
                        end

                        return Vector2.new(x, y), cursor + 8
                    end;

                    [vectorint16byte] = @native function(buff: buffer, byte: number, cursor: number): (Vector2int16, number)
                        local x = buffer.readi16(buff, cursor)
                        local y = buffer.readi16(buff, cursor + 2)

                        return Vector2int16.new(x, y), cursor + 4
                    end;
                }
            end)(),
            ["Vector3"]=(function()
                local SanitizingEnabled = Settings.sanitize_nanandinf

                local vectorbyte = 15
                local vectorint16byte = 31

                return {
                    [vectorbyte] = @native function(buff: buffer, byte: number, cursor: number): (vector, number, boolean?)
                        local x = buffer.readf32(buff, cursor)
                        local y = buffer.readf32(buff, cursor + 4)
                        local z = buffer.readf32(buff, cursor + 8)

                        -- need to check if deduplication is possible as if nan exists, the vector
                        -- cannot be deduplicated during writing process, thus would cause value positions to get shifted
                        local candeduplicate = true
                        local vec

                        if SanitizingEnabled then
                            candeduplicate = x == x and y == y and z == z

                            if (x / x) ~= 1 then x = 0 end
                            if (y / y) ~= 1 then y = 0 end
                            if (z / z) ~= 1 then z = 0 end

                            vec = vector.create(x, y, z)
                        else 
                            vec = vector.create(x, y, z)
                            candeduplicate = vec == vec
                        end

                        return vec, cursor + 12, candeduplicate
                    end;

                    [vectorint16byte] = @native function(buff: buffer, byte: number, cursor: number): (Vector3int16, number)
                        local x = buffer.readi16(buff, cursor)
                        local y = buffer.readi16(buff, cursor + 2)
                        local z = buffer.readi16(buff, cursor + 4)

                        return Vector3int16.new(x, y, z), cursor + 6
                    end;
                }
            end)(),
            ["buffer"]=(function()
                local bufferu8byte = 12
                local bufferu16byte = 13
                local bufferu32byte = 14

                @native
                local function readbuffer(buff: buffer, byte: number, cursor: number, info): (buffer, number)
                    local length 
                            
                    if byte == bufferu8byte then length = buffer.readu8(buff, cursor); cursor += 1
                    elseif byte == bufferu16byte then length = buffer.readu16(buff, cursor); cursor += 2
                    else length = buffer.readu32(buff, cursor); cursor += 4 end
                    
                    local value = buffer.create(length)
                    buffer.copy(value, 0, buff, cursor, length)

                    return value, cursor + length
                end

                return {
                    [bufferu8byte] = readbuffer;
                    [bufferu16byte] = readbuffer;
                    [bufferu32byte] = readbuffer;
                }
            end)(),
            ["number"]=(function()
                local bytetovalue = Enums.bytetovalue

                local nanbyte = 108

                local u8numbyte = 5
                local n_u8numbyte = 8

                local u16numbyte = 6
                local n_u16numbyte = 9

                local u32numbyte = 7
                local n_u32numbyte = 10

                local floatnumbyte = 11

                local writebytesign

                local t = {
                    [u8numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        return buffer.readu8(buff, cursor), cursor + 1
                    end;
                    [n_u8numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        return -buffer.readu8(buff, cursor), cursor + 1
                    end;

                    [u16numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        return buffer.readu16(buff, cursor), cursor + 2, true
                    end;
                    [n_u16numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        return -buffer.readu16(buff, cursor), cursor + 2, true
                    end;

                    [u32numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        return buffer.readu32(buff, cursor), cursor + 4, true
                    end;
                    [n_u32numbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        return -buffer.readu32(buff, cursor), cursor + 4, true
                    end;
                }

                if Settings.sanitize_nanandinf then
                    t[floatnumbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        local n = buffer.readf64(buff, cursor)
                        return if (n / n) ~= 1 then 0 else n, cursor + 8, true
                    end
                else 
                    t[floatnumbyte] = @native function(buff: buffer, byte: number, cursor: number): (number, number, boolean?)
                        return buffer.readf64(buff, cursor), cursor + 8, true
                    end
                end

                return t
            end)(),
            ["string"]=(function()
                local stringu8byte = 54
                local stringu16byte = 55
                local stringu32byte = 56

                return {
                    [stringu8byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number, boolean?)
                        local length = buffer.readu8(buff, cursor); cursor += 1
                        return buffer.readstring(buff, cursor, length), cursor + length, true
                    end;

                    [stringu16byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number, boolean?)
                        local length = buffer.readu16(buff, cursor); cursor += 2
                        return buffer.readstring(buff, cursor, length), cursor + length, true
                    end;

                    [stringu32byte] = @native function(buff: buffer, byte: number, cursor: number): (string, number, boolean?)
                        local length = buffer.readu32(buff, cursor); cursor += 4
                        return buffer.readstring(buff, cursor, length), cursor + length, true
                    end;
                }
            end)(),
            ["table_and_deduplicate"]=(function()
                local ByteToValue = Enums.bytetovalue

                local tblu8byte = 51
                local tblu16byte = 52
                local tblu32byte = 53
                local dedupu8byte = 57
                local dedupu16byte = 58
                local dedupu32byte = 59
                local referenceu8byte = 60
                local referenceu16byte = 61
                local referenceu32byte = 62

                local customvaluebyte = 99

                @native
                local function readtable(buff: buffer, byte: number, cursor: number, info)
                    local index 
                            
                    if byte == tblu8byte then index = buffer.readu8(buff, cursor); cursor += 1
                    elseif byte == tblu16byte then index = buffer.readu16(buff, cursor); cursor += 2
                    else index = buffer.readu32(buff, cursor); cursor += 4 end
                    
                    local formedtables = info.tables
                    local f = formedtables[index]

                    if f then return f, cursor
                    else 
                        local value = {}
                        formedtables[index] = value

                        return value, cursor
                    end
                end

                @native
                local function readdeduplicate(buff: buffer, byte: number, cursor: number, info)
                    local index 
                            
                    if byte == dedupu8byte then index = buffer.readu8(buff, cursor); cursor += 1
                    elseif byte == dedupu16byte then index = buffer.readu16(buff, cursor); cursor += 2
                    else index = buffer.readu32(buff, cursor); cursor += 4 end
                    
                    return info.deduplicationtable[index], cursor
                end

                @native 
                local function readreference(buff: buffer, byte: number, cursor: number, info)
                    local index 
                            
                    if byte == referenceu8byte then index = buffer.readu8(buff, cursor); cursor += 1
                    elseif byte == referenceu16byte then index = buffer.readu16(buff, cursor); cursor += 2
                    else index = buffer.readu32(buff, cursor); cursor += 4 end
                    
                    local references = info.references

                    if references then
                        return references[index], cursor
                    else
                        error('Missing references table when decoding buffer that contains value references.') 
                    end
                end

                local t = {
                    [tblu8byte] = readtable;
                    [tblu16byte] = readtable;
                    [tblu32byte] = readtable;

                    [dedupu8byte] = readdeduplicate;
                    [dedupu16byte] = readdeduplicate;
                    [dedupu32byte] = readdeduplicate;

                    [referenceu8byte] = readreference;
                    [referenceu16byte] = readreference;
                    [referenceu32byte] = readreference;

                    [customvaluebyte] = @native function(buff: buffer, byte: number, cursor: number)
                        return ByteToValue[-buffer.readu8(buff, cursor)], cursor + 1
                    end,

                }

                -- doing those here so theres no cost for indexing ByteToValue
                for byte, v in ByteToValue do 
                    if byte > 0 then
                        -- this runs somehow faster with native .... ok i guess
                        t[byte] = @native function(buff, byte, cursor) return v, cursor end
                    end
                end

                return t
            end)(),
            ["template"]=(function()
                local templatebyte = -1
                local writebytesign

                return {
                    [templatebyte] = @native function(buff: buffer, byte: number, cursor: number): (any, number)
                        error('Byte read function should be changed for the template.', 0)
                    end;
                }
            end)()
        }

        for name, t in cachedTables do
            if name == "template" then continue end

            for num, func in t do
                if bytetodatatype[num] then
                    warn(`The modules {name} and {bytetodatatype[num]} are using the same byte {num}`)
                    continue
                end

                bytetofunction[num] = func
                bytetodatatype[num] = name
            end
        end

        table.clear(bytetodatatype)
        return bytetofunction
    end)()

    local Read=(function()
        local Datatypes = ReadDatatypes

        local defaultwritingtable = {}
        return function(buff: buffer, readstart: number?, references: { any }?, dedupenabled: boolean?, shiftseed: number?): { [any]: any }
            local cursor = readstart or 0
            local isdoingdeduplication_old = false

            do
                local firstbyte = buffer.readu8(buff, cursor)
                if shiftseed then
                    math.randomseed(shiftseed)
                    firstbyte = (firstbyte - math.random(1, 127)) % 128
                    math.randomseed(shiftseed)
                end

                if firstbyte == 101 then
                    return {}
                elseif firstbyte > 1 then
                    error(`expected '0', '1', or '101' for first byte, got {firstbyte}`)
                end

                isdoingdeduplication_old = firstbyte == 0
                if isdoingdeduplication_old then dedupenabled = false end
            end

            local deduplicationindex = 0
            local deduplicationtable = if dedupenabled then {} else nil
            local currenttable = {}
            local maintable = currenttable
            
            local writingtable = defaultwritingtable

            local formedtables = {currenttable}
            local formedcount = 0

            local lastwasdictkey = false
            local dictkey = nil
            local currentindex = 0

            local info = {
                stringform = nil,
                deduplicationtable = deduplicationtable,
                references = references,
                tables = formedtables,
            }

            while cursor <= (buffer.len(buff) - 1) do
                local byte = buffer.readu8(buff, cursor)
                cursor += 1

                local isdictkey = byte > 127
                if isdictkey then
                    byte = (255 - byte)
                end

                if shiftseed then
                    byte = (byte - math.random(1, 127)) % 128
                end

                local value: any, canbededuplicated: boolean?

                local func = Datatypes[byte]
                if func then
                    value, cursor, canbededuplicated = func(buff, byte, cursor, info)
                elseif byte == 1 then 
                    formedcount += 1
                    
                    if currentindex > 0 then
                        table.move(writingtable, 1, currentindex, 1, currenttable)
                        currentindex = 0
                    end
                    
                    currenttable = formedtables[formedcount]
                    if currenttable == nil then
                        currenttable = {}
                        formedtables[formedcount] = currenttable
                    end

                    lastwasdictkey = false
                    dictkey = nil

                    continue
                elseif byte == 0 then
                    if isdoingdeduplication_old then
                        isdoingdeduplication_old = false

                        currenttable = {}
                        deduplicationtable = currenttable
                        info.deduplicationtable = deduplicationtable

                        continue
                    else
                        if shiftseed then math.randomseed(os.time()) end
                        
                        if currentindex > 0 then
                            table.move(writingtable, 1, currentindex, 1, currenttable)
                        end
                        
                        table.clear(writingtable)
                        return maintable
                    end
                elseif byte == 101 then value = {}
                elseif byte ~= 4 then -- not nil
                    error(`{byte} is not a type byte`)
                end

                if dedupenabled and canbededuplicated then
                    deduplicationindex += 1
                    deduplicationtable[deduplicationindex] = value
                end

                if lastwasdictkey then
                    lastwasdictkey = false

                    if dictkey ~= nil then
                        currenttable[dictkey] = value
                        dictkey = nil
                    end
                elseif isdictkey then
                    dictkey = value
                    lastwasdictkey = true
                else
                    currentindex += 1
                    writingtable[currentindex] = value
                end
            end

            if shiftseed then math.randomseed(os.time()) end

            error("buffer is not terminated with zero byte", 0)
        end

    end)()

    local Write=(function()
        local uI16_max = (2 ^ 16) - 1

        local valuetobyte = Enums.valuetobyte
        local color3always6bytes: boolean = Settings.color3always6bytes
        local fullrbxenum: boolean = Settings.rbxenum_behavior == 'full'

        local writef16 = Miscellaneous.writef16
        local writeCFrame = Miscellaneous.writeCFrame
        local CFrameSize = Miscellaneous.cframesize

        -- shift the byte associated with a value/datatype by the number given
        local tryshift = function(v: number, shiftseed: number?): number
            if shiftseed then return (v + math.random(1, 127)) % 128
            else return v end
        end

        -- write the byte associated with a given value or datatype
        local function writebytesign(buff: buffer, cursor: number, value: number, isdict: boolean?, shiftseed: number?)
            if shiftseed then value = (value + math.random(1, 127)) % 128 end
            if isdict then value = 255 - value end

            buffer.writeu8(buff, cursor, value)
        end

        -- expand the size of the writingbuffer
        local function expandbuffertosize(buff: buffer, newsize: number, info: encodeinfo): buffer
            if newsize > info.allocatedsize then
                newsize //= 1/1.375
                info.allocatedsize = newsize 

                local newbuff = buffer.create(newsize)
                buffer.copy(newbuff, 0, buff)

                return newbuff
            end

            return buff
        end

        -- write every value into the buffer
        local function write(
            buff: buffer,
            cursor: number,
            info: encodeinfo,
            dedupallowed: boolean?,
            shiftseed: number?
        ): (buffer, number)

            local scancount: number = 1
            local deduplicatedcount: number = 0
            local referencecount: number = 0

            local valuepositionlookup = info.valuepositionlookup

            local scanlist = info.scanlist
            local referencelist = info.referencelist

            for _, tbl in scanlist do 
                buff = expandbuffertosize(buff, cursor + 1, info)
                writebytesign(buff, cursor, 1, nil, shiftseed); cursor += 1

                local arraywritelength: number = rawlen(tbl)
                local isdoingdict: boolean = arraywritelength == 0

                local iternum: number = if isdoingdict then 2 else 1	
                local lastkey: number = 0
                for k, v in next, tbl do 
                    if (not isdoingdict) then
                        local diff: number = (k - lastkey) - 1

                        if diff > 0 then
                            buff = expandbuffertosize(buff, cursor + diff, info)
                            if shiftseed then
                                for i = 0, diff - 1 do 
                                    buffer.writeu8(buff, cursor + i, (4 + math.random(1, 127)) % 128)
                                end
                            else buffer.fill(buff, cursor, 4, diff) end
                            cursor += diff
                        end

                        lastkey = k 
                    end

                    for i = 1, iternum do 
                        local isdict: boolean = isdoingdict and i == 1
                        local value: any = if isdict then k else v

                        local valuebyte: number? = valuetobyte[value]
                        if valuebyte then
                            if valuebyte <= 0 then
                                buff = expandbuffertosize(buff, cursor + 2, info)
                                writebytesign(buff, cursor, 99, isdict, shiftseed)
                                buffer.writeu8(buff, cursor + 1, -valuebyte); cursor += 2
                            else
                                buff = expandbuffertosize(buff, cursor + 1, info)
                                writebytesign(buff, cursor, valuebyte, isdict, shiftseed); cursor += 1
                            end

                            continue
                        end

                        local t: string = typeof(value)
                        local candeduplicate: boolean = dedupallowed and (t == 'string' or t == 'Vector3' or t == 'number' or (fullrbxenum and (t == 'EnumItem' or t == 'Enum')))

                        if candeduplicate then
                            if value ~= value then
                                -- nan shouldnt be deduplicated, whether in a vector or as a number

                                if t == 'number' then
                                    buff = expandbuffertosize(buff, cursor + 1, info)
                                    writebytesign(buff, cursor, 108, isdict, shiftseed); cursor += 1
                                else 
                                    local value: Vector3 = value
                                    -- vector in this case

                                    buff = expandbuffertosize(buff, cursor + 13, info)

                                    writebytesign(buff, cursor, 15, isdict, shiftseed); cursor += 1
                                    buffer.writef32(buff, cursor, value.X); cursor += 4
                                    buffer.writef32(buff, cursor, value.Y); cursor += 4
                                    buffer.writef32(buff, cursor, value.Z); cursor += 4
                                end

                                continue
                            end

                            if t == 'number' then
                                local value: number = value
                                -- numbers below 256 that arent float values shouldnt be deduplicated

                                local abs = math.abs(value)
                                if not (abs > 0xFF or abs % 1 ~= 0) then
                                    -- encoding here to avoid rechecking later
                                    buff = expandbuffertosize(buff, cursor + 5, info)

                                    writebytesign(buff, cursor, if value < 0 then 8 else 5, isdict, shiftseed)
                                    buffer.writeu8(buff, cursor + 1, abs); cursor += 2

                                    continue
                                end
                            end

                            local added: number? = valuepositionlookup[value]

                            if added then
                                if added <= 0xFF then -- u8
                                    buff = expandbuffertosize(buff, cursor + 2, info)
                                    writebytesign(buff, cursor, 57, isdict, shiftseed)
                                    buffer.writeu8(buff, cursor + 1, added); cursor += 2
                                elseif added <= 0xFFFF then -- u16
                                    buff = expandbuffertosize(buff, cursor + 3, info)
                                    writebytesign(buff, cursor, 58, isdict, shiftseed)
                                    buffer.writeu16(buff, cursor + 1, added); cursor += 3
                                else -- u32
                                    buff = expandbuffertosize(buff, cursor + 5, info)
                                    writebytesign(buff, cursor, 59, isdict, shiftseed)
                                    buffer.writeu32(buff, cursor + 1, added); cursor += 5
                                end

                                continue
                            else 
                                deduplicatedcount += 1
                                valuepositionlookup[value] = deduplicatedcount
                            end
                        end

                        if t == "nil" then
                            buff = expandbuffertosize(buff, cursor + 1, info)
                            writebytesign(buff, cursor, 4, isdict, shiftseed); cursor += 1
                        elseif t == "number" then
                            local value: number = value

                            if value ~= value then
                                buff = expandbuffertosize(buff, cursor + 1, info)
                                writebytesign(buff, cursor, 108, isdict, shiftseed); cursor += 1
                            else
                                local abs = math.abs(value)
                                if (value % 1) ~= 0 or abs > 0xFFFFFFFF then -- float64
                                    buff = expandbuffertosize(buff, cursor + 9, info)


                                    writebytesign(buff, cursor, 11, isdict, shiftseed)
                                    buffer.writef64(buff, cursor + 1, value); cursor += 9
                                else
                                    local offset = if value < 0 then 3 else 0

                                    if abs <= 0xFF then -- uint8
                                        buff = expandbuffertosize(buff, cursor + 2, info)

                                        writebytesign(buff, cursor, 5 + offset, isdict, shiftseed)
                                        buffer.writeu8(buff, cursor + 1, abs); cursor += 2
                                    elseif abs <= 0xFFFF then -- uint16
                                        buff = expandbuffertosize(buff, cursor + 3, info)

                                        writebytesign(buff, cursor, 6 + offset, isdict, shiftseed)
                                        buffer.writeu16(buff, cursor + 1, abs); cursor += 3
                                    else
                                        buff = expandbuffertosize(buff, cursor + 5, info)

                                        writebytesign(buff, cursor, 7 + offset, isdict, shiftseed)
                                        buffer.writeu32(buff, cursor + 1, abs); cursor += 5
                                    end
                                end
                            end
                        elseif t == "string" then
                            local value: string = value
                            local len: number = #value 

                            if len <= 0xFF then -- not zero-terminated since no benefit in making it zero-terminated
                                buff = expandbuffertosize(buff, cursor + len + 2, info)

                                writebytesign(buff, cursor, 54, isdict, shiftseed)
                                buffer.writeu8(buff, cursor + 1, len); cursor += 2
                            elseif len <= 0xFFFF then
                                buff = expandbuffertosize(buff, cursor + len + 3, info)

                                writebytesign(buff, cursor, 55, isdict, shiftseed)
                                buffer.writeu16(buff, cursor + 1, len); cursor += 3
                            else
                                buff = expandbuffertosize(buff, cursor + len + 5, info)

                                writebytesign(buff, cursor, 56, isdict, shiftseed)
                                buffer.writeu32(buff, cursor + 1, len); cursor += 5
                            end

                            buffer.writestring(buff, cursor, value); cursor += len
                        elseif t == "table" then
                            local value: {[any]: any} = value
                            local scanpos: number? = valuepositionlookup[value]
                            if (not scanpos) and (next(value) ~= nil) then
                                scanpos = scancount + 1
                                scancount = scanpos :: any
                                valuepositionlookup[value] = scanpos
                                scanlist[scanpos] = value
                            end

                            if scanpos then
                                if scanpos <= 0xFF then
                                    buff = expandbuffertosize(buff, cursor + 2, info)

                                    writebytesign(buff, cursor, 51, isdict, shiftseed)
                                    buffer.writeu8(buff, cursor + 1, scanpos); cursor += 2
                                elseif scanpos <= 0xFFFF then
                                    buff = expandbuffertosize(buff, cursor + 3, info)

                                    writebytesign(buff, cursor, 52, isdict, shiftseed)
                                    buffer.writeu16(buff, cursor + 1, scanpos); cursor += 3
                                else
                                    buff = expandbuffertosize(buff, cursor + 5, info)

                                    writebytesign(buff, cursor, 53, isdict, shiftseed)
                                    buffer.writeu32(buff, cursor + 1, scanpos); cursor += 5
                                end
                            else
                                buff = expandbuffertosize(buff, cursor + 1, info)

                                writebytesign(buff, cursor, 101, isdict, shiftseed); cursor += 1
                            end
                        elseif t == "buffer" then
                            local value: buffer = value
                            local length: number = buffer.len(value)

                            if length <= 0xFF then
                                buff = expandbuffertosize(buff, cursor + 2, info)

                                writebytesign(buff, cursor, 12, isdict, shiftseed)
                                buffer.writeu8(buff, cursor + 1, length); cursor += 2
                            elseif length <= 0xFFFF then
                                buff = expandbuffertosize(buff, cursor + 3, info)

                                writebytesign(buff, cursor, 13, isdict, shiftseed)
                                buffer.writeu16(buff, cursor + 1, length); cursor += 3
                            else
                                buff = expandbuffertosize(buff, cursor + 5, info)

                                writebytesign(buff, cursor, 14, isdict, shiftseed)
                                buffer.writeu32(buff, cursor + 1, length); cursor += 5
                            end

                            buffer.copy(buff, cursor, value)
                            cursor += length
                        elseif t == "Vector3" then
                            local value: Vector3 = value
                            buff = expandbuffertosize(buff, cursor + 13, info)

                            writebytesign(buff, cursor, 15, isdict, shiftseed); cursor += 1
                            buffer.writef32(buff, cursor, value.X); cursor += 4
                            buffer.writef32(buff, cursor, value.Y); cursor += 4
                            buffer.writef32(buff, cursor, value.Z); cursor += 4
                        elseif t == "Vector2" then
                            local value: Vector2 = value
                            buff = expandbuffertosize(buff, cursor + 9, info)

                            writebytesign(buff, cursor, 16, isdict, shiftseed); cursor += 1
                            buffer.writef32(buff, cursor, value.X); cursor += 4
                            buffer.writef32(buff, cursor, value.Y); cursor += 4
                        elseif t == "CFrame" then
                            local value: CFrame = value
                            buff = expandbuffertosize(buff, cursor + CFrameSize + 1, info)

                            writebytesign(buff, cursor, 17, isdict, shiftseed); cursor += 1
                            writeCFrame(buff, cursor, value); cursor += CFrameSize
                        elseif t == "Ray" then
                            local value: Ray = value
                            buff = expandbuffertosize(buff, cursor + 25, info)

                            writebytesign(buff, cursor, 18, isdict, shiftseed); cursor += 1

                            local pos: Vector3, dir: Vector3 = value.Origin, value.Direction
                            buffer.writef32(buff, cursor, pos.X); cursor += 4
                            buffer.writef32(buff, cursor, pos.Y); cursor += 4
                            buffer.writef32(buff, cursor, pos.Z); cursor += 4
                            buffer.writef32(buff, cursor, dir.X); cursor += 4
                            buffer.writef32(buff, cursor, dir.Y); cursor += 4
                            buffer.writef32(buff, cursor, dir.Z); cursor += 4
                        elseif t == "Enum" then
                            local value: Enum = value
                            local size: number = 3 -- <u8> 19 | <u16> position
                            if fullrbxenum then 
                                size = 2 + #RbxEnumEncoder.enumitem_to_type[value] 
                                -- <u8> byte | <u8> length | string
                            end 

                            buff = expandbuffertosize(buff, cursor + size, info)
                            writebytesign(buff, cursor, 19, isdict, shiftseed)
                            cursor = RbxEnumEncoder.encodeEnum(buff, cursor + 1, value)
                        elseif t == "EnumItem" then
                            local value: EnumItem = value
                            local size: number = 3 -- <u8> 20 | <u16> position
                            if fullrbxenum then 
                                size = 4 + #RbxEnumEncoder.enumitem_to_type[value] 
                                -- <u8> 20 | <u8> length | string | <u16> value
                            end

                            buff = expandbuffertosize(buff, cursor + size, info)

                            writebytesign(buff, cursor, 20, isdict, shiftseed)
                            cursor = RbxEnumEncoder.encodeEnumItem(buff, cursor + 1, value)
                        elseif t == "NumberRange" then
                            local value: NumberRange = value
                            buff = expandbuffertosize(buff, cursor + 9, info)
                            writebytesign(buff, cursor, 21, isdict, shiftseed); cursor += 1

                            buffer.writef32(buff, cursor, value.Min); cursor += 4
                            buffer.writef32(buff, cursor, value.Max); cursor += 4
                        elseif t == "NumberSequence" then
                            local value: NumberSequence = value
                            local keypoints: {NumberSequenceKeypoint} = value.Keypoints

                            buff = expandbuffertosize(buff, cursor + 2 + #keypoints * 8, info)

                            writebytesign(buff, cursor, 22, isdict, shiftseed);
                            buffer.writeu8(buff, cursor + 1, #keypoints); cursor += 2

                            for _, k in keypoints do
                                buffer.writeu16(buff, cursor, math.round(k.Time * uI16_max))
                                buffer.writef32(buff, cursor + 2, k.Value)
                                
                                writef16(buff, cursor + 6, k.Envelope); cursor += 8
                            end
                        elseif t == "Color3" then
                            local value: Color3 = value
                            local r: number, g: number, b: number = value.R, value.G, value.B

                            if color3always6bytes or (math.max(r, g, b) > 1 or math.min(r, g, b) < 0) then
                                buff = expandbuffertosize(buff, cursor + 7, info)

                                -- one or more of values is out of 1 byte limit, so this encodes as 2 bytes each
                                writebytesign(buff, cursor, 24, isdict, shiftseed)
                                writef16(buff, cursor + 1, r)
                                writef16(buff, cursor + 3, g)
                                writef16(buff, cursor + 5, b)
                                cursor += 7
                            else
                                buff = expandbuffertosize(buff, cursor + 4, info)

                                writebytesign(buff, cursor, 23, isdict, shiftseed)
                                buffer.writeu8(buff, cursor + 1, math.round(r * 255))
                                buffer.writeu8(buff, cursor + 2, math.round(g * 255))
                                buffer.writeu8(buff, cursor + 3, math.round(b * 255))
                                cursor += 4
                            end
                        elseif t == "ColorSequence" then
                            local value: ColorSequence = value
                            local keypoints: {ColorSequenceKeypoint} = value.Keypoints

                            buff = expandbuffertosize(buff, cursor + 2 + #keypoints * 5, info)

                            writebytesign(buff, cursor, 25, isdict, shiftseed)
                            buffer.writeu8(buff, cursor + 1, #keypoints); cursor += 2

                            for _, k in keypoints do
                                local color = k.Value

                                -- colors in colorsequences are always limited to 0-1
                                buffer.writeu16(buff, cursor, math.round(k.Time * uI16_max))
                                buffer.writeu8(buff, cursor + 2, math.round(color.R * 255))
                                buffer.writeu8(buff, cursor + 3, math.round(color.G * 255))
                                buffer.writeu8(buff, cursor + 4, math.round(color.B * 255))
                                cursor += 5
                            end
                        elseif t == "UDim" then
                            local value: UDim = value
                            buff = expandbuffertosize(buff, cursor + 9, info)
                            writebytesign(buff, cursor, 26, isdict, shiftseed)

                            buffer.writef32(buff, cursor + 1, value.Scale)
                            buffer.writei32(buff, cursor + 5, value.Offset)
                            cursor += 9
                        elseif t == "UDim2" then
                            local value: UDim2 = value
                            buff = expandbuffertosize(buff, cursor + 17, info)
                            local x: UDim, y: UDim = value.X, value.Y

                            writebytesign(buff, cursor, 27, isdict, shiftseed)

                            buffer.writef32(buff, cursor + 1, x.Scale)
                            buffer.writei32(buff, cursor + 5, x.Offset)
                            buffer.writef32(buff, cursor + 9, y.Scale)
                            buffer.writei32(buff, cursor + 13, y.Offset)
                            cursor += 17
                        elseif t == "Rect" then
                            local value: Rect = value
                            buff = expandbuffertosize(buff, cursor + 17, info)
                            local min: Vector2, max: Vector2 = value.Min, value.Max

                            writebytesign(buff, cursor, 28, isdict, shiftseed)

                            buffer.writef32(buff, cursor + 1, min.X)
                            buffer.writef32(buff, cursor + 5, min.Y)
                            buffer.writef32(buff, cursor + 9, max.X)
                            buffer.writef32(buff, cursor + 13, max.Y)
                            cursor += 17
                        elseif t == "PhysicalProperties" then
                            local value: PhysicalProperties = value
                            buff = expandbuffertosize(buff, cursor + 21, info)
                            writebytesign(buff, cursor, 29, isdict, shiftseed)

                            buffer.writef32(buff, cursor + 1, value.Density)
                            buffer.writef32(buff, cursor + 5, value.Friction)
                            buffer.writef32(buff, cursor + 9, value.Elasticity)
                            buffer.writef32(buff, cursor + 13, value.FrictionWeight)
                            buffer.writef32(buff, cursor + 17, value.ElasticityWeight)
                            cursor += 21
                        elseif t == "BrickColor" then
                            local value: BrickColor = value
                            buff = expandbuffertosize(buff, cursor + 3, info)
                            writebytesign(buff, cursor, 30, isdict, shiftseed)
                            buffer.writeu16(buff, cursor + 1, value.Number)
                            cursor += 3
                        elseif t == "Vector3int16" then
                            local value: Vector3int16 = value
                            buff = expandbuffertosize(buff, cursor + 7, info)
                            writebytesign(buff, cursor, 31, isdict, shiftseed)
                            buffer.writei16(buff, cursor + 1, value.X)
                            buffer.writei16(buff, cursor + 3, value.Y)
                            buffer.writei16(buff, cursor + 5, value.Z)
                            cursor += 7
                        elseif t == "Vector2int16" then
                            local value: Vector2int16 = value
                            buff = expandbuffertosize(buff, cursor + 5, info)
                            writebytesign(buff, cursor, 32, isdict, shiftseed)
                            buffer.writei16(buff, cursor + 1, value.X)
                            buffer.writei16(buff, cursor + 3, value.Y)
                            cursor += 5
                        elseif t == "Content" then
                            local value: Content = value

                            if value.SourceType == Enum.ContentSourceType.Uri then
                                local uri: string = value.Uri :: string
                                local num: string? = string.match(uri, "%d+$")

                                if num then
                                    buff = expandbuffertosize(buff, cursor + 10, info)
                                    writebytesign(buff, cursor, 33, isdict, shiftseed)
                                    buffer.writeu8(buff, cursor + 1, 1)
                                    buffer.writef64(buff, cursor + 2, tonumber(num) :: number)
                                    cursor += 10
                                else
                                    -- im going to make a guess and say that the content links are NOT going past 254 bytes in length 😨
                                    local len: number = #uri
                                    if len > 254 then
                                        error("content uri length cannot be more than 254 bytes.", 0)
                                    end

                                    buff = expandbuffertosize(buff, cursor + 2 + len, info)
                                    writebytesign(buff, cursor, 33, isdict, shiftseed)
                                    buffer.writeu8(buff, cursor + 1, len + 1); cursor += 2
                                    buffer.writestring(buff, cursor , uri)

                                    cursor += len
                                end

                                continue
                            else 
                                buff = expandbuffertosize(buff, cursor + 2, info)
                                writebytesign(buff, cursor, 33, isdict, shiftseed)
                                buffer.writeu8(buff, cursor + 1, 0); cursor += 2
                            end

                        elseif t == "Font" then
                            local value: Font = value

                            local family: string = value.Family
                            local num: string? = string.match(family, "%d+$")

                            if num then
                                buff = expandbuffertosize(buff, cursor + 13, info)

                                writebytesign(buff, cursor, 34, isdict, shiftseed)
                                buffer.writeu8(buff, cursor + 1, 0)
                                buffer.writef64(buff, cursor + 2, tonumber(num) :: number)

                                cursor += 10
                            else
                                local familyname: string = string.match(family, "/(%w+).json$") or ""
                                local length: number = #familyname

                                -- same here
                                if length > 254 then
                                    error("font name length cannot be more than 254 bytes.", 0)
                                end

                                buff = expandbuffertosize(buff, cursor + 5 + length, info)
                                writebytesign(buff, cursor, 34, isdict, shiftseed)
                                buffer.writeu8(buff, cursor + 1, length + 1); cursor += 2
                                buffer.writestring(buff, cursor, familyname)

                                cursor += length
                            end

                            buffer.writeu16(buff, cursor, RbxEnumEncoder.enumitem_to_value[value.Weight])
                            buffer.writeu8(buff, cursor + 2, RbxEnumEncoder.enumitem_to_value[value.Style]); cursor += 3
                        elseif t == "DateTime" then
                            local value: DateTime = value

                            buff = expandbuffertosize(buff, cursor + 9, info)
                            writebytesign(buff, cursor, 35, isdict, shiftseed)
                            buffer.writef64(buff, cursor + 1, value.UnixTimestampMillis); cursor += 9
                        else
                            if referencelist then
                                local referenceposition: number = valuepositionlookup[value]

                                if not referenceposition then
                                    referenceposition = referencecount + 1

                                    referencecount = referenceposition :: any
                                    valuepositionlookup[value] = referenceposition
                                    referencelist[referenceposition] = value
                                end

                                if referenceposition <= 0xFF then
                                    buff = expandbuffertosize(buff, cursor + 2, info)
                                    writebytesign(buff, cursor, 60, isdict, shiftseed)
                                    buffer.writeu8(buff, cursor + 1, referenceposition); cursor += 2
                                elseif referenceposition <= 0xFFFF then
                                    buff = expandbuffertosize(buff, cursor + 3, info)
                                    writebytesign(buff, cursor, 61, isdict, shiftseed)
                                    buffer.writeu16(buff, cursor + 1, referenceposition); cursor += 3
                                else 
                                    buff = expandbuffertosize(buff, cursor + 5, info)
                                    writebytesign(buff, cursor, 62, isdict, shiftseed)
                                    buffer.writeu32(buff, cursor + 1, referenceposition); cursor += 5
                                end
                            elseif isdict then break
                            else 
                                buff = expandbuffertosize(buff, cursor + 1, info)
                                writebytesign(buff, cursor, 4, isdict, shiftseed); cursor += 1 
                            end
                        end

                    end	

                    if k == arraywritelength then iternum = 2; isdoingdict = true end
                end
            end

            return buff, cursor
        end


        local writingbuffer = buffer.create(256)
        local writingbuffersize = 256

        type BenchmarkerProfiler = {
            Begin: (name: string) -> nil;
            End: () -> nil;
        }

        --[[
        returns the table given encoded as a buffer, and the size of buffer

        param - value : the table to encode
        param - writeoffset : writing starts from the offset given.
        param - allowreferences : if enabled, it returns a table containing the values it couldn't encode alongside the first 2 values.
        param - allowdeduplication : attempt to deduplicate repeated values if enabled to reduce buffer size
        param - shiftseed : the type bytes of values are shuffled using the seed.
        ]]
        return function(
            value: { [any]: any },
            writeoffset: number?,
            allowreferences: boolean?,
            allowdeduplication: boolean?,
            shiftseed: number?,
            Profiler: BenchmarkerProfiler?
        ): (buffer, { any }?)
            if type(value) == "table" then
                if shiftseed then math.randomseed(shiftseed) end
                local referencelist = if allowreferences then {} else nil

                if next(value) == nil then
                    local b = buffer.create(1)
                    buffer.writeu8(b, 0, tryshift(101, shiftseed))

                    if shiftseed then math.randomseed(os.time()) end

                    return b, referencelist
                end

                local cursor: number = writeoffset or 0

                local info: encodeinfo = {
                    valuepositionlookup = {[value] = 1},
                    scanlist = {value},

                    referencelist = referencelist,

                    allocatedsize = writingbuffersize;
                }

                local buff = writingbuffer

                if Profiler then
                    Profiler.Begin("Write")
                end

                buff, cursor = write(buff, cursor, info, allowdeduplication, shiftseed)

                buff = expandbuffertosize(buff, cursor + 1, info)
                writebytesign(buff, cursor, 0, nil, shiftseed)

                if Profiler then
                    Profiler.End()
                    Profiler.Begin("Finish")
                end

                writingbuffer = buff
                writingbuffersize = info.allocatedsize

                local truncatedbuffer = buffer.create(cursor + 2)
                buffer.copy(truncatedbuffer, 0, buff, 0, cursor + 1)

                if shiftseed then math.randomseed(os.time()) end

                if Profiler then
                    Profiler.End()
                end

                return truncatedbuffer, referencelist
            else
                error(`expected a table to be encoded into a buffer, got {typeof(value)}`, 0)
            end
        end
    end)()

    return {
        read = Read;
        write = Write;
        enums = Enums
    }
end)()

local Encoders=(function()
    local Zstd=(function()
        local HttpService = game:GetService("HttpService")
        local EncodingService = game:GetService("EncodingService")
        local Zstd = {}

        Zstd.CompressBuffer = function(Buffer, CompressionLevel)
            return EncodingService:CompressBuffer(Buffer, Enum.CompressionAlgorithm.Zstd, CompressionLevel)
        end

        Zstd.DecompressBuffer = function(Buffer)
            return EncodingService:DecompressBuffer(Buffer, Enum.CompressionAlgorithm.Zstd)
        end

        Zstd.Compress = function(String, CompressionLevel)
            local Buffer = buffer.fromstring(String)
            
            return buffer.tostring(Zstd.CompressBuffer(Buffer, CompressionLevel))
        end

        Zstd.Decompress = function(String)
            local Buffer = buffer.fromstring(String)

            return buffer.tostring(Zstd.DecompressBuffer(Buffer))
        end

        return Zstd
    end)()

    local Base94=(function()
        local string_char = string.char
        local string_byte = string.byte
        local table_concat = table.concat
        local math_floor = math.floor
        local bit32_lshift = bit32.lshift
        local bit32_rshift = bit32.rshift
        local bit32_bor = bit32.bor
        local bit32_band = bit32.band
        local buffer_create = buffer.create
        local buffer_len = buffer.len
        local buffer_readu8 = buffer.readu8
        local buffer_writeu8 = buffer.writeu8

        local alphabet = (function()
            local chars = {}

            for code = 32, 127 do
                if code ~= 34 and code ~= 92 then
                    chars[#chars + 1] = string_char(code)
                end
            end

            return table_concat(chars)
        end)()

        local lookupValueToCharacter = buffer_create(94)
        local lookupCharacterToValue = buffer_create(256)
        local powersOf94 = {94^4, 94^3, 94^2, 94^1, 1}

        for i = 0, 93 do
            local charCode = string_byte(alphabet, i + 1)

            buffer_writeu8(lookupValueToCharacter, i, charCode)
            buffer_writeu8(lookupCharacterToValue, charCode, i)
        end

        local function encode(input: buffer): buffer
            local inLen = buffer_len(input)
            local full = math_floor(inLen / 4)
            local rem	= inLen % 4
            local outLen = full * 5 + (rem > 0 and rem + 1 or 0)
            local out = buffer_create(outLen)

            -- full 4-byte chunks
            for ci = 0, full - 1 do
                local baseIn = ci * 4
                local chunk = bit32_bor(
                    bit32_lshift(buffer_readu8(input, baseIn), 24),
                    bit32_lshift(buffer_readu8(input, baseIn + 1), 16),
                    bit32_lshift(buffer_readu8(input, baseIn + 2), 8),
                    buffer_readu8(input, baseIn + 3)
                )

                -- decompose into five 0–93 digits and write directly to the buffer,
                -- big-endian (most significant digit first)
                local baseOut = ci * 5
                local tempChunk = chunk
                for i = 4, 0, -1 do
                    local digit = tempChunk % 94
                    tempChunk = math_floor(tempChunk / 94)
                    buffer_writeu8(out, baseOut + i, buffer_readu8(lookupValueToCharacter, digit))
                end
            end

            if rem > 0 then
                local baseIn = full * 4
                local chunk = 0

                if rem >= 1 then chunk = bit32_bor(bit32_lshift(chunk, 8), buffer_readu8(input, baseIn)) end
                if rem >= 2 then chunk = bit32_bor(bit32_lshift(chunk, 8), buffer_readu8(input, baseIn + 1)) end
                if rem >= 3 then chunk = bit32_bor(bit32_lshift(chunk, 8), buffer_readu8(input, baseIn + 2)) end

                local baseOut = full * 5
                local requiredChars = rem + 1

                for i = requiredChars - 1, 0, -1 do
                    local digit = chunk % 94
                    chunk = math_floor(chunk / 94)
                    buffer_writeu8(out, baseOut + i, buffer_readu8(lookupValueToCharacter, digit))
                end
            end

            return out
        end

        local function decode(input: buffer): buffer
            local inLen = buffer_len(input)
            local full = math_floor(inLen / 5)
            local rem	= inLen % 5
            if rem == 1 then rem = 0 end -- 1-char tail is invalid padding
            local outLen = full * 4 + (rem > 0 and rem - 1 or 0)
            local out = buffer_create(outLen)

            -- full 5-char chunks
            for ci = 0, full - 1 do
                local baseIn = ci * 5
                local value = 0

                -- reconstruct number using horner's method for efficiency :smirk:
                for i = 0, 4 do
                    local c = buffer_readu8(input, baseIn + i)
                    local d = buffer_readu8(lookupCharacterToValue, c)
                    value = value * 94 + d
                end

                -- extract b1..b4
                local baseOut = ci * 4
                for i = 0, 3 do
                    local shift = 24 - (i * 8)
                    local byte = bit32_band(bit32_rshift(value, shift), 0xFF)
                    buffer_writeu8(out, baseOut + i, byte)
                end
            end

            -- partial tail
            if rem > 0 then
                local baseIn = full * 5
                local value = 0

                -- reconstruct the number from the big-endian digits
                for i = 0, rem - 1 do
                    local c = buffer_readu8(input, baseIn + i)
                    local d = buffer_readu8(lookupCharacterToValue, c)
                    value = value * 94 + d
                end

                local requiredBytes = rem - 1
                local baseOut = full * 4

                -- extract the original bytes from the reconstructed number, big-endian
                for i = requiredBytes - 1, 0, -1 do
                    local byte = bit32_band(value, 0xFF)
                    value = bit32_rshift(value, 8)
                    buffer_writeu8(out, baseOut + i, byte)
                end
            end

            return out
        end

        return {
            encode = encode,
            decode = decode,
        }
    end)()

    local Zlib=(function()
        local Compression = {}
        local LibDeflate = {}

        Compression.Deflate = {}
        Compression.Zlib = {}
        Compression.Library = LibDeflate

        --[[
            Method: Compression.Deflate.Compress
            
            Description: Compresses a string using the raw deflate format
            
            Input:
                - String: data = The data to be compressed
                - table?: configs = The configuration table to control the compression
                
            Output:
                - String: compressedData = The compressed data
                - int: paddedBits = The number of bits padded at the end of the output
                
            For more information see:
                - LibDeflate:CompressDeflate
                - compression_configs
        ]]

        function Compression.Deflate.Compress(data, configs)
            return LibDeflate:CompressDeflate(data, configs)
        end


        --[[
            Method: Compression.Deflate.Decompress
            
            Description: Decompresses a raw deflate compressed data.
            
            Input:
                - String: compressedData = The data to be decompressed
                
            Output:
                - String: data = The decompressed data
                
            For more information see:
                - LibDeflate:DecompressDeflate
                - compression_configs
        ]]

        function Compression.Deflate.Decompress(compressedData)
            return LibDeflate:DecompressDeflate(compressedData)
        end



        --[[
            Method: Compression.Zlib.Compress
            
            Description: Compresses a string using the zlib format
            
            Input:
                - String: data = The data to be compressed
                - table?: configs = The configuration table to control the compression
                
            Output:
                - String: compressedData = The compressed data
                - int: paddedBits = The number of bits padded at the end of the output
                
            For more information see:
                - LibDeflate:CompressZlib
                - compression_configs
        ]]

        function Compression.Zlib.Compress(data, configs)
            return LibDeflate:CompressZlib(data, configs)
        end


        --[[
            Method: Compression.Deflate.Decompress
            
            Description: Decompresses a zlib compressed data.
            
            Input:
                - String: compressedData = The data to be decompressed
                
            Output:
                - String: data = The decompressed data
                
            For more information see:
                - LibDeflate:DecompressZlib
                - compression_configs
        ]]

        function Compression.Zlib.Decompress(compressedData)
            return LibDeflate:DecompressZlib(compressedData)
        end





        --[[

            LIBDEFLATE LIBRARY:

        ]]


        do
            -- Semantic version. all lowercase.
            -- Suffix can be alpha1, alpha2, beta1, beta2, rc1, rc2, etc.
            -- NOTE: Two version numbers needs to modify.
            -- 1. On the top of LibDeflate.lua
            -- 2. _VERSION
            -- 3. _MINOR

            -- version to store the official version of LibDeflate
            local _VERSION = "1.0.2-release"

            -- When MAJOR is changed, I should name it as LibDeflate2
            local _MAJOR = "LibDeflate"

            -- Update this whenever a new version, for LibStub version registration.
            -- 0 : v0.x
            -- 1 : v1.0.0
            -- 2 : v1.0.1
            -- 3 : v1.0.2
            local _MINOR = 3

            local _COPYRIGHT =
                "LibDeflate ".._VERSION
                .." Copyright (C) 2018-2020 Haoqian He."
                .." Licensed under the zlib License"

            -- Register in the World of Warcraft library "LibStub" if detected.
            LibDeflate = {}

            LibDeflate._VERSION = _VERSION
            LibDeflate._MAJOR = _MAJOR
            LibDeflate._MINOR = _MINOR
            LibDeflate._COPYRIGHT = _COPYRIGHT
        end

        -- localize Lua api for faster access.
        local assert = assert
        local error = error
        local pairs = pairs
        local string_byte = string.byte
        local string_char = string.char
        local string_find = string.find
        local string_gsub = string.gsub
        local string_sub = string.sub
        local table_concat = table.concat
        local table_sort = table.sort
        local tostring = tostring
        local type = type

        -- Converts i to 2^i, (0<=i<=32)
        -- This is used to implement bit left shift and bit right shift.
        -- "x >> y" in C:   "(x-x%_pow2[y])/_pow2[y]" in Lua
        -- "x << y" in C:   "x*_pow2[y]" in Lua
        local _pow2 = {}

        -- Converts any byte to a character, (0<=byte<=255)
        local _byte_to_char = {}

        -- _reverseBitsTbl[len][val] stores the bit reverse of
        -- the number with bit length "len" and value "val"
        -- For example, decimal number 6 with bits length 5 is binary 00110
        -- It's reverse is binary 01100,
        -- which is decimal 12 and 12 == _reverseBitsTbl[5][6]
        -- 1<=len<=9, 0<=val<=2^len-1
        -- The reason for 1<=len<=9 is that the max of min bitlen of huffman code
        -- of a huffman alphabet is 9?
        local _reverse_bits_tbl = {}

        -- Convert a LZ77 length (3<=len<=258) to
        -- a deflate literal/LZ77_length code (257<=code<=285)
        local _length_to_deflate_code = {}

        -- convert a LZ77 length (3<=len<=258) to
        -- a deflate literal/LZ77_length code extra bits.
        local _length_to_deflate_extra_bits = {}

        -- Convert a LZ77 length (3<=len<=258) to
        -- a deflate literal/LZ77_length code extra bit length.
        local _length_to_deflate_extra_bitlen = {}

        -- Convert a small LZ77 distance (1<=dist<=256) to a deflate code.
        local _dist256_to_deflate_code = {}

        -- Convert a small LZ77 distance (1<=dist<=256) to
        -- a deflate distance code extra bits.
        local _dist256_to_deflate_extra_bits = {}

        -- Convert a small LZ77 distance (1<=dist<=256) to
        -- a deflate distance code extra bit length.
        local _dist256_to_deflate_extra_bitlen = {}

        -- Convert a literal/LZ77_length deflate code to LZ77 base length
        -- The key of the table is (code - 256), 257<=code<=285
        local _literal_deflate_code_to_base_len = {
            3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
            35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258,
        }

        -- Convert a literal/LZ77_length deflate code to base LZ77 length extra bits
        -- The key of the table is (code - 256), 257<=code<=285
        local _literal_deflate_code_to_extra_bitlen = {
            0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
            3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0,
        }

        -- Convert a distance deflate code to base LZ77 distance. (0<=code<=29)
        local _dist_deflate_code_to_base_dist = {
            [0] = 1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
            257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145,
            8193, 12289, 16385, 24577,
        }

        -- Convert a distance deflate code to LZ77 bits length. (0<=code<=29)
        local _dist_deflate_code_to_extra_bitlen = {
            [0] = 0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
            7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13,
        }

        -- The code order of the first huffman header in the dynamic deflate block.
        -- See the page 12 of RFC1951
        local _rle_codes_huffman_bitlen_order = {16, 17, 18,
            0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
        }

        -- The following tables are used by fixed deflate block.
        -- The value of these tables are assigned at the bottom of the source.

        -- The huffman code of the literal/LZ77_length deflate codes,
        -- in fixed deflate block.
        local _fix_block_literal_huffman_code

        -- Convert huffman code of the literal/LZ77_length to deflate codes,
        -- in fixed deflate block.
        local _fix_block_literal_huffman_to_deflate_code

        -- The bit length of the huffman code of literal/LZ77_length deflate codes,
        -- in fixed deflate block.
        local _fix_block_literal_huffman_bitlen

        -- The count of each bit length of the literal/LZ77_length deflate codes,
        -- in fixed deflate block.
        local _fix_block_literal_huffman_bitlen_count

        -- The huffman code of the distance deflate codes,
        -- in fixed deflate block.
        local _fix_block_dist_huffman_code

        -- Convert huffman code of the distance to deflate codes,
        -- in fixed deflate block.
        local _fix_block_dist_huffman_to_deflate_code

        -- The bit length of the huffman code of the distance deflate codes,
        -- in fixed deflate block.
        local _fix_block_dist_huffman_bitlen

        -- The count of each bit length of the huffman code of
        -- the distance deflate codes,
        -- in fixed deflate block.
        local _fix_block_dist_huffman_bitlen_count

        for i = 0, 255 do
            _byte_to_char[i] = string_char(i)
        end

        do
            local pow = 1
            for i = 0, 32 do
                _pow2[i] = pow
                pow = pow * 2
            end
        end

        for i = 1, 9 do
            _reverse_bits_tbl[i] = {}
            for j=0, _pow2[i+1]-1 do
                local reverse = 0
                local value = j
                for _ = 1, i do
                    -- The following line is equivalent to "res | (code %2)" in C.
                    reverse = reverse - reverse%2
                        + (((reverse%2==1) or (value % 2) == 1) and 1 or 0)
                    value = (value-value%2)/2
                    reverse = reverse * 2
                end
                _reverse_bits_tbl[i][j] = (reverse-reverse%2)/2
            end
        end

        -- The source code is written according to the pattern in the numbers
        -- in RFC1951 Page10.
        do
            local a = 18
            local b = 16
            local c = 265
            local bitlen = 1
            for len = 3, 258 do
                if len <= 10 then
                    _length_to_deflate_code[len] = len + 254
                    _length_to_deflate_extra_bitlen[len] = 0
                elseif len == 258 then
                    _length_to_deflate_code[len] = 285
                    _length_to_deflate_extra_bitlen[len] = 0
                else
                    if len > a then
                        a = a + b
                        b = b * 2
                        c = c + 4
                        bitlen = bitlen + 1
                    end
                    local t = len-a-1+b/2
                    _length_to_deflate_code[len] = (t-(t%(b/8)))/(b/8) + c
                    _length_to_deflate_extra_bitlen[len] = bitlen
                    _length_to_deflate_extra_bits[len] = t % (b/8)
                end
            end
        end

        -- The source code is written according to the pattern in the numbers
        -- in RFC1951 Page11.
        do
            _dist256_to_deflate_code[1] = 0
            _dist256_to_deflate_code[2] = 1
            _dist256_to_deflate_extra_bitlen[1] = 0
            _dist256_to_deflate_extra_bitlen[2] = 0

            local a = 3
            local b = 4
            local code = 2
            local bitlen = 0
            for dist = 3, 256 do
                if dist > b then
                    a = a * 2
                    b = b * 2
                    code = code + 2
                    bitlen = bitlen + 1
                end
                _dist256_to_deflate_code[dist] = (dist <= a) and code or (code+1)
                _dist256_to_deflate_extra_bitlen[dist] = (bitlen < 0) and 0 or bitlen
                if b >= 8 then
                    _dist256_to_deflate_extra_bits[dist] = (dist-b/2-1) % (b/4)
                end
            end
        end

        --- Calculate the Adler-32 checksum of the string. <br>
        -- See RFC1950 Page 9 https://tools.ietf.org/html/rfc1950 for the
        -- definition of Adler-32 checksum.
        -- @param str [string] the input string to calcuate its Adler-32 checksum.
        -- @return [integer] The Adler-32 checksum, which is greater or equal to 0,
        -- and less than 2^32 (4294967296).
        function LibDeflate:Adler32(str)
            -- This function is loop unrolled by better performance.
            --
            -- Here is the minimum code:
            --
            -- local a = 1
            -- local b = 0
            -- for i=1, #str do
            -- 		local s = string.byte(str, i, i)
            -- 		a = (a+s)%65521
            -- 		b = (b+a)%65521
            -- 		end
            -- return b*65536+a
            if type(str) ~= "string" then
                error(("Usage: LibDeflate:Adler32(str):"
                    .." 'str' - string expected got '%s'."):format(type(str)), 2)
            end
            local strlen = #str

            local i = 1
            local a = 1
            local b = 0
            while i <= strlen - 15 do
                local x1, x2, x3, x4, x5, x6, x7, x8,
                x9, x10, x11, x12, x13, x14, x15, x16 = string_byte(str, i, i+15)
                b = (b+16*a+16*x1+15*x2+14*x3+13*x4+12*x5+11*x6+10*x7+9*x8+8*x9
                    +7*x10+6*x11+5*x12+4*x13+3*x14+2*x15+x16)%65521
                a = (a+x1+x2+x3+x4+x5+x6+x7+x8+x9+x10+x11+x12+x13+x14+x15+x16)%65521
                i =  i + 16
            end
            while (i <= strlen) do
                local x = string_byte(str, i, i)
                a = (a + x) % 65521
                b = (b + a) % 65521
                i = i + 1
            end
            return (b*65536+a) % 4294967296
        end

        -- Compare adler32 checksum.
        -- adler32 should be compared with a mod to avoid sign problem
        -- 4072834167 (unsigned) is the same adler32 as -222133129
        local function IsEqualAdler32(actual, expected)
            return (actual % 4294967296) == (expected % 4294967296)
        end

        --- Create a preset dictionary.
        --
        -- This function is not fast, and the memory consumption of the produced
        -- dictionary is about 50 times of the input string. Therefore, it is suggestted
        -- to run this function only once in your program.
        --
        -- It is very important to know that if you do use a preset dictionary,
        -- compressors and decompressors MUST USE THE SAME dictionary. That is,
        -- dictionary must be created using the same string. If you update your program
        -- with a new dictionary, people with the old version won't be able to transmit
        -- data with people with the new version. Therefore, changing the dictionary
        -- must be very careful.
        --
        -- The parameters "strlen" and "adler32" add a layer of verification to ensure
        -- the parameter "str" is not modified unintentionally during the program
        -- development.
        --
        -- @usage local dict_str = "1234567890"
        --
        -- -- print(dict_str:len(), LibDeflate:Adler32(dict_str))
        -- -- Hardcode the print result below to verify it to avoid acciently
        -- -- modification of 'str' during the program development.
        -- -- string length: 10, Adler-32: 187433486,
        -- -- Don't calculate string length and its Adler-32 at run-time.
        --
        -- local dict = LibDeflate:CreateDictionary(dict_str, 10, 187433486)
        --
        -- @param str [string] The string used as the preset dictionary. <br>
        -- You should put stuffs that frequently appears in the dictionary
        -- string and preferablely put more frequently appeared stuffs toward the end
        -- of the string. <br>
        -- Empty string and string longer than 32768 bytes are not allowed.
        -- @param strlen [integer] The length of 'str'. Please pass in this parameter
        -- as a hardcoded constant, in order to verify the content of 'str'. The value
        -- of this parameter should be known before your program runs.
        -- @param adler32 [integer] The Adler-32 checksum of 'str'. Please pass in this
        -- parameter as a hardcoded constant, in order to verify the content of 'str'.
        -- The value of this parameter should be known before your program runs.
        -- @return  [table] The dictionary used for preset dictionary compression and
        -- decompression.
        -- @raise error if 'strlen' does not match the length of 'str',
        -- or if 'adler32' does not match the Adler-32 checksum of 'str'.
        function LibDeflate:CreateDictionary(str, strlen, adler32)
            if type(str) ~= "string" then
                error(("Usage: LibDeflate:CreateDictionary(str, strlen, adler32):"
                    .." 'str' - string expected got '%s'."):format(type(str)), 2)
            end
            if type(strlen) ~= "number" then
                error(("Usage: LibDeflate:CreateDictionary(str, strlen, adler32):"
                    .." 'strlen' - number expected got '%s'."):format(
                        type(strlen)), 2)
            end
            if type(adler32) ~= "number" then
                error(("Usage: LibDeflate:CreateDictionary(str, strlen, adler32):"
                    .." 'adler32' - number expected got '%s'."):format(
                        type(adler32)), 2)
            end
            if strlen ~= #str then
                error(("Usage: LibDeflate:CreateDictionary(str, strlen, adler32):"
                    .." 'strlen' does not match the actual length of 'str'."
                    .." 'strlen': %u, '#str': %u ."
                    .." Please check if 'str' is modified unintentionally.")
                    :format(strlen, #str))
            end
            if strlen == 0 then
                error(("Usage: LibDeflate:CreateDictionary(str, strlen, adler32):"
                    .." 'str' - Empty string is not allowed."), 2)
            end
            if strlen > 32768 then
                error(("Usage: LibDeflate:CreateDictionary(str, strlen, adler32):"
                    .." 'str' - string longer than 32768 bytes is not allowed."
                    .." Got %d bytes."):format(strlen), 2)
            end
            local actual_adler32 = self:Adler32(str)
            if not IsEqualAdler32(adler32, actual_adler32) then
                error(("Usage: LibDeflate:CreateDictionary(str, strlen, adler32):"
                    .." 'adler32' does not match the actual adler32 of 'str'."
                    .." 'adler32': %u, 'Adler32(str)': %u ."
                    .." Please check if 'str' is modified unintentionally.")
                    :format(adler32, actual_adler32))
            end

            local dictionary = {}
            dictionary.adler32 = adler32
            dictionary.hash_tables = {}
            dictionary.string_table = {}
            dictionary.strlen = strlen
            local string_table = dictionary.string_table
            local hash_tables = dictionary.hash_tables
            string_table[1] = string_byte(str, 1, 1)
            string_table[2] = string_byte(str, 2, 2)
            if strlen >= 3 then
                local i = 1
                local hash = string_table[1]*256+string_table[2]
                while i <= strlen - 2 - 3 do
                    local x1, x2, x3, x4 = string_byte(str, i+2, i+5)
                    string_table[i+2] = x1
                    string_table[i+3] = x2
                    string_table[i+4] = x3
                    string_table[i+5] = x4
                    hash = (hash*256+x1)%16777216
                    local t = hash_tables[hash]
                    if not t then t = {}; hash_tables[hash] = t end
                    t[#t+1] = i-strlen
                    i = i + 1
                    hash = (hash*256+x2)%16777216
                    t = hash_tables[hash]
                    if not t then t = {}; hash_tables[hash] = t end
                    t[#t+1] = i-strlen
                    i = i + 1
                    hash = (hash*256+x3)%16777216
                    t = hash_tables[hash]
                    if not t then t = {}; hash_tables[hash] = t end
                    t[#t+1] = i-strlen
                    i = i + 1
                    hash = (hash*256+x4)%16777216
                    t = hash_tables[hash]
                    if not t then t = {}; hash_tables[hash] = t end
                    t[#t+1] = i-strlen
                    i = i + 1
                end
                while i <= strlen - 2 do
                    local x = string_byte(str, i+2)
                    string_table[i+2] = x
                    hash = (hash*256+x)%16777216
                    local t = hash_tables[hash]
                    if not t then t = {}; hash_tables[hash] = t end
                    t[#t+1] = i-strlen
                    i = i + 1
                end
            end
            return dictionary
        end

        -- Check if the dictionary is valid.
        -- @param dictionary The preset dictionary for compression and decompression.
        -- @return true if valid, false if not valid.
        -- @return if not valid, the error message.
        local function IsValidDictionary(dictionary)
            if type(dictionary) ~= "table" then
                return false, ("'dictionary' - table expected got '%s'.")
                    :format(type(dictionary))
            end
            if type(dictionary.adler32) ~= "number"
                or type(dictionary.string_table) ~= "table"
                or type(dictionary.strlen) ~= "number"
                or dictionary.strlen <= 0
                or dictionary.strlen > 32768
                or dictionary.strlen ~= #dictionary.string_table
                or type(dictionary.hash_tables) ~= "table"
            then
                return false, ("'dictionary' - corrupted dictionary.")
                    :format(type(dictionary))
            end
            return true, ""
        end

        --[[
            key of the configuration table is the compression level,
            and its value stores the compression setting.
            These numbers come from zlib source code.
            Higher compression level usually means better compression.
            (Because LibDeflate uses a simplified version of zlib algorithm,
            there is no guarantee that higher compression level does not create
            bigger file than lower level, but I can say it's 99% likely)
            Be careful with the high compression level. This is a pure lua
            implementation compressor/decompressor, which is significant slower than
            a C/C++ equivalant compressor/decompressor. Very high compression level
            costs significant more CPU time, and usually compression size won't be
            significant smaller when you increase compression level by 1, when the
            level is already very high. Benchmark yourself if you can afford it.
            See also https://github.com/madler/zlib/blob/master/doc/algorithm.txt,
            https://github.com/madler/zlib/blob/master/deflate.c for more information.
            The meaning of each field:
            @field 1 use_lazy_evaluation:
                true/false. Whether the program uses lazy evaluation.
                See what is "lazy evaluation" in the link above.
                lazy_evaluation improves ratio, but relatively slow.
            @field 2 good_prev_length:
                Only effective if lazy is set, Only use 1/4 of max_chain,
                if prev length of lazy match is above this.
            @field 3 max_insert_length/max_lazy_match:
                If not using lazy evaluation,
                insert new strings in the hash table only if the match length is not
                greater than this length.
                If using lazy evaluation, only continue lazy evaluation,
                if previous match length is strictly smaller than this value.
            @field 4 nice_length:
                Number. Don't continue to go down the hash chain,
                if match length is above this.
            @field 5 max_chain:
                Number. The maximum number of hash chains we look.
        --]]
        local _compression_level_configs = {
            [0] = {false, nil, 0, 0, 0}, -- level 0, no compression
            [1] = {false, nil, 4, 8, 4}, -- level 1, similar to zlib level 1
            [2] = {false, nil, 5, 18, 8}, -- level 2, similar to zlib level 2
            [3] = {false, nil, 6, 32, 32},	-- level 3, similar to zlib level 3
            [4] = {true, 4,	4, 16, 16},	-- level 4, similar to zlib level 4
            [5] = {true, 8,	16,	32,	32}, -- level 5, similar to zlib level 5
            [6] = {true, 8,	16,	128, 128}, -- level 6, similar to zlib level 6
            [7] = {true, 8,	32,	128, 256}, -- (SLOW) level 7, similar to zlib level 7
            [8] = {true, 32, 128, 258, 1024} , --(SLOW) level 8,similar to zlib level 8
            [9] = {true, 32, 258, 258, 4096},
            -- (VERY SLOW) level 9, similar to zlib level 9
        }

        -- Check if the compression/decompression arguments is valid
        -- @param str The input string.
        -- @param check_dictionary if true, check if dictionary is valid.
        -- @param dictionary The preset dictionary for compression and decompression.
        -- @param check_configs if true, check if config is valid.
        -- @param configs The compression configuration table
        -- @return true if valid, false if not valid.
        -- @return if not valid, the error message.
        local function IsValidArguments(str,
            check_dictionary, dictionary,
            check_configs, configs)

            if type(str) ~= "string" then
                return false,
                ("'str' - string expected got '%s'."):format(type(str))
            end
            if check_dictionary then
                local dict_valid, dict_err = IsValidDictionary(dictionary)
                if not dict_valid then
                    return false, dict_err
                end
            end
            if check_configs then
                local type_configs = type(configs)
                if type_configs ~= "nil" and type_configs ~= "table" then
                    return false,
                    ("'configs' - nil or table expected got '%s'.")
                        :format(type(configs))
                end
                if type_configs == "table" then
                    for k, v in pairs(configs) do
                        if k ~= "level" and k ~= "strategy" then
                            return false,
                            ("'configs' - unsupported table key in the configs: '%s'.")
                                :format(k)
                        elseif k == "level" and not _compression_level_configs[v] then
                            return false,
                            ("'configs' - unsupported 'level': %s."):format(tostring(v))
                        elseif k == "strategy" and v ~= "fixed" and v ~= "huffman_only"
                            and v ~= "dynamic" then
                            -- random_block_type is for testing purpose
                            return false, ("'configs' - unsupported 'strategy': '%s'.")
                                :format(tostring(v))
                        end
                    end
                end
            end
            return true, ""
        end



        --[[ --------------------------------------------------------------------------
            Compress code
        --]] --------------------------------------------------------------------------

        -- partial flush to save memory
        local _FLUSH_MODE_MEMORY_CLEANUP = 0
        -- full flush with partial bytes
        local _FLUSH_MODE_OUTPUT = 1
        -- write bytes to get to byte boundary
        local _FLUSH_MODE_BYTE_BOUNDARY = 2
        -- no flush, just get num of bits written so far
        local _FLUSH_MODE_NO_FLUSH = 3

        --[[
            Create an empty writer to easily write stuffs as the unit of bits.
            Return values:
            1. WriteBits(code, bitlen):
            2. WriteString(str):
            3. Flush(mode):
        --]]
        local function CreateWriter()
            local buffer_size = 0
            local cache = 0
            local cache_bitlen = 0
            local total_bitlen = 0
            local buffer = {}
            -- When buffer is big enough, flush into result_buffer to save memory.
            local result_buffer = {}

            -- Write bits with value "value" and bit length of "bitlen" into writer.
            -- @param value: The value being written
            -- @param bitlen: The bit length of "value"
            -- @return nil
            local function WriteBits(value, bitlen)
                cache = cache + value * _pow2[cache_bitlen]
                cache_bitlen = cache_bitlen + bitlen
                total_bitlen = total_bitlen + bitlen
                -- Only bulk to buffer every 4 bytes. This is quicker.
                if cache_bitlen >= 32 then
                    buffer_size = buffer_size + 1
                    buffer[buffer_size] =
                        _byte_to_char[cache % 256]
                        .._byte_to_char[((cache-cache%256)/256 % 256)]
                        .._byte_to_char[((cache-cache%65536)/65536 % 256)]
                        .._byte_to_char[((cache-cache%16777216)/16777216 % 256)]
                    local rshift_mask = _pow2[32 - cache_bitlen + bitlen]
                    cache = (value - value%rshift_mask)/rshift_mask
                    cache_bitlen = cache_bitlen - 32
                end
            end

            -- Write the entire string into the writer.
            -- @param str The string being written
            -- @return nil
            local function WriteString(str)
                for _ = 1, cache_bitlen, 8 do
                    buffer_size = buffer_size + 1
                    buffer[buffer_size] = string_char(cache % 256)
                    cache = (cache-cache%256)/256
                end
                cache_bitlen = 0
                buffer_size = buffer_size + 1
                buffer[buffer_size] = str
                total_bitlen = total_bitlen + #str*8
            end

            -- Flush current stuffs in the writer and return it.
            -- This operation will free most of the memory.
            -- @param mode See the descrtion of the constant and the source code.
            -- @return The total number of bits stored in the writer right now.
            -- for byte boundary mode, it includes the padding bits.
            -- for output mode, it does not include padding bits.
            -- @return Return the outputs if mode is output.
            local function FlushWriter(mode)
                if mode == _FLUSH_MODE_NO_FLUSH then
                    return total_bitlen
                end

                if mode == _FLUSH_MODE_OUTPUT
                    or mode == _FLUSH_MODE_BYTE_BOUNDARY then
                    -- Full flush, also output cache.
                    -- Need to pad some bits if cache_bitlen is not multiple of 8.
                    local padding_bitlen = (8 - cache_bitlen % 8) % 8

                    if cache_bitlen > 0 then
                        -- padding with all 1 bits, mainly because "\000" is not
                        -- good to be tranmitted. I do this so "\000" is a little bit
                        -- less frequent.
                        cache = cache - _pow2[cache_bitlen]
                            + _pow2[cache_bitlen+padding_bitlen]
                        for _ = 1, cache_bitlen, 8 do
                            buffer_size = buffer_size + 1
                            buffer[buffer_size] = _byte_to_char[cache % 256]
                            cache = (cache-cache%256)/256
                        end

                        cache = 0
                        cache_bitlen = 0
                    end
                    if mode == _FLUSH_MODE_BYTE_BOUNDARY then
                        total_bitlen = total_bitlen + padding_bitlen
                        return total_bitlen
                    end
                end

                local flushed = table_concat(buffer)
                buffer = {}
                buffer_size = 0
                result_buffer[#result_buffer+1] = flushed

                if mode == _FLUSH_MODE_MEMORY_CLEANUP then
                    return total_bitlen
                else
                    return total_bitlen, table_concat(result_buffer)
                end
            end

            return WriteBits, WriteString, FlushWriter
        end

        -- Push an element into a max heap
        -- @param heap A max heap whose max element is at index 1.
        -- @param e The element to be pushed. Assume element "e" is a table
        --  and comparison is done via its first entry e[1]
        -- @param heap_size current number of elements in the heap.
        --  NOTE: There may be some garbage stored in
        --  heap[heap_size+1], heap[heap_size+2], etc..
        -- @return nil
        local function MinHeapPush(heap, e, heap_size)
            heap_size = heap_size + 1
            heap[heap_size] = e
            local value = e[1]
            local pos = heap_size
            local parent_pos = (pos-pos%2)/2

            while (parent_pos >= 1 and heap[parent_pos][1] > value) do
                local t = heap[parent_pos]
                heap[parent_pos] = e
                heap[pos] = t
                pos = parent_pos
                parent_pos = (parent_pos-parent_pos%2)/2
            end
        end

        -- Pop an element from a max heap
        -- @param heap A max heap whose max element is at index 1.
        -- @param heap_size current number of elements in the heap.
        -- @return the poped element
        -- Note: This function does not change table size of "heap" to save CPU time.
        local function MinHeapPop(heap, heap_size)
            local top = heap[1]
            local e = heap[heap_size]
            local value = e[1]
            heap[1] = e
            heap[heap_size] = top
            heap_size = heap_size - 1

            local pos = 1
            local left_child_pos = pos * 2
            local right_child_pos = left_child_pos + 1

            while (left_child_pos <= heap_size) do
                local left_child = heap[left_child_pos]
                if (right_child_pos <= heap_size
                    and heap[right_child_pos][1] < left_child[1]) then
                    local right_child = heap[right_child_pos]
                    if right_child[1] < value then
                        heap[right_child_pos] = e
                        heap[pos] = right_child
                        pos = right_child_pos
                        left_child_pos = pos * 2
                        right_child_pos = left_child_pos + 1
                    else
                        break
                    end
                else
                    if left_child[1] < value then
                        heap[left_child_pos] = e
                        heap[pos] = left_child
                        pos = left_child_pos
                        left_child_pos = pos * 2
                        right_child_pos = left_child_pos + 1
                    else
                        break
                    end
                end
            end

            return top
        end

        -- Deflate defines a special huffman tree, which is unique once the bit length
        -- of huffman code of all symbols are known.
        -- @param bitlen_count Number of symbols with a specific bitlen
        -- @param symbol_bitlen The bit length of a symbol
        -- @param max_symbol The max symbol among all symbols,
        --		which is (number of symbols - 1)
        -- @param max_bitlen The max huffman bit length among all symbols.
        -- @return The huffman code of all symbols.
        local function GetHuffmanCodeFromBitlen(bitlen_counts, symbol_bitlens
            , max_symbol, max_bitlen)
            local huffman_code = 0
            local next_codes = {}
            local symbol_huffman_codes = {}
            for bitlen = 1, max_bitlen do
                huffman_code = (huffman_code+(bitlen_counts[bitlen-1] or 0))*2
                next_codes[bitlen] = huffman_code
            end
            for symbol = 0, max_symbol do
                local bitlen = symbol_bitlens[symbol]
                if bitlen then
                    huffman_code = next_codes[bitlen]
                    next_codes[bitlen] = huffman_code + 1

                    -- Reverse the bits of huffman code,
                    -- because most signifant bits of huffman code
                    -- is stored first into the compressed data.
                    -- @see RFC1951 Page5 Section 3.1.1
                    if bitlen <= 9 then -- Have cached reverse for small bitlen.
                        symbol_huffman_codes[symbol] =
                            _reverse_bits_tbl[bitlen][huffman_code]
                    else
                        local reverse = 0
                        for _ = 1, bitlen do
                            reverse = reverse - reverse%2
                                + (((reverse%2==1)
                                    or (huffman_code % 2) == 1) and 1 or 0)
                            huffman_code = (huffman_code-huffman_code%2)/2
                            reverse = reverse*2
                        end
                        symbol_huffman_codes[symbol] = (reverse-reverse%2)/2
                    end
                end
            end
            return symbol_huffman_codes
        end

        -- A helper function to sort heap elements
        -- a[1], b[1] is the huffman frequency
        -- a[2], b[2] is the symbol value.
        local function SortByFirstThenSecond(a, b)
            return a[1] < b[1] or
                (a[1] == b[1] and a[2] < b[2])
        end

        -- Calculate the huffman bit length and huffman code.
        -- @param symbol_count: A table whose table key is the symbol, and table value
        --		is the symbol frenquency (nil means 0 frequency).
        -- @param max_bitlen: See description of return value.
        -- @param max_symbol: The maximum symbol
        -- @return a table whose key is the symbol, and the value is the huffman bit
        --		bit length. We guarantee that all bit length <= max_bitlen.
        --		For 0<=symbol<=max_symbol, table value could be nil if the frequency
        --		of the symbol is 0 or nil.
        -- @return a table whose key is the symbol, and the value is the huffman code.
        -- @return a number indicating the maximum symbol whose bitlen is not 0.
        local function GetHuffmanBitlenAndCode(symbol_counts, max_bitlen, max_symbol)
            local heap_size
            local max_non_zero_bitlen_symbol = -1
            local leafs = {}
            local heap = {}
            local symbol_bitlens = {}
            local symbol_codes = {}
            local bitlen_counts = {}

            --[[
                tree[1]: weight, temporarily used as parent and bitLengths
                tree[2]: symbol
                tree[3]: left child
                tree[4]: right child
            --]]
            local number_unique_symbols = 0
            for symbol, count in pairs(symbol_counts) do
                number_unique_symbols = number_unique_symbols + 1
                leafs[number_unique_symbols] = {count, symbol}
            end

            if (number_unique_symbols == 0) then
                -- no code.
                return {}, {}, -1
            elseif (number_unique_symbols == 1) then
                -- Only one code. In this case, its huffman code
                -- needs to be assigned as 0, and bit length is 1.
                -- This is the only case that the return result
                -- represents an imcomplete huffman tree.
                local symbol = leafs[1][2]
                symbol_bitlens[symbol] = 1
                symbol_codes[symbol] = 0
                return symbol_bitlens, symbol_codes, symbol
            else
                table_sort(leafs, SortByFirstThenSecond)
                heap_size = number_unique_symbols
                for i = 1, heap_size do
                    heap[i] = leafs[i]
                end

                while (heap_size > 1) do
                    -- Note: pop does not change table size of heap
                    local leftChild = MinHeapPop(heap, heap_size)
                    heap_size = heap_size - 1
                    local rightChild = MinHeapPop(heap, heap_size)
                    heap_size = heap_size - 1
                    local newNode =
                        {leftChild[1]+rightChild[1], -1, leftChild, rightChild}
                    MinHeapPush(heap, newNode, heap_size)
                    heap_size = heap_size + 1
                end

                -- Number of leafs whose bit length is greater than max_len.
                local number_bitlen_overflow = 0

                -- Calculate bit length of all nodes
                local fifo = {heap[1], 0, 0, 0} -- preallocate some spaces.
                local fifo_size = 1
                local index = 1
                heap[1][1] = 0
                while (index <= fifo_size) do -- Breath first search
                    local e = fifo[index]
                    local bitlen = e[1]
                    local symbol = e[2]
                    local left_child = e[3]
                    local right_child = e[4]
                    if left_child then
                        fifo_size = fifo_size + 1
                        fifo[fifo_size] = left_child
                        left_child[1] = bitlen + 1
                    end
                    if right_child then
                        fifo_size = fifo_size + 1
                        fifo[fifo_size] = right_child
                        right_child[1] = bitlen + 1
                    end
                    index = index + 1

                    if (bitlen > max_bitlen) then
                        number_bitlen_overflow = number_bitlen_overflow + 1
                        bitlen = max_bitlen
                    end
                    if symbol >= 0 then
                        symbol_bitlens[symbol] = bitlen
                        max_non_zero_bitlen_symbol =
                            (symbol > max_non_zero_bitlen_symbol)
                            and symbol or max_non_zero_bitlen_symbol
                        bitlen_counts[bitlen] = (bitlen_counts[bitlen] or 0) + 1
                    end
                end

                -- Resolve bit length overflow
                -- @see ZLib/trees.c:gen_bitlen(s, desc), for reference
                if (number_bitlen_overflow > 0) then
                    repeat
                        local bitlen = max_bitlen - 1
                        while ((bitlen_counts[bitlen] or 0) == 0) do
                            bitlen = bitlen - 1
                        end
                        -- move one leaf down the tree
                        bitlen_counts[bitlen] = bitlen_counts[bitlen] - 1
                        -- move one overflow item as its brother
                        bitlen_counts[bitlen+1] = (bitlen_counts[bitlen+1] or 0) + 2
                        bitlen_counts[max_bitlen] = bitlen_counts[max_bitlen] - 1
                        number_bitlen_overflow = number_bitlen_overflow - 2
                    until (number_bitlen_overflow <= 0)

                    index = 1
                    for bitlen = max_bitlen, 1, -1 do
                        local n = bitlen_counts[bitlen] or 0
                        while (n > 0) do
                            local symbol = leafs[index][2]
                            symbol_bitlens[symbol] = bitlen
                            n = n - 1
                            index = index + 1
                        end
                    end
                end

                symbol_codes = GetHuffmanCodeFromBitlen(bitlen_counts, symbol_bitlens,
                    max_symbol, max_bitlen)
                return symbol_bitlens, symbol_codes, max_non_zero_bitlen_symbol
            end
        end

        -- Calculate the first huffman header in the dynamic huffman block
        -- @see RFC1951 Page 12
        -- @param lcode_bitlen: The huffman bit length of literal/LZ77_length.
        -- @param max_non_zero_bitlen_lcode: The maximum literal/LZ77_length symbol
        --		whose huffman bit length is not zero.
        -- @param dcode_bitlen: The huffman bit length of LZ77 distance.
        -- @param max_non_zero_bitlen_dcode: The maximum LZ77 distance symbol
        --		whose huffman bit length is not zero.
        -- @return The run length encoded codes.
        -- @return The extra bits. One entry for each rle code that needs extra bits.
        --		(code == 16 or 17 or 18).
        -- @return The count of appearance of each rle codes.
        local function RunLengthEncodeHuffmanBitlen(
            lcode_bitlens,
            max_non_zero_bitlen_lcode,
            dcode_bitlens,
            max_non_zero_bitlen_dcode)
            local rle_code_tblsize = 0
            local rle_codes = {}
            local rle_code_counts = {}
            local rle_extra_bits_tblsize = 0
            local rle_extra_bits = {}
            local prev = nil
            local count = 0

            -- If there is no distance code, assume one distance code of bit length 0.
            -- RFC1951: One distance code of zero bits means that
            -- there are no distance codes used at all (the data is all literals).
            max_non_zero_bitlen_dcode = (max_non_zero_bitlen_dcode < 0)
                and 0 or max_non_zero_bitlen_dcode
            local max_code = max_non_zero_bitlen_lcode+max_non_zero_bitlen_dcode+1

            for code = 0, max_code+1 do
                local len = (code <= max_non_zero_bitlen_lcode)
                    and (lcode_bitlens[code] or 0)
                    or ((code <= max_code)
                        and (dcode_bitlens[code-max_non_zero_bitlen_lcode-1] or 0) or nil)
                if len == prev then
                    count = count + 1
                    if len ~= 0 and count == 6 then
                        rle_code_tblsize = rle_code_tblsize + 1
                        rle_codes[rle_code_tblsize] = 16
                        rle_extra_bits_tblsize = rle_extra_bits_tblsize + 1
                        rle_extra_bits[rle_extra_bits_tblsize] = 3
                        rle_code_counts[16] = (rle_code_counts[16] or 0) + 1
                        count = 0
                    elseif len == 0 and count == 138 then
                        rle_code_tblsize = rle_code_tblsize + 1
                        rle_codes[rle_code_tblsize] = 18
                        rle_extra_bits_tblsize = rle_extra_bits_tblsize + 1
                        rle_extra_bits[rle_extra_bits_tblsize] = 127
                        rle_code_counts[18] = (rle_code_counts[18] or 0) + 1
                        count = 0
                    end
                else
                    if count == 1 then
                        rle_code_tblsize = rle_code_tblsize + 1
                        rle_codes[rle_code_tblsize] = prev
                        rle_code_counts[prev] = (rle_code_counts[prev] or 0) + 1
                    elseif count == 2 then
                        rle_code_tblsize = rle_code_tblsize + 1
                        rle_codes[rle_code_tblsize] = prev
                        rle_code_tblsize = rle_code_tblsize + 1
                        rle_codes[rle_code_tblsize] = prev
                        rle_code_counts[prev] = (rle_code_counts[prev] or 0) + 2
                    elseif count >= 3 then
                        rle_code_tblsize = rle_code_tblsize + 1
                        local rleCode = (prev ~= 0) and 16 or (count <= 10 and 17 or 18)
                        rle_codes[rle_code_tblsize] = rleCode
                        rle_code_counts[rleCode] = (rle_code_counts[rleCode] or 0) + 1
                        rle_extra_bits_tblsize = rle_extra_bits_tblsize + 1
                        rle_extra_bits[rle_extra_bits_tblsize] =
                            (count <= 10) and (count - 3) or (count - 11)
                    end

                    prev = len
                    if len and len ~= 0 then
                        rle_code_tblsize = rle_code_tblsize + 1
                        rle_codes[rle_code_tblsize] = len
                        rle_code_counts[len] = (rle_code_counts[len] or 0) + 1
                        count = 0
                    else
                        count = 1
                    end
                end
            end

            return rle_codes, rle_extra_bits, rle_code_counts
        end

        -- Load the string into a table, in order to speed up LZ77.
        -- Loop unrolled 16 times to speed this function up.
        -- @param str The string to be loaded.
        -- @param t The load destination
        -- @param start str[index] will be the first character to be loaded.
        -- @param end str[index] will be the last character to be loaded
        -- @param offset str[index] will be loaded into t[index-offset]
        -- @return t
        local function LoadStringToTable(str, t, start, stop, offset)
            local i = start - offset
            while i <= stop - 15 - offset do
                t[i], t[i+1], t[i+2], t[i+3], t[i+4], t[i+5], t[i+6], t[i+7], t[i+8],
                t[i+9], t[i+10], t[i+11], t[i+12], t[i+13], t[i+14], t[i+15] =
                    string_byte(str, i + offset, i + 15 + offset)
                i = i + 16
            end
            while (i <= stop - offset) do
                t[i] = string_byte(str, i + offset, i + offset)
                i = i + 1
            end
            return t
        end

        -- Do LZ77 process. This function uses the majority of the CPU time.
        -- @see zlib/deflate.c:deflate_fast(), zlib/deflate.c:deflate_slow()
        -- @see https://github.com/madler/zlib/blob/master/doc/algorithm.txt
        -- This function uses the algorithms used above. You should read the
        -- algorithm.txt above to understand what is the hash function and the
        -- lazy evaluation.
        --
        -- The special optimization used here is hash functions used here.
        -- The hash function is just the multiplication of the three consective
        -- characters. So if the hash matches, it guarantees 3 characters are matched.
        -- This optimization can be implemented because Lua table is a hash table.
        --
        -- @param level integer that describes compression level.
        -- @param string_table table that stores the value of string to be compressed.
        --			The index of this table starts from 1.
        --			The caller needs to make sure all values needed by this function
        --			are loaded.
        --			Assume "str" is the origin input string into the compressor
        --			str[block_start]..str[block_end+3] needs to be loaded into
        --			string_table[block_start-offset]..string_table[block_end-offset]
        --			If dictionary is presented, the last 258 bytes of the dictionary
        --			needs to be loaded into sing_table[-257..0]
        --			(See more in the description of offset.)
        -- @param hash_tables. The table key is the hash value (0<=hash<=16777216=256^3)
        --			The table value is an array0 that stores the indexes of the
        --			input data string to be compressed, such that
        --			hash == str[index]*str[index+1]*str[index+2]
        --			Indexes are ordered in this array.
        -- @param block_start The indexes of the input data string to be compressed.
        --				that starts the LZ77 block.
        -- @param block_end The indexes of the input data string to be compressed.
        --				that stores the LZ77 block.
        -- @param offset str[index] is stored in string_table[index-offset],
        --			This offset is mainly an optimization to limit the index
        --			of string_table, so lua can access this table quicker.
        -- @param dictionary See LibDeflate:CreateDictionary
        -- @return literal/LZ77_length deflate codes.
        -- @return the extra bits of literal/LZ77_length deflate codes.
        -- @return the count of each literal/LZ77 deflate code.
        -- @return LZ77 distance deflate codes.
        -- @return the extra bits of LZ77 distance deflate codes.
        -- @return the count of each LZ77 distance deflate code.
        local function GetBlockLZ77Result(level, string_table, hash_tables, block_start,
            block_end, offset, dictionary)
            local config = _compression_level_configs[level]
            local config_use_lazy
            , config_good_prev_length
            , config_max_lazy_match
            , config_nice_length
            , config_max_hash_chain =
                config[1], config[2], config[3], config[4], config[5]

            local config_max_insert_length = (not config_use_lazy)
                and config_max_lazy_match or 2147483646
            local config_good_hash_chain =
                (config_max_hash_chain-config_max_hash_chain%4/4)

            local hash

            local dict_hash_tables
            local dict_string_table
            local dict_string_len = 0

            if dictionary then
                dict_hash_tables = dictionary.hash_tables
                dict_string_table = dictionary.string_table
                dict_string_len = dictionary.strlen
                assert(block_start == 1)
                if block_end >= block_start and dict_string_len >= 2 then
                    hash = dict_string_table[dict_string_len-1]*65536
                        + dict_string_table[dict_string_len]*256 + string_table[1]
                    local t = hash_tables[hash]
                    if not t then t = {}; hash_tables[hash] = t end
                    t[#t+1] = -1
                end
                if block_end >= block_start+1 and dict_string_len >= 1 then
                    hash = dict_string_table[dict_string_len]*65536
                        + string_table[1]*256 + string_table[2]
                    local t = hash_tables[hash]
                    if not t then t = {}; hash_tables[hash] = t end
                    t[#t+1] = 0
                end
            end

            local dict_string_len_plus3 = dict_string_len + 3

            hash = (string_table[block_start-offset] or 0)*256
                + (string_table[block_start+1-offset] or 0)

            local lcodes = {}
            local lcode_tblsize = 0
            local lcodes_counts = {}
            local dcodes = {}
            local dcodes_tblsize = 0
            local dcodes_counts = {}

            local lextra_bits = {}
            local lextra_bits_tblsize = 0
            local dextra_bits = {}
            local dextra_bits_tblsize = 0

            local match_available = false
            local prev_len
            local prev_dist
            local cur_len = 0
            local cur_dist = 0

            local index = block_start
            local index_end = block_end + (config_use_lazy and 1 or 0)

            -- the zlib source code writes separate code for lazy evaluation and
            -- not lazy evaluation, which is easier to understand.
            -- I put them together, so it is a bit harder to understand.
            -- because I think this is easier for me to maintain it.
            while (index <= index_end) do
                local string_table_index = index - offset
                local offset_minus_three = offset - 3
                prev_len = cur_len
                prev_dist = cur_dist
                cur_len = 0

                hash = (hash*256+(string_table[string_table_index+2] or 0))%16777216

                local chain_index
                local cur_chain
                local hash_chain = hash_tables[hash]
                local chain_old_size
                if not hash_chain then
                    chain_old_size = 0
                    hash_chain = {}
                    hash_tables[hash] = hash_chain
                    if dict_hash_tables then
                        cur_chain = dict_hash_tables[hash]
                        chain_index = cur_chain and #cur_chain or 0
                    else
                        chain_index = 0
                    end
                else
                    chain_old_size = #hash_chain
                    cur_chain = hash_chain
                    chain_index = chain_old_size
                end

                if index <= block_end then
                    hash_chain[chain_old_size+1] = index
                end

                if (chain_index > 0 and index + 2 <= block_end
                    and (not config_use_lazy or prev_len < config_max_lazy_match)) then

                    local depth =
                        (config_use_lazy and prev_len >= config_good_prev_length)
                        and config_good_hash_chain or config_max_hash_chain

                    local max_len_minus_one = block_end - index
                    max_len_minus_one = (max_len_minus_one >= 257) and 257 or max_len_minus_one
                    max_len_minus_one = max_len_minus_one + string_table_index
                    local string_table_index_plus_three = string_table_index + 3

                    while chain_index >= 1 and depth > 0 do
                        local prev = cur_chain[chain_index]

                        if index - prev > 32768 then
                            break
                        end
                        if prev < index then
                            local sj = string_table_index_plus_three

                            if prev >= -257 then
                                local pj = prev - offset_minus_three
                                while (sj <= max_len_minus_one
                                    and string_table[pj]
                                    == string_table[sj]) do
                                    sj = sj + 1
                                    pj = pj + 1
                                end
                            else
                                local pj = dict_string_len_plus3 + prev
                                while (sj <= max_len_minus_one
                                    and dict_string_table[pj]
                                    == string_table[sj]) do
                                    sj = sj + 1
                                    pj = pj + 1
                                end
                            end
                            local j = sj - string_table_index
                            if j > cur_len then
                                cur_len = j
                                cur_dist = index - prev
                            end
                            if cur_len >= config_nice_length then
                                break
                            end
                        end

                        chain_index = chain_index - 1
                        depth = depth - 1
                        if chain_index == 0 and prev > 0 and dict_hash_tables then
                            cur_chain = dict_hash_tables[hash]
                            chain_index = cur_chain and #cur_chain or 0
                        end
                    end
                end

                if not config_use_lazy then
                    prev_len, prev_dist = cur_len, cur_dist
                end
                if ((not config_use_lazy or match_available)
                    and (prev_len > 3 or (prev_len == 3 and prev_dist < 4096))
                    and cur_len <= prev_len )then
                    local code = _length_to_deflate_code[prev_len]
                    local length_extra_bits_bitlen =
                        _length_to_deflate_extra_bitlen[prev_len]
                    local dist_code, dist_extra_bits_bitlen, dist_extra_bits
                    if prev_dist <= 256 then -- have cached code for small distance.
                        dist_code = _dist256_to_deflate_code[prev_dist]
                        dist_extra_bits = _dist256_to_deflate_extra_bits[prev_dist]
                        dist_extra_bits_bitlen =
                            _dist256_to_deflate_extra_bitlen[prev_dist]
                    else
                        dist_code = 16
                        dist_extra_bits_bitlen = 7
                        local a = 384
                        local b = 512

                        while true do
                            if prev_dist <= a then
                                dist_extra_bits = (prev_dist-(b/2)-1) % (b/4)
                                break
                            elseif prev_dist <= b then
                                dist_extra_bits = (prev_dist-(b/2)-1) % (b/4)
                                dist_code = dist_code + 1
                                break
                            else
                                dist_code = dist_code + 2
                                dist_extra_bits_bitlen = dist_extra_bits_bitlen + 1
                                a = a*2
                                b = b*2
                            end
                        end
                    end
                    lcode_tblsize = lcode_tblsize + 1
                    lcodes[lcode_tblsize] = code
                    lcodes_counts[code] = (lcodes_counts[code] or 0) + 1

                    dcodes_tblsize = dcodes_tblsize + 1
                    dcodes[dcodes_tblsize] = dist_code
                    dcodes_counts[dist_code] = (dcodes_counts[dist_code] or 0) + 1

                    if length_extra_bits_bitlen > 0 then
                        local lenExtraBits = _length_to_deflate_extra_bits[prev_len]
                        lextra_bits_tblsize = lextra_bits_tblsize + 1
                        lextra_bits[lextra_bits_tblsize] = lenExtraBits
                    end
                    if dist_extra_bits_bitlen > 0 then
                        dextra_bits_tblsize = dextra_bits_tblsize + 1
                        dextra_bits[dextra_bits_tblsize] = dist_extra_bits
                    end

                    for i=index+1, index+prev_len-(config_use_lazy and 2 or 1) do
                        hash = (hash*256+(string_table[i-offset+2] or 0))%16777216
                        if prev_len <= config_max_insert_length then
                            hash_chain = hash_tables[hash]
                            if not hash_chain then
                                hash_chain = {}
                                hash_tables[hash] = hash_chain
                            end
                            hash_chain[#hash_chain+1] = i
                        end
                    end
                    index = index + prev_len - (config_use_lazy and 1 or 0)
                    match_available = false
                elseif (not config_use_lazy) or match_available then
                    local code = string_table[config_use_lazy
                        and (string_table_index-1) or string_table_index]
                    lcode_tblsize = lcode_tblsize + 1
                    lcodes[lcode_tblsize] = code
                    lcodes_counts[code] = (lcodes_counts[code] or 0) + 1
                    index = index + 1
                else
                    match_available = true
                    index = index + 1
                end
            end

            -- Write "end of block" symbol
            lcode_tblsize = lcode_tblsize + 1
            lcodes[lcode_tblsize] = 256
            lcodes_counts[256] = (lcodes_counts[256] or 0) + 1

            return lcodes, lextra_bits, lcodes_counts, dcodes, dextra_bits
            , dcodes_counts
        end

        -- Get the header data of dynamic block.
        -- @param lcodes_count The count of each literal/LZ77_length codes.
        -- @param dcodes_count The count of each Lz77 distance codes.
        -- @return a lots of stuffs.
        -- @see RFC1951 Page 12
        local function GetBlockDynamicHuffmanHeader(lcodes_counts, dcodes_counts)
            local lcodes_huffman_bitlens, lcodes_huffman_codes
            , max_non_zero_bitlen_lcode =
                GetHuffmanBitlenAndCode(lcodes_counts, 15, 285)
            local dcodes_huffman_bitlens, dcodes_huffman_codes
            , max_non_zero_bitlen_dcode =
                GetHuffmanBitlenAndCode(dcodes_counts, 15, 29)

            local rle_deflate_codes, rle_extra_bits, rle_codes_counts =
                RunLengthEncodeHuffmanBitlen(lcodes_huffman_bitlens
                    ,max_non_zero_bitlen_lcode, dcodes_huffman_bitlens
                    , max_non_zero_bitlen_dcode)

            local rle_codes_huffman_bitlens, rle_codes_huffman_codes =
                GetHuffmanBitlenAndCode(rle_codes_counts, 7, 18)

            local HCLEN = 0
            for i = 1, 19 do
                local symbol = _rle_codes_huffman_bitlen_order[i]
                local length = rle_codes_huffman_bitlens[symbol] or 0
                if length ~= 0 then
                    HCLEN = i
                end
            end

            HCLEN = HCLEN - 4
            local HLIT = max_non_zero_bitlen_lcode + 1 - 257
            local HDIST = max_non_zero_bitlen_dcode + 1 - 1
            if HDIST < 0 then HDIST = 0 end

            return HLIT, HDIST, HCLEN, rle_codes_huffman_bitlens
            , rle_codes_huffman_codes, rle_deflate_codes, rle_extra_bits
            , lcodes_huffman_bitlens, lcodes_huffman_codes
            , dcodes_huffman_bitlens, dcodes_huffman_codes
        end

        -- Get the size of dynamic block without writing any bits into the writer.
        -- @param ... Read the source code of GetBlockDynamicHuffmanHeader()
        -- @return the bit length of the dynamic block
        local function GetDynamicHuffmanBlockSize(lcodes, dcodes, HCLEN
            , rle_codes_huffman_bitlens, rle_deflate_codes
            , lcodes_huffman_bitlens, dcodes_huffman_bitlens)

            local block_bitlen = 17 -- 1+2+5+5+4
            block_bitlen = block_bitlen + (HCLEN+4)*3

            for i = 1, #rle_deflate_codes do
                local code = rle_deflate_codes[i]
                block_bitlen = block_bitlen + rle_codes_huffman_bitlens[code]
                if code >= 16 then
                    block_bitlen = block_bitlen +
                        ((code == 16) and 2 or (code == 17 and 3 or 7))
                end
            end

            local length_code_count = 0
            for i = 1, #lcodes do
                local code = lcodes[i]
                local huffman_bitlen = lcodes_huffman_bitlens[code]
                block_bitlen = block_bitlen + huffman_bitlen
                if code > 256 then -- Length code
                    length_code_count = length_code_count + 1
                    if code > 264 and code < 285 then -- Length code with extra bits
                        local extra_bits_bitlen =
                            _literal_deflate_code_to_extra_bitlen[code-256]
                        block_bitlen = block_bitlen + extra_bits_bitlen
                    end
                    local dist_code = dcodes[length_code_count]
                    local dist_huffman_bitlen = dcodes_huffman_bitlens[dist_code]
                    block_bitlen = block_bitlen + dist_huffman_bitlen

                    if dist_code > 3 then -- dist code with extra bits
                        local dist_extra_bits_bitlen = (dist_code-dist_code%2)/2 - 1
                        block_bitlen = block_bitlen + dist_extra_bits_bitlen
                    end
                end
            end
            return block_bitlen
        end

        -- Write dynamic block.
        -- @param ... Read the source code of GetBlockDynamicHuffmanHeader()
        local function CompressDynamicHuffmanBlock(WriteBits, is_last_block
            , lcodes, lextra_bits, dcodes, dextra_bits, HLIT, HDIST, HCLEN
            , rle_codes_huffman_bitlens, rle_codes_huffman_codes
            , rle_deflate_codes, rle_extra_bits
            , lcodes_huffman_bitlens, lcodes_huffman_codes
            , dcodes_huffman_bitlens, dcodes_huffman_codes)

            WriteBits(is_last_block and 1 or 0, 1) -- Last block identifier
            WriteBits(2, 2) -- Dynamic Huffman block identifier

            WriteBits(HLIT, 5)
            WriteBits(HDIST, 5)
            WriteBits(HCLEN, 4)

            for i = 1, HCLEN+4 do
                local symbol = _rle_codes_huffman_bitlen_order[i]
                local length = rle_codes_huffman_bitlens[symbol] or 0
                WriteBits(length, 3)
            end

            local rleExtraBitsIndex = 1
            for i=1, #rle_deflate_codes do
                local code = rle_deflate_codes[i]
                WriteBits(rle_codes_huffman_codes[code]
                    , rle_codes_huffman_bitlens[code])
                if code >= 16 then
                    local extraBits = rle_extra_bits[rleExtraBitsIndex]
                    WriteBits(extraBits, (code == 16) and 2 or (code == 17 and 3 or 7))
                    rleExtraBitsIndex = rleExtraBitsIndex + 1
                end
            end

            local length_code_count = 0
            local length_code_with_extra_count = 0
            local dist_code_with_extra_count = 0

            for i=1, #lcodes do
                local deflate_codee = lcodes[i]
                local huffman_code = lcodes_huffman_codes[deflate_codee]
                local huffman_bitlen = lcodes_huffman_bitlens[deflate_codee]
                WriteBits(huffman_code, huffman_bitlen)
                if deflate_codee > 256 then -- Length code
                    length_code_count = length_code_count + 1
                    if deflate_codee > 264 and deflate_codee < 285 then
                        -- Length code with extra bits
                        length_code_with_extra_count = length_code_with_extra_count + 1
                        local extra_bits = lextra_bits[length_code_with_extra_count]
                        local extra_bits_bitlen =
                            _literal_deflate_code_to_extra_bitlen[deflate_codee-256]
                        WriteBits(extra_bits, extra_bits_bitlen)
                    end
                    -- Write distance code
                    local dist_deflate_code = dcodes[length_code_count]
                    local dist_huffman_code = dcodes_huffman_codes[dist_deflate_code]
                    local dist_huffman_bitlen =
                        dcodes_huffman_bitlens[dist_deflate_code]
                    WriteBits(dist_huffman_code, dist_huffman_bitlen)

                    if dist_deflate_code > 3 then -- dist code with extra bits
                        dist_code_with_extra_count = dist_code_with_extra_count + 1
                        local dist_extra_bits = dextra_bits[dist_code_with_extra_count]
                        local dist_extra_bits_bitlen =
                            (dist_deflate_code-dist_deflate_code%2)/2 - 1
                        WriteBits(dist_extra_bits, dist_extra_bits_bitlen)
                    end
                end
            end
        end

        -- Get the size of fixed block without writing any bits into the writer.
        -- @param lcodes literal/LZ77_length deflate codes
        -- @param decodes LZ77 distance deflate codes
        -- @return the bit length of the fixed block
        local function GetFixedHuffmanBlockSize(lcodes, dcodes)
            local block_bitlen = 3
            local length_code_count = 0
            for i=1, #lcodes do
                local code = lcodes[i]
                local huffman_bitlen = _fix_block_literal_huffman_bitlen[code]
                block_bitlen = block_bitlen + huffman_bitlen
                if code > 256 then -- Length code
                    length_code_count = length_code_count + 1
                    if code > 264 and code < 285 then -- Length code with extra bits
                        local extra_bits_bitlen =
                            _literal_deflate_code_to_extra_bitlen[code-256]
                        block_bitlen = block_bitlen + extra_bits_bitlen
                    end
                    local dist_code = dcodes[length_code_count]
                    block_bitlen = block_bitlen + 5

                    if dist_code > 3 then -- dist code with extra bits
                        local dist_extra_bits_bitlen =
                            (dist_code-dist_code%2)/2 - 1
                        block_bitlen = block_bitlen + dist_extra_bits_bitlen
                    end
                end
            end
            return block_bitlen
        end

        -- Write fixed block.
        -- @param lcodes literal/LZ77_length deflate codes
        -- @param decodes LZ77 distance deflate codes
        local function CompressFixedHuffmanBlock(WriteBits, is_last_block,
            lcodes, lextra_bits, dcodes, dextra_bits)
            WriteBits(is_last_block and 1 or 0, 1) -- Last block identifier
            WriteBits(1, 2) -- Fixed Huffman block identifier
            local length_code_count = 0
            local length_code_with_extra_count = 0
            local dist_code_with_extra_count = 0
            for i=1, #lcodes do
                local deflate_code = lcodes[i]
                local huffman_code = _fix_block_literal_huffman_code[deflate_code]
                local huffman_bitlen = _fix_block_literal_huffman_bitlen[deflate_code]
                WriteBits(huffman_code, huffman_bitlen)
                if deflate_code > 256 then -- Length code
                    length_code_count = length_code_count + 1
                    if deflate_code > 264 and deflate_code < 285 then
                        -- Length code with extra bits
                        length_code_with_extra_count = length_code_with_extra_count + 1
                        local extra_bits = lextra_bits[length_code_with_extra_count]
                        local extra_bits_bitlen =
                            _literal_deflate_code_to_extra_bitlen[deflate_code-256]
                        WriteBits(extra_bits, extra_bits_bitlen)
                    end
                    -- Write distance code
                    local dist_code = dcodes[length_code_count]
                    local dist_huffman_code = _fix_block_dist_huffman_code[dist_code]
                    WriteBits(dist_huffman_code, 5)

                    if dist_code > 3 then -- dist code with extra bits
                        dist_code_with_extra_count = dist_code_with_extra_count + 1
                        local dist_extra_bits = dextra_bits[dist_code_with_extra_count]
                        local dist_extra_bits_bitlen = (dist_code-dist_code%2)/2 - 1
                        WriteBits(dist_extra_bits, dist_extra_bits_bitlen)
                    end
                end
            end
        end

        -- Get the size of store block without writing any bits into the writer.
        -- @param block_start The start index of the origin input string
        -- @param block_end The end index of the origin input string
        -- @param Total bit lens had been written into the compressed result before,
        -- because store block needs to shift to byte boundary.
        -- @return the bit length of the fixed block
        local function GetStoreBlockSize(block_start, block_end, total_bitlen)
            assert(block_end-block_start+1 <= 65535)
            local block_bitlen = 3
            total_bitlen = total_bitlen + 3
            local padding_bitlen = (8-total_bitlen%8)%8
            block_bitlen = block_bitlen + padding_bitlen
            block_bitlen = block_bitlen + 32
            block_bitlen = block_bitlen + (block_end - block_start + 1) * 8
            return block_bitlen
        end

        -- Write the store block.
        -- @param ... lots of stuffs
        -- @return nil
        local function CompressStoreBlock(WriteBits, WriteString, is_last_block, str
            , block_start, block_end, total_bitlen)
            assert(block_end-block_start+1 <= 65535)
            WriteBits(is_last_block and 1 or 0, 1) -- Last block identifer.
            WriteBits(0, 2) -- Store block identifier.
            total_bitlen = total_bitlen + 3
            local padding_bitlen = (8-total_bitlen%8)%8
            if padding_bitlen > 0 then
                WriteBits(_pow2[padding_bitlen]-1, padding_bitlen)
            end
            local size = block_end - block_start + 1
            WriteBits(size, 16)

            -- Write size's one's complement
            local comp = (255 - size % 256) + (255 - (size-size%256)/256)*256
            WriteBits(comp, 16)

            WriteString(str:sub(block_start, block_end))
        end

        -- Do the deflate
        -- Currently using a simple way to determine the block size
        -- (This is why the compression ratio is little bit worse than zlib when
        -- the input size is very large
        -- The first block is 64KB, the following block is 32KB.
        -- After each block, there is a memory cleanup operation.
        -- This is not a fast operation, but it is needed to save memory usage, so
        -- the memory usage does not grow unboundly. If the data size is less than
        -- 64KB, then memory cleanup won't happen.
        -- This function determines whether to use store/fixed/dynamic blocks by
        -- calculating the block size of each block type and chooses the smallest one.
        local function Deflate(configs, WriteBits, WriteString, FlushWriter, str
            , dictionary)
            local string_table = {}
            local hash_tables = {}
            local is_last_block = nil
            local block_start
            local block_end
            local bitlen_written
            local total_bitlen = FlushWriter(_FLUSH_MODE_NO_FLUSH)
            local strlen = #str
            local offset

            local level
            local strategy
            if configs then
                if configs.level then
                    level = configs.level
                end
                if configs.strategy then
                    strategy = configs.strategy
                end
            end

            if not level then
                if strlen < 2048 then
                    level = 7
                elseif strlen > 65536 then
                    level = 3
                else
                    level = 5
                end
            end

            while not is_last_block do
                if not block_start then
                    block_start = 1
                    block_end = 64*1024 - 1
                    offset = 0
                else
                    block_start = block_end + 1
                    block_end = block_end + 32*1024
                    offset = block_start - 32*1024 - 1
                end

                if block_end >= strlen then
                    block_end = strlen
                    is_last_block = true
                else
                    is_last_block = false
                end

                local lcodes, lextra_bits, lcodes_counts, dcodes, dextra_bits
                , dcodes_counts

                local HLIT, HDIST, HCLEN, rle_codes_huffman_bitlens
                , rle_codes_huffman_codes, rle_deflate_codes
                , rle_extra_bits, lcodes_huffman_bitlens, lcodes_huffman_codes
                , dcodes_huffman_bitlens, dcodes_huffman_codes

                local dynamic_block_bitlen
                local fixed_block_bitlen
                local store_block_bitlen

                if level ~= 0 then

                    -- GetBlockLZ77 needs block_start to block_end+3 to be loaded.
                    LoadStringToTable(str, string_table, block_start, block_end + 3
                        , offset)
                    if block_start == 1 and dictionary then
                        local dict_string_table = dictionary.string_table
                        local dict_strlen = dictionary.strlen
                        for i=0, (-dict_strlen+1)<-257
                            and -257 or (-dict_strlen+1), -1 do
                            string_table[i] = dict_string_table[dict_strlen+i]
                        end
                    end

                    if strategy == "huffman_only" then
                        lcodes = {}
                        LoadStringToTable(str, lcodes, block_start, block_end
                            , block_start-1)
                        lextra_bits = {}
                        lcodes_counts = {}
                        lcodes[block_end - block_start+2] = 256 -- end of block
                        for i=1, block_end - block_start+2 do
                            local code = lcodes[i]
                            lcodes_counts[code] = (lcodes_counts[code] or 0) + 1
                        end
                        dcodes = {}
                        dextra_bits = {}
                        dcodes_counts = {}
                    else
                        lcodes, lextra_bits, lcodes_counts, dcodes, dextra_bits
                        , dcodes_counts = GetBlockLZ77Result(level, string_table
                            , hash_tables, block_start, block_end, offset, dictionary
                        )
                    end

                    HLIT, HDIST, HCLEN, rle_codes_huffman_bitlens
                    , rle_codes_huffman_codes, rle_deflate_codes
                    , rle_extra_bits, lcodes_huffman_bitlens, lcodes_huffman_codes
                    , dcodes_huffman_bitlens, dcodes_huffman_codes =
                        GetBlockDynamicHuffmanHeader(lcodes_counts, dcodes_counts)
                    dynamic_block_bitlen = GetDynamicHuffmanBlockSize(
                        lcodes, dcodes, HCLEN, rle_codes_huffman_bitlens
                        , rle_deflate_codes, lcodes_huffman_bitlens
                        , dcodes_huffman_bitlens)
                    fixed_block_bitlen = GetFixedHuffmanBlockSize(lcodes, dcodes)
                end

                store_block_bitlen = GetStoreBlockSize(block_start, block_end
                    , total_bitlen)

                local min_bitlen = store_block_bitlen
                min_bitlen = (fixed_block_bitlen and fixed_block_bitlen < min_bitlen)
                    and fixed_block_bitlen or min_bitlen
                min_bitlen = (dynamic_block_bitlen
                    and dynamic_block_bitlen < min_bitlen)
                    and dynamic_block_bitlen or min_bitlen

                if level == 0 or (strategy ~= "fixed" and strategy ~= "dynamic" and
                    store_block_bitlen == min_bitlen) then
                    CompressStoreBlock(WriteBits, WriteString, is_last_block
                        , str, block_start, block_end, total_bitlen)
                    total_bitlen = total_bitlen + store_block_bitlen
                elseif strategy ~= "dynamic" and (
                    strategy == "fixed" or fixed_block_bitlen == min_bitlen) then
                    CompressFixedHuffmanBlock(WriteBits, is_last_block,
                        lcodes, lextra_bits, dcodes, dextra_bits)
                    total_bitlen = total_bitlen + fixed_block_bitlen
                elseif strategy == "dynamic" or dynamic_block_bitlen == min_bitlen then
                    CompressDynamicHuffmanBlock(WriteBits, is_last_block, lcodes
                        , lextra_bits, dcodes, dextra_bits, HLIT, HDIST, HCLEN
                        , rle_codes_huffman_bitlens, rle_codes_huffman_codes
                        , rle_deflate_codes, rle_extra_bits
                        , lcodes_huffman_bitlens, lcodes_huffman_codes
                        , dcodes_huffman_bitlens, dcodes_huffman_codes)
                    total_bitlen = total_bitlen + dynamic_block_bitlen
                end

                if is_last_block then
                    bitlen_written = FlushWriter(_FLUSH_MODE_NO_FLUSH)
                else
                    bitlen_written = FlushWriter(_FLUSH_MODE_MEMORY_CLEANUP)
                end

                assert(bitlen_written == total_bitlen)

                -- Memory clean up, so memory consumption does not always grow linearly
                -- , even if input string is > 64K.
                -- Not a very efficient operation, but this operation won't happen
                -- when the input data size is less than 64K.
                if not is_last_block then
                    local j
                    if dictionary and block_start == 1 then
                        j = 0
                        while (string_table[j]) do
                            string_table[j] = nil
                            j = j - 1
                        end
                    end
                    dictionary = nil
                    j = 1
                    for i = block_end-32767, block_end do
                        string_table[j] = string_table[i-offset]
                        j = j + 1
                    end

                    for k, t in pairs(hash_tables) do
                        local tSize = #t
                        if tSize > 0 and block_end+1 - t[1] > 32768 then
                            if tSize == 1 then
                                hash_tables[k] = nil
                            else
                                local new = {}
                                local newSize = 0
                                for i = 2, tSize do
                                    j = t[i]
                                    if block_end+1 - j <= 32768 then
                                        newSize = newSize + 1
                                        new[newSize] = j
                                    end
                                end
                                hash_tables[k] = new
                            end
                        end
                    end
                end
            end
        end

        --- The description to compression configuration table. <br>
        -- Any field can be nil to use its default. <br>
        -- Table with keys other than those below is an invalid table.
        -- @class table
        -- @name compression_configs
        -- @field level The compression level ranged from 0 to 9. 0 is no compression.
        -- 9 is the slowest but best compression. Use nil for default level.
        -- @field strategy The compression strategy. "fixed" to only use fixed deflate
        -- compression block. "dynamic" to only use dynamic block. "huffman_only" to
        -- do no LZ77 compression. Only do huffman compression.


        -- @see LibDeflate:CompressDeflate(str, configs)
        -- @see LibDeflate:CompressDeflateWithDict(str, dictionary, configs)
        local function CompressDeflateInternal(str, dictionary, configs)
            local WriteBits, WriteString, FlushWriter = CreateWriter()
            Deflate(configs, WriteBits, WriteString, FlushWriter, str, dictionary)
            local total_bitlen, result = FlushWriter(_FLUSH_MODE_OUTPUT)
            local padding_bitlen = (8-total_bitlen%8)%8
            return result, padding_bitlen
        end

        -- @see LibDeflate:CompressZlib
        -- @see LibDeflate:CompressZlibWithDict
        local function CompressZlibInternal(str, dictionary, configs)
            local WriteBits, WriteString, FlushWriter = CreateWriter()

            local CM = 8 -- Compression method
            local CINFO = 7 --Window Size = 32K
            local CMF = CINFO*16+CM
            WriteBits(CMF, 8)

            local FDIST = dictionary and 1 or 0
            local FLEVEL = 2 -- Default compression
            local FLG = FLEVEL*64+FDIST*32
            local FCHECK = (31-(CMF*256+FLG)%31)
            -- The FCHECK value must be such that CMF and FLG,
            -- when viewed as a 16-bit unsigned integer stored
            -- in MSB order (CMF*256 + FLG), is a multiple of 31.
            FLG = FLG + FCHECK
            WriteBits(FLG, 8)

            if FDIST == 1 then
                local adler32 = dictionary.adler32
                local byte0 = adler32 % 256
                adler32 = (adler32 - byte0) / 256
                local byte1 = adler32 % 256
                adler32 = (adler32 - byte1) / 256
                local byte2 = adler32 % 256
                adler32 = (adler32 - byte2) / 256
                local byte3 = adler32 % 256
                WriteBits(byte3, 8)
                WriteBits(byte2, 8)
                WriteBits(byte1, 8)
                WriteBits(byte0, 8)
            end

            Deflate(configs, WriteBits, WriteString, FlushWriter, str, dictionary)
            FlushWriter(_FLUSH_MODE_BYTE_BOUNDARY)

            local adler32 = LibDeflate:Adler32(str)

            -- Most significant byte first
            local byte3 = adler32%256
            adler32 = (adler32 - byte3) / 256
            local byte2 = adler32%256
            adler32 = (adler32 - byte2) / 256
            local byte1 = adler32%256
            adler32 = (adler32 - byte1) / 256
            local byte0 = adler32%256

            WriteBits(byte0, 8)
            WriteBits(byte1, 8)
            WriteBits(byte2, 8)
            WriteBits(byte3, 8)
            local total_bitlen, result = FlushWriter(_FLUSH_MODE_OUTPUT)
            local padding_bitlen = (8-total_bitlen%8)%8
            return result, padding_bitlen
        end

        --- Compress using the raw deflate format.
        -- @param str [string] The data to be compressed.
        -- @param configs [table/nil] The configuration table to control the compression
        -- . If nil, use the default configuration.
        -- @return [string] The compressed data.
        -- @return [integer] The number of bits padded at the end of output.
        -- 0 <= bits < 8  <br>
        -- This means the most significant "bits" of the last byte of the returned
        -- compressed data are padding bits and they don't affect decompression.
        -- You don't need to use this value unless you want to do some postprocessing
        -- to the compressed data.
        -- @see compression_configs
        -- @see LibDeflate:DecompressDeflate
        function LibDeflate:CompressDeflate(str, configs)
            local arg_valid, arg_err = IsValidArguments(str, false, nil, true, configs)
            if not arg_valid then
                error(("Usage: LibDeflate:CompressDeflate(str, configs): "
                    ..arg_err), 2)
            end
            return CompressDeflateInternal(str, nil, configs)
        end

        --- Compress using the raw deflate format with a preset dictionary.
        -- @param str [string] The data to be compressed.
        -- @param dictionary [table] The preset dictionary produced by
        -- LibDeflate:CreateDictionary
        -- @param configs [table/nil] The configuration table to control the compression
        -- . If nil, use the default configuration.
        -- @return [string] The compressed data.
        -- @return [integer] The number of bits padded at the end of output.
        -- 0 <= bits < 8  <br>
        -- This means the most significant "bits" of the last byte of the returned
        -- compressed data are padding bits and they don't affect decompression.
        -- You don't need to use this value unless you want to do some postprocessing
        -- to the compressed data.
        -- @see compression_configs
        -- @see LibDeflate:CreateDictionary
        -- @see LibDeflate:DecompressDeflateWithDict
        function LibDeflate:CompressDeflateWithDict(str, dictionary, configs)
            local arg_valid, arg_err = IsValidArguments(str, true, dictionary
                , true, configs)
            if not arg_valid then
                error(("Usage: LibDeflate:CompressDeflateWithDict"
                    .."(str, dictionary, configs): "
                    ..arg_err), 2)
            end
            return CompressDeflateInternal(str, dictionary, configs)
        end

        --- Compress using the zlib format.
        -- @param str [string] the data to be compressed.
        -- @param configs [table/nil] The configuration table to control the compression
        -- . If nil, use the default configuration.
        -- @return [string] The compressed data.
        -- @return [integer] The number of bits padded at the end of output.
        -- Should always be 0.
        -- Zlib formatted compressed data never has padding bits at the end.
        -- @see compression_configs
        -- @see LibDeflate:DecompressZlib
        function LibDeflate:CompressZlib(str, configs)
            local arg_valid, arg_err = IsValidArguments(str, false, nil, true, configs)
            if not arg_valid then
                error(("Usage: LibDeflate:CompressZlib(str, configs): "
                    ..arg_err), 2)
            end
            return CompressZlibInternal(str, nil, configs)
        end

        --- Compress using the zlib format with a preset dictionary.
        -- @param str [string] the data to be compressed.
        -- @param dictionary [table] A preset dictionary produced
        -- by LibDeflate:CreateDictionary()
        -- @param configs [table/nil] The configuration table to control the compression
        -- . If nil, use the default configuration.
        -- @return [string] The compressed data.
        -- @return [integer] The number of bits padded at the end of output.
        -- Should always be 0.
        -- Zlib formatted compressed data never has padding bits at the end.
        -- @see compression_configs
        -- @see LibDeflate:CreateDictionary
        -- @see LibDeflate:DecompressZlibWithDict
        function LibDeflate:CompressZlibWithDict(str, dictionary, configs)
            local arg_valid, arg_err = IsValidArguments(str, true, dictionary
                , true, configs)
            if not arg_valid then
                error(("Usage: LibDeflate:CompressZlibWithDict"
                    .."(str, dictionary, configs): "
                    ..arg_err), 2)
            end
            return CompressZlibInternal(str, dictionary, configs)
        end

        --[[ --------------------------------------------------------------------------
            Decompress code
        --]] --------------------------------------------------------------------------

        --[[
            Create a reader to easily reader stuffs as the unit of bits.
            Return values:
            1. ReadBits(bitlen)
            2. ReadBytes(bytelen, buffer, buffer_size)
            3. Decode(huffman_bitlen_count, huffman_symbol, min_bitlen)
            4. ReaderBitlenLeft()
            5. SkipToByteBoundary()
        --]]
        local function CreateReader(input_string)
            local input = input_string
            local input_strlen = #input_string
            local input_next_byte_pos = 1
            local cache_bitlen = 0
            local cache = 0

            -- Read some bits.
            -- To improve speed, this function does not
            -- check if the input has been exhausted.
            -- Use ReaderBitlenLeft() < 0 to check it.
            -- @param bitlen the number of bits to read
            -- @return the data is read.
            local function ReadBits(bitlen)
                local rshift_mask = _pow2[bitlen]
                local code
                if bitlen <= cache_bitlen then
                    code = cache % rshift_mask
                    cache = (cache - code) / rshift_mask
                    cache_bitlen = cache_bitlen - bitlen
                else -- Whether input has been exhausted is not checked.
                    local lshift_mask = _pow2[cache_bitlen]
                    local byte1, byte2, byte3, byte4 = string_byte(input
                        , input_next_byte_pos, input_next_byte_pos+3)
                    -- This requires lua number to be at least double ()
                    cache = cache + ((byte1 or 0)+(byte2 or 0)*256
                        + (byte3 or 0)*65536+(byte4 or 0)*16777216)*lshift_mask
                    input_next_byte_pos = input_next_byte_pos + 4
                    cache_bitlen = cache_bitlen + 32 - bitlen
                    code = cache % rshift_mask
                    cache = (cache - code) / rshift_mask
                end
                return code
            end

            -- Read some bytes from the reader.
            -- Assume reader is on the byte boundary.
            -- @param bytelen The number of bytes to be read.
            -- @param buffer The byte read will be stored into this buffer.
            -- @param buffer_size The buffer will be modified starting from
            --	buffer[buffer_size+1], ending at buffer[buffer_size+bytelen-1]
            -- @return the new buffer_size
            local function ReadBytes(bytelen, buffer, buffer_size)
                assert(cache_bitlen % 8 == 0)

                local byte_from_cache = (cache_bitlen/8 < bytelen)
                    and (cache_bitlen/8) or bytelen
                for _=1, byte_from_cache do
                    local byte = cache % 256
                    buffer_size = buffer_size + 1
                    buffer[buffer_size] = string_char(byte)
                    cache = (cache - byte) / 256
                end
                cache_bitlen = cache_bitlen - byte_from_cache*8
                bytelen = bytelen - byte_from_cache
                if (input_strlen - input_next_byte_pos - bytelen + 1) * 8
                    + cache_bitlen < 0 then
                    return -1 -- out of input
                end
                for i=input_next_byte_pos, input_next_byte_pos+bytelen-1 do
                    buffer_size = buffer_size + 1
                    buffer[buffer_size] = string_sub(input, i, i)
                end

                input_next_byte_pos = input_next_byte_pos + bytelen
                return buffer_size
            end

            -- Decode huffman code
            -- To improve speed, this function does not check
            -- if the input has been exhausted.
            -- Use ReaderBitlenLeft() < 0 to check it.
            -- Credits for Mark Adler. This code is from puff:Decode()
            -- @see puff:Decode(...)
            -- @param huffman_bitlen_count
            -- @param huffman_symbol
            -- @param min_bitlen The minimum huffman bit length of all symbols
            -- @return The decoded deflate code.
            --	Negative value is returned if decoding fails.
            local function Decode(huffman_bitlen_counts, huffman_symbols, min_bitlen)
                local code = 0
                local first = 0
                local index = 0
                local count
                if min_bitlen > 0 then
                    if cache_bitlen < 15 and input then
                        local lshift_mask = _pow2[cache_bitlen]
                        local byte1, byte2, byte3, byte4 =
                            string_byte(input, input_next_byte_pos
                                , input_next_byte_pos+3)
                        -- This requires lua number to be at least double ()
                        cache = cache + ((byte1 or 0)+(byte2 or 0)*256
                            +(byte3 or 0)*65536+(byte4 or 0)*16777216)*lshift_mask
                        input_next_byte_pos = input_next_byte_pos + 4
                        cache_bitlen = cache_bitlen + 32
                    end

                    local rshift_mask = _pow2[min_bitlen]
                    cache_bitlen = cache_bitlen - min_bitlen
                    code = cache % rshift_mask
                    cache = (cache - code) / rshift_mask
                    -- Reverse the bits
                    code = _reverse_bits_tbl[min_bitlen][code]

                    count = huffman_bitlen_counts[min_bitlen]
                    if code < count then
                        return huffman_symbols[code]
                    end
                    index = count
                    first = count * 2
                    code = code * 2
                end

                for bitlen = min_bitlen+1, 15 do
                    local bit
                    bit = cache % 2
                    cache = (cache - bit) / 2
                    cache_bitlen = cache_bitlen - 1

                    code = (bit==1) and (code + 1 - code % 2) or code
                    count = huffman_bitlen_counts[bitlen] or 0
                    local diff = code - first
                    if diff < count then
                        return huffman_symbols[index + diff]
                    end
                    index = index + count
                    first = first + count
                    first = first * 2
                    code = code * 2
                end
                -- invalid literal/length or distance code
                -- in fixed or dynamic block (run out of code)
                return -10
            end

            local function ReaderBitlenLeft()
                return (input_strlen - input_next_byte_pos + 1) * 8 + cache_bitlen
            end

            local function SkipToByteBoundary()
                local skipped_bitlen = cache_bitlen%8
                local rshift_mask = _pow2[skipped_bitlen]
                cache_bitlen = cache_bitlen - skipped_bitlen
                cache = (cache - cache % rshift_mask) / rshift_mask
            end

            return ReadBits, ReadBytes, Decode, ReaderBitlenLeft, SkipToByteBoundary
        end

        -- Create a deflate state, so I can pass in less arguments to functions.
        -- @param str the whole string to be decompressed.
        -- @param dictionary The preset dictionary. nil if not provided.
        --		This dictionary should be produced by LibDeflate:CreateDictionary(str)
        -- @return The decomrpess state.
        local function CreateDecompressState(str, dictionary)
            local ReadBits, ReadBytes, Decode, ReaderBitlenLeft
            , SkipToByteBoundary = CreateReader(str)
            local state =
                {
                    ReadBits = ReadBits,
                    ReadBytes = ReadBytes,
                    Decode = Decode,
                    ReaderBitlenLeft = ReaderBitlenLeft,
                    SkipToByteBoundary = SkipToByteBoundary,
                    buffer_size = 0,
                    buffer = {},
                    result_buffer = {},
                    dictionary = dictionary,
                }
            return state
        end

        -- Get the stuffs needed to decode huffman codes
        -- @see puff.c:construct(...)
        -- @param huffman_bitlen The huffman bit length of the huffman codes.
        -- @param max_symbol The maximum symbol
        -- @param max_bitlen The min huffman bit length of all codes
        -- @return zero or positive for success, negative for failure.
        -- @return The count of each huffman bit length.
        -- @return A table to convert huffman codes to deflate codes.
        -- @return The minimum huffman bit length.
        local function GetHuffmanForDecode(huffman_bitlens, max_symbol, max_bitlen)
            local huffman_bitlen_counts = {}
            local min_bitlen = max_bitlen
            for symbol = 0, max_symbol do
                local bitlen = huffman_bitlens[symbol] or 0
                min_bitlen = (bitlen > 0 and bitlen < min_bitlen)
                    and bitlen or min_bitlen
                huffman_bitlen_counts[bitlen] = (huffman_bitlen_counts[bitlen] or 0)+1
            end

            if huffman_bitlen_counts[0] == max_symbol+1 then -- No Codes
                return 0, huffman_bitlen_counts, {}, 0 -- Complete, but decode will fail
            end

            local left = 1
            for len = 1, max_bitlen do
                left = left * 2
                left = left - (huffman_bitlen_counts[len] or 0)
                if left < 0 then
                    return left -- Over-subscribed, return negative
                end
            end

            -- Generate offsets info symbol table for each length for sorting
            local offsets = {}
            offsets[1] = 0
            for len = 1, max_bitlen-1 do
                offsets[len + 1] = offsets[len] + (huffman_bitlen_counts[len] or 0)
            end

            local huffman_symbols = {}
            for symbol = 0, max_symbol do
                local bitlen = huffman_bitlens[symbol] or 0
                if bitlen ~= 0 then
                    local offset = offsets[bitlen]
                    huffman_symbols[offset] = symbol
                    offsets[bitlen] = offsets[bitlen] + 1
                end
            end

            -- Return zero for complete set, positive for incomplete set.
            return left, huffman_bitlen_counts, huffman_symbols, min_bitlen
        end

        -- Decode a fixed or dynamic huffman blocks, excluding last block identifier
        -- and block type identifer.
        -- @see puff.c:codes()
        -- @param state decompression state that will be modified by this function.
        --	@see CreateDecompressState
        -- @param ... Read the source code
        -- @return 0 on success, other value on failure.
        local function DecodeUntilEndOfBlock(state, lcodes_huffman_bitlens
            , lcodes_huffman_symbols, lcodes_huffman_min_bitlen
            , dcodes_huffman_bitlens, dcodes_huffman_symbols
            , dcodes_huffman_min_bitlen)
            local buffer, buffer_size, ReadBits, Decode, ReaderBitlenLeft
            , result_buffer =
                state.buffer, state.buffer_size, state.ReadBits, state.Decode
            , state.ReaderBitlenLeft, state.result_buffer
            local dictionary = state.dictionary
            local dict_string_table
            local dict_strlen

            local buffer_end = 1
            if dictionary and not buffer[0] then
                -- If there is a dictionary, copy the last 258 bytes into
                -- the string_table to make the copy in the main loop quicker.
                -- This is done only once per decompression.
                dict_string_table = dictionary.string_table
                dict_strlen = dictionary.strlen
                buffer_end = -dict_strlen + 1
                for i=0, (-dict_strlen+1)<-257 and -257 or (-dict_strlen+1), -1 do
                    buffer[i] = _byte_to_char[dict_string_table[dict_strlen+i]]
                end
            end

            repeat
                local symbol = Decode(lcodes_huffman_bitlens
                    , lcodes_huffman_symbols, lcodes_huffman_min_bitlen)
                if symbol < 0 or symbol > 285 then
                    -- invalid literal/length or distance code in fixed or dynamic block
                    return -10
                elseif symbol < 256 then -- Literal
                    buffer_size = buffer_size + 1
                    buffer[buffer_size] = _byte_to_char[symbol]
                elseif symbol > 256 then -- Length code
                    symbol = symbol - 256
                    local bitlen = _literal_deflate_code_to_base_len[symbol]
                    bitlen = (symbol >= 8)
                        and (bitlen
                            + ReadBits(_literal_deflate_code_to_extra_bitlen[symbol]))
                        or bitlen
                    symbol = Decode(dcodes_huffman_bitlens, dcodes_huffman_symbols
                        , dcodes_huffman_min_bitlen)
                    if symbol < 0 or symbol > 29 then
                        -- invalid literal/length or distance code in fixed or dynamic block
                        return -10
                    end
                    local dist = _dist_deflate_code_to_base_dist[symbol]
                    dist = (dist > 4) and (dist
                        + ReadBits(_dist_deflate_code_to_extra_bitlen[symbol])) or dist

                    local char_buffer_index = buffer_size-dist+1
                    if char_buffer_index < buffer_end then
                        -- distance is too far back in fixed or dynamic block
                        return -11
                    end
                    if char_buffer_index >= -257 then
                        for _=1, bitlen do
                            buffer_size = buffer_size + 1
                            buffer[buffer_size] = buffer[char_buffer_index]
                            char_buffer_index = char_buffer_index + 1
                        end
                    else
                        char_buffer_index = dict_strlen + char_buffer_index
                        for _=1, bitlen do
                            buffer_size = buffer_size + 1
                            buffer[buffer_size] =
                                _byte_to_char[dict_string_table[char_buffer_index]]
                            char_buffer_index = char_buffer_index + 1
                        end
                    end
                end

                if ReaderBitlenLeft() < 0 then
                    return 2 -- available inflate data did not terminate
                end

                if buffer_size >= 65536 then
                    result_buffer[#result_buffer+1] =
                        table_concat(buffer, "", 1, 32768)
                    for i=32769, buffer_size do
                        buffer[i-32768] = buffer[i]
                    end
                    buffer_size = buffer_size - 32768
                    buffer[buffer_size+1] = nil
                    -- NOTE: buffer[32769..end] and buffer[-257..0] are not cleared.
                    -- This is why "buffer_size" variable is needed.
                end
            until symbol == 256

            state.buffer_size = buffer_size

            return 0
        end

        -- Decompress a store block
        -- @param state decompression state that will be modified by this function.
        -- @return 0 if succeeds, other value if fails.
        local function DecompressStoreBlock(state)
            local buffer, buffer_size, ReadBits, ReadBytes, ReaderBitlenLeft
            , SkipToByteBoundary, result_buffer =
                state.buffer, state.buffer_size, state.ReadBits, state.ReadBytes
            , state.ReaderBitlenLeft, state.SkipToByteBoundary, state.result_buffer

            SkipToByteBoundary()
            local bytelen = ReadBits(16)
            if ReaderBitlenLeft() < 0 then
                return 2 -- available inflate data did not terminate
            end
            local bytelenComp = ReadBits(16)
            if ReaderBitlenLeft() < 0 then
                return 2 -- available inflate data did not terminate
            end

            if bytelen % 256 + bytelenComp % 256 ~= 255 then
                return -2 -- Not one's complement
            end
            if (bytelen-bytelen % 256)/256
                + (bytelenComp-bytelenComp % 256)/256 ~= 255 then
                return -2 -- Not one's complement
            end

            -- Note that ReadBytes will skip to the next byte boundary first.
            buffer_size = ReadBytes(bytelen, buffer, buffer_size)
            if buffer_size < 0 then
                return 2 -- available inflate data did not terminate
            end

            -- memory clean up when there are enough bytes in the buffer.
            if buffer_size >= 65536 then
                result_buffer[#result_buffer+1] = table_concat(buffer, "", 1, 32768)
                for i=32769, buffer_size do
                    buffer[i-32768] = buffer[i]
                end
                buffer_size = buffer_size - 32768
                buffer[buffer_size+1] = nil
            end
            state.buffer_size = buffer_size
            return 0
        end

        -- Decompress a fixed block
        -- @param state decompression state that will be modified by this function.
        -- @return 0 if succeeds other value if fails.
        local function DecompressFixBlock(state)
            return DecodeUntilEndOfBlock(state
                , _fix_block_literal_huffman_bitlen_count
                , _fix_block_literal_huffman_to_deflate_code, 7
                , _fix_block_dist_huffman_bitlen_count
                , _fix_block_dist_huffman_to_deflate_code, 5)
        end

        -- Decompress a dynamic block
        -- @param state decompression state that will be modified by this function.
        -- @return 0 if success, other value if fails.
        local function DecompressDynamicBlock(state)
            local ReadBits, Decode = state.ReadBits, state.Decode
            local nlen = ReadBits(5) + 257
            local ndist = ReadBits(5) + 1
            local ncode = ReadBits(4) + 4
            if nlen > 286 or ndist > 30 then
                -- dynamic block code description: too many length or distance codes
                return -3
            end

            local rle_codes_huffman_bitlens = {}

            for i = 1, ncode do
                rle_codes_huffman_bitlens[_rle_codes_huffman_bitlen_order[i]] =
                    ReadBits(3)
            end

            local rle_codes_err, rle_codes_huffman_bitlen_counts,
            rle_codes_huffman_symbols, rle_codes_huffman_min_bitlen =
                GetHuffmanForDecode(rle_codes_huffman_bitlens, 18, 7)
            if rle_codes_err ~= 0 then -- Require complete code set here
                -- dynamic block code description: code lengths codes incomplete
                return -4
            end

            local lcodes_huffman_bitlens = {}
            local dcodes_huffman_bitlens = {}
            -- Read length/literal and distance code length tables
            local index = 0
            while index < nlen + ndist do
                local symbol -- Decoded value
                local bitlen -- Last length to repeat

                symbol = Decode(rle_codes_huffman_bitlen_counts
                    , rle_codes_huffman_symbols, rle_codes_huffman_min_bitlen)

                if symbol < 0 then
                    return symbol -- Invalid symbol
                elseif symbol < 16 then
                    if index < nlen then
                        lcodes_huffman_bitlens[index] = symbol
                    else
                        dcodes_huffman_bitlens[index-nlen] = symbol
                    end
                    index = index + 1
                else
                    bitlen = 0
                    if symbol == 16 then
                        if index == 0 then
                            -- dynamic block code description: repeat lengths
                            -- with no first length
                            return -5
                        end
                        if index-1 < nlen then
                            bitlen = lcodes_huffman_bitlens[index-1]
                        else
                            bitlen = dcodes_huffman_bitlens[index-nlen-1]
                        end
                        symbol = 3 + ReadBits(2)
                    elseif symbol == 17 then -- Repeat zero 3..10 times
                        symbol = 3 + ReadBits(3)
                    else -- == 18, repeat zero 11.138 times
                        symbol = 11 + ReadBits(7)
                    end
                    if index + symbol > nlen + ndist then
                        -- dynamic block code description:
                        -- repeat more than specified lengths
                        return -6
                    end
                    while symbol > 0 do -- Repeat last or zero symbol times
                        symbol = symbol - 1
                        if index < nlen then
                            lcodes_huffman_bitlens[index] = bitlen
                        else
                            dcodes_huffman_bitlens[index-nlen] = bitlen
                        end
                        index = index + 1
                    end
                end
            end

            if (lcodes_huffman_bitlens[256] or 0) == 0 then
                -- dynamic block code description: missing end-of-block code
                return -9
            end

            local lcodes_err, lcodes_huffman_bitlen_counts
            , lcodes_huffman_symbols, lcodes_huffman_min_bitlen =
                GetHuffmanForDecode(lcodes_huffman_bitlens, nlen-1, 15)
            --dynamic block code description: invalid literal/length code lengths,
            -- Incomplete code ok only for single length 1 code
            if (lcodes_err ~=0 and (lcodes_err < 0
                or nlen ~= (lcodes_huffman_bitlen_counts[0] or 0)
                +(lcodes_huffman_bitlen_counts[1] or 0))) then
                return -7
            end

            local dcodes_err, dcodes_huffman_bitlen_counts
            , dcodes_huffman_symbols, dcodes_huffman_min_bitlen =
                GetHuffmanForDecode(dcodes_huffman_bitlens, ndist-1, 15)
            -- dynamic block code description: invalid distance code lengths,
            -- Incomplete code ok only for single length 1 code
            if (dcodes_err ~=0 and (dcodes_err < 0
                or ndist ~= (dcodes_huffman_bitlen_counts[0] or 0)
                + (dcodes_huffman_bitlen_counts[1] or 0))) then
                return -8
            end

            -- Build buffman table for literal/length codes
            return DecodeUntilEndOfBlock(state, lcodes_huffman_bitlen_counts
                , lcodes_huffman_symbols, lcodes_huffman_min_bitlen
                , dcodes_huffman_bitlen_counts, dcodes_huffman_symbols
                , dcodes_huffman_min_bitlen)
        end

        -- Decompress a deflate stream
        -- @param state: a decompression state
        -- @return the decompressed string if succeeds. nil if fails.
        local function Inflate(state)
            local ReadBits = state.ReadBits

            local is_last_block
            while not is_last_block do
                is_last_block = (ReadBits(1) == 1)
                local block_type = ReadBits(2)
                local status
                if block_type == 0 then
                    status = DecompressStoreBlock(state)
                elseif block_type == 1 then
                    status = DecompressFixBlock(state)
                elseif block_type == 2 then
                    status = DecompressDynamicBlock(state)
                else
                    return nil, -1 -- invalid block type (type == 3)
                end
                if status ~= 0 then
                    return nil, status
                end
            end

            state.result_buffer[#state.result_buffer+1] =
                table_concat(state.buffer, "", 1, state.buffer_size)
            local result = table_concat(state.result_buffer)
            return result
        end

        -- @see LibDeflate:DecompressDeflate(str)
        -- @see LibDeflate:DecompressDeflateWithDict(str, dictionary)
        local function DecompressDeflateInternal(str, dictionary)
            local state = CreateDecompressState(str, dictionary)
            local result, status = Inflate(state)
            if not result then
                return nil, status
            end

            local bitlen_left = state.ReaderBitlenLeft()
            local bytelen_left = (bitlen_left - bitlen_left % 8) / 8
            return result, bytelen_left
        end

        -- @see LibDeflate:DecompressZlib(str)
        -- @see LibDeflate:DecompressZlibWithDict(str)
        local function DecompressZlibInternal(str, dictionary)
            local state = CreateDecompressState(str, dictionary)
            local ReadBits = state.ReadBits

            local CMF = ReadBits(8)
            if state.ReaderBitlenLeft() < 0 then
                return nil, 2 -- available inflate data did not terminate
            end
            local CM = CMF % 16
            local CINFO = (CMF - CM) / 16
            if CM ~= 8 then
                return nil, -12 -- invalid compression method
            end
            if CINFO > 7 then
                return nil, -13 -- invalid window size
            end

            local FLG = ReadBits(8)
            if state.ReaderBitlenLeft() < 0 then
                return nil, 2 -- available inflate data did not terminate
            end
            if (CMF*256+FLG)%31 ~= 0 then
                return nil, -14 -- invalid header checksum
            end

            local FDIST = ((FLG-FLG%32)/32 % 2)
            local FLEVEL = ((FLG-FLG%64)/64 % 4) -- luacheck: ignore FLEVEL

            if FDIST == 1 then
                if not dictionary then
                    return nil, -16 -- need dictonary, but dictionary is not provided.
                end
                local byte3 = ReadBits(8)
                local byte2 = ReadBits(8)
                local byte1 = ReadBits(8)
                local byte0 = ReadBits(8)
                local actual_adler32 = byte3*16777216+byte2*65536+byte1*256+byte0
                if state.ReaderBitlenLeft() < 0 then
                    return nil, 2 -- available inflate data did not terminate
                end
                if not IsEqualAdler32(actual_adler32, dictionary.adler32) then
                    return nil, -17 -- dictionary adler32 does not match
                end
            end
            local result, status = Inflate(state)
            if not result then
                return nil, status
            end
            state.SkipToByteBoundary()

            local adler_byte0 = ReadBits(8)
            local adler_byte1 = ReadBits(8)
            local adler_byte2 = ReadBits(8)
            local adler_byte3 = ReadBits(8)
            if state.ReaderBitlenLeft() < 0 then
                return nil, 2 -- available inflate data did not terminate
            end

            local adler32_expected = adler_byte0*16777216
                + adler_byte1*65536 + adler_byte2*256 + adler_byte3
            local adler32_actual = LibDeflate:Adler32(result)
            if not IsEqualAdler32(adler32_expected, adler32_actual) then
                return nil, -15 -- Adler32 checksum does not match
            end

            local bitlen_left = state.ReaderBitlenLeft()
            local bytelen_left = (bitlen_left - bitlen_left % 8) / 8
            return result, bytelen_left
        end

        --- Decompress a raw deflate compressed data.
        -- @param str [string] The data to be decompressed.
        -- @return [string/nil] If the decompression succeeds, return the decompressed
        -- data. If the decompression fails, return nil. You should check if this return
        -- value is non-nil to know if the decompression succeeds.
        -- @return [integer] If the decompression succeeds, return the number of
        -- unprocessed bytes in the input compressed data. This return value is a
        -- positive integer if the input data is a valid compressed data appended by an
        -- arbitary non-empty string. This return value is 0 if the input data does not
        -- contain any extra bytes.<br>
        -- If the decompression fails (The first return value of this function is nil),
        -- this return value is undefined.
        -- @see LibDeflate:CompressDeflate
        function LibDeflate:DecompressDeflate(str)
            local arg_valid, arg_err = IsValidArguments(str)
            if not arg_valid then
                error(("Usage: LibDeflate:DecompressDeflate(str): "
                    ..arg_err), 2)
            end
            return DecompressDeflateInternal(str)
        end

        --- Decompress a raw deflate compressed data with a preset dictionary.
        -- @param str [string] The data to be decompressed.
        -- @param dictionary [table] The preset dictionary used by
        -- LibDeflate:CompressDeflateWithDict when the compressed data is produced.
        -- Decompression and compression must use the same dictionary.
        -- Otherwise wrong decompressed data could be produced without generating any
        -- error.
        -- @return [string/nil] If the decompression succeeds, return the decompressed
        -- data. If the decompression fails, return nil. You should check if this return
        -- value is non-nil to know if the decompression succeeds.
        -- @return [integer] If the decompression succeeds, return the number of
        -- unprocessed bytes in the input compressed data. This return value is a
        -- positive integer if the input data is a valid compressed data appended by an
        -- arbitary non-empty string. This return value is 0 if the input data does not
        -- contain any extra bytes.<br>
        -- If the decompression fails (The first return value of this function is nil),
        -- this return value is undefined.
        -- @see LibDeflate:CompressDeflateWithDict
        function LibDeflate:DecompressDeflateWithDict(str, dictionary)
            local arg_valid, arg_err = IsValidArguments(str, true, dictionary)
            if not arg_valid then
                error(("Usage: LibDeflate:DecompressDeflateWithDict(str, dictionary): "
                    ..arg_err), 2)
            end
            return DecompressDeflateInternal(str, dictionary)
        end

        --- Decompress a zlib compressed data.
        -- @param str [string] The data to be decompressed
        -- @return [string/nil] If the decompression succeeds, return the decompressed
        -- data. If the decompression fails, return nil. You should check if this return
        -- value is non-nil to know if the decompression succeeds.
        -- @return [integer] If the decompression succeeds, return the number of
        -- unprocessed bytes in the input compressed data. This return value is a
        -- positive integer if the input data is a valid compressed data appended by an
        -- arbitary non-empty string. This return value is 0 if the input data does not
        -- contain any extra bytes.<br>
        -- If the decompression fails (The first return value of this function is nil),
        -- this return value is undefined.
        -- @see LibDeflate:CompressZlib
        function LibDeflate:DecompressZlib(str)
            local arg_valid, arg_err = IsValidArguments(str)
            if not arg_valid then
                error(("Usage: LibDeflate:DecompressZlib(str): "
                    ..arg_err), 2)
            end
            return DecompressZlibInternal(str)
        end

        --- Decompress a zlib compressed data with a preset dictionary.
        -- @param str [string] The data to be decompressed
        -- @param dictionary [table] The preset dictionary used by
        -- LibDeflate:CompressDeflateWithDict when the compressed data is produced.
        -- Decompression and compression must use the same dictionary.
        -- Otherwise wrong decompressed data could be produced without generating any
        -- error.
        -- @return [string/nil] If the decompression succeeds, return the decompressed
        -- data. If the decompression fails, return nil. You should check if this return
        -- value is non-nil to know if the decompression succeeds.
        -- @return [integer] If the decompression succeeds, return the number of
        -- unprocessed bytes in the input compressed data. This return value is a
        -- positive integer if the input data is a valid compressed data appended by an
        -- arbitary non-empty string. This return value is 0 if the input data does not
        -- contain any extra bytes.<br>
        -- If the decompression fails (The first return value of this function is nil),
        -- this return value is undefined.
        -- @see LibDeflate:CompressZlibWithDict
        function LibDeflate:DecompressZlibWithDict(str, dictionary)
            local arg_valid, arg_err = IsValidArguments(str, true, dictionary)
            if not arg_valid then
                error(("Usage: LibDeflate:DecompressZlibWithDict(str, dictionary): "
                    ..arg_err), 2)
            end
            return DecompressZlibInternal(str, dictionary)
        end

        -- Calculate the huffman code of fixed block
        do
            _fix_block_literal_huffman_bitlen = {}
            for sym=0, 143 do
                _fix_block_literal_huffman_bitlen[sym] = 8
            end
            for sym=144, 255 do
                _fix_block_literal_huffman_bitlen[sym] = 9
            end
            for sym=256, 279 do
                _fix_block_literal_huffman_bitlen[sym] = 7
            end
            for sym=280, 287 do
                _fix_block_literal_huffman_bitlen[sym] = 8
            end

            _fix_block_dist_huffman_bitlen = {}
            for dist=0, 31 do
                _fix_block_dist_huffman_bitlen[dist] = 5
            end
            local status
            status, _fix_block_literal_huffman_bitlen_count
            , _fix_block_literal_huffman_to_deflate_code =
                GetHuffmanForDecode(_fix_block_literal_huffman_bitlen, 287, 9)
            assert(status == 0)
            status, _fix_block_dist_huffman_bitlen_count,
            _fix_block_dist_huffman_to_deflate_code =
                GetHuffmanForDecode(_fix_block_dist_huffman_bitlen, 31, 5)
            assert(status == 0)

            _fix_block_literal_huffman_code =
                GetHuffmanCodeFromBitlen(_fix_block_literal_huffman_bitlen_count
                    , _fix_block_literal_huffman_bitlen, 287, 9)
            _fix_block_dist_huffman_code =
                GetHuffmanCodeFromBitlen(_fix_block_dist_huffman_bitlen_count
                    , _fix_block_dist_huffman_bitlen, 31, 5)
        end

        -- Prefix encoding algorithm
        -- Credits to LibCompress.
        -- The code has been rewritten by the author of LibDeflate.
        ------------------------------------------------------------------------------

        -- to be able to match any requested byte value, the search
        -- string must be preprocessed characters to escape with %:
        -- ( ) . % + - * ? [ ] ^ $
        -- "illegal" byte values:
        -- 0 is replaces %z
        local _gsub_escape_table = {
            ["\000"] = "%z", ["("] = "%(", [")"] = "%)", ["."] = "%.",
            ["%"] = "%%", ["+"] = "%+", ["-"] = "%-", ["*"] = "%*",
            ["?"] = "%?", ["["] = "%[", ["]"] = "%]", ["^"] = "%^",
            ["$"] = "%$",
        }

        local function escape_for_gsub(str)
            return str:gsub("([%z%(%)%.%%%+%-%*%?%[%]%^%$])", _gsub_escape_table)
        end

        --- Create a custom codec with encoder and decoder. <br>
        -- This codec is used to convert an input string to make it not contain
        -- some specific bytes.
        -- This created codec and the parameters of this function do NOT take
        -- localization into account. One byte (0-255) in the string is exactly one
        -- character (0-255).
        -- Credits to LibCompress.
        -- The code has been rewritten by the author of LibDeflate. <br>
        -- @param reserved_chars [string] The created encoder will ensure encoded
        -- data does not contain any single character in reserved_chars. This parameter
        -- should be non-empty.
        -- @param escape_chars [string] The escape character(s) used in the created
        -- codec. The codec converts any character included in reserved\_chars /
        -- escape\_chars / map\_chars to (one escape char + one character not in
        -- reserved\_chars / escape\_chars / map\_chars).
        -- You usually only need to provide a length-1 string for this parameter.
        -- Length-2 string is only needed when
        -- reserved\_chars + escape\_chars + map\_chars is longer than 127.
        -- This parameter should be non-empty.
        -- @param map_chars [string] The created encoder will map every
        -- reserved\_chars:sub(i, i) (1 <= i <= #map\_chars) to map\_chars:sub(i, i).
        -- This parameter CAN be empty string.
        -- @return [table/nil] If the codec cannot be created, return nil.<br>
        -- If the codec can be created according to the given
        -- parameters, return the codec, which is a encode/decode table.
        -- The table contains two functions: <br>
        -- t:Encode(str) returns the encoded string. <br>
        -- t:Decode(str) returns the decoded string if succeeds. nil if fails.
        -- @return [nil/string] If the codec is successfully created, return nil.
        -- If not, return a string that describes the reason why the codec cannot be
        -- created.
        -- @usage
        -- -- Create an encoder/decoder that maps all "\000" to "\003",
        -- -- and escape "\001" (and "\002" and "\003") properly
        -- local codec = LibDeflate:CreateCodec("\000\001", "\002", "\003")
        --
        -- local encoded = codec:Encode(SOME_STRING)
        -- -- "encoded" does not contain "\000" or "\001"
        -- local decoded = codec:Decode(encoded)
        -- -- assert(decoded == SOME_STRING)
        function LibDeflate:CreateCodec(reserved_chars, escape_chars
            , map_chars)
            if type(reserved_chars) ~= "string"
                or type(escape_chars) ~= "string"
                or type(map_chars) ~= "string" then
                error(
                    "Usage: LibDeflate:CreateCodec(reserved_chars,"
                        .." escape_chars, map_chars):"
                        .." All arguments must be string.", 2)
            end

            if escape_chars == "" then
                return nil, "No escape characters supplied."
            end
            if #reserved_chars < #map_chars then
                return nil, "The number of reserved characters must be"
                    .." at least as many as the number of mapped chars."
            end
            if reserved_chars == "" then
                return nil, "No characters to encode."
            end

            local encode_bytes = reserved_chars..escape_chars..map_chars
            -- build list of bytes not available as a suffix to a prefix byte
            local taken = {}
            for i = 1, #encode_bytes do
                local byte = string_byte(encode_bytes, i, i)
                if taken[byte] then
                    return nil, "There must be no duplicate characters in the"
                        .." concatenation of reserved_chars, escape_chars and"
                        .." map_chars."
                end
                taken[byte] = true
            end

            local decode_patterns = {}
            local decode_repls = {}

            -- the encoding can be a single gsub
            -- , but the decoding can require multiple gsubs
            local encode_search = {}
            local encode_translate = {}

            -- map single byte to single byte
            if #map_chars > 0 then
                local decode_search = {}
                local decode_translate = {}
                for i = 1, #map_chars do
                    local from = string_sub(reserved_chars, i, i)
                    local to = string_sub(map_chars, i, i)
                    encode_translate[from] = to
                    encode_search[#encode_search+1] = from
                    decode_translate[to] = from
                    decode_search[#decode_search+1] = to
                end
                decode_patterns[#decode_patterns+1] =
                    "([".. escape_for_gsub(table_concat(decode_search)).."])"
                decode_repls[#decode_repls+1] = decode_translate
            end

            local escape_char_index = 1
            local escape_char = string_sub(escape_chars
                , escape_char_index, escape_char_index)
            -- map single byte to double-byte
            local r = 0 -- suffix char value to the escapeChar

            local decode_search = {}
            local decode_translate = {}
            for i = 1, #encode_bytes do
                local c = string_sub(encode_bytes, i, i)
                if not encode_translate[c] then
                    while r >= 256 or taken[r] do
                        r = r + 1
                        if r > 255 then -- switch to next escapeChar
                            decode_patterns[#decode_patterns+1] =
                                escape_for_gsub(escape_char)
                                .."(["
                                .. escape_for_gsub(table_concat(decode_search)).."])"
                            decode_repls[#decode_repls+1] = decode_translate

                            escape_char_index = escape_char_index + 1
                            escape_char = string_sub(escape_chars, escape_char_index
                                , escape_char_index)
                            r = 0
                            decode_search = {}
                            decode_translate = {}

                            if not escape_char or escape_char == "" then
                                -- actually I don't need to check
                                -- "not ecape_char", but what if Lua changes
                                -- the behavior of string.sub() in the future?
                                -- we are out of escape chars and we need more!
                                return nil, "Out of escape characters."
                            end
                        end
                    end

                    local char_r = _byte_to_char[r]
                    encode_translate[c] = escape_char..char_r
                    encode_search[#encode_search+1] = c
                    decode_translate[char_r] = c
                    decode_search[#decode_search+1] = char_r
                    r = r + 1
                end
                if i == #encode_bytes then
                    decode_patterns[#decode_patterns+1] =
                        escape_for_gsub(escape_char).."(["
                        .. escape_for_gsub(table_concat(decode_search)).."])"
                    decode_repls[#decode_repls+1] = decode_translate
                end
            end

            local codec = {}

            local encode_pattern = "(["
                .. escape_for_gsub(table_concat(encode_search)).."])"
            local encode_repl = encode_translate

            function codec:Encode(str)
                if type(str) ~= "string" then
                    error(("Usage: codec:Encode(str):"
                        .." 'str' - string expected got '%s'."):format(type(str)), 2)
                end
                return string_gsub(str, encode_pattern, encode_repl)
            end

            local decode_tblsize = #decode_patterns
            local decode_fail_pattern = "(["
                .. escape_for_gsub(reserved_chars).."])"

            function codec:Decode(str)
                if type(str) ~= "string" then
                    error(("Usage: codec:Decode(str):"
                        .." 'str' - string expected got '%s'."):format(type(str)), 2)
                end
                if string_find(str, decode_fail_pattern) then
                    return nil
                end
                for i = 1, decode_tblsize do
                    str = string_gsub(str, decode_patterns[i], decode_repls[i])
                end
                return str
            end

            return codec
        end

        local _addon_channel_codec


        -- Credits to WeakAuras2 and Galmok for the 6 bit encoding algorithm.
        -- The code has been rewritten by the author of LibDeflate.
        -- The result of encoding will be 25% larger than the
        -- origin string, but every single byte of the encoding result will be
        -- printable characters as the following.
        local _byte_to_6bit_char = {
            [0]="a", "b", "c", "d", "e", "f", "g", "h",
            "i", "j", "k", "l", "m", "n", "o", "p",
            "q", "r", "s", "t", "u", "v", "w", "x",
            "y", "z", "A", "B", "C", "D", "E", "F",
            "G", "H", "I", "J", "K", "L", "M", "N",
            "O", "P", "Q", "R", "S", "T", "U", "V",
            "W", "X", "Y", "Z", "0", "1", "2", "3",
            "4", "5", "6", "7", "8", "9", "(", ")",
        }

        local _6bit_to_byte = {
            [97]=0,[98]=1,[99]=2,[100]=3,[101]=4,[102]=5,[103]=6,[104]=7,
            [105]=8,[106]=9,[107]=10,[108]=11,[109]=12,[110]=13,[111]=14,[112]=15,
            [113]=16,[114]=17,[115]=18,[116]=19,[117]=20,[118]=21,[119]=22,[120]=23,
            [121]=24,[122]=25,[65]=26,[66]=27,[67]=28,[68]=29,[69]=30,[70]=31,
            [71]=32,[72]=33,[73]=34,[74]=35,[75]=36,[76]=37,[77]=38,[78]=39,
            [79]=40,[80]=41,[81]=42,[82]=43,[83]=44,[84]=45,[85]=46,[86]=47,
            [87]=48,[88]=49,[89]=50,[90]=51,[48]=52,[49]=53,[50]=54,[51]=55,
            [52]=56,[53]=57,[54]=58,[55]=59,[56]=60,[57]=61,[40]=62,[41]=63,
        }

        --- Encode the string to make it printable. <br>
        --
        -- Credit to WeakAuras2, this function is equivalant to the implementation
        -- it is using right now. <br>
        -- The code has been rewritten by the author of LibDeflate. <br>
        -- The encoded string will be 25% larger than the origin string. However, every
        -- single byte of the encoded string will be one of 64 printable ASCII
        -- characters, which are can be easier copied, pasted and displayed.
        -- (26 lowercase letters, 26 uppercase letters, 10 numbers digits,
        -- left parenthese, or right parenthese)
        -- @param str [string] The string to be encoded.
        -- @return [string] The encoded string.
        function LibDeflate:EncodeForPrint(str)
            if type(str) ~= "string" then
                error(("Usage: LibDeflate:EncodeForPrint(str):"
                    .." 'str' - string expected got '%s'."):format(type(str)), 2)
            end
            local strlen = #str
            local strlenMinus2 = strlen - 2
            local i = 1
            local buffer = {}
            local buffer_size = 0
            while i <= strlenMinus2 do
                local x1, x2, x3 = string_byte(str, i, i+2)
                i = i + 3
                local cache = x1+x2*256+x3*65536
                local b1 = cache % 64
                cache = (cache - b1) / 64
                local b2 = cache % 64
                cache = (cache - b2) / 64
                local b3 = cache % 64
                local b4 = (cache - b3) / 64
                buffer_size = buffer_size + 1
                buffer[buffer_size] =
                    _byte_to_6bit_char[b1].._byte_to_6bit_char[b2]
                    .._byte_to_6bit_char[b3].._byte_to_6bit_char[b4]
            end

            local cache = 0
            local cache_bitlen = 0
            while i <= strlen do
                local x = string_byte(str, i, i)
                cache = cache + x * _pow2[cache_bitlen]
                cache_bitlen = cache_bitlen + 8
                i = i + 1
            end
            while cache_bitlen > 0 do
                local bit6 = cache % 64
                buffer_size = buffer_size + 1
                buffer[buffer_size] = _byte_to_6bit_char[bit6]
                cache = (cache - bit6) / 64
                cache_bitlen = cache_bitlen - 6
            end

            return table_concat(buffer)
        end

        --- Decode the printable string produced by LibDeflate:EncodeForPrint.
        -- "str" will have its prefixed and trailing control characters or space
        -- removed before it is decoded, so it is easier to use if "str" comes form
        -- user copy and paste with some prefixed or trailing spaces.
        -- Then decode fails if the string contains any characters cant be produced by
        -- LibDeflate:EncodeForPrint. That means, decode fails if the string contains a
        -- characters NOT one of 26 lowercase letters, 26 uppercase letters,
        -- 10 numbers digits, left parenthese, or right parenthese.
        -- @param str [string] The string to be decoded
        -- @return [string/nil] The decoded string if succeeds. nil if fails.
        function LibDeflate:DecodeForPrint(str)
            if type(str) ~= "string" then
                error(("Usage: LibDeflate:DecodeForPrint(str):"
                    .." 'str' - string expected got '%s'."):format(type(str)), 2)
            end
            str = str:gsub("^[%c ]+", "")
            str = str:gsub("[%c ]+$", "")

            local strlen = #str
            if strlen == 1 then
                return nil
            end
            local strlenMinus3 = strlen - 3
            local i = 1
            local buffer = {}
            local buffer_size = 0
            while i <= strlenMinus3 do
                local x1, x2, x3, x4 = string_byte(str, i, i+3)
                x1 = _6bit_to_byte[x1]
                x2 = _6bit_to_byte[x2]
                x3 = _6bit_to_byte[x3]
                x4 = _6bit_to_byte[x4]
                if not (x1 and x2 and x3 and x4) then
                    return nil
                end
                i = i + 4
                local cache = x1+x2*64+x3*4096+x4*262144
                local b1 = cache % 256
                cache = (cache - b1) / 256
                local b2 = cache % 256
                local b3 = (cache - b2) / 256
                buffer_size = buffer_size + 1
                buffer[buffer_size] =
                    _byte_to_char[b1].._byte_to_char[b2].._byte_to_char[b3]
            end

            local cache  = 0
            local cache_bitlen = 0
            while i <= strlen do
                local x = string_byte(str, i, i)
                x =  _6bit_to_byte[x]
                if not x then
                    return nil
                end
                cache = cache + x * _pow2[cache_bitlen]
                cache_bitlen = cache_bitlen + 6
                i = i + 1
            end

            while cache_bitlen >= 8 do
                local byte = cache % 256
                buffer_size = buffer_size + 1
                buffer[buffer_size] = _byte_to_char[byte]
                cache = (cache - byte) / 256
                cache_bitlen = cache_bitlen - 8
            end

            return table_concat(buffer)
        end

        local function InternalClearCache()
            _addon_channel_codec = nil
        end

        -- For test. Don't use the functions in this table for real application.
        -- Stuffs in this table is subject to change.
        LibDeflate.internals = {
            LoadStringToTable = LoadStringToTable,
            IsValidDictionary = IsValidDictionary,
            IsEqualAdler32 = IsEqualAdler32,
            _byte_to_6bit_char = _byte_to_6bit_char,
            _6bit_to_byte = _6bit_to_byte,
            InternalClearCache = InternalClearCache,
        }

        return Compression
    end)()

    return {
        ["Zstd"]=Zstd,
        ["Base94"]=Base94,
        ["Zlib"]=Zlib,
    }
end)()

local OldCompress = (function()
    local Compressor = {}
    local Base94 = Encoders.Base94
    local ZLib = Encoders.Zlib

    local ENABLE_DATA_COMPRESSION = true
    local ZLIB_COMPRESSION_LEVEL = 9
    local MAX_CACHED_VALUES = 100

    local GetKeyCount = function(Dictionary)
        local Count = 0
        
        for _ in pairs(Dictionary) do
            Count += 1
        end
        
        return Count
    end

    local GetFirstKeyOfDict = function(Dictionary)
        for Key in pairs(Dictionary) do
            return Key
        end
    end

    local Cache = setmetatable({}, {
        __newindex = function(self, New, Index)
            local CacheCount = GetKeyCount(self)
            
            if CacheCount > MAX_CACHED_VALUES then
                local Key = GetFirstKeyOfDict(self)
                
                rawset(self, Key, nil)
            end
            
            rawset(self, New, Index)
        end
    })

    local Cache2 = setmetatable({}, {
        __newindex = function(self, New, Index)
            local CacheCount = GetKeyCount(self)

            if CacheCount > MAX_CACHED_VALUES then
                local Key = GetFirstKeyOfDict(self)

                rawset(self, Key, nil)
            end

            rawset(self, New, Index)
        end
    })

    local ZLibCompress = ZLib.Zlib.Compress
    local ZLibDecompress = ZLib.Zlib.Decompress
    local B94Encode = Base94.encode
    local B94Decode = Base94.decode

    Compressor.Compress = function(String)
        if not ENABLE_DATA_COMPRESSION then
            return String
        end
        
        local Cached = Cache[String]
        
        if Cached then
            return Cached
        end
        
        local ZLibCompressed
        
        if #String > 100 then
            ZLibCompressed = ZLibCompress(String, {
                level = ZLIB_COMPRESSION_LEVEL
            })
        else
            ZLibCompressed = String
        end
        
        local EncodedBuffer = B94Encode(buffer.fromstring(ZLibCompressed))
        local B94Encoded = buffer.tostring(EncodedBuffer)
        
        Cache[String] = B94Encoded
        
        return B94Encoded
    end

    Compressor.Decompress = function(String)
        if not ENABLE_DATA_COMPRESSION then
            return String
        end
        
        local Cached = Cache[String]

        if Cached then
            return Cached
        end

        local DecodedBuffer = B94Decode(buffer.fromstring(String))
        local B94Decoded = buffer.tostring(DecodedBuffer)
        local Status, ZLibDecompressed = pcall(ZLibDecompress, B94Decoded)
        
        if Status and ZLibDecompressed ~= nil then
            Cache[String] = ZLibDecompressed
            
            return ZLibDecompressed
        end
        
        Cache[String] = B94Decoded
        
        return B94Decoded
    end

    Compressor.CompressNoEncoding = function(String)
        if not ENABLE_DATA_COMPRESSION then
            return String
        end
        
        local Cached = Cache2[String]
        
        if Cached then
            return Cached
        end
        
        local ZLibCompressed = ZLibCompress(String, {
            level = ZLIB_COMPRESSION_LEVEL
        })
        
        Cache2[String] = ZLibCompressed
        
        return ZLibCompressed
    end

    Compressor.DecompressNoEncoding = function(String)
        if not ENABLE_DATA_COMPRESSION then
            return String
        end
        
        local Cached = Cache2[String]

        if Cached then
            return Cached
        end
        
        local Status, ZLibDecompressed = pcall(ZLibDecompress, String)

        if Status and ZLibDecompressed ~= nil then
            Cache2[String] = ZLibDecompressed

            return ZLibDecompressed
        end
    end

    return Compressor
end)()

local NewCompress = (function()
    local Compressor = {}
    local ZStd = Encoders.Zstd

    local GetKeyCount = function(Dictionary)
        local Count = 0

        for _ in pairs(Dictionary) do
            Count += 1
        end

        return Count
    end

    local GetFirstKeyOfDict = function(Dictionary)
        for Key in pairs(Dictionary) do
            return Key
        end
    end

    local Cache = setmetatable({}, {
        __newindex = function(self, New, Index)
            local CacheCount = GetKeyCount(self)

            if CacheCount > 100 then
                local Key = GetFirstKeyOfDict(self)

                rawset(self, Key, nil)
            end

            rawset(self, New, Index)
        end
    })

    Compressor.Compress = function(String, CompressionLevel)
        local Cached = Cache[String]

        if Cached then
            return Cached
        end

        local Compressed = ZStd.Compress(String, CompressionLevel)

        Cache[String] = Compressed

        return Compressed
    end

    Compressor.Decompress = function(String)
        local Cached = Cache[String]

        if Cached then
            return Cached
        end

        local Decompressed = ZStd.Decompress(String)

        Cache[String] = Decompressed

        return Decompressed
    end

    return Compressor
end)()

local Base94 = Encoders.Base94
local CreateInstanceMap, ReverseInstanceMap -- these function are declared this way because they will be calling themselves
local InstanceReferenceCache = {}
local CreatableInstancesCache = {}
local PropertiesOfClassCache = {}
local PropertyCompressionCount = 0 -- resets every mapping session, make sure to reset inside serializeinstance after use
local Minstance = {}

local InstanceCreationInternalHooks = {}

local __index = function(Object, Index)
	return Object[Index]
end

local __newindex = function(Object, Index, New)
	Object[Index] = New
end

-- see if we can fetch the internal metamethods for faster indexing and newindexing (proven to be 15% faster! WOW!)
pcall(function()
	local TemporaryInstance = Instance_new("Part")

	local SuspectedIndex = select(2, xpcall(function()
		return game[NULL]
	end, function()
		return debug_info(2, "f")
	end))

	local SuspectedNewindex = select(2, xpcall(function()
		game[NULL] = NULL
	end, function()
		return debug_info(2, "f")
	end))

	SuspectedNewindex(TemporaryInstance, "Name", "antiskid on top")

	if TemporaryInstance.Name == "antiskid on top" then
		__newindex = SuspectedNewindex
	end

	if SuspectedIndex(TemporaryInstance, "Name") == "antiskid on top" then
		__index = SuspectedIndex
	end

	TemporaryInstance:Destroy()
end)

if ReflectionServiceWrapper.InitializeApiDump() ~= true then
	return error("Failed to initialize API. Minstance will not work.")
end

local IsClassCreatable = function(ClassName)
	local Cached = CreatableInstancesCache[ClassName]
	
	if Cached then
		return Cached
	end
	
	local Status, TestInstance = pcall(Instance_new, ClassName)

	if not Status or TestInstance == NULL then
		CreatableInstancesCache[ClassName] = false
		
		return false
	else
		pcall(function()
			TestInstance:Destroy()
		end)
		
		CreatableInstancesCache[ClassName] = true

		return true
	end
end

local SafelyIndexInto = function(Object, Index)
	local Status, Value = pcall(__index, Object, Index)

	if Status then
		return Status, Value
	else
		return Status
	end
end

local ThrowToConsole = function(Message, Type)
	if Type == 2 then
		return error(`[Minstance] {Message}`)
		-- elseif Type == 1 then
		-- return warn(`[Minstance] {Message}`)
		-- end
	end

	-- return print(`[Minstance] {Message}`)
	return warn(`[Minstance] {Message}`)
end

local CreateAddressFromDescendantToParent = function(Descendant, Parent)
	local Address = {}
	local CurrentDescendant = Descendant
	
	if Descendant == Parent then
		return {0}
	end
	
	while CurrentDescendant and CurrentDescendant ~= Parent do
		local DescendantParent = __index(CurrentDescendant, "Parent")
		
		if not DescendantParent then
			return {}
		end
		
		local Position = 0
		
		for i, Child in ipairs(DescendantParent:GetChildren()) do
			if Child == CurrentDescendant then
				Position = i
				break
			end
		end

		table_insert(Address, 1, Position)

		CurrentDescendant = DescendantParent
	end

	return Address
end

CreateInstanceMap = function(TargetInstance, IncludeDescendants, PrintProcess, MainInstanceReference, IncludeAttributes, DisallowedProperties, PropertyCompression)
	local ClassName = __index(TargetInstance, "ClassName")

	local Map = {
		C = ClassName, -- the key of this dict was previously ClassName, shortened for compression
		P = {} -- the key of this dict was previously Properties, shortened for compression
	}
	
	if not PropertyCompression then
		Map.PC = {} -- the key of this dict was previously PropertyCompression, shortened for compression
		PropertyCompression = Map.PC
	end

	if not IsClassCreatable(ClassName) then
		ThrowToConsole(`Skipping Instance "{TargetInstance:GetFullName()}" ({ClassName}) because it is not creatable.`)
		return
	end

	local FreshInstance, PropertiesOfClass
	local PropertiesInMap = Map.P
	local FoundValidPropertyOnce = false
	local CachedFreshInstance = InstanceReferenceCache[ClassName]
	local PropertiesCache = PropertiesOfClassCache[ClassName]
	
	if PropertiesCache then
		PropertiesOfClass = PropertiesCache
	else
		PropertiesOfClass = ReflectionServiceWrapper.GetPropertiesOfClass(ClassName)
		PropertiesOfClassCache[ClassName] = PropertiesOfClass
	end
	
	if CachedFreshInstance then
		FreshInstance = CachedFreshInstance
	else
		FreshInstance = Instance_new(ClassName)
		InstanceReferenceCache[ClassName] = FreshInstance
	end

	for _, Property in ipairs(PropertiesOfClass) do
		if DisallowedProperties then
			local List = DisallowedProperties[ClassName]

			if List then
				if List[Property] then
					continue
				end
			end
		end
		
		if not PropertiesInMap[Property] and Property ~= "Parent" then
			local Status, ValueInFreshInstance = SafelyIndexInto(FreshInstance, Property)

			if Status then
				local ValueInOriginalInstance = __index(TargetInstance, Property)

				if ValueInFreshInstance ~= ValueInOriginalInstance then
					if not FoundValidPropertyOnce then
						FoundValidPropertyOnce = true
					end
					
					-- i just realized i can compress my serialized data further by generating a list of properties used in all of the instances and having that list in the main instance map like {Name = 1, BrickColor = 2, ...} and then the properties table of child instances would be {[1] = "name", [2] = enum.some.value}
					local ShortenedProperty = PropertyCompression[Property]
					
					if not ShortenedProperty then
						PropertyCompressionCount += 1
						
						PropertyCompression[Property] = PropertyCompressionCount
						ShortenedProperty = PropertyCompressionCount
					end
					
					if typeof(ValueInOriginalInstance) == "Instance" then -- this is rare to occur
						if ValueInOriginalInstance == MainInstanceReference then
							PropertiesInMap[ShortenedProperty] = {["Pointer"] = {0}}
						else
							if ValueInOriginalInstance:IsDescendantOf(MainInstanceReference) then
								local Pointer = CreateAddressFromDescendantToParent(ValueInOriginalInstance, MainInstanceReference)
								
								if #Pointer >= 1 then
									PropertiesInMap[ShortenedProperty] = {["Pointer"] = Pointer}
								end
							else
								ThrowToConsole(`Skipping property "{Property}" of Instance "{TargetInstance:GetFullName()}" ({ClassName}) because the value of the property references an Instance that is not a descendant of the main Instance being serialized.`)
							end
						end
					else
						PropertiesInMap[ShortenedProperty] = ValueInOriginalInstance
					end
				end
			end
		end
	end

	if not FoundValidPropertyOnce then
		Map.P = NULL -- the key of this dict was previously Properties, shortened for compression
	end
	
	if IncludeAttributes then
		local Attributes = TargetInstance:GetAttributes()
		
		for _ in pairs(Attributes) do
			Map.A = Attributes -- the key of this dict was previously Attributes, shortened for compression
			break
		end
	end

	-- if PrintProcess then
		-- ThrowToConsole(`Mapping Instance "{TargetInstance:GetFullName()}" ({ClassName})...`)
	-- end

	if IncludeDescendants then
		local Children = TargetInstance:GetChildren()
		local ChildrenCount = #Children

		if ChildrenCount > 0 then
			Map.K = table_create(ChildrenCount) -- the key of this dict was previously Children, shortened for compression, now set to K as in Kids
			local MicroOptimizationReference = Map.K

			for _, Child in ipairs(Children) do
				local NewInstanceMap = CreateInstanceMap(Child, true, PrintProcess, MainInstanceReference, IncludeAttributes, DisallowedProperties, PropertyCompression)

				if NewInstanceMap then
					table_insert(MicroOptimizationReference, NewInstanceMap)
				end
			end
		end
	end

	return Map
end

-- support meshparts deserialization
local CreateMeshPart = function(Id, Options)
	local Success, ErrorOrMeshPart = pcall(function()
		return AssetService:CreateMeshPartAsync(Id, Options)
	end)
	
	if Success then
		return ErrorOrMeshPart
	else
		ThrowToConsole(`Failed to create MeshPart with content ID "{tostring(Id)}". Returning default MeshPart. Error: {ErrorOrMeshPart}`)
		return Instance_new("MeshPart")
	end
end

InstanceCreationInternalHooks.MeshPart = function(Properties, InvertedPropertyCompression)
	local Id
	local Options = {}
	local HandledProperties = {}
	
	-- WASTE OF CPU CYCLES I KNOW.. TODO: FIX
	for PropertyId, Value in pairs(Properties) do
		local PropertyName = InvertedPropertyCompression[PropertyId]

		if PropertyName == "MeshContent" then
			if not Id then
				Id = Value
			end
			
			HandledProperties[PropertyName] = true
		elseif PropertyName == "MeshId" then
			if not Id then
				Id = Value
			end

			HandledProperties[PropertyName] = true
		elseif PropertyName == "CollisionFidelity" then
			Options["CollisionFidelity"] = Value
			HandledProperties[PropertyName] = true
		elseif PropertyName == "RenderFidelity" then
			Options["RenderFidelity"] = Value
			HandledProperties[PropertyName] = true
		elseif PropertyName == "FluidFidelity" then
			Options["FluidFidelity"] = Value
			HandledProperties[PropertyName] = true
		end
	end

	if not Id then
		ThrowToConsole("Attempted to deserialize a MeshPart without a MeshId property. Returning default MeshPart.")
		return Instance_new("MeshPart"), {}
	end
	
	if not next(Options) then
		Options = nil
	end
	
	-- silence the noise.
	HandledProperties["MeshContent"] = true
	
	return CreateMeshPart(Id, Options), HandledProperties
end

ReverseInstanceMap = function(Map, ParentOfInstance, DeserializeMeshPartsProperly, MainMapReference, TemporaryCacheTable, PropertyCompression)
	local ClassName = Map.C
	local Properties = Map.P
	local Children = Map.K
	local Attributes = Map.A
	local CallbackTable = Map.Callbacks
	local InternalPropertyHooks = EMPTY_TABLE
	local UseInternalPropertyHooks = false -- CPU CYCLES MUST NOT GO TO WASTE!!
	local CreationHook = InstanceCreationInternalHooks[ClassName]
	local MainInstance
	
	if not PropertyCompression then
		local PotentialPropertyCompression = Map.PC
		
		if not PotentialPropertyCompression then
			return ThrowToConsole(`This version of MInstance is sadly not backwards compatible with MInstance 1.0 data due to changes in data structure to achieve more compression.`)
		else
			local ReversedPC = {}
			
			for PropertyName, PropertyId in pairs(PotentialPropertyCompression) do
				ReversedPC[PropertyId] = PropertyName
			end
			
			PropertyCompression = ReversedPC
		end
	end
	
	if CreationHook then
		if ClassName == "MeshPart" then
			if DeserializeMeshPartsProperly then
				UseInternalPropertyHooks = true
				MainInstance, InternalPropertyHooks = CreationHook(Properties, PropertyCompression)
			else
				MainInstance = Instance_new(ClassName)
			end
		else
			MainInstance = CreationHook(Properties, PropertyCompression)
		end
	else
		MainInstance = Instance_new(ClassName)
	end
	
	local SafelySetProperty = function(Property, Value)
		local Status, Error = pcall(__newindex, MainInstance, Property, Value)
		
		if not Status then
			ThrowToConsole(`Unable to set property {Property} to Instance "{tostring(MainInstance)}" ({ClassName}) for reason: "{Error}"`)
		end
	end
	
	TemporaryCacheTable[Map] = MainInstance
	
	if CallbackTable then
		for _,func in CallbackTable do
			func(MainInstance)
		end
	end

	if ParentOfInstance then
		__newindex(MainInstance, "Parent", ParentOfInstance)
	end

	if Properties then
		for PropertyId, Value in pairs(Properties) do
			local PropertyName = PropertyCompression[PropertyId]
			
			if not PropertyName then
				ThrowToConsole(`A property with an unknown name has been skipped due to it not being in the reverse table (PropertyCompression table). If you encounter this, data corruption might have occured to the serialized data.`)
				continue
			end
			
			if type(Value) == "table" then
				local Location = Value.Pointer
				
				if type(Location) == "table" then
					if #Location >= 1 then
						local CurrentlyPointingTo = NULL
						
						if #Location == 1 and Location[1] == 0 then
							CurrentlyPointingTo = MainMapReference
						else
							for _, Index in ipairs(Location) do
								if CurrentlyPointingTo then
									local ChildrenList = CurrentlyPointingTo.K

									if ChildrenList then
										local IsValidMap = ChildrenList[Index]

										if IsValidMap then
											CurrentlyPointingTo = IsValidMap
										else
											ThrowToConsole(`Skipped setting property "{PropertyName}" to Instance "{tostring(MainInstance)}" because it was trying to find the Instance that the property was referencing to but could not find it.`)
											break
										end
									end
								else
									local ChildrenList = MainMapReference.K

									if ChildrenList then
										local IsValidMap = ChildrenList[Index]

										if IsValidMap then
											CurrentlyPointingTo = IsValidMap
										else
											ThrowToConsole(`Skipped setting property "{PropertyName}" to Instance "{tostring(MainInstance)}" because it was trying to find the Instance that the property was referencing to but could not find it.`)
											break
										end
									end
								end
							end
						end
						
						local CachedInstance = TemporaryCacheTable[CurrentlyPointingTo]
						
						if CachedInstance then
							SafelySetProperty(PropertyName, CachedInstance)
						else
							local function Callback(GotInstance)
								SafelySetProperty(PropertyName, GotInstance)
							end
							
							if CurrentlyPointingTo.Callbacks then
								table_insert(CurrentlyPointingTo.Callbacks, Callback)
							else
								CurrentlyPointingTo.Callbacks = {Callback}
							end
						end
					else
						ThrowToConsole(`Skipped setting property "{PropertyName}" to Instance "{tostring(MainInstance)}" because it was trying to find the Instance that the property was referencing to but could not find it.`)
					end
				end
			else
				if UseInternalPropertyHooks then -- CPU CYCLES MUST NOT GO TO WASTE!!
					if InternalPropertyHooks[PropertyName] then
						continue
					end
				end
				
				SafelySetProperty(PropertyName, Value)
			end
		end
	end
	
	if Attributes then
		for Name, Value in pairs(Attributes) do
			MainInstance:SetAttribute(Name, Value)
		end
	end
	
	if Children then
		for _, Child in ipairs(Children) do
			ReverseInstanceMap(Child, MainInstance, DeserializeMeshPartsProperly, MainMapReference, TemporaryCacheTable, PropertyCompression)
		end
	end

	return MainInstance
end

Minstance.SerializeInstance = function(TargetInstance: Instance, SerializationSettings: {
	IncludeDescendants: boolean,
	CompressSerializedData: boolean,
	CompressionLevel: number,
	EncodeInBase94: boolean,
	AnnoyingConsolePrints: boolean,
	UseLegacySlowCompressor: boolean,
	IncludeAttributes: boolean,
	DisallowedProperties: {[string]: {[string]: any} } | nil
	})
	
	local StartBenchmarkTime

	local DefaultSerializationSettings = {
		IncludeDescendants = true,
		CompressSerializedData = true,
		CompressionLevel = 8, -- seems to be the sweet spot to balance performance and compression ratio
		EncodeInBase94 = false,
		AnnoyingConsolePrints = false,
		UseLegacySlowCompressor = false,
		IncludeAttributes = true,
		DisallowedProperties = NULL
		-- EXAMPLE:
		-- {
			--	["Part"] = {
			--		["BrickColor"] = true
			--	}
		-- }
	}

	local Settings = SerializationSettings or {}
	for Setting, DefaultValue in pairs(DefaultSerializationSettings) do
		if Settings[Setting] == NULL then
			Settings[Setting] = DefaultValue
		end
	end

	if not ReflectionServiceWrapper.IsApiInitialized() then
		return ThrowToConsole(`There was a problem with initalizing the API and Minstance can not serialize an Instance. Please get in contact with @WalletOverflow in Roblox and let them know about this, and please show recent console errors coming from this module.`, 2)
	end

	if typeof(TargetInstance) ~= "Instance" then
		return ThrowToConsole(`Invalid first argument passed into SerializeInstance! Expected: Instance`, 2)
	end

	if not IsClassCreatable(TargetInstance.ClassName) then
		return ThrowToConsole(`Instance "{TargetInstance:GetFullName()}" ({TargetInstance.ClassName}) is not creatable and can not be serialized.`, 2)
	end

	if Settings.AnnoyingConsolePrints then
		ThrowToConsole(`You are seeing this because AnnoyingConsolePrints setting was set to true in SerializationSettings.`)
		ThrowToConsole(`Target Instance: "{TargetInstance:GetFullName()}" ({TargetInstance.ClassName}) ({tostring(#TargetInstance:GetDescendants())} descendants)`)
		ThrowToConsole(`Mapping Instance...`)

		StartBenchmarkTime = os_clock()
	end

	if PropertyCompressionCount > 0 then
		PropertyCompressionCount = 0
	end

	local MainMap = CreateInstanceMap(TargetInstance, Settings.IncludeDescendants, Settings.AnnoyingConsolePrints, TargetInstance, Settings.IncludeAttributes, Settings.DisallowedProperties)

	if PropertyCompressionCount > 0 then
		PropertyCompressionCount = 0
	end

	if Settings.AnnoyingConsolePrints then
		if Settings.IncludeDescendants then
			ThrowToConsole(string_format(`Finished serializing/mapping "{TargetInstance:GetFullName()}" (and {tostring(#TargetInstance:GetDescendants())} descendants) in %.4fs!`, os_clock() - StartBenchmarkTime))
		else
			ThrowToConsole(string_format(`Finished serializing/mapping "{TargetInstance:GetFullName()}" in %.4fs!`, os_clock() - StartBenchmarkTime))
		end
	end

	local BinaryEncoded = BufferEncoder.write(MainMap, nil, nil, true)

	if not Settings.CompressSerializedData then
		if Settings.EncodeInBase94 then
			return buffer_tostring(Base94.encode(BinaryEncoded))
		else
			return buffer_tostring(BinaryEncoded)
		end
	else
		if Settings.AnnoyingConsolePrints then
			ThrowToConsole(`Attempting to compress serialized data...`)
			StartBenchmarkTime = os_clock()
		end

		local BinaryEncodedString = buffer_tostring(BinaryEncoded)

		if Settings.UseLegacySlowCompressor then
			if Settings.EncodeInBase94 then
				local FinalCompressedData = OldCompress.Compress(BinaryEncodedString)

				if Settings.AnnoyingConsolePrints then
					ThrowToConsole(string_format(`Finished compressing & encoding serialized data in %.4fs!`, os_clock() - StartBenchmarkTime))
					ThrowToConsole(`Serialized data character count before compression: {#BinaryEncodedString}`)
					ThrowToConsole(`Serialized data character count after compression: {#FinalCompressedData}`)
				end

				return FinalCompressedData
			else
				local FinalCompressedData = OldCompress.CompressNoEncoding(BinaryEncodedString, Settings.CompressionLevel)

				if Settings.AnnoyingConsolePrints then
					ThrowToConsole(string_format(`Finished compressing serialized data in %.4fs!`, os_clock() - StartBenchmarkTime))
					ThrowToConsole(`Serialized data character count before compression: {#BinaryEncodedString}`)
					ThrowToConsole(`Serialized data character count after compression: {#FinalCompressedData}`)
				end

				return FinalCompressedData
			end
		else
			local Compressed = NewCompress.Compress(BinaryEncodedString, Settings.CompressionLevel)

			if Settings.EncodeInBase94 then
				local Base94Encoded = buffer_tostring(Base94.encode(buffer_fromstring(Compressed)))

				if Settings.AnnoyingConsolePrints then
					ThrowToConsole(string_format(`Finished compressing & encoding serialized data in %.4fs!`, os_clock() - StartBenchmarkTime))
					ThrowToConsole(`Serialized data character count before compression: {#BinaryEncodedString}`)
					ThrowToConsole(`Serialized data character count after compression: {#Base94Encoded}`)
				end

				return Base94Encoded
			else
				if Settings.AnnoyingConsolePrints then
					ThrowToConsole(string_format(`Finished compressing serialized data in %.4fs!`, os_clock() - StartBenchmarkTime))
					ThrowToConsole(`Serialized data character count before compression: {#BinaryEncodedString}`)
					ThrowToConsole(`Serialized data character count after compression: {#Compressed}`)
				end

				return Compressed
			end
		end
	end
end

Minstance.DeserializeInstance = function(SerializedData: string, DeserializationSettings: {
	IsDataCompressed: boolean,
	IsBase94Encoded: boolean,
	AnnoyingConsolePrints: boolean,
	IsCompressedWithLegacyCompressor: boolean,
	ProperlyDeserializeMeshParts: boolean,
	ParentInstanceWhileDeserializing: Instance?
	})

	local StartBenchmarkTime, MainMap

	local DefaultDeserializationSettings = {
		IsDataCompressed = true,
		IsBase94Encoded = false,
		AnnoyingConsolePrints = false,
		IsCompressedWithLegacyCompressor = false,
		ProperlyDeserializeMeshParts = false, -- load mesh parts, if off then put mesh put but not load content
		ParentInstanceWhileDeserializing = NULL
	}

	local Settings = DeserializationSettings or {}
	for Setting, DefaultValue in pairs(DefaultDeserializationSettings) do
		if Settings[Setting] == NULL then
			Settings[Setting] = DefaultValue
		end
	end

	if not ReflectionServiceWrapper.IsApiInitialized() then
		return ThrowToConsole(`There was a problem with initalizing the API and Minstance can not deserialize an Instance. Please get in contact with @WalletOverflow in Roblox and let them know about this, and please show recent console errors coming from this module.`, 2)
	end

	if typeof(SerializedData) ~= "string" then
		return ThrowToConsole(`Invalid first argument passed into DeserializeInstance! Expected: string`, 2)
	end

	if Settings.AnnoyingConsolePrints then
		ThrowToConsole(`You are seeing this because AnnoyingConsolePrints setting was set to true in SerializationSettings.`)
		ThrowToConsole(`Processing serialized data...`)

		StartBenchmarkTime = os_clock()
	end

	if Settings.IsDataCompressed then
		if Settings.IsCompressedWithLegacyCompressor then
			if Settings.IsBase94Encoded then
				local BinaryFormat = OldCompress.Decompress(SerializedData)

				MainMap = BufferEncoder.read(buffer_fromstring(BinaryFormat), nil, nil, true)
			else
				local BinaryFormat = OldCompress.DecompressNoEncoding(SerializedData)

				MainMap = BufferEncoder.read(buffer_fromstring(BinaryFormat), nil, nil, true)
			end
		else
			if Settings.IsBase94Encoded then
				local Base94Decoded = buffer_tostring(Base94.decode(buffer_fromstring(SerializedData)))
				local BinaryFormat = NewCompress.Decompress(Base94Decoded)

				MainMap = BufferEncoder.read(buffer_fromstring(BinaryFormat), nil, nil, true)
			else
				local BinaryFormat = NewCompress.Decompress(SerializedData)

				MainMap = BufferEncoder.read(buffer_fromstring(BinaryFormat), nil, nil, true)
			end
		end
	else
		if Settings.IsBase94Encoded then
			local BinaryBuffer = Base94.decode(buffer_fromstring(SerializedData))

			MainMap = BufferEncoder.read(BinaryBuffer, nil, nil, true)
		else
			MainMap = BufferEncoder.read(buffer_fromstring(SerializedData), nil, nil, true)
		end
	end

	if Settings.AnnoyingConsolePrints then
		ThrowToConsole(string_format(`Finished processing serialized data in %.4fs!`, os_clock() - StartBenchmarkTime))
		ThrowToConsole(`Attempting to demap/deserialize serialized data into Instance...`)

		StartBenchmarkTime = os_clock()
	end

	local MapReversalCache = {}
	local MainInstance = ReverseInstanceMap(MainMap, Settings.ParentInstanceWhileDeserializing, Settings.ProperlyDeserializeMeshParts, MainMap, MapReversalCache)

	table_clear(MapReversalCache)

	if Settings.AnnoyingConsolePrints then
		ThrowToConsole(string_format(`Finished demapping/deserializing serialized data into an Instance in %.4fs!`, os_clock() - StartBenchmarkTime))
	end

	return MainInstance
end

-- Minstance.CreateInstanceMap = CreateInstanceMap
-- Minstance.ReverseInstanceMap = ReverseInstanceMap

return Minstance