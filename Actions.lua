Fury.Actions = {}

-- Charge tracking
FuryLastChargeCast = 0
FuryThunderClapCost = 20

--------------------------------------------------
-- Charge/Intercept Action
--------------------------------------------------
function Fury.Actions:Charge()
    local dist = Fury.Utils:Distance()
    
    -- No target or out of combat
    if not UnitExists("target") and not FuryCombat then
        if Fury_Configuration["PrimaryStance"] and
           Fury_Configuration["PrimaryStance"] ~= 0 and
           Fury.Utils:GetActiveStance() ~= Fury_Configuration["PrimaryStance"] then
            Fury.Utils:DoShapeShift(Fury_Configuration["PrimaryStance"])
        end
        Fury:Debug("No target")
        return
    end
    
    -- Dismount if needed
    if FuryMount and dist <= 25 then
        Fury:Debug("Dismounting")
        Dismount()
        FuryMount = nil
        return
    end
    
    -- In Combat
    if FuryCombat then
        self:ChargeInCombat(dist)
    else
        self:ChargeOutOfCombat(dist)
    end
end

function Fury.Actions:ChargeInCombat(dist)
    local stance = Fury.Utils:GetActiveStance()
    
    -- Auto attack
    Fury.Utils:EnableAutoAttack()
    
    -- Intercept (in Berserker Stance)
    -- If distance is unknown (100), try anyway - the game will error if out of range
    if Fury_Configuration[ABILITY_INTERCEPT_FURY] and
       stance == 3 and
       (dist <= 25 and dist > 7 or dist == 100) and
       UnitMana("player") >= 10 and
       FuryLastChargeCast + 1 < GetTime() and
       Fury.Utils:IsSpellReady(ABILITY_INTERCEPT_FURY) then
        Fury:Debug("C2. Intercept")
        CastSpellByName(ABILITY_INTERCEPT_FURY)
        FuryLastChargeCast = GetTime()
        return
    end
    
    -- Bloodrage for Intercept
    if Fury_Configuration[ABILITY_BLOODRAGE_FURY] and
       stance == 3 and
       UnitMana("player") < 10 and
       (dist <= 25 or dist == 100) and
       Fury.Utils:IsSpellReady(ABILITY_INTERCEPT_FURY) and
       Fury.Utils:IsSpellReady(ABILITY_BLOODRAGE_FURY) then
        Fury:Debug("C3. Bloodrage")
        CastSpellByName(ABILITY_BLOODRAGE_FURY)
        return
    end
    
    -- Switch to Berserker Stance for Intercept
    if Fury_Configuration[ABILITY_INTERCEPT_FURY] and
       stance ~= 3 and
       (UnitMana("player") >= 10 or dist == 100) and
       FuryLastChargeCast + 1 < GetTime() and
       Fury.Utils:IsSpellReadyIn(ABILITY_INTERCEPT_FURY) <= 3 then
        Fury:Debug("C5. Berserker Stance (Intercept)")
        if FuryOldStance == nil then
            FuryOldStance = stance
        elseif FuryOldStance == 3 then
            FuryDanceDone = true
        end
        Fury.Utils:DoShapeShift(3)
        return
    end
end

function Fury.Actions:ChargeOutOfCombat(dist)
    local stance = Fury.Utils:GetActiveStance()
    local currentRage = UnitMana("player")
    local stanceChangeRage = tonumber(Fury_Configuration["StanceChangeRage"]) or 25
    
    -- Charge (in Battle Stance)
    -- If distance is unknown (100), try anyway - the game will error if out of range
    if Fury_Configuration[ABILITY_CHARGE_FURY] and
       stance == 1 and
       (dist <= 25 and dist > 7 or dist == 100) and
       FuryLastChargeCast + 0.5 < GetTime() and
       Fury.Utils:IsSpellReady(ABILITY_CHARGE_FURY) then
        Fury:Debug("O1. Charge")
        CastSpellByName(ABILITY_CHARGE_FURY)
        FuryLastChargeCast = GetTime()
        return
    end
    
    -- Special case: Use Intercept from Berserker if rage loss would be too high
    if Fury_Configuration[ABILITY_INTERCEPT_FURY] and
       stance == 3 and
       currentRage > stanceChangeRage and
       currentRage >= 10 and
       dist <= 25 and dist > 7 and
       FuryLastChargeCast + 0.5 < GetTime() and
       Fury.Utils:IsSpellReady(ABILITY_INTERCEPT_FURY) then
        Fury:Debug("O2. Intercept (avoid rage loss)")
        CastSpellByName(ABILITY_INTERCEPT_FURY)
        FuryLastChargeCast = GetTime()
        return
    end
    
    -- Switch to Battle Stance for Charge (even from Berserker if low rage)
    if Fury_Configuration[ABILITY_CHARGE_FURY] and
       stance ~= 1 and
       (dist > 7 or dist == 100) and
       Fury.Utils:IsSpellReadyIn(ABILITY_CHARGE_FURY) <= 5 then
        Fury:Debug("O3. Battle Stance (for Charge)")
        if Fury_Configuration["PrimaryStance"] ~= 1 and FuryOldStance == nil then
            FuryOldStance = stance
        elseif FuryOldStance == 1 then
            FuryOldStance = nil
            FuryDanceDone = true
        end
        Fury.Utils:DoShapeShift(1)
        return
    end
end

--------------------------------------------------
-- Shoot Ranged Weapon
--------------------------------------------------
function Fury.Actions:Shoot()
    local ranged_type = Fury.Utils:Ranged()
    local spell
    
    if ranged_type == ITEM_TYPE_BOWS_FURY then
        spell = ABILITY_SHOOT_BOW_FURY
    elseif ranged_type == ITEM_TYPE_CROSSBOWS_FURY then
        spell = ABILITY_SHOOT_CROSSBOW_FURY
    elseif ranged_type == ITEM_TYPE_GUNS_FURY then
        spell = ABILITY_SHOOT_GUN_FURY
    elseif ranged_type == ITEM_TYPE_THROWN_FURY then
        spell = ABILITY_THROW_FURY
    else
        return false
    end
    
    if Fury.Utils:IsSpellReady(spell) then
        Fury:Debug(spell)
        CastSpellByName(spell)
        FuryLastSpellCast = GetTime()
        return true
    end
    
    return false
end

-- Legacy function wrappers
function Fury_Charge()
    Fury.Actions:Charge()
end

function Fury_Shoot()
    return Fury.Actions:Shoot()
end
