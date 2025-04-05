---[[
--- EtherHammer - Server Script.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

local Packet = require 'asledgehammer/network/Packet';
local PlayerListener = require 'asledgehammer/network/PlayerListener';

-- (Only run on server-side of a multiplayer session)
if isClient() or not isServer() then return end

(function()
    local info = function(message)
        print('[EtherHammerX] :: ' .. tostring(message));
    end

    local pad2 = function(str)
        if #str == 1 then return '0' .. str end
        return str;
    end

    --- Converts a millisecond UNIX timestamp to a human-readable ISO-8601 formatted date string.
    --- @param time number The time in milliseconds. (use `getTimeInMillis()`)
    ---
    --- @return string date The formatted date as a string.
    local toISO8601 = function(time)
        local d = os.date("*t", Math.floor(time / 1000));
        local year = tostring(d.year);
        local month = pad2(tostring(d.month));
        local day = pad2(tostring(d.day));
        local hour = pad2(tostring(d.hour));
        local min = pad2(tostring(d.min));
        local sec = pad2(tostring(d.sec));
        local msec = tostring(time);
        msec = string.sub(msec, #time - 3);
        return year .. '-' .. month .. '-' .. day .. 'T' .. hour .. ':' .. min .. ':' .. sec .. '.' .. msec .. 'Z';
    end

    local log = function(message)
        local writer = getFileWriter('ModLoader/mods/EtherHammerX/reports.log', true, true);
        writer:writeln('[' .. toISO8601(getTimeInMillis()) .. '] :: ' .. message);
        writer:close();
    end

    -- The packet-module identity.
    local MODULE_ID = { string = 'MODULE_ID' };

    --- (Login statuses)
    local STATUS_AWAIT_HEARTBEAT_REQUEST = 1;
    local STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE = 2;
    local STATUS_VERIFIED = 3;

    -- Check to see if CraftHammer is installed.

    --- @type fun(player: IsoPlayer, reason?: string): void
    local kickPlayerFromServer = kickPlayerFromServer; -- (Exposed CraftHammer API)
    if kickPlayerFromServer == nil then
        info(
            '!!! WARNING: CraftHammer isn\'t installed on the server! ' ..
            'Kicking players from server-side is disabled. !!!'
        );
        info('To install CraftHammer, follow this link and grab the latest version here: https://discord.gg/r6PeSFuJDU');
        kickPlayerFromServer = function(player)
            info(
                '!!! WARNING: CraftHammer isn\'t installed on the server! ' ..
                'Kicking players from server-side is disabled. (Cannot kick player "' .. player:getUsername() .. '") !!!'
            );
        end
    end

    local function run()
        -- - @type table<string, boolean>
        -- local verifiedOnce = {};

        --- @type table<string, number>
        local playerStatuses = {};

        --- @type table<string, string>
        local playerKeys = {};

        --- @type table,string, fun(player:IsoPlayer):string>
        local playerFuncs = {};

        --- @type table<string, string>
        local serverFragments = {};

        --- @type table<string, number>
        local playerRequestLast = {};

        --- Dynamically loaded and fed from `keys.lua`.
        ---
        --- @type fun(player: IsoPlayer): string
        local serverKey = { func = 'SERVER_KEY_FUNCTION' };

        --- Sends a followup request to cycle the key, requesting for the current key as well.
        ---
        --- @param player IsoPlayer The player object.
        --- @param username string The player username.
        ---
        --- @return void
        local requestHeartbeat = function(player, username)
            -- Set these twice. The reason is that due to the nature of dynamic functions, an error could stall the
            -- process.
            playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE;
            playerRequestLast[username] = getTimeInMillis();

            if not playerFuncs[username] then
                playerFuncs[username] = { func = 'CLIENT_KEY_FUNCTION' };
            end

            -- Generate the next server key-fragment for the player.
            local serverFragment = serverKey(player);
            serverFragments[username] = serverFragment;

            local oldKey = playerKeys[username];
            playerKeys[username] = serverFragments[username] .. playerFuncs[username](player);

            local packet = Packet(MODULE_ID, { string = 'HEARTBEAT_REQUEST_COMMAND' }, { message = serverFragment });
            packet:encrypt(oldKey, function()
                packet:sendToPlayer(player);
                -- Restart the timer after encrypting the packet and sending it.
                playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE;
                playerRequestLast[username] = getTimeInMillis();
            end);
        end

        --- Handles the cleanup of player-resources when logging out.
        ---
        --- @param username string The username of the player logging out.
        ---
        --- @return void
        local function processLogout(username)
            -- Dispose of status & request times.
            playerStatuses[username] = nil;
            playerRequestLast[username] = nil;
            playerKeys[username] = nil;
            playerFuncs[username] = nil;
        end

        --- (Generic kick-player function)
        ---
        --- @param player IsoPlayer The player to kick.
        --- @param username string The username of the player.
        --- @param reason string | nil (Optional) The reason the player is kicked.
        ---
        --- @return void
        local function kick(player, username, reason)
            local message = 'Kicking player \'' .. username .. '\'.';
            if reason then
                message = message .. ' (Reason: \'' .. reason .. '\')';
            end
            log(message);
            processLogout(username);
            kickPlayerFromServer(player, reason);
        end

        --- Handles packets received for each player.
        ---
        --- @param player IsoPlayer The player that sent the packet.
        --- @param id string The identity of the packet sent.
        --- @param data table Additional data provided for the packet.
        ---
        --- @return void
        local function onReceivePacket(player, id, data)
            if id == { string = 'HEARTBEAT_RESPONSE_COMMAND' } then
                local username = player:getUsername();

                local key = playerKeys[username];
                if data.key ~= key then
                    kick(player, username, 'Client key mismatch.');
                    return;
                end

                -- The player is now verified.
                playerStatuses[username] = STATUS_VERIFIED;

                -- if not verifiedOnce[username] then
                -- info('Player \'' .. tostring(username) .. '\' verified.');
                -- verifiedOnce[username] = true;
                -- end
            elseif id == { string = 'HANDSHAKE_REQUEST_COMMAND' } then
                -- The initial handshake request requires a known key. Use the initially-generated key here.
                local username = player:getUsername();
                local serverKeyFragment = serverKey(player);

                if not playerFuncs[username] then
                    playerFuncs[username] = { func = 'CLIENT_KEY_FUNCTION' };
                end

                local packet = Packet(MODULE_ID, { string = 'HEARTBEAT_REQUEST_COMMAND' },
                    { message = serverKeyFragment });
                packet:encrypt({ string = 'HANDSHAKE_KEY' }, function()
                    packet:sendToPlayer(player);
                    -- Start the timer only after encrypting the packet and sending it.
                    playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE;
                    playerRequestLast[username] = getTimeInMillis();
                end);

                -- The expected response should be in the new key.
                playerKeys[username] = serverKeyFragment .. playerFuncs[username](player);
            elseif id == { string = 'REPORT_COMMAND' } then
                -- The initial handshake request requires a known key. Use the initially-generated key here.
                local username = player:getUsername();
                local type = data.type;
                local reason = data.reason;
                local message = type;
                if reason then message = message .. ' (' .. reason .. ')' end
                info(username .. ' was kicked for ' .. message);
                kick(player, username, message);
            end
        end

        Events.OnClientCommand.Add(function(module, command, player, args)
            if module ~= MODULE_ID then return end

            local username = player:getUsername();
            local packet = Packet(module, command, args);

            local key = playerKeys[username];
            if not key then
                playerKeys[username] = { string = 'HANDSHAKE_KEY' };
                key = playerKeys[username];
            end

            packet:decrypt(key, function()
                -- Make sure that the packet is proper. Anything other can be considered tampering.
                if not packet.valid then
                    info('Player ' .. username .. ' sent a bad packet. Disconnecting them from the server..');
                    kick(player, username, 'Sent a bad packet.');
                    return;
                end
                onReceivePacket(player, packet.command, packet.data);
            end);
        end);

        Events.OnServerPlayerLogin.Add(
        --- @param player IsoPlayer
        ---
        --- @return void
            function(player)
                local username = player:getUsername();
                if playerStatuses[username] == nil then
                    playerStatuses[username] = STATUS_AWAIT_HEARTBEAT_REQUEST;
                    playerKeys[username] = { string = 'HANDSHAKE_KEY' };
                    playerRequestLast[username] = getTimeInMillis();
                    info('Player \'' .. tostring(username) .. '\' joined the game.');
                end
            end
        );
        Events.OnServerPlayerLogout.Add(
        --- @param player IsoPlayer
        ---
        --- @return void
            function(player)
                local username = player:getUsername();
                processLogout(username);
                info('Player \'' .. tostring(username) .. '\' left the game.');
            end
        );

        --- @type number, number
        local tickTimeLast, tickTimeNow = -1, -1;
        Events.OnTickEvenPaused.Add(function()
            tickTimeNow = getTimeInMillis();

            -- Only run once every TIME_TO_TICK second(s).
            if tickTimeNow - tickTimeLast < { number = 'TIME_TO_TICK' } * 1000 then return end
            tickTimeLast = tickTimeNow;

            -- Update player statuses and request heartbeats.
            for username, player in pairs(PlayerListener.players) do
                local status = playerStatuses[username];
                if status == STATUS_AWAIT_HEARTBEAT_REQUEST then -- The player logged in and is ready to receive the first heartbeat.
                    if getTimeInMillis() - playerRequestLast[username] > { number = 'TIME_TO_GREET' } * 1000 then
                        kick(player, username, 'Verification timeout. (No response #1)');
                        return;
                    end
                elseif status == STATUS_AWAIT_HEARTBEAT_REQUEST_RECEIVE then -- Waiting on a response.
                    if getTimeInMillis() - playerRequestLast[username] > { number = 'TIME_TO_GREET' } * 1000 then
                        kick(player, username, 'Verification timeout. (No response #2)');
                        return;
                    end
                elseif { boolean = "SHOULD_HEARTBEAT" } and status == STATUS_VERIFIED then -- Is verified and heartbeats are periodically requested.
                    if getTimeInMillis() - playerRequestLast[username] > { number = 'TIME_TO_HEARTBEAT' } * 1000 then
                        requestHeartbeat(player, username);
                    end
                end
            end
        end);
    end

    Events.OnServerStarted.Add(run);
end)();
