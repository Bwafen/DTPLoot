DTPLoot = {}
local mod = DTPLoot
local currentItem, lastItem = nil,nil
local DTPRollDB = {}

-- Definitions --

-- Looks for guild members without DB entries, fills accordingly.
local function update()
    SetGuildRosterShowOffline(true)
    GuildRoster()
    --SendChatMessage(GetNumGuildMembers(),"WHISPER", nil, UnitName("player"))
    for i=1,GetNumGuildMembers() do
    local name,rank = GetGuildRosterInfo(i)
    local msg = ""         
        if not DTPLootBonusDB[name] then                               
            local rb = (rank == "Shadow Council") and 7 or 0
            DTPLootBonusDB[name] = {["rankBonus"]=rb, ["bountyBonus"]=0}
            msg = msg..name..", "
        end
    end
    SenChatMessage("New members detected:","WHISPER", nil, UnitName("player"))
    SendChatMessage(msg,"WHISPER", nil, UnitName("player"))
end

-- Resets bounty bonuses
local function resetBonus()
    SendChatMessage("Resetting bounties.","OFFICER", nil, nil)
    SetGuildRosterShowOffline(true)    
    GuildRoster()
    for i=1,GetNumGuildMembers() do
        local name, rank = GetGuildRosterInfo(i)
        DTPLootBonusDB[name].bountyBonus = 0
        if rank == "Initiate" then
            DTPLootBonusDB[name].rankBonus = 5
        end        
    end
end

-- (Re)initializes the loot bonus database
local function initDB()    
    if not DTPLootBonusDB then
        DTPLootBonusDB = {}
        SendChatMessage("DB Init","WHISPER", nil, UnitName("player"))
    end
end

-- Given a player name and number, sets player's bounty to this value. Says we did in in chat.
local function setPlayerBonus(name, amount)
    local msg ="(~\")~ " .. name .."'s bounty bonus set to " .. amount.."."
    if DTPLootBonusDB[name] then
    DTPLootBonusDB[name].bountyBonus = tonumber(amount)
    end
    SendChatMessage(msg,"GUILD", nil, nil)
end

-- Displays a list of all players with active bounty bonuses
local function showBonuses()
    SetGuildRosterShowOffline(true)    
    GuildRoster() 
    local msg = "Active bounties: "
    for i=1,GetNumGuildMembers() do
        local name= GetGuildRosterInfo(i)           
        if DTPLootBonusDB[name].bountyBonus ~=0 then
            msg = msg.. "<"..name..": " ..DTPLootBonusDB[name].bountyBonus.."> "            
        end
    end
    SendChatMessage(msg,"OFFICER", nil, nil)
end

-- Displays a chat message asking people to manifest their interest in a linked item.
local function askForRolls(itemlink)
    if currentItem == nil then
        if itemlink then
            if string.match(itemlink,"|%w+|Hitem:.+|r") then
                local str = "Now assigning item ".. itemlink            
                SendChatMessage(str, "PARTY", nil, nil)
                SendChatMessage("Please /roll if interested.", "PARTY", nil, nil)
                currentItem = itemlink            
            else
                SendChatMessage("Invalid argument. Try /dtploot [anItemLink]","WHISPER", nil, UnitName("player"))
            end
        end
    else 
        SendChatMessage("Another roll is ongoing.","WHISPER", nil, UnitName("player"))
    end
end

-- Given a player's name, returns their current loot bonus.
local function getBonus(playername)
    local bonus = 0
    if GetGuildInfo(playername) == "Debauchery Tea Party" and DTPLootBonusDB[playername] then -- CHANGE GUILDNAME ON RELEASE
        bonus = DTPLootBonusDB[playername].rankBonus + DTPLootBonusDB[playername].bountyBonus
    end
    return bonus
end

-- Saves rolls into a temp DB
local function saveScore(name,nb)
    DTPRollDB[name] = nb
end

