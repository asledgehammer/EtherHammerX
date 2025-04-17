local TimeUtils = require 'asledgehammer/util/TimeUtils';

--- @type ServerPlayerInfo | nil
local info;

--- @type table<string, 'kick' | 'log' | 'off'>
local cheats;

--- @param api EtherHammerXClientAPI
local function runSlow(api)
    api.getServerPlayerInfo(function(_info)
        info = _info;
    end);
end

--- @param api EtherHammerXClientAPI
local function runFast(api)
    -- print('runFast()');
    local core = getCore();
    local player = getPlayer();

    -- Check for consistent accessLevel.
    if cheats.access_level ~= 'off' then
        if info and info.accessLevel ~= player:getAccessLevel() then
            local message = 'access-level mismatch (Client: ' ..
                player:getAccessLevel() .. ', Server: ' .. info.accessLevel .. ')';
            api.report('Generic', message, cheats.access_level);
        end
    end

    --- @type string[]
    ---
    --- The active cheats to report.
    local active_cheats = {};

    --- @type ReportAction
    local most_severe_action = 'log';

    local function checkSeverity(action)
        if not most_severe_action then
            most_severe_action = action;
        elseif most_severe_action ~= 'kick' and action == 'kick' then
            most_severe_action = action;
        end
    end

    -- Non-staff.
    if info and info.accessLevel == 'None' then
        if cheats.debug_mode ~= 'off' and core:getDebug() then
            table.insert(active_cheats, 'debug-mode');
            checkSeverity(cheats.debug_mode);
        end

        if cheats.god_mod ~= 'off' and player:isGodMod() then
            table.insert(active_cheats, 'god-mod');
            checkSeverity(cheats.god_mod);
        end

        if cheats.invisible ~= 'off' and player:isInvisible() then
            table.insert(active_cheats, 'invisibility');
            checkSeverity(cheats.invisible);
        end

        if cheats.invincible ~= 'off' and player:isInvincible() then
            table.insert(active_cheats, 'invincibility');
            checkSeverity(cheats.invincible);
        end

        if cheats.ghost_mode ~= 'off' and player:isGhostMode() then
            table.insert(active_cheats, 'ghost-mode');
            checkSeverity(cheats.ghost_mode);
        end

        if cheats.no_clip ~= 'off' and player:isNoClip() then
            table.insert(active_cheats, 'no-clip');
            checkSeverity(cheats.no_clip);
        end

        if cheats.timed_action_instant ~= 'off' and player:isTimedActionInstantCheat() then
            table.insert(active_cheats, 'instant-actions');
            checkSeverity(cheats.timed_action_instant);
        end

        if cheats.unlimited_carry ~= 'off' and player:isUnlimitedCarry() then
            table.insert(active_cheats, 'unlimited-carry');
            checkSeverity(cheats.unlimited_carry);
        end

        if cheats.unlimited_endurance ~= 'off' and player:isUnlimitedEndurance() then
            table.insert(active_cheats, 'unlimited-endurance');
            checkSeverity(cheats.unlimited_endurance);
        end

        if cheats.build ~= 'off' and player:isBuildCheat() then
            table.insert(active_cheats, 'build-cheat');
            checkSeverity(cheats.build);
        end

        if cheats.farming ~= 'off' and player:isFarmingCheat() then
            table.insert(active_cheats, 'farm-cheat');
            checkSeverity(cheats.farming);
        end

        if cheats.health ~= 'off' and player:isHealthCheat() then
            table.insert(active_cheats, 'health-cheat');
            checkSeverity(cheats.health);
        end

        if cheats.mechanics ~= 'off' and player:isMechanicsCheat() then
            table.insert(active_cheats, 'mechanics-cheat');
            checkSeverity(cheats.mechanics);
        end

        if cheats.movables ~= 'off' and player:isMovablesCheat() then
            table.insert(active_cheats, 'moveables-cheat');
            checkSeverity(cheats.movables);
        end

        if cheats.can_see_all ~= 'off' and player:isCanSeeAll() then
            table.insert(active_cheats, 'can-see-all');
            checkSeverity(cheats.can_see_all);
        end

        if cheats.can_hear_all ~= 'off' and player:isCanHearAll() then
            table.insert(active_cheats, 'can-hear-all');
            checkSeverity(cheats.can_hear_all);
        end

        if cheats.zombies_dont_attack ~= 'off' and player:isZombiesDontAttack() then
            table.insert(active_cheats, 'zombies-dont-attack');
            checkSeverity(cheats.zombies_dont_attack);
        end

        if cheats.show_mp_info ~= 'off' and player:isShowMPInfos() then
            table.insert(active_cheats, 'show-mp-info');
            checkSeverity(cheats.show_mp_info);
        end
    end

    -- Report all active cheats.
    if #active_cheats ~= 0 then
        local reason = '';
        for _, cheat in ipairs(active_cheats) do
            if reason == '' then reason = cheat else reason = reason .. ', ' .. cheat end
        end
        api.report('Generic', reason, most_severe_action);
        return;
    end
end

--- @param api EtherHammerXClientAPI
--- @param options {fast_check_time: number, info_time: number, cheats: table<string, 'kick'|'log'|'off'>}
return function(api, options)
    -- Initial fetch of server player-info.
    runSlow(api);

    cheats = options.cheats or {
        access_level = 'kick',
        debug_mode = 'kick',
        god_mod = 'kick',
        invisible = 'kick',
        invincible = 'kick',
        ghost_mode = 'kick',
        no_clip = 'kick',
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
        zombies_dont_attack = 'kick',
        show_mp_info = 'kick'
    };

    --- Poly-fill missing cheat definition(s).
    if not cheats.access_level then cheats.access_level = 'kick' end
    if not cheats.debug_mode then cheats.debug_mode = 'kick' end
    if not cheats.god_mod then cheats.god_mod = 'kick' end
    if not cheats.invisible then cheats.invisible = 'kick' end
    if not cheats.invincible then cheats.invincible = 'kick' end
    if not cheats.ghost_mode then cheats.ghost_mode = 'kick' end
    if not cheats.no_clip then cheats.no_clip = 'kick' end
    if not cheats.timed_action_instant then cheats.timed_action_instant = 'kick' end
    if not cheats.unlimited_carry then cheats.unlimited_carry = 'kick' end
    if not cheats.unlimited_endurance then cheats.unlimited_endurance = 'kick' end
    if not cheats.build then cheats.build = 'kick' end
    if not cheats.farming then cheats.farming = 'kick' end
    if not cheats.health then cheats.health = 'kick' end
    if not cheats.mechanics then cheats.mechanics = 'kick' end
    if not cheats.movables then cheats.movables = 'kick' end
    if not cheats.can_see_all then cheats.can_see_all = 'kick' end
    if not cheats.can_hear_all then cheats.can_hear_all = 'kick' end
    if not cheats.zombies_dont_attack then cheats.zombies_dont_attack = 'kick' end
    if not cheats.show_mp_info then cheats.show_mp_info = 'kick' end

    local fast_check_time = options.fast_check_time or 60;
    local info_time = options.info_time or 60;

    TimeUtils.everySeconds(function() runSlow(api) end, info_time);
    TimeUtils.everyTicks(function() runFast(api) end, fast_check_time);
end;
