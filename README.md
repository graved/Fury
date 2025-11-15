# Fury - Warrior Rotation Addon

**Author:** Graved89 (Originally by Bhaerau and CubeNicke)  
**Version:** Optimized for Turtle WoW (1.12.1 Client)

Advanced warrior combat rotation addon with automatic spec detection, intelligent decision-making, and optimized rotations for all warrior specs. Features include automatic stance dancing, smart cooldown management, swing timer integration for optimal Slam timing, and comprehensive customization options.

## Quick Start

### Basic Setup
1. **Keybind `/fury single`** to a convenient key (e.g., `1` or mouse button)
2. **Keybind `/fury charge`** for pulling (handles Charge/Intercept automatically)
3. Spam your main keybind in combat - the addon handles everything!

### Recommended Keybinds
- **Main Rotation:** `/fury single` - One-button rotation (SPAM THIS!)
- **Charge/Pull:** `/fury charge` - Smart Charge/Intercept with stance handling
- **Multi-Target:** `/fury multi` - AoE rotation (Cleave + Whirlwind)
- **Ranged Pull:** `/fury shoot` - Fire equipped ranged weapon

## Commands

### Main Rotation
```bash
/fury single              # Execute single-target rotation (main combat button)
/fury multi               # Execute multi-target/AoE rotation
/fury charge              # Smart Charge/Intercept with stance handling
/fury shoot               # Fire equipped ranged weapon
```

### Ability Management
```bash
/fury ability <name>      # Toggle specific ability on/off (e.g., "Heroic Strike", "Rend")
/fury threat              # Toggle between Heroic Strike (high threat) and Cleave (low threat)
/fury attack              # Toggle auto-attack feature
```

### Configuration
```bash
/fury default             # Reset ALL settings to default values
/fury stance <1|2|3|name> # Set primary stance (Battle/Defensive/Berserker or "default")
/fury talents             # Rescan talents and action bars (use after talent/actionbar changes)
```

### Rage Management
```bash
/fury attackrage <number>    # Min rage for Heroic Strike/Cleave dump (default: 30)
/fury rage <number>          # Max rage for rage-generating abilities (default: 60)
/fury dance <number>         # Max rage waste for stance dancing (default: 25)
```

### Ability Thresholds
```bash
/fury bloodrage <number>     # Min HP% for Bloodrage (default: 50)
/fury berserk <number>       # Min HP% for Berserker Rage (default: 60)
/fury hamstring <number>     # Max HP% for Hamstring on NPCs (default: 40)
/fury flurrytrigger <number> # Min rage for Hamstring proc trigger (default: 52)
```

### Target Filtering
```bash
/fury demodiff <number>   # Max level difference for Demoralizing Shout (default: 7)
/fury sunderdiff <number> # Max level difference for Sunder Armor (default: 7)
```

### Debugging
```bash
/fury help [command]         # Print help text for specific command
/fury debug                  # Toggle debug mode (shows rotation decisions)
/fury distance               # Show distance to target
/fury logfile [on|off|clear] # Log rotation to SavedVariables file
/fury unit [player|target]   # Show buffs and debuffs for unit
/fury where                  # Show current zone/location info
```