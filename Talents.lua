Fury.Talents = {}

--------------------------------------------------
-- Scan Talents and Spell Book
--------------------------------------------------
function Fury.Talents:Scan()
    local i = 1
    Fury:Debug("Scanning Spell Book")
    
    -- Scan spell book for stances
    while true do
        local spellName, spellRank = GetSpellName(i, BOOKTYPE_SPELL)
        if not spellName then
            break
        end
        if spellName == ABILITY_BERSERKER_STANCE_FURY then
            FuryBerserkerStance = true
            Fury:Debug(ABILITY_BERSERKER_STANCE_FURY)
        elseif spellName == ABILITY_DEFENSIVE_STANCE_FURY then
            FuryDefensiveStance = true
            Fury:Debug(ABILITY_DEFENSIVE_STANCE_FURY)
        end
        i = i + 1
    end
    
    Fury:Debug("Scanning Talent Tree")
    
    -- Arms Tree (Tab 1)
    self:ScanArmsTree()
    
    -- Fury Tree (Tab 2)
    self:ScanFuryTree()
    
    -- Protection Tree (Tab 3)
    self:ScanProtectionTree()
    
    -- Racial Abilities
    self:ScanRacials()
    
    -- Class Abilities
    self:ScanClassAbilities()
    
    -- Initialize distance checks
    Fury.Utils:InitDistance()
    
    -- Detect spec based on talents and weapons
    Fury.Utils:DetectSpec()
    
    FuryTalents = true
end

--------------------------------------------------
-- Scan Arms Tree
--------------------------------------------------
function Fury.Talents:ScanArmsTree()
    -- Improved Heroic Strike (1,1)
    local _, _, _, _, currRank = GetTalentInfo(1, 1)
    FuryHeroicStrikeCost = (15 - tonumber(currRank))
    if FuryHeroicStrikeCost < 15 then
        Fury:Debug("Improved Heroic Strike: Rank " .. currRank)
    end
    
    -- Tactical Mastery (1,5)
    local _, _, _, _, currRank = GetTalentInfo(1, 5)
    FuryTacticalMastery = (tonumber(currRank) * 5)
    if FuryTacticalMastery > 0 then
        Fury:Debug("Tactical Mastery: " .. FuryTacticalMastery .. " rage")
    end
    
    -- Improved Thunder Clap (1,6)
    local _, _, _, _, currRank = GetTalentInfo(1, 6)
    FuryThunderClapCost = (20 - tonumber(currRank))
    if FuryThunderClapCost < 20 then
        Fury:Debug("Improved Thunder Clap")
    end
    
    -- Sweeping Strikes (1,13)
    local _, _, _, _, currRank = GetTalentInfo(1, 13)
    if currRank > 0 then
        Fury:Debug("Sweeping Strikes")
        FurySweepingStrikes = true
    else
        FurySweepingStrikes = false
    end
    
    -- Mace Specialization (1,14)
    local _, _, _, _, currRank = GetTalentInfo(1, 14)
    if currRank > 0 then
        Fury:Debug("Mace Specialization")
        FuryMaceSpec = true
    else
        FuryMaceSpec = false
    end
    
    -- Sword Specialization (1,15)
    local _, _, _, _, currRank = GetTalentInfo(1, 15)
    if currRank > 0 then
        Fury:Debug("Sword Specialization")
        FurySwordSpec = true
    else
        FurySwordSpec = false
    end
    
    -- Improved Hamstring (1,17)
    local _, _, _, _, currRank = GetTalentInfo(1, 17)
    if currRank > 0 then
        Fury:Debug("Improved Hamstring")
        FuryImpHamstring = true
    else
        FuryImpHamstring = false
    end
    
    -- Mortal Strike (1,18)
    local _, _, _, _, currRank = GetTalentInfo(1, 18)
    if currRank > 0 then
        Fury:Debug("Mortal Strike")
        FuryMortalStrike = true
    else
        FuryMortalStrike = false
    end
end

--------------------------------------------------
-- Scan Fury Tree
--------------------------------------------------
function Fury.Talents:ScanFuryTree()
    -- Piercing Howl (2,6)
    local _, _, _, _, currRank = GetTalentInfo(2, 6)
    if currRank > 0 then
        Fury:Debug("Piercing Howl")
        FuryPiercingHowl = true
    else
        FuryPiercingHowl = false
    end
    
    -- Improved Execute (2,10)
    local _, _, _, _, currRank = GetTalentInfo(2, 10)
    FuryExecuteCost = (15 - string.sub(tostring(tonumber(currRank) * 2.5), 1, 2))
    if FuryExecuteCost < 15 then
        Fury:Debug("Improved Execute: Cost " .. FuryExecuteCost)
    end
    
    -- Death Wish (2,13)
    local _, _, _, _, currRank = GetTalentInfo(2, 13)
    if currRank > 0 then
        Fury:Debug("Death Wish")
        FuryDeathWish = true
    else
        FuryDeathWish = false
    end
    
    -- Improved Berserker Rage (2,15)
    local _, _, _, _, currRank = GetTalentInfo(2, 15)
    FuryImprovedBerserkerRageRank = currRank
    if currRank > 0 then
        Fury:Debug("Improved Berserker Rage (Rank " .. currRank .. ")")
        FuryBerserkerRage = true
    else
        FuryBerserkerRage = false
    end
    
    -- Flurry (2,16)
    local _, _, _, _, currRank = GetTalentInfo(2, 16)
    if currRank > 0 then
        Fury:Debug("Flurry")
        FuryFlurry = true
    else
        FuryFlurry = false
    end
    
    -- Bloodthirst (2,17)
    local _, _, _, _, currRank = GetTalentInfo(2, 17)
    if currRank > 0 then
        Fury:Debug("Bloodthirst")
        FuryBloodthirst = true
    else
        FuryBloodthirst = false
    end
end

--------------------------------------------------
-- Scan Protection Tree
--------------------------------------------------
function Fury.Talents:ScanProtectionTree()
    -- Shield Slam (3,17)
    local _, _, _, _, currRank = GetTalentInfo(3, 17)
    if currRank > 0 then
        Fury:Debug("Shield Slam")
        FuryShieldSlam = true
    else
        FuryShieldSlam = false
    end
end

--------------------------------------------------
-- Scan Racial Abilities
--------------------------------------------------
function Fury.Talents:ScanRacials()
    if UnitRace("player") == RACE_ORC then
        Fury:Debug("Blood Fury")
        FuryRacialBloodFury = true
    else
        FuryRacialBloodFury = false
    end
    
    if UnitRace("player") == RACE_TROLL then
        Fury:Debug("Berserking")
        FuryRacialBerserking = true
    else
        FuryRacialBerserking = false
    end
end

--------------------------------------------------
-- Scan Class Abilities
--------------------------------------------------
function Fury.Talents:ScanClassAbilities()
    if Fury.Utils:SpellId("Whirlwind") then
        Fury:Debug("Whirlwind")
        FuryWhirlwind = true
    else
        FuryWhirlwind = false
    end
end
