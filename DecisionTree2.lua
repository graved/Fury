--------------------------------------------------
-- Constants
--------------------------------------------------
local GCD_TIME = 1.5        -- Global Cooldown duration
local SLAM_CAST_TIME = 1.5  -- Slam spell cast time

--------------------------------------------------
-- 16. Rend (Anti-Stealth)
--------------------------------------------------
function Fury.DecisionTree:TryRend()
    if not Fury_Configuration[ABILITY_REND_FURY] then return false end
    if not UnitIsPlayer("target") then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < 10 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_REND_FURY) then return false end
    if Fury.Utils:HasAntiStealthDebuff() then return false end
    
    -- Only use against rogues and hunters
    if UnitClass("target") ~= CLASS_ROGUE_FURY and UnitClass("target") ~= CLASS_HUNTER_FURY then
        return false
    end
    
    local stance = Fury.Utils:GetActiveStance()
    if stance == 3 then
        if UnitMana("player") <= (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) and
           Fury_Configuration["PrimaryStance"] ~= 0 then
            if not FuryOldStance then
                FuryOldStance = stance
            end
            Fury:Debug("16. Battle Stance (Rend)")
            Fury.Utils:DoShapeShift(1)
            return true
        end
        return false
    end
    
    Fury:Debug("16. Rend")
    if FuryOldStance == 3 then
        FuryDanceDone = true
    end
    CastSpellByName(ABILITY_REND_FURY)
    return true
end


--------------------------------------------------
-- 18. Rooted Actions
--------------------------------------------------
function Fury.DecisionTree:TryRootedActions(debuffImmobilizing)
    if not debuffImmobilizing then return false end
    if Fury.Utils:Distance() < 8 then return false end
    
    -- Try Berserker Rage first (breaks Fear/Sap/Incapacitate, requires Berserker Stance)
    if FuryBerserkerRage and 
       Fury_Configuration[ABILITY_BERSERKER_RAGE_FURY] and
       Fury.Utils:IsSpellReady(ABILITY_BERSERKER_RAGE_FURY) then
        
        local stance = Fury.Utils:GetActiveStance()
        if stance ~= 3 then
            Fury:Debug("18. Berserker Stance (Berserker Rage)")
            Fury.Utils:DoShapeShift(3)
            return true
        end
        
        Fury:Debug("18. Berserker Rage (break CC)")
        CastSpellByName(ABILITY_BERSERKER_RAGE_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    -- If Berserker Rage not available, go defensive to reduce damage
    local stance = Fury.Utils:GetActiveStance()
    if stance ~= 2 then
        Fury:Debug("18. Defensive Stance (Rooted)")
        Fury.Utils:DoShapeShift(2)
        return true
    end
    
    if FuryOldStance == 2 then
        FuryDanceDone = true
    end
    
    -- Shoot ranged weapon
    return Fury.Actions:Shoot()
end


--------------------------------------------------
-- 20. Primary Stance Dance
--------------------------------------------------
function Fury.DecisionTree:TryPrimaryStanceDance()
    if not Fury_Configuration["PrimaryStance"] then return false end
    if Fury_Configuration["PrimaryStance"] == false then return false end
    if FuryOldStance then return false end
    if FuryDanceDone then return false end
    if Fury_Configuration["PrimaryStance"] == 3 and not FuryBerserkerStance then return false end
    if Fury_Configuration["PrimaryStance"] == Fury.Utils:GetActiveStance() then return false end
    if Fury_Configuration["PrimaryStance"] == 0 then return false end
    if UnitMana("player") > (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) then return false end
    
    if FuryLastStanceCast and FuryLastStanceCast + 1 > GetTime() then
        return false
    end
    
    Fury:Debug("20. Primary Stance (" .. Fury_Configuration["PrimaryStance"] .. ")")
    Fury.Utils:DoShapeShift(Fury_Configuration["PrimaryStance"])
    return true
end

--------------------------------------------------
-- 21. Disarm (PVP)
--------------------------------------------------
function Fury.DecisionTree:TryDisarm()
    if not Fury_Configuration[ABILITY_DISARM_FURY] then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if not UnitIsPlayer("target") then return false end
    if UnitMana("player") < 20 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_DISARM_FURY) then return false end
    if Fury_ImmuneDisarm[UnitName("target")] then return false end
    
    -- Only disarm physical classes
    local targetClass = UnitClass("target")
    if targetClass ~= CLASS_HUNTER_FURY and
       targetClass ~= CLASS_PALADIN_FURY and
       targetClass ~= CLASS_ROGUE_FURY and
       targetClass ~= CLASS_SHAMAN_FURY and
       targetClass ~= CLASS_WARRIOR_FURY then
        return false
    end
    
    local stance = Fury.Utils:GetActiveStance()
    if stance == 2 or
       (UnitMana("player") <= (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) and
        Fury_Configuration["PrimaryStance"] ~= 0) then
        
        if stance ~= 2 then
            if not FuryOldStance then
                FuryOldStance = stance
            end
            Fury:Debug("21. Defensive Stance (Disarm)")
            Fury.Utils:DoShapeShift(2)
            return true
        end
        
        Fury:Debug("21. Disarm")
        if FuryOldStance ~= 2 then
            FuryDanceDone = true
        end
        CastSpellByName(ABILITY_DISARM_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end

--------------------------------------------------
-- 22-32. Main Rotation Abilities
--------------------------------------------------

function Fury.DecisionTree:TrySweepingStrikes()
    if not FurySweepingStrikes then return false end
    if not Fury_Configuration[ABILITY_SWEEPING_STRIKES_FURY] then return false end
    if UnitMana("player") < 30 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_SWEEPING_STRIKES_FURY) then return false end
    
    Fury:Debug("22. Sweeping Strikes")
    CastSpellByName(ABILITY_SWEEPING_STRIKES_FURY)
    return true
