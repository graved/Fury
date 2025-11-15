-- Namespace (force table creation, overwrite any function)
if type(Fury) ~= "table" then
    Fury = {}
end
--------------------------------------------------
-- Global Variables
--------------------------------------------------

-- Global state tracking
FuryTalents = false
FuryCombat = false
FuryAttack = false
FuryMount = false
FuryOldStance = nil
FuryDanceDone = nil
FuryOverpower = nil
FurySpellInterrupt = nil
FuryFleeing = false
FuryLastSpellCast = 0
FuryLastStanceCast = 0
FuryLastSunder = 0
FuryLastChargeCast = 0
FuryLastLog = 0
FuryRevengeReadyUntil = 0
FuryRageDumped = false
FuryLastAutoAttackCheck = 0

-- Spec Detection
FurySpec = nil  -- "ARMS", "DW_FURY", "2H_FURY"
FuryWeaponType = nil  -- "2H", "DW", "1H+SHIELD"

-- Debug Logging
FuryLogToFile = false

-- Talent flags
FuryTacticalMastery = 0
FuryBloodthirst = false
FuryMortalStrike = false
FuryShieldSlam = false
FuryDeathWish = false
FuryBerserkerStance = false
FuryPiercingHowl = false
FurySweepingStrikes = false
FuryBerserkerRage = false
FuryImprovedBerserkerRageRank = 0
FuryFlurry = false
FuryImpHamstring = false
FurySwordSpec = false
FuryMaceSpec = false
FuryRacialBerserking = false
FuryRacialBloodFury = false
FuryWhirlwind = false

-- Execute/Heroic Strike costs
FuryExecuteCost = 15
FuryHeroicStrikeCost = 15

--------------------------------------------------
-- Initialization
--------------------------------------------------
function Fury:Initialize()
    if not Fury_Configuration then
        Fury_Configuration = {}
    end
    if not Fury_Runners then
        Fury_Runners = {}
    end
    if not Fury_ImmuneDisarm then
        Fury_ImmuneDisarm = {}
    end
    if not Fury_DebugLog then
        Fury_DebugLog = {}
    end
    
    Fury.Config:Initialize()
    Fury.SwingTimer:Initialize()
end

--------------------------------------------------
-- Print to chat
--------------------------------------------------
function Fury:Print(msg)
    if not DEFAULT_CHAT_FRAME then
        return
    end
    DEFAULT_CHAT_FRAME:AddMessage(BINDING_HEADER_FURY .. ": " .. (msg or ""))
end

--------------------------------------------------
-- Debug output
--------------------------------------------------
function Fury:Debug(msg)
    if (msg or "") == "" then
        FuryRageDumped = nil
        return
    end
    
    -- Log to file if enabled
    if FuryLogToFile and Fury_DebugLog then
        local timestamp = string.format("%.3f", GetTime())
        local rage = UnitMana("player")
        local hp = string.format("%.0f%%", (UnitHealth("player") / UnitHealthMax("player")) * 100)
        local targetHp = "0%"
        if UnitExists("target") then
            targetHp = string.format("%.0f%%", (UnitHealth("target") / UnitHealthMax("target")) * 100)
        end
        local logEntry = string.format("[%s] Rage:%d HP:%s Target:%s | %s", timestamp, rage, hp, targetHp, msg)
        table.insert(Fury_DebugLog, logEntry)
    end
    
    if Fury_Configuration and Fury_Configuration["Debug"] then
        self:Print(msg)
    end
    
    FuryRageDumped = nil
end


--------------------------------------------------
-- Event Registration
--------------------------------------------------
function Fury:OnLoad()
    local events = {
        "CHARACTER_POINTS_CHANGED",
        "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES",
        "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES",
        "CHAT_MSG_COMBAT_SELF_MISSES",
        "CHAT_MSG_MONSTER_EMOTE",
        "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
        "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE",
        "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE",
        "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS",
        "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE",
        "CHAT_MSG_SPELL_SELF_DAMAGE",
        "PLAYER_AURAS_CHANGED",
        "PLAYER_ENTER_COMBAT",
        "PLAYER_ENTERING_WORLD",
        "PLAYER_LEAVE_COMBAT",
        "PLAYER_REGEN_DISABLED",
        "PLAYER_REGEN_ENABLED",
        "PLAYER_TARGET_CHANGED",
        "SPELLCAST_FAILED",
        "SPELLCAST_INTERRUPTED",
        "UNIT_CASTEVENT",
        "UNIT_COMBAT",
        "UNIT_INVENTORY_CHANGED",
        "VARIABLES_LOADED"
    }
    
    for _, event in pairs(events) do
        this:RegisterEvent(event)
    end
    
    SLASH_FURY1 = "/fury"
    SLASH_FURY2 = "/fu"
    SlashCmdList["FURY"] = function(msg)
        if not Fury.Commands then
            DEFAULT_CHAT_FRAME:AddMessage("ERROR: Fury.Commands not loaded!")
            return
        end
        if not Fury.Commands.Handle then
            DEFAULT_CHAT_FRAME:AddMessage("ERROR: Fury.Commands.Handle not found!")
            return
        end
        Fury.Commands:Handle(msg)
    end
    
    -- Confirm slash commands are registered
    DEFAULT_CHAT_FRAME:AddMessage("Fury: Slash commands /fury and /fu registered.")
