Fury.DecisionTree = {}

function Fury.DecisionTree:IsMultiMode()
    return self.currentMode == "multi"
end

--------------------------------------------------
-- Execute Single Target Rotation (Direct Call)
--------------------------------------------------
function Fury.DecisionTree:ExecuteSingle()
    if not self:CheckPreconditions() then return end
    
    local debuffImmobilizing = Fury.Utils:HasImmobilizingDebuff()
    
    self.currentMode = "single"
    self:ExecuteCommonSetup()
    if self:ExecuteCommonPriorities(debuffImmobilizing) then
        return
    end
    
    -- Execute Single Target rotation
    self:ExecuteSingleTargetRotation(debuffImmobilizing)
end

--------------------------------------------------
-- Execute Multi Target Rotation (Direct Call)
--------------------------------------------------
function Fury.DecisionTree:ExecuteMulti()
    if not self:CheckPreconditions() then return end
    
    local debuffImmobilizing = Fury.Utils:HasImmobilizingDebuff()
    
    self.currentMode = "multi"
    self:ExecuteCommonSetup()
    if self:ExecuteCommonPriorities(debuffImmobilizing) then
        return
    end
    
    -- Execute Multi Target rotation
    self:ExecuteMultiTargetRotation(debuffImmobilizing)
end

--------------------------------------------------
-- Check Preconditions
--------------------------------------------------
function Fury.DecisionTree:CheckPreconditions()
    if UnitIsCivilian("target") then
        return false
    end
    
    if UnitClass("player") ~= CLASS_WARRIOR_FURY then
        return false
    end
    
    if not FuryTalents then
        return false
    end
    
    return true
end

--------------------------------------------------
-- Common Setup (Auto Attack, Timers)
--------------------------------------------------
function Fury.DecisionTree:ExecuteCommonSetup()
    -- 1. Auto Attack
    Fury.Utils:EnableAutoAttack()
    
    -- 2-4. Timer Management
    self:ManageTimers()
end

--------------------------------------------------
-- Common Priorities (for both rotations)
--------------------------------------------------
function Fury.DecisionTree:ExecuteCommonPriorities(debuffImmobilizing)
    -- 5. Dismount if mounted
    if self:TryDismount() then return true end
    
    -- 6. Berserker Rage (fear/incapacitate break)
    if self:TryBerserkerRage(debuffImmobilizing) then return true end
    
    -- 7. Immobilize Breakers (Improved Berserker Rage)
    if self:TryImmobilizeBreakers(debuffImmobilizing) then return true end
    
    return false
end

--------------------------------------------------
-- Single Target Rotation
--------------------------------------------------
function Fury.DecisionTree:ExecuteSingleTargetRotation(debuffImmobilizing)
    -- 8. Execute (with Bloodthirst > Execute logic at AP >= 2000)
    if self:TryExecute() then return end
    
    -- 9. Spell Interrupts (HIGH PRIO for fast reaction)
    if self:TryInterrupts() then return end
    
    -- 10. Battle Shout (keep buff active)
    if self:TryBattleShout() then return end
    
    -- 11. Hamstring (runners)
    if self:TryHamstring() then return end
    
    -- 12. Rend (anti-stealth)
    if self:TryRend() then return end
    
    -- 13. Rooted (Berserker Rage / Shoot)
    if self:TryRootedActions(debuffImmobilizing) then return end
    
    -- 14. Primary Stance Dance
    if self:TryPrimaryStanceDance() then return end
    
    -- 15. Disarm (PVP)
    if self:TryDisarm() then return end
    
    -- 16. Sunder Armor (apply + refresh, intelligent mob filtering)
    if self:TrySunderArmor() then return end
    
    -- 17. Bloodthirst
    if self:TryBloodthirst() then return end
    
    -- 18. Mortal Strike
    if self:TryMortalStrike() then return end
    
    -- 19. Whirlwind
    if self:TryWhirlwind() then return end
    
    -- 20. Slam (2H Fury - after each swing, main rage dump)
    if self:TrySlam() then return end
    
    -- 21. Overpower (only when rage/global is free, after main rotation)
    if self:TryOverpower() then return end
    
    -- 22. Demoralizing Shout
    if self:TryDemoralizingShout() then return end
    
    -- 23. Stance Dance (return)
    if self:TryReturnStance() then return end
    
    -- 24. Bloodrage
    if self:TryBloodrage() then return end
    
    -- 25. Rage Dump (Heroic Strike)
    if self:TryRageDump() then return end