end

function Fury.DecisionTree:TryBloodthirst()
    if not FuryBloodthirst then return false end
    if not Fury_Configuration[ABILITY_BLOODTHIRST_FURY] then return false end
    if UnitMana("player") < 30 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_BLOODTHIRST_FURY) then return false end
    
    Fury:Debug("23. Bloodthirst")
    CastSpellByName(ABILITY_BLOODTHIRST_FURY)
    FuryLastSpellCast = GetTime()
    return true
end

function Fury.DecisionTree:TryMortalStrike()
    if not FuryMortalStrike then return false end
    if not Fury_Configuration[ABILITY_MORTAL_STRIKE_FURY] then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < 30 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_MORTAL_STRIKE_FURY) then return false end
    
    Fury:Debug("24. Mortal Strike")
    CastSpellByName(ABILITY_MORTAL_STRIKE_FURY)
    FuryLastSpellCast = GetTime()
    return true
end

function Fury.DecisionTree:TryWhirlwind()
    if not Fury_Configuration[ABILITY_WHIRLWIND_FURY] then return false end
    if Fury.Utils:Distance() > 10 then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < 25 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_WHIRLWIND_FURY) then return false end
    
    -- Don't clip Bloodthirst CD: If WW has <1s CD and BT has <2s CD, wait for BT
    if FuryBloodthirst and Fury_Configuration[ABILITY_BLOODTHIRST_FURY] then
        local btReady = Fury.Utils:IsSpellReadyIn(ABILITY_BLOODTHIRST_FURY)
        if btReady <= 2 and btReady > 0 then
            Fury:Debug("25. Wait for Bloodthirst (don't clip)")
            return false
        end
    end
    
    local stance = Fury.Utils:GetActiveStance()
    
    -- If already in Berserker or Primary is Berserker or we can stance dance
    local canCast = stance == 3 or
                    Fury_Configuration["PrimaryStance"] == 3 or
                    (Fury_Configuration["PrimaryStance"] ~= 2 and
                     UnitMana("player") <= (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) and
                     Fury_Configuration["PrimaryStance"] ~= 0)
    
    if canCast then
        if stance ~= 3 then
            if not FuryOldStance then
                FuryOldStance = stance
            end
            Fury:Debug("25. Berserker Stance (Whirlwind)")
            Fury.Utils:DoShapeShift(3)
            return true
        end
        
        Fury:Debug("25. Whirlwind")
        if FuryOldStance ~= 3 then
            FuryDanceDone = true
        end
        CastSpellByName(ABILITY_WHIRLWIND_FURY)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end

