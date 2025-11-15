--------------------------------------------------
-- 34-42. Cooldowns (Racials only - Death Wish is manual)
--------------------------------------------------
function Fury.DecisionTree:TryCooldowns()
    if not FuryCombat then return false end
    if not FuryAttack then return false end
    
    -- Berserking (Troll Racial)
    if self:TryBerserking() then return true end
    
    -- Blood Fury (Orc Racial)
    if self:TryBloodFury() then return true end
    
    -- NOTE: Death Wish removed from auto rotation per guide
    -- Use manually via keybind or macro for precise timing
    
    return false
end

function Fury.DecisionTree:TryBerserking()
    if not FuryRacialBerserking then return false end
    if not Fury_Configuration[RACIAL_BERSERKING_FURY] then return false end
    if UnitMana("player") < 5 then return false end
    if (UnitHealth("player") / UnitHealthMax("player") * 100) > tonumber(Fury_Configuration["BerserkHealth"]) then return false end
    if Fury.Utils:HasBuff("player", "Racial_Berserk") then return false end
    if not Fury.Utils:IsSpellReady(RACIAL_BERSERKING_FURY) then return false end
    
    Fury:Debug("40. Berserking")
    CastSpellByName(RACIAL_BERSERKING_FURY)
    FuryLastSpellCast = GetTime()
    return true
end

function Fury.DecisionTree:TryBloodFury()
    if not FuryRacialBloodFury then return false end
    if not Fury_Configuration[RACIAL_BLOOD_FURY] then return false end
    if Fury.Utils:GetActiveStance() == 2 then return false end
    if not Fury.Utils:IsSpellReady(RACIAL_BLOOD_FURY) then return false end
    
    Fury:Debug("41. Blood Fury")
    CastSpellByName(RACIAL_BLOOD_FURY)
    return true
end

--------------------------------------------------
-- 46. Bloodrage
--------------------------------------------------
function Fury.DecisionTree:TryBloodrage()
    if not Fury_Configuration[ABILITY_BLOODRAGE_FURY] then return false end
    if UnitMana("player") > tonumber(Fury_Configuration["MaximumRage"]) then return false end
    if (UnitHealth("player") / UnitHealthMax("player") * 100) < tonumber(Fury_Configuration["BloodrageHealth"]) then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_BLOODRAGE_FURY) then return false end
    
    -- Don't use Bloodrage before combat if we can still Charge!
    -- Bloodrage puts you in combat and prevents Charge!
    if not FuryCombat and UnitExists("target") then
        -- If Charge is ready and target is not in melee range, wait for Charge!
        if Fury_Configuration[ABILITY_CHARGE_FURY] and 
           Fury.Utils:IsSpellReady(ABILITY_CHARGE_FURY) and
           not CheckInteractDistance("target", 1) then
            return false
        end
    end
    
    Fury:Debug("46. Bloodrage")
    CastSpellByName(ABILITY_BLOODRAGE_FURY)
    return true
end

--------------------------------------------------
-- 50-53. Rage Dump
--------------------------------------------------
function Fury.DecisionTree:TryRageDump()
    -- Check if we should dump rage
    local shouldDump = self:IsMultiMode() or
                      Fury_Configuration["PrimaryStance"] == 2 or
                      ((Fury_Configuration[ABILITY_MORTAL_STRIKE_FURY] and FuryMortalStrike and 
                        not Fury.Utils:IsSpellReady(ABILITY_MORTAL_STRIKE_FURY)) or 
                       not Fury_Configuration[ABILITY_MORTAL_STRIKE_FURY] or not FuryMortalStrike) and
                      ((Fury_Configuration[ABILITY_BLOODTHIRST_FURY] and FuryBloodthirst and 
                        not Fury.Utils:IsSpellReady(ABILITY_BLOODTHIRST_FURY)) or 
                       not Fury_Configuration[ABILITY_BLOODTHIRST_FURY] or not FuryBloodthirst) and
                      ((Fury_Configuration[ABILITY_WHIRLWIND_FURY] and 
                        not Fury.Utils:IsSpellReady(ABILITY_WHIRLWIND_FURY)) or 
                       not Fury_Configuration[ABILITY_WHIRLWIND_FURY] or not FuryWhirlwind)
    
    if not shouldDump then
        if not FuryRageDumped then
            FuryRageDumped = true
        end
        return false
    end
    
    -- Try Sunder (trigger procs at high rage)
    if self:TrySunderProc() then return true end
    
    -- Try Hamstring (trigger procs)
    if self:TryHamstringTrigger() then return true end
    
    -- Try Heroic Strike
    if self:TryHeroicStrike() then return true end
   
    if not FuryRageDumped then
        FuryRageDumped = true
    end
    
    return false
end

function Fury.DecisionTree:TrySunderProc()
    if not Fury_Configuration[ABILITY_SUNDER_ARMOR_FURY] then return false end
    if UnitMana("player") < 60 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_SUNDER_ARMOR_FURY) then return false end
    
    -- Only use on Bosses (same check as TrySunderArmor)
    local targetLevel = UnitLevel("target")
    local classification = UnitClassification("target")
    
    if classification ~= "worldboss" and 
       classification ~= "rareelite" and 
       not (classification == "elite" and targetLevel == -1) and
       targetLevel ~= 63 then
        return false
    end
    
    -- Use Sunder to trigger procs when rage > 60
    -- Guide: "Master Strike/Pummel/Hamstring/Sunder solely to proc windfury/flurry/crusader"
    Fury:Debug("50. Sunder Armor (Proc trigger, rage > 60)")
    CastSpellByName(ABILITY_SUNDER_ARMOR_FURY)
    -- DON'T update FuryLastSunder - this is just for procs, not for uptime tracking!
    FuryLastSpellCast = GetTime()
    return true
