local TimeUtils = require 'asledgehammer/util/TimeUtils';

--- @type ServerPlayerInfo | nil
local info;

--- @param player IsoPlayer
---
--- @return string | nil
local function checkCapacityWeight(player)
    local inventory = player:getInventory();
    local capacityWeight = inventory:getCapacityWeight();
    if capacityWeight == 0 then
        return 'Unlimited Capacity. (weight is 0)';
    end
end

local function runSlow(api, options)
    api.getServerPlayerInfo(function(_info)
        info = _info;
    end);
end

local function runFast(api, options)
    local core = getCore();
    local player = getPlayer();

    -- Check for consistent accessLevel.
    if info and info.accessLevel ~= player:getAccessLevel() then
        api.report('Generic',
            'access-level mismatch (Client: ' .. player:getAccessLevel() .. ', Server: ' .. info.accessLevel .. ')',
            true);
    end

    --- @type string[]
    ---
    --- The active cheats to report.
    local cheats = {};

    -- Non-staff.
    if info and info.accessLevel == 'None' then
        if core:getDebug() then
            table.insert(cheats, 'debug-mode');
        end
        if player:isGodMod() then
            table.insert(cheats, 'god-mod');
        end
        if player:isInvisible() then
            table.insert(cheats, 'invisibility');
        end
        if player:isInvincible() then
            table.insert(cheats, 'invincibility');
        end
        if player:isGhostMode() then
            table.insert(cheats, 'ghost-mode');
        end
        if player:isNoClip() then
            table.insert(cheats, 'no-clip');
        end
        if player:isTimedActionInstantCheat() then
            table.insert(cheats, 'instant-actions');
        end
        if player:isUnlimitedCarry() then
            table.insert(cheats, 'unlimited-carry');
        else
            local result = checkCapacityWeight(player);
            if result ~= nil then
                table.insert(cheats, result);
            end
        end
        if player:isUnlimitedEndurance() then
            table.insert(cheats, 'unlimited-endurance');
        end
        if player:isBuildCheat() then
            table.insert(cheats, 'build-cheat');
        end
        if player:isFarmingCheat() then
            table.insert(cheats, 'farm-cheat');
        end
        if player:isHealthCheat() then
            table.insert(cheats, 'health-cheat');
        end
        if player:isMechanicsCheat() then
            table.insert(cheats, 'mechanics-cheat');
        end
        if player:isMovablesCheat() then
            table.insert(cheats, 'moveables-cheat');
        end
        if player:isCanSeeAll() then
            table.insert(cheats, 'can-see-all');
        end
        if player:isCanHearAll() then
            table.insert(cheats, 'can-hear-all');
        end
        if player:isZombiesDontAttack() then
            table.insert(cheats, 'zombies-dont-attack');
        end
        if player:isShowMPInfos() then
            table.insert(cheats, 'show-mp-info');
        end
    end

    -- Report all active cheats.
    if #cheats ~= 0 then
        local reason = '';
        for _, cheat in ipairs(cheats) do
            if reason == '' then reason = cheat else reason = reason .. ', ' .. cheat end
        end
        api.report('Generic', reason, true);
        return;
    end
end

--- @param api EtherHammerXClientAPI
--- @param options table<string, any>
return function(api, options)
    -- Initial fetch of server player-info.
    runSlow(api, options);

    TimeUtils.everySeconds(function() runSlow(api, options) end, 60);
    TimeUtils.everyTicks(function() runFast(api, options) end, 60);
end;