end

--------------------------------------------------
-- Multi Target (AoE) Rotation
--------------------------------------------------
function Fury.DecisionTree:ExecuteMultiTargetRotation(debuffImmobilizing)
    -- 8. Execute (only if target <20% and rage surplus exists)
    if self:TryExecute() then return end
    
    -- 9. Spell Interrupts (still important)
    if self:TryInterrupts() then return end
    
    -- 10. Battle Shout (keep buff active)
    if self:TryBattleShout() then return end
    
    -- 11. Rooted (Berserker Rage / Shoot)
    if self:TryRootedActions(debuffImmobilizing) then return end
    
    -- 12. Primary Stance Dance
    if self:TryPrimaryStanceDance() then return end
    
    -- 13. Sweeping Strikes (HIGHEST PRIO for AoE - before WW/Cleave)
    if self:TrySweepingStrikes() then return end
    
    -- 14. Whirlwind (CORE AoE - keep on CD!)
    if self:TryWhirlwind() then return end
    
    -- 15. Bloodthirst (good single target damage in AoE)
    if self:TryBloodthirst() then return end
    
    -- 16. Mortal Strike (good single target damage in AoE)
    if self:TryMortalStrike() then return end

    -- 17. Sunder Armor (1 stack only in AoE, low prio)
    if self:TrySunderArmor() then return end

    -- 18. Cleave (CORE AoE - main rage dump for multi-target)
    if self:TryRageDumpAoE() then return end
        
    -- 19. Slam (fallback rage dump if needed)
    if self:TrySlam() then return end
    
    -- 20. Demoralizing Shout (good for AoE threat/mitigation)
    if self:TryDemoralizingShout() then return end
    
    -- 21. Stance Dance (return)
    if self:TryReturnStance() then return end
    
    -- 22. Bloodrage
    if self:TryBloodrage() then return end
end

--------------------------------------------------
-- Timer Management
--------------------------------------------------
function Fury.DecisionTree:ManageTimers()
    -- Reset Overpower timer
    if FuryOverpower and (GetTime() - FuryOverpower) > 4 then
        FuryOverpower = nil
    end
    
    -- Reset interrupt timer
    if FurySpellInterrupt and (GetTime() - FurySpellInterrupt) > 2 then
        FurySpellInterrupt = nil
    end
end

--------------------------------------------------
-- 5. Dismount
--------------------------------------------------
function Fury.DecisionTree:TryDismount()
    if FuryMount then
        Fury:Debug("5. Dismount")
        Dismount()
        FuryMount = nil
        return true
    end
    return false
end

--------------------------------------------------
-- 6. Berserker Rage (Fear/Incapacitate Break)
--------------------------------------------------
function Fury.DecisionTree:TryBerserkerRage(debuffImmobilizing)
    if Fury_Configuration[ABILITY_BERSERKER_RAGE_FURY] and
       (FuryIncapacitate or FuryFear) and
       Fury.Utils:GetActiveStance() == 3 and
       Fury.Utils:IsSpellReady(ABILITY_BERSERKER_RAGE_FURY) then
        Fury:Debug("6. Berserker Rage")
        CastSpellByName(ABILITY_BERSERKER_RAGE_FURY)
        return true
    end
    return false
end

