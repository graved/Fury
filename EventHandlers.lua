Fury.EventHandlers = {}

-- Flurry tracking variables
FuryFlurryStart = nil
FuryCombatStart = nil
FuryCombatEnd = nil
FuryAttackStart = nil
FuryAttackEnd = nil
FlurryCombatTotal = 0
FuryCombatTotal = 0

--------------------------------------------------
-- Handle Dodge Events
--------------------------------------------------
function Fury.EventHandlers:HandleDodge(arg1)
    if string.find(arg1, CHAT_OVERPOWER1_FURY) or string.find(arg1, CHAT_OVERPOWER2_FURY) then
        FuryOverpower = GetTime()
    end
end

--------------------------------------------------
-- Handle Runner Detection
--------------------------------------------------
function Fury.EventHandlers:HandleRunner(arg1, arg2)
    if arg1 == CHAT_RUNNER_FURY then
        Fury_Runners[arg2] = true
        FuryFleeing = true
    end
end

--------------------------------------------------
-- Handle Spellcasting
--------------------------------------------------
function Fury.EventHandlers:HandleSpellcast(arg1)
    for mob, spell in string.gfind(arg1, CHAT_CAST_FURY) do
        if mob == UnitName("target") and UnitCanAttack("player", "target") and mob ~= spell then
            FurySpellInterrupt = GetTime()
            return
        end
    end
end

--------------------------------------------------
-- Handle Buffs
--------------------------------------------------
function Fury.EventHandlers:HandleBuffs(arg1)
    if arg1 == CHAT_GAINED_FLURRY_FURY then
        FuryFlurryStart = GetTime()
    end
end

--------------------------------------------------
-- Handle Debuffs
--------------------------------------------------
function Fury.EventHandlers:HandleDebuffs(arg1)
    -- Incapacitate effects
    if arg1 == CHAT_SAP_FURY or 
       arg1 == CHAT_GOUGE_FURY or 
       arg1 == CHAT_REPENTANCE_FURY or 
       arg1 == CHAT_ROCKET_HELM_FURY then
        FuryIncapacitate = true
    -- Fear effects
    elseif arg1 == CHAT_FEAR_FURY or 
           arg1 == CHAT_INTIMIDATING_SHOUT_FURY or 
           arg1 == CHAT_PSYCHIC_SCREAM_FURY or 
           arg1 == CHAT_PANIC_FURY or 
           arg1 == CHAT_BELLOWING_ROAR_FURY or 
           arg1 == CHAT_ANCIENT_DESPAIR_FURY or 
           arg1 == CHAT_TERRIFYING_SCREECH_FURY or 
           arg1 == CHAT_HOWL_OF_TERROR_FURY then
        FuryFear = true
    end
end

--------------------------------------------------
-- Handle Debuff Removal
--------------------------------------------------
function Fury.EventHandlers:HandleDebuffRemoval(arg1)
    -- Incapacitate fades
    if arg1 == CHAT_SAP2_FURY or 
       arg1 == CHAT_GOUGE2_FURY or 
       arg1 == CHAT_REPENTANCE2_FURY or 
       arg1 == CHAT_ROCKET_HELM2_FURY then
        FuryIncapacitate = nil
    -- Fear fades
    elseif arg1 == CHAT_FEAR2_FURY or 
           arg1 == CHAT_INTIMIDATING_SHOUT2_FURY or 
           arg1 == CHAT_PSYCHIC_SCREAM2_FURY or 
           arg1 == CHAT_PANIC2_FURY or 
           arg1 == CHAT_BELLOWING_ROAR2_FURY or 
           arg1 == CHAT_ANCIENT_DESPAIR2_FURY or 
           arg1 == CHAT_TERRIFYING_SCREECH2_FURY or 
           arg1 == CHAT_HOWL_OF_TERROR2_FURY then
        FuryFear = nil
    -- Flurry fades
    elseif arg1 == CHAT_LOST_FLURRY_FURY then
        if FuryFlurryStart then
            FlurryCombatTotal = FlurryCombatTotal + (GetTime() - FuryFlurryStart)
            FuryFlurryStart = nil
        end
        if FuryAttackEnd and FuryFlurry and (FlurryCombatTotal > 0) and (FuryCombatTotal > 0) then
            local p = math.floor(FlurryCombatTotal / FuryCombatTotal * 100)
            Fury:Debug(TEXT_FURY_FLURRY .. p .. "%")
            FlurryCombatTotal = 0
            FuryCombatTotal = 0
        end
    end
