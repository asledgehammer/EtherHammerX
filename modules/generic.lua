--- @param api EtherHammerXClientAPI
--- @param options table<string, any>
return function(api, options)
    local core = getCore();

    api.getServerPlayerInfo(function(info)
        local player = getPlayer();

        local function checkCapacityWeight()
            local inventory = player:getInventory();
            local capacityWeight = inventory:getCapacityWeight();
            if capacityWeight == 0 then
                return 'Unlimited Capacity. (weight is 0)';
            end
        end

        local function checkInventoryWeightMismatch()
            local reportedWeight = player:getInventoryWeight();
            local calcWeight = 0;
            local inventory = player:getInventory();
            local items = inventory:getItems();
            local itemsCount = items:size();
            if itemsCount ~= 0 then
                for i = 0, itemsCount - 1 do
                    --- @type InventoryItem
                    local item = items:get(i);
                    if item:getAttachedSlot() > -1 and not player:isEquipped(item) then
                        calcWeight = calcWeight + item:getHotbarEquippedWeight();
                    elseif (player:isEquipped(item)) then
                        calcWeight = calcWeight + item:getEquippedWeight();
                    else
                        calcWeight = calcWeight + item:getUnequippedWeight();
                    end
                end
            end
            -- Check to 2-decimal places.
            reportedWeight = toInt(reportedWeight * 100) / 100;
            calcWeight = toInt(calcWeight * 100) / 100;

            if reportedWeight ~= calcWeight then
                return 'wrong inventory-weight. (reported = ' ..
                    tostring(reportedWeight) .. ' calculated = ' .. tostring(calcWeight) .. ')';
            end
        end

        --- @type string[]
        ---
        --- The active cheats to report.
        local cheats = {};

        -- Check for consistent accessLevel.
        if info.accessLevel ~= player:getAccessLevel() then
            table.insert(cheats, 'access-level mismatch');
        end

        -- Non-staff.
        if info.accessLevel == 'None' then
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
                local result = checkCapacityWeight();
                if result ~= nil then
                    table.insert(cheats, result);
                end
                -- Some cheats deep-edit returned values for inventory. Double-check..
                result = checkInventoryWeightMismatch();
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
    end);
end;