function Fury.DecisionTree:TrySlam()
    -- Slam is primarily for 2H Fury
    -- Cast after each swing hit as main rage dump
    -- Guide: "Slam right after your swing hits. Slam pauses swing timer"
    
    -- Basic checks
    if not Fury_Configuration[ABILITY_SLAM_FURY] then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_SLAM_FURY) then return false end
    if UnitMana("player") < 15 then return false end
    if not Fury.Utils:Uses2H() then return false end
    
    -- Don't cast during GCD
    if FuryLastSpellCast and GetTime() - FuryLastSpellCast < GCD_TIME then
        return false
    end
    
    -- SwingTimer check: Need at least SLAM_CAST_TIME before next swing
    -- to avoid interrupting/delaying the swing
    if Fury.SwingTimer and FurySwingTimer and FurySwingTimer < SLAM_CAST_TIME then
        return false
    end
    
    -- Don't clip high priority abilities that will be ready during Slam cast
    if Fury.Utils:IsSpellReadyIn(ABILITY_BLOODTHIRST_FURY) <= SLAM_CAST_TIME then return false end
    if Fury.Utils:IsSpellReadyIn(ABILITY_MORTAL_STRIKE_FURY) <= SLAM_CAST_TIME then return false end
    if Fury.Utils:IsSpellReadyIn(ABILITY_WHIRLWIND_FURY) <= SLAM_CAST_TIME then return false end
    
    Fury:Debug("25a. Slam (2H Fury)")
    CastSpellByName(ABILITY_SLAM_FURY)
    FuryLastSpellCast = GetTime()
    return true
end

function Fury.DecisionTree:TrySunderArmor()
    if not Fury_Configuration[ABILITY_SUNDER_ARMOR_FURY] then return false end
    if UnitMana("player") < 15 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_SUNDER_ARMOR_FURY) then return false end
    
    -- Don't waste Sunder on dying targets
    local targetHpPercent = (UnitHealth("target") / UnitHealthMax("target")) * 100
    if targetHpPercent < 30 then return false end
    
    local targetLevel = UnitLevel("target")
    local playerLevel = UnitLevel("player")
    local classification = UnitClassification("target")
    
    -- Skip if target is too low level (use SunderDiff config)
    local sunderDiff = tonumber(Fury_Configuration["SunderDiff"]) or 7
    if targetLevel > 0 and (playerLevel - targetLevel) >= sunderDiff then
        return false
    end
    
    -- Determine if this is a Boss/Elite/Rare (worth full 5 stacks + refresh)
    local isBoss = classification == "worldboss" or 
                   classification == "rareelite" or 
                   (classification == "elite" and targetLevel == -1) or
                   targetLevel == 63
    
    -- Skip normal mobs (not elite/rare/boss)
    if not isBoss and classification ~= "elite" and classification ~= "rare" then
        return false
    end
    
    -- Check current Sunder stacks
    local sunderStacks = Fury.Utils:GetSunderStacks("target")
    
    -- Check if we're in Multi-Target mode
    local isMultiTarget = self:IsMultiMode()
    
    if isMultiTarget then
        -- Multi-Target: Only apply 1 stack, no refresh
        if sunderStacks < 1 then
            FuryLastSunder = GetTime()
            Fury:Debug("22. Sunder Armor (AoE - 1 stack only)")
            CastSpellByName(ABILITY_SUNDER_ARMOR_FURY)
            FuryLastSpellCast = GetTime()
            return true
        end
    elseif isBoss then
        -- Single Target Boss: Apply up to 5 stacks, then refresh
        if sunderStacks < 5 then
            -- Apply stacks
            if sunderStacks == 0 then
                FuryLastSunder = GetTime()
            end
            Fury:Debug("22. Sunder Armor (apply " .. (sunderStacks + 1) .. "/5)")
            CastSpellByName(ABILITY_SUNDER_ARMOR_FURY)
            FuryLastSpellCast = GetTime()
            return true
        elseif sunderStacks == 5 then
            -- Refresh before expiry (30s duration, refresh at 25s = 5s buffer)
            if GetTime() > FuryLastSunder + 25 then
                Fury:Debug("22. Sunder Armor (refresh)")
                CastSpellByName(ABILITY_SUNDER_ARMOR_FURY)
                FuryLastSunder = GetTime()
                FuryLastSpellCast = GetTime()
                return true
            end
        end
    else
        -- Single Target Elite/Rare (non-boss): Only apply 3 stacks, no refresh
        if sunderStacks < 3 then
            if sunderStacks == 0 then
                FuryLastSunder = GetTime()
            end
            Fury:Debug("22. Sunder Armor (apply " .. (sunderStacks + 1) .. "/3 - Elite)")
            CastSpellByName(ABILITY_SUNDER_ARMOR_FURY)
            FuryLastSpellCast = GetTime()
            return true
        end
    end
    
    return false