end

--------------------------------------------------
-- Auto-Attack Check (called periodically)
--------------------------------------------------
function Fury:CheckAutoAttack()
    -- Only check every 0.5 seconds to avoid spam
    if FuryLastAutoAttackCheck + 0.5 > GetTime() then
        return
    end
    FuryLastAutoAttackCheck = GetTime()
    
    -- Re-enable auto attack if needed (only in combat to avoid spam out of combat)
    if FuryCombat and Fury.Utils then
        Fury.Utils:EnableAutoAttack()
    end
end

--------------------------------------------------
-- Event Handler
--------------------------------------------------
function Fury:OnEvent(event)
    if event == "VARIABLES_LOADED" then
        self:Initialize()
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Scan talents on login/zone change as fallback
        if not FuryTalents then
            Fury.Talents:Scan()
        end
        
    elseif event == "PLAYER_TARGET_CHANGED" then
        FuryOverpower = nil
        FurySpellInterrupt = nil
        
    elseif event == "CHARACTER_POINTS_CHANGED" then
        Fury.Talents:Scan()
        
    elseif event == "PLAYER_ENTER_COMBAT" then
        FuryAttack = true
        
    elseif event == "PLAYER_LEAVE_COMBAT" then
        FuryAttack = false
        
    elseif event == "PLAYER_REGEN_DISABLED" then
        FuryCombat = true
        
    elseif event == "PLAYER_REGEN_ENABLED" then
        FuryCombat = false
        FuryFleeing = false
        
    elseif event == "PLAYER_AURAS_CHANGED" then
        if UnitIsMounted and UnitIsMounted("player") then
            FuryMount = true
        else
            FuryMount = nil
        end
        
    elseif event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" or event == "CHAT_MSG_COMBAT_SELF_MISSES" then
        Fury.EventHandlers:HandleDodge(arg1)
        
    elseif event == "CHAT_MSG_MONSTER_EMOTE" then
        Fury.EventHandlers:HandleRunner(arg1, arg2)
        
    elseif event == "CHAT_MSG_SPELL_CREATURE_VS_CREATURE_DAMAGE" or 
           event == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE" then
        Fury.EventHandlers:HandleSpellcast(arg1)
        
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_BUFFS" then
        Fury.EventHandlers:HandleBuffs(arg1)
        
    elseif event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" then
        Fury.EventHandlers:HandleDebuffs(arg1)
        
    elseif event == "CHAT_MSG_SPELL_SELF_DAMAGE" then
        Fury.EventHandlers:HandleAbilities(arg1)
        
    elseif event == "UNIT_COMBAT" then
        Fury.EventHandlers:HandleCombat(arg1, arg2)
        
    elseif event == "SPELLCAST_FAILED" or event == "SPELLCAST_INTERRUPTED" then
        Fury.EventHandlers:HandleSpellFailed(arg1)
    end
    
    -- Forward relevant events to SwingTimer
    if Fury.SwingTimer and (
       event == "PLAYER_ENTERING_WORLD" or
       event == "PLAYER_REGEN_ENABLED" or
       event == "PLAYER_REGEN_DISABLED" or
       event == "CHARACTER_POINTS_CHANGED" or
       event == "UNIT_CASTEVENT" or
       event == "UNIT_INVENTORY_CHANGED" or
       event == "CHAT_MSG_COMBAT_CREATURE_VS_SELF_MISSES" or
       event == "CHAT_MSG_SPELL_CREATURE_VS_SELF_DAMAGE" or
       event == "CHAT_MSG_COMBAT_HOSTILEPLAYER_MISSES" or
       event == "CHAT_MSG_SPELL_HOSTILEPLAYER_DAMAGE") then
        Fury.SwingTimer:OnEvent(event)
    end
end

-- Legacy function wrappers for XML compatibility
function Fury_OnLoad()
    if type(Fury) == "table" then
        Fury:OnLoad()
    end
end

function Fury_OnEvent(event)
    if type(Fury) == "table" then
        Fury:OnEvent(event)
    end
end

-- Legacy wrapper - no longer has a default rotation
-- Use /fury single or /fury multi instead
function Fury_Execute()
    if type(Fury) == "table" and Fury.Print then
        Fury:Print("Keine Standard-Rotation! Nutze '/fury single' oder '/fury multi'")
    end
end
