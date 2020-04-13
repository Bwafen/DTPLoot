DTPLoot = {}
local mod = DTPLoot
local currentItem, lastItem = nil,nil
local DTPRollDB = {}

-- Definitions --

-- Looks for guild members without DB entries, fills accordingly.
local function updateRoster()
    SetGuildRosterShowOffline(true)
    GuildRoster()
    DEFAULT_CHAT_FRAME:AddMessage(GetNumGuildMembers().." guild members found. Updating.")
    local msg = "" 
    for i=1,GetNumGuildMembers() do
        local name,rank = GetGuildRosterInfo(i)
        local rb = (rank == "Raider" or rank == "Shadow Council") and 0 or 0
        if not DTPLootBonusDB[name] then                               
            DTPLootBonusDB[name] = {["rankBonus"]=rb, ["bountyBonus"]=0}
            msg = msg..name..", "
        else
            DTPLootBonusDB[name].rankBonus = rb
        end
    end
    if msg ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage("New members detected: "..msg)
    end
end

-- Sets everyone's bouty bonus to zero
local function resetBonus()
    for i=1,GetNumGuildMembers() do
        local name = GetGuildRosterInfo(i)
        DTPLootBonusDB[name].bountyBonus = 0
    end

end

-- (Re)initializes the loot bonus database
local function initDB()    
    if not DTPLootBonusDB then
        DTPLootBonusDB = {}
        DEFAULT_CHAT_FRAME:AddMessage("DB Init")
    end
end

-- Given a player name and number, sets player's bounty to this value. Says we did in in chat.
local function setPlayerBonus(name, amount)
    local msg ="(~\")~ " .. name .."'s bounty bonus set to " .. amount.."."
    if DTPLootBonusDB[name] then
    DTPLootBonusDB[name].bountyBonus = tonumber(amount)
    SendChatMessage(msg,"GUILD",nil,nil)
    else 
        DEFAULT_CHAT_FRAME:AddMessage(name.." not found in guild list.")
    end
    
end

-- Displays a list of all players with active bounty bonuses
local function showBonuses()
    SetGuildRosterShowOffline(true)    
    GuildRoster()
    local msg = ""
    for i=1,GetNumGuildMembers() do
        local name,rank = GetGuildRosterInfo(i)           
        if DTPLootBonusDB[name].bountyBonus ~=0 then
            msg = msg.. "<"..name..": " ..DTPLootBonusDB[name].bountyBonus.."> "
        end
    end
    if msg == "" then
        msg = "None."
    end
    SendChatMessage("Active bounties:","OFFICER",nil,nil)
    SendChatMessage(msg,"OFFICER",nil,nil)                       
end

-- resets bounties, requests an update in (officer) chat -- SET TO OFFICER ON RELEASE
function requestUpdate()
    updateRoster()
    resetBonus()
    SendChatMessage("<DTPLoot>Requesting update.","OFFICER", nil,nil)
    mod.frame:RegisterEvent("CHAT_MSG_OFFICER")
    mod.frame:SetScript("OnEvent", function(self, event, ...)
        if event == "CHAT_MSG_OFFICER" then
            local response,author = ...
            if author ~= UnitName("player") and string.match(response,"<.+: %d+>.-") then                
                DEFAULT_CHAT_FRAME:AddMessage("Received response. Proceeding.")
                for occurence in string.gmatch(response,"<%a+: %d+>") do
                    local nom, nb = string.match(occurence,"<(%a+): (%d+)>")
                    DTPLootBonusDB[nom].bountyBonus = tonumber(nb)
                    DEFAULT_CHAT_FRAME:AddMessage("*"..nom.." --> "..nb.."*")
                end
                mod.frame:UnregisterEvent("CHAT_MSG_OFFICER")
            elseif author ~= UnitName("player") and string.match(response,"None.") then
                DEFAULT_CHAT_FRAME:AddMessage("Received response. There are no active bounties atm.")
                mod.frame:UnregisterEvent("CHAT_MSG_OFFICER")
            end
        end
    end)
end

-- Given a player's name, returns their current loot bonus.
local function getBonus(author)
    local bonus = 0
    if DTPLootBonusDB[author] then -- CHANGE GUILDNAME ON RELEASE
        bonus = DTPLootBonusDB[author].rankBonus + DTPLootBonusDB[author].bountyBonus
    end
    return bonus
end

-- Displays a chat message asking people to manifest their interest in a linked item.
local function askForRolls(itemlink)
    if currentItem == nil then
        if itemlink then
            if string.match(itemlink,"|%w+|Hitem:.+|r") then
                local str = "Now assigning item ".. itemlink            
                SendChatMessage(str, "RAID_WARNING", nil, nil)
                SendChatMessage("Please /roll for main spec upgrades.", "RAID_WARNING", nil, nil)
                currentItem = itemlink            
            else
                DEFAULT_CHAT_FRAME:AddMessage("Invalid argument. Try /dtploot [anItemLink]")
            end
        end
    else 
        DEFAULT_CHAT_FRAME:AddMessage("Another roll is ongoing.")
    end
end

-- Saves rolls into a temp table
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
            SendChatMessage("Breaking ties...","RAID", nil, nil)
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
        SendChatMessage(msg,"RAID_WARNING", nil, nil)
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
    updateRoster()
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
                    SendChatMessage(resultMsg,"RAID", nil, nil)
                end
            end
        end)    
    end    
end

-- Sets a player's bountyBonus, resets bountyBonus for all players, or requests updated bounty list.
SLASH_DTPBONUS1 = "/dtpbonus"   
SLASH_DTPBONUS2 = "/dtpdb"                
SlashCmdList["DTPBONUS"] = function(argstring)
    if argstring then
        if argstring == "reset" then
            updateRoster()
            resetBonus()
        elseif argstring == "update" then
            requestUpdate()
        elseif argstring == "show" or argstring == "all" or argstring == "list" then
            showBonuses()
        elseif  string.match(argstring,"%a+%s%d+") then
            local playerName = string.match(argstring, "%a+")
            local amount = string.match(argstring, "%d+")   
            setPlayerBonus(playerName,amount)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Invalid argument. Try \'list\', \'update\', \'reset\', or \'playername number\'.")
        end
    end
end

-- Test purposes only. Do not use.
--[[
SLASH_DTPTEST1 = "/dtptest"
SlashCmdList["DTPTEST"] = function()    
    requestUpdate()
end

SLASH_DTPGUILD1 = "/dtpg"
SlashCmdList["DTPGUILD"] = function()    
    SetGuildRosterShowOffline(true)
    GuildRoster()
    DEFAULT_CHAT_FRAME:AddMessage(GetNumGuildMembers())   
    for i=1,GetNumGuildMembers(),1 do
        local name, rank = GetGuildRosterInfo(i)
        DEFAULT_CHAT_FRAME:AddMessage(name.." - "..rank)        
    end    
end
]]--