-- Finds out who gets the purple
local function findWinner(scores)  
    local highRoll = 0
    local w1,w2,w3 = "", "", ""
    for key,value in pairs(scores) do
        if value >= highRoll then
            highRoll = value
            w3 = w2; w2 = w1; w1 = key
        end
    end
    local winners = (scores[w1]==scores[w3]) and {w1,w2,w3} or (scores[w2]==scores[w]) and {w1,w2} or {w1}
        if scores[w1]==scores[w2] then
            SendChatMessage("Breaking ties...","PARTY", nil, UnitName("player"))
        end
    local winner = winners[math.random(getn(winners))]
    return winner, highRoll
end

-- Stops listening for rolls, displays the winner in chat.
local function endCurrentRoll()
    mod.frame:UnregisterEvent("CHAT_MSG_SYSTEM")
    if currentItem then
        local winner, highRoll = findWinner(DTPRollDB)
        local msg = "<"..winner .. "> awarded " .. currentItem .. " with a roll of " .. highRoll.."."
        SendChatMessage(msg,"PARTY", nil, UnitName("player"))
    end
    lastItem = currentItem
    currentItem = nil
end


-- Instructions --

-- We need a frame to be able to listen for events
mod.frame = CreateFrame("Frame", "DTPLoot", UIParent)
mod.frame:SetFrameStrata("BACKGROUND")


-- Updates guid list when logging out
mod.frame:RegisterEvent("PLAYER_LOGOUT")
mod.frame:SetScript("OnEvent", function(self, event, ...)
    initDB()
    update()
end)



----------------------
-- Slash commands--
----------------------

-- Starts/ends loot process.
SLASH_DTP1 = "/dtploot"
SLASH_DTP2 = "/dtproll"
SlashCmdList["DTP"] = function(arg)
    local alreadyRolled = {}
    if arg == "end" then
    endCurrentRoll()
    else
        askForRolls(arg)               
        mod.frame:RegisterEvent("CHAT_MSG_SYSTEM")
        mod.frame:SetScript("OnEvent", function(self, event, ...)
            if event == "CHAT_MSG_SYSTEM"  then
                local message = ...
                local author, rollResult, rollMin, rollMax = string.match(message, "(.+) rolls (%d+) %((1)-(100)%)")
                if author and not alreadyRolled[author] then
                    alreadyRolled[author] = true
                    local modifiedRoll = tonumber(rollResult) + getBonus(author)
                    local resultMsg = "<"..author..": "..modifiedRoll.."("..rollResult.."+"..getBonus(author)..")>"
                    saveScore(author,modifiedRoll)                    
                    SendChatMessage(resultMsg,"PARTY", nil, nil)
                end
            end
        end)    
    end    
end

-- Sets a player's bountyBonus, or resets bountyBonus for all players.
SLASH_DTPBONUS1 = "/dtpbonus"   
SLASH_DTPBONUS2 = "/dtpdb"                
SlashCmdList["DTPBONUS"] = function(argstring)
    if argstring then
        if argstring == "reset" then
            resetBonus()
        elseif argstring == "show" or argstring == "all" then
            showBonuses()
        elseif  string.match(argstring,"%a+%s%d+") then
            local playerName = string.match(argstring, "%a+")
            local amount = string.match(argstring, "%d+")   
            setPlayerBonus(playerName,amount)
        else
            SendChatMessage("Invalid argument. Try /dtpbonus aPLayerName aNumber","WHISPER", nil, UnitName("player")) 
        end
    end
end

-- Test purposes only. Do not use.
--[[
SLASH_DTPTEST1 = "/dtptest"
SlashCmdList["DTPTEST"] = function()    
    local msg = DTPLootBonusDB[UnitName("player")].bountyBonus + DTPLootBonusDB[UnitName("player")].rankBonus
    SendChatMessage(msg,"WHISPER", nil, UnitName("player"))
end

SLASH_DTPGUILD1 = "/dtpg"
SlashCmdList["DTPGUILD"] = function()    
    SetGuildRosterShowOffline(true)
    GuildRoster()
    SendChatMessage(GetNumGuildMembers(),"WHISPER", nil, UnitName("player"))   
    for i=1,GetNumGuildMembers(),1 do
        local name, rank = GetGuildRosterInfo(i)
        SendChatMessage(name.." - "..rank,"WHISPER", nil, UnitName("player"))        
    end    
end
]]--