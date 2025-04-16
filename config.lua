---[[
--- This file is for EtherHammerX.
---
--- The configuration for EtherHammerX anti-cheat framework. All configuation options goes here.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @return EtherHammerXConfiguration
return {
    --- The time (in second(s)) that the client must respond at the time on login.
    ---
    --- @type number
    TIME_TO_GREET = 10,

    --- The time (in second(s)) that the client must respond after a request is sent post-greeting.
    ---
    --- @type number
    TIME_TO_VERIFY = 120,

    --- If true, players are pinged for a new key and verification is done.
    ---
    --- @type boolean
    SHOULD_HEARTBEAT = true,

    --- The time (in second(s)) that the client must respond (At the time of request) periodically.
    ---
    --- @type number
    TIME_TO_HEARTBEAT = 20,

    --- The time (in second(s)) that the player-manager updates.
    ---
    --- @type number
    TIME_TO_TICK = 5,

    --- The key-generation profile to use. All server and client key fragments are calculated and audited using these functions.
    ---
    --- Filename(s) must be consistent:
    --- - `keys/<KEY_ID>_client.lua`
    --- - `keys/<KEY_ID>_server.lua`
    ---
    --- NOTE: In order to audit the client key-fragment against hack-tampering / forging keys, the client key-fragment must be
    --- consistent if ran on both the client and server, otherwise the audit will fail.
    ---
    --- @type string
    KEY = 'basic',

    --- All modules to check for anti-cheats are defined here.
    ---
    --- Filename must be:
    --- - `modules/<MODULE_ID>.lua`
    ---
    --- NOTE: Server-side modules are optional.
    MODULES = {
        etherhack = {
            enable = true,
            name = 'EtherHack',
            options = {
                --- @type boolean
                ---
                --- If true, a ticket is submitted to the admins that the player is hacking.
                submit_ticket_on_kick = true,
            }
        },
        generic = {
            enable = true,
            name = 'Generic',
            runOnce = true,
            options = {
                --- @type number
                --- 
                --- The time it takes to check for cheats. (In tick(s))
                fast_check_time = 20,

                --- @type number
                --- 
                --- The time it takes to get server-side info of the player. (In second(s))
                info_time = 60,
                
                --- @type table<string, 'kick'|'log'|'off'>
                --- 
                --- Set these to kick, log, or disable cheat checks.
                cheats = {
                    access_level = 'kick',
                    debug_mode = 'kick',
                    god_mod = 'kick',
                    invisible = 'kick',
                    invincible = 'kick',
                    ghost_mode = 'kick',
                    no_clip = 'log',
                    timed_action_instant = 'kick',
                    unlimited_carry = 'kick',
                    unlimited_endurance = 'kick',
                    build = 'kick',
                    farming = 'kick',
                    health = 'kick',
                    mechanics = 'kick',
                    movables = 'kick',
                    can_see_all = 'kick',
                    can_hear_all = 'kick',
                    zombies_dont_attack = 'log',
                    show_mp_info = 'kick'
                }
            }
        }
    }
};