--------------------------------------------------
-- 7. Immobilize Breakers (Improved Berserker Rage)
--------------------------------------------------
function Fury.DecisionTree:TryImmobilizeBreakers(debuffImmobilizing)
    -- Improved Berserker Rage: Break out of movement impairing effects
    -- Rank 1: 50% chance to break, Rank 2: 100% chance
    if debuffImmobilizing and
       FuryImprovedBerserkerRageRank > 0 and
       Fury_Configuration[ABILITY_BERSERKER_RAGE_FURY] and
       Fury.Utils:IsSpellReady(ABILITY_BERSERKER_RAGE_FURY) then
        
        local stance = Fury.Utils:GetActiveStance()
        if stance ~= 3 then
            Fury:Debug("7. Berserker Stance (Improved Berserker Rage)")
            Fury.Utils:DoShapeShift(3)
            return true
        end
        
        local chance = (FuryImprovedBerserkerRageRank == 2) and "100%" or "50%"
        Fury:Debug("8. Berserker Rage (" .. chance .. " break immobilize)")
        CastSpellByName(ABILITY_BERSERKER_RAGE_FURY)
        return true
    end
    
    return false
end

--------------------------------------------------
-- 8. Execute (with Bloodthirst > Execute logic)
--------------------------------------------------
function Fury.DecisionTree:TryExecute()
    if not Fury_Configuration[ABILITY_EXECUTE_FURY] then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if UnitMana("player") < FuryExecuteCost then return false end
    if (UnitHealth("target") / UnitHealthMax("target") * 100) > 20 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_EXECUTE_FURY) then return false end
    
    -- Bloodthirst > Execute when AP >= 2000 and rage 30-60
    -- Execute: 600 + 20*15 = 900 damage at 30 rage
    -- Bloodthirst: 200 + 0.35*AP, breakpoint at 2000 AP
    local rage = UnitMana("player")
    if FuryBloodthirst and
       Fury_Configuration[ABILITY_BLOODTHIRST_FURY] and
       rage >= 30 and rage <= 60 then
        
        local _, _, _, _, _, _, _, _, _, _, attackPower = UnitDamage("player")
        if attackPower >= 2000 and Fury.Utils:IsSpellReady(ABILITY_BLOODTHIRST_FURY) then
            Fury:Debug("8. Bloodthirst (AP >= 2000, better than Execute)")
            CastSpellByName(ABILITY_BLOODTHIRST_FURY)
            FuryLastSpellCast = GetTime()
            return true
        end
    end
    
    local stance = Fury.Utils:GetActiveStance()
    if stance == 2 then
        if Fury_Configuration["PrimaryStance"] ~= 2 and
           rage <= (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) and
           Fury_Configuration["PrimaryStance"] ~= 0 then
            Fury:Debug("8. Berserker Stance (Execute)")
            if not FuryOldStance then
                FuryOldStance = stance
            end
            Fury.Utils:DoShapeShift(1)
            return true
        end
        return false
    end
    
    Fury:Debug("8. Execute")
    if FuryOldStance == stance then
        FuryDanceDone = true
    end
    CastSpellByName(ABILITY_EXECUTE_FURY)
    FuryLastSpellCast = GetTime()
    return true
end

--------------------------------------------------
-- 21. Overpower
--------------------------------------------------
function Fury.DecisionTree:TryOverpower()
    if not Fury_Configuration[ABILITY_OVERPOWER_FURY] then return false end
    if not FuryOverpower then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_OVERPOWER_FURY) then return false end
    
    -- Don't stance dance if we're still in GCD
    if FuryLastSpellCast and GetTime() - FuryLastSpellCast < 1.5 then
        return false
    end
    
    local stance = Fury.Utils:GetActiveStance()
    if stance ~= 1 then
        -- Only stance dance if we have enough rage to cast Overpower AFTER the change
        -- Tactical Mastery keeps rage, but we need at least 5 rage after switching
        local rageAfterSwitch = math.min(UnitMana("player"), FuryTacticalMastery)
        if rageAfterSwitch < 5 then
            return false  -- Not enough rage after switch
        end
        
        if (Fury_Configuration["PrimaryStance"] ~= 2 and
            (UnitHealth("target") / UnitHealthMax("target") * 100) > 20 and
            not (FuryFlurry and Fury.Utils:HasBuff("player", "Ability_GhoulFrenzy"))) or
           UnitIsPlayer("target") then
            if Fury_Configuration["PrimaryStance"] ~= 0 then
                Fury:Debug("21. Battle Stance (Overpower)")
                if not FuryOldStance then
                    FuryOldStance = stance
                end
                Fury.Utils:DoShapeShift(1)
                return true
            end
        end
        return false
    end
    
    -- In Battle Stance now - cast Overpower
    if UnitMana("player") < 5 then return false end
    
    Fury:Debug("21. Overpower")
    CastSpellByName(ABILITY_OVERPOWER_FURY)
    FuryLastSpellCast = GetTime()
    FuryOverpower = nil  -- Clear flag after casting
    return true