end

function Fury.DecisionTree:TryBattleShout()
    if not Fury_Configuration[ABILITY_BATTLE_SHOUT_FURY] then return false end
    if Fury.Utils:HasBuff("player", "Ability_Warrior_BattleShout") then return false end
    if UnitMana("player") < 10 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_BATTLE_SHOUT_FURY) then return false end
    
    Fury:Debug("28. Battle Shout")
    CastSpellByName(ABILITY_BATTLE_SHOUT_FURY)
    FuryLastSpellCast = GetTime()
    return true
end

function Fury.DecisionTree:TryDemoralizingShout()
    if not Fury_Configuration[ABILITY_DEMORALIZING_SHOUT_FURY] then return false end
    if Fury.Utils:HasDebuff("target", "Ability_Warrior_WarCry") then return false end
    if Fury.Utils:HasDebuff("target", "Ability_Druid_DemoralizingRoar") then return false end
    if UnitMana("player") < 10 then return false end
    if UnitIsPlayer("target") then return false end
    if FuryFleeing then return false end
    if not FuryAttack then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_DEMORALIZING_SHOUT_FURY) then return false end
    if UnitLevel("Player") - UnitLevel("Target") >= Fury_Configuration["DemoDiff"] then return false end
    
    -- Only use on melee classes
    local targetClass = UnitClass("target")
    if targetClass ~= CLASS_WARRIOR_FURY and targetClass ~= CLASS_ROGUE_FURY then
        return false
    end
    
    Fury:Debug("29. Demoralizing Shout")
    CastSpellByName(ABILITY_DEMORALIZING_SHOUT_FURY)
    FuryLastSpellCast = GetTime()
    return true
end


function Fury.DecisionTree:TryReturnStance()
    if not FuryDanceDone then return false end
    if not FuryOldStance then return false end
    if FuryLastStanceCast + 1.5 > GetTime() then return false end
    if UnitMana("player") > (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) then return false end
    
    if not Fury_Configuration["PrimaryStance"] then
        Fury:Debug("33. Old Stance (" .. FuryOldStance .. ")")
        Fury.Utils:DoShapeShift(FuryOldStance)
    elseif Fury_Configuration["PrimaryStance"] ~= 0 then
        Fury:Debug("33. Primary Stance (" .. Fury_Configuration["PrimaryStance"] .. ")")
        Fury.Utils:DoShapeShift(Fury_Configuration["PrimaryStance"])
    end
    
    if FuryOldStance == Fury.Utils:GetActiveStance() or
       Fury_Configuration["PrimaryStance"] == Fury.Utils:GetActiveStance() then
        Fury:Debug("33. Variables cleared (Dance done)")
        FuryOldStance = nil
        FuryDanceDone = nil
    end
    
    return true
end

-- Remaining methods continued in DecisionTree3.lua