end

function Fury.DecisionTree:TryHamstringTrigger()
    if not Fury_Configuration[ABILITY_HAMSTRING_FURY] then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < Fury.Utils:HamstringCost() then return false end
    if UnitMana("player") < tonumber(Fury_Configuration["FlurryTriggerRage"]) then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_HAMSTRING_FURY) then return false end
    
    -- Check if we want to trigger procs
    local shouldTrigger = (FuryFlurry and not Fury.Utils:HasBuff("player", "Ability_GhoulFrenzy")) or
                         FuryImpHamstring or FurySwordSpec or FuryMaceSpec
    
    if shouldTrigger then
        Fury:Debug("51. Hamstring (Trigger ...)")
        CastSpellByName(ABILITY_HAMSTRING_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end

function Fury.DecisionTree:TryHeroicStrike()
    if not Fury_Configuration[ABILITY_HEROIC_STRIKE_FURY] then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if self:IsMultiMode() then return false end
    if UnitMana("player") < FuryHeroicStrikeCost then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_HEROIC_STRIKE_FURY) then return false end
    
    -- Heroic Strike is LOW PRIO for 2H Fury
    -- Guide: "2H fury: Heroic Strike is very low prio. Use Slam instead"
    if Fury.Utils:Is2HFury() then
        -- Only use HS for 2H Fury if rage is capping (95+)
        -- AND all major abilities are on CD
        if UnitMana("player") < 95 then return false end
        
        -- Don't use if Bloodthirst, Whirlwind, or Slam will be ready soon
        if Fury.Utils:IsSpellReadyIn(ABILITY_BLOODTHIRST_FURY) <= 2 then return false end
        if Fury.Utils:IsSpellReadyIn(ABILITY_WHIRLWIND_FURY) <= 2 then return false end
        if Fury_Configuration[ABILITY_SLAM_FURY] and Fury.Utils:IsSpellReady(ABILITY_SLAM_FURY) then 
            return false 
        end
        
        -- Rage is capping, all abilities on CD - use HS to avoid waste
        Fury:Debug("52. Heroic Strike (2H Fury rage cap)")
        CastSpellByName(ABILITY_HEROIC_STRIKE_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    -- For DW Fury: Check if we have enough rage
    local hasEnoughRage = UnitMana("player") >= tonumber(Fury_Configuration["NextAttackRage"]) or
                         (not FuryMortalStrike and not FuryWhirlwind and not FuryBloodthirst) or
                         Fury_Configuration["PrimaryStance"] == 2
    
    if hasEnoughRage then
        Fury:Debug("52. Heroic Strike")
        CastSpellByName(ABILITY_HEROIC_STRIKE_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end

function Fury.DecisionTree:TryCleave()
    local isMulti = self:IsMultiMode()
    if not Fury_Configuration[ABILITY_CLEAVE_FURY] and not isMulti then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < 20 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_CLEAVE_FURY) then return false end
    
    -- Check if we have enough rage
    local hasEnoughRage
    if isMulti then
        hasEnoughRage = UnitMana("player") >= 25
    else
        hasEnoughRage = UnitMana("player") >= tonumber(Fury_Configuration["NextAttackRage"]) or
                         Fury_Configuration["PrimaryStance"] == 2
    end
    
    if hasEnoughRage then
        Fury:Debug("53. Cleave")
        CastSpellByName(ABILITY_CLEAVE_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end

--------------------------------------------------
-- AoE Rage Dump (Multi Target Mode)
--------------------------------------------------
function Fury.DecisionTree:TryRageDumpAoE()
    -- For Multi-Target, prioritize Cleave over Heroic Strike
    -- Skip Sunder procs and Hamstring triggers in AoE
    
    -- Try Cleave (HIGH PRIO for AoE)
    if self:TryCleaveAoE() then return true end
    
    -- Try Heroic Strike as fallback if Cleave not available
    if self:TryHeroicStrikeAoE() then return true end
    
    if not FuryRageDumped then
        FuryRageDumped = true
    end
    
    return false
end

function Fury.DecisionTree:TryCleaveAoE()
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < 20 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_CLEAVE_FURY) then return false end
    
    -- In AoE mode, use Cleave more aggressively
    if UnitMana("player") >= 25 then
        Fury:Debug("53. Cleave (AoE)")
        CastSpellByName(ABILITY_CLEAVE_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end

function Fury.DecisionTree:TryHeroicStrikeAoE()
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < FuryHeroicStrikeCost then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_HEROIC_STRIKE_FURY) then return false end
    
    -- Use HS in AoE only if Cleave is not available and rage is high
    if UnitMana("player") >= 40 then
        Fury:Debug("52. Heroic Strike (AoE fallback)")
        CastSpellByName(ABILITY_HEROIC_STRIKE_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end