end

--------------------------------------------------
-- 9. Spell Interrupts
--------------------------------------------------
function Fury.DecisionTree:TryInterrupts()
    if not FurySpellInterrupt then return false end
    
    -- Pummel
    if self:TryPummel() then return true end
    
    return false
end

function Fury.DecisionTree:TryPummel()
    if not Fury_Configuration[ABILITY_PUMMEL_FURY] then return false end
    if UnitMana("player") < 10 then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_PUMMEL_FURY) then return false end
    
    -- Check if target is interruptible
    if not UnitIsPlayer("target") or
       (UnitIsPlayer("target") and
        UnitClass("target") ~= CLASS_ROGUE_FURY and
        UnitClass("target") ~= CLASS_WARRIOR_FURY and
        UnitClass("target") ~= CLASS_HUNTER_FURY) then
        
        local stance = Fury.Utils:GetActiveStance()
        if stance ~= 3 then
            if UnitMana("player") <= (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) and
               Fury_Configuration["PrimaryStance"] ~= 0 then
                Fury:Debug("9. Berserker Stance (Pummel)")
                if not FuryOldStance then
                    FuryOldStance = stance
                end
                Fury.Utils:DoShapeShift(3)
                FuryLastSpellCast = GetTime()
                return true
            end
            return false
        end
        
        Fury:Debug("9. Pummel")
        CastSpellByName(ABILITY_PUMMEL_FURY)
        return true
    end
    
    return false
end


--------------------------------------------------
-- 11. Hamstring (Runners)
--------------------------------------------------
function Fury.DecisionTree:TryHamstring()
    if not Fury_Configuration[ABILITY_HAMSTRING_FURY] then return false end
    if not Fury.Utils:HasWeapon() then return false end
    if not FuryAttack then return false end
    if Fury.Utils:Distance() ~= 5 then return false end
    if UnitMana("player") < Fury.Utils:HamstringCost() then return false end
    if not Fury.Utils:IsSpellReady(ABILITY_HAMSTRING_FURY) then return false end
    if Fury.Utils:HasBuff("target", "INV_Potion_04") then return false end
    if Fury.Utils:HasBuff("target", "Spell_Holy_SealOfValor") then return false end
    
    -- Check if target is a runner or player
    local isTarget = UnitIsPlayer("target") or
                    (Fury_Runners[UnitName("target")] and
                     (UnitHealth("target") / UnitHealthMax("target") * 100) <= tonumber(Fury_Configuration["HamstringHealth"]))
    
    if not isTarget then return false end
    
    -- Check if snare is needed
    if Fury.Utils:SnareDebuff("target") and not (FuryImpHamstring and UnitMana("player") < 30) then
        return false
    end
    
    local stance = Fury.Utils:GetActiveStance()
    if stance == 2 then
        if UnitMana("player") <= (FuryTacticalMastery + Fury_Configuration["StanceChangeRage"]) and
           Fury_Configuration["PrimaryStance"] ~= 0 then
            if not FuryOldStance then
                FuryOldStance = stance
            end
            Fury:Debug("11. Berserker Stance (Hamstring)")
            if Fury_Configuration["PrimaryStance"] == 3 then
                Fury.Utils:DoShapeShift(3)
            else
                Fury.Utils:DoShapeShift(1)
            end
            return true
        end
        return false
    end
    
    Fury:Debug("11. Hamstring")
    if FuryOldStance == 2 then
        FuryDanceDone = true
    end
    CastSpellByName(ABILITY_HAMSTRING_FURY)
    return true
end

--------------------------------------------------
-- Continue with remaining abilities...
-- (To keep file size manageable, I'll add key methods)
--------------------------------------------------

-- Legacy wrapper now in Core.lua to avoid namespace conflicts