end

--------------------------------------------------
-- Handle Abilities
--------------------------------------------------
function Fury.EventHandlers:HandleAbilities(arg1)
    -- Overpower used
    if string.find(arg1, CHAT_OVERPOWER3_FURY) or 
       string.find(arg1, CHAT_OVERPOWER4_FURY) or 
       string.find(arg1, CHAT_OVERPOWER5_FURY) then
        FuryOverpower = nil
    end
    
    -- Interrupt used
    if string.find(arg1, CHAT_INTERRUPT1_FURY) then
        FurySpellInterrupt = nil
    end
end

--------------------------------------------------
-- Handle Combat Events
--------------------------------------------------
function Fury.EventHandlers:HandleCombat(arg1, arg2)
    -- Revenge trigger
    if string.find(arg1, CHAT_BLOCK_FURY) or 
       string.find(arg1, CHAT_PARRY_FURY) or 
       string.find(arg1, CHAT_DODGE_FURY) then
        FuryRevengeReadyUntil = GetTime() + 4
    end
    
    -- Interrupt miss
    if string.find(arg1, CHAT_INTERRUPT2_FURY) or 
       string.find(arg1, CHAT_INTERRUPT3_FURY) or 
       string.find(arg1, CHAT_INTERRUPT4_FURY) or 
       string.find(arg1, CHAT_INTERRUPT5_FURY) then
        FurySpellInterrupt = nil
    end
end

--------------------------------------------------
-- Handle Spell Failed
--------------------------------------------------
function Fury.EventHandlers:HandleSpellFailed(arg1)
    if arg1 then
        -- Check for disarm immunity
        if string.find(arg1, CHAT_DISARM_IMMUNE_FURY) then
            local _, _, target = string.find(arg1, CHAT_DISARM_IMMUNE_FURY)
            if target then
                Fury_ImmuneDisarm[target] = true
                Fury:Debug(target .. " is immune to disarm")
            end
        end
    end
end

--------------------------------------------------
-- Combat Enter
--------------------------------------------------
function Fury.EventHandlers:OnCombatEnter()
    FuryCombat = true
    FuryCombatStart = GetTime()
    FlurryCombatTotal = 0
    FuryCombatTotal = 0
    
    if not FuryAttackStart then
        FuryAttackEnd = nil
        FuryAttackStart = FuryCombatStart
    end
    
    if Fury.Utils:HasBuff("player", "Ability_GhoulFrenzy") then
        FuryFlurryStart = GetTime()
    end
end

--------------------------------------------------
-- Combat Leave
--------------------------------------------------
function Fury.EventHandlers:OnCombatLeave()
    FuryCombatEnd = GetTime()
    FuryCombat = nil
    FuryDanceDone = nil
    FuryOldStance = nil
    FuryFlurryStart = nil
    FuryFleeing = false
    
    if FuryFlurry and (FlurryCombatTotal > 0) and (FuryCombatTotal > 0) then
        local p = math.floor(FlurryCombatTotal / FuryCombatTotal * 100)
        Fury:Debug(TEXT_FURY_FLURRY .. p .. "%")
        FlurryCombatTotal = 0
        FuryCombatTotal = 0
    end
    
    -- Check for items on cooldown
    for slot = 1, 18 do
        local name = Fury.Utils:CheckCooldown(slot)
        if name then
            Fury:Print(name .. " " .. CHAT_IS_ON_CD_FURY)
        end
    end
end

--------------------------------------------------
-- Attack Enter
--------------------------------------------------
function Fury.EventHandlers:OnAttackEnter()
    FuryAttack = true
    FuryAttackEnd = nil
    FuryAttackStart = GetTime()
    
    if Fury.Utils:HasBuff("player", "Ability_GhoulFrenzy") then
        FuryFlurryStart = GetTime()
    end
end

--------------------------------------------------
-- Attack Leave
--------------------------------------------------
function Fury.EventHandlers:OnAttackLeave()
    FuryAttack = false
    FuryAttackEnd = GetTime()
    FuryCombatTotal = FuryCombatTotal + (FuryAttackEnd - FuryAttackStart)
    FuryAttackStart = nil
end
