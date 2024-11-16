---[[
--- EtherHammer - Server Script.
---
--- @author asledgehammer, JabDoesThings, 2024
---]]

local Packet = require 'asledgehammer/network/Packet';
local PlayerListener = require 'asledgehammer/network/PlayerListener';

-- (Only run on server-side of a multiplayer session)
if isClient() or not isServer() then return end

(function()
    -- The packet-module identity.
    local MODULE_ID = 'EtherHammer';

    --- (Login statuses)
    local STATUS_AWAIT_GREET = 1;
    local STATUS_AWAIT_VERIFICATION = 2;
    local STATUS_AWAIT_SENT_REQUEST = 3;
    local STATUS_SENT_VERIFICATION_REQUEST = 4;

    -- (Heartbeat statuses)
    local STATUS_AWAIT_SENT_HEARTBEAT_REQUEST = 5;
    local STATUS_SENT_HEARTBEAT_REQUEST = 6;

    local STATUS_VERIFIED = 7;

    --- @type number
    --- The time (in second(s)) that the client must respond at the time on login.
    local TIME_TO_GREET = 10;

    --- @type number
    --- The time (in second(s)) that the client must respond after a request is sent post-greeting.
    local TIME_TO_VERIFY = 120;

    --- @type boolean
    --- If true, players are pinged for a new key and verification is done.
    local SHOULD_HEARTBEAT = true;

    --- @type number
    --- The time (in second(s)) that the client must respond (At the time of request) periodically.
    local TIME_TO_HEARTBEAT = 20;

    local TIME_TO_TICK = 5;

    local function run()
        --- @type table<string, number>
        local playerStatuses = {};

        --- @type table<string, string>
        local playerKeys = {};

        --- @type table<string, number>
        local playerFragments = {};

        --- @type table<string, number>
        local playerRequestLast = {};

        --- Sends a login verification request to cycle the key, requesting for the current key as well.
        ---
        --- @param player IsoPlayer The player object.
        --- @param username string The player username.
        ---
        --- @return void
        local function requestVerification(player, username)

            -- Create server-side key-fragment.
            local fragment1 = getTimeInMillis();
            playerFragments[username] = fragment1;

            local packet = Packet(MODULE_ID, 'join_request', { message = fragment1 });
            packet:encrypt('EtherHammer_' .. username, function()
                packet:sendToPlayer(player);
                -- Start the timer only after encrypting the packet and sending it.
                playerStatuses[username] = STATUS_SENT_VERIFICATION_REQUEST;
                playerRequestLast[username] = getTimeInMillis();
            end);

            playerStatuses[username] = STATUS_AWAIT_SENT_REQUEST;
        end

        --- Sends a followup request to cycle the key, requesting for the current key as well.
        ---
        --- @param player IsoPlayer The player object.
        --- @param username string The player username.
        ---
        --- @return void
        local requestHeartbeat = function(player, username)
            -- Create new server-side key-fragment.
            local fragment1 = getTimeInMillis();
            playerFragments[username] = fragment1;
            playerRequestLast[username] = fragment1;

            local packet = Packet(MODULE_ID, 'heartbeat_request', { message = fragment1 });
            packet:encrypt(playerKeys[username], function()
                packet:sendToPlayer(player);
                -- Start the timer only after encrypting the packet and sending it.
                playerStatuses[username] = STATUS_SENT_HEARTBEAT_REQUEST;
                playerRequestLast[username] = getTimeInMillis();
            end);

            playerStatuses[username] = STATUS_AWAIT_SENT_HEARTBEAT_REQUEST;
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
            kickPlayerFromServer(player, reason);
        end

        --- Checks on the players' status and handles them.
        ---
        --- @param player IsoPlayer The player to check.
        --- @param username string The username of the player.
        ---
        --- @return void
        local function onPlayerTick(player, username)
            local status = playerStatuses[username];

            if status == STATUS_AWAIT_GREET then
                
                local timeNow = getTimeInMillis();
                local timeRequest = playerRequestLast[username];

                if timeRequest == nil then
                    timeRequest = getTimeInMillis();
                    playerRequestLast[username] = timeRequest;
                end

                if timeNow - timeRequest > TIME_TO_GREET * 1000 then
                    kick(player, username);
                    return;
                end

            elseif status == STATUS_AWAIT_VERIFICATION then
                requestVerification(player, username);
            elseif status == STATUS_SENT_VERIFICATION_REQUEST then
                local timeNow = getTimeInMillis();
                local timeRequest = playerRequestLast[username];

                -- If greater than TIME_TO_VERIFY Seconds, kick player.
                if timeNow - timeRequest > TIME_TO_VERIFY * 1000 then
                    kick(player, username);
                    return;
                end
            elseif status == STATUS_VERIFIED then
                if SHOULD_HEARTBEAT then
                    local timeNow = getTimeInMillis();
                    local timeRequest = playerRequestLast[username];

                    if timeNow - timeRequest > TIME_TO_HEARTBEAT * 1000 then
                        requestHeartbeat(player, username);
                    end
                end
            elseif status == STATUS_SENT_HEARTBEAT_REQUEST then
                local timeNow = getTimeInMillis();
                local timeRequest = playerRequestLast[username];

                if timeNow - timeRequest > TIME_TO_VERIFY * 1000 then
                    kick(player, username);
                    return;
                end
            end
        end

        --- Handles packets received for each player.
        ---
        --- @param player IsoPlayer The player that sent the packet.
        --- @param id string The identity of the packet sent.
        --- @param data table Additional data provided for the packet.
        ---
        --- @return void
        local function onReceivePacket(player, id, data)
            if id == 'join_response' or id == 'heartbeat_response' then
                local username = player:getUsername();

                -- Create the next key.
                local fragment1 = playerFragments[username];
                local fragment2 = data.message;

                -- (Heartbeat) Verify that the returned key is the current key.
                if id == 'heartbeat_response' then
                    local keyOld = playerKeys[username];
                    if data.key ~= keyOld then
                        kick(player, username);
                        return;
                    end
                end

                -- Create the next key.
                playerKeys[username] = MODULE_ID .. '_' .. username .. fragment1 .. fragment2;

                -- The player is now verified.
                playerStatuses[username] = STATUS_VERIFIED;

                if id == 'join_response' then
                    print('[EtherHammer] :: Player \'' .. tostring(username) .. '\' verified.');
                elseif id == 'heartbeat_response' then
                    -- print('[EtherHammer] :: Player \'' .. tostring(username) .. '\' reverified.');
                end

            elseif id == 'handshake_request' then
                local username = player:getUsername();
                requestVerification(player, username);
            end
        end

        local function onPlayerLogin(player)
            local username = player:getUsername();

            -- Signal that the player needs verification.
            playerStatuses[username] = STATUS_AWAIT_GREET;
            playerKeys[username] = MODULE_ID .. '_' .. username;

            print('[EtherHammer] :: Player \'' .. tostring(username) .. '\' joined the game.');
            onPlayerTick(player, username);
        end

        local function onPlayerLogout(player)
            local username = player:getUsername();
            processLogout(username);
            print('[EtherHammer] :: Player \'' .. tostring(username) .. '\' left the game.');
        end

        --- @type number
        local tickTimeNow = -1;
        --- @type number
        local tickTimeLast = -1;

        local function onTick()
            tickTimeNow = getTimeInMillis();

            -- Only run once every TIME_TO_TICK second(s).
            if tickTimeNow - tickTimeLast < TIME_TO_TICK * 1000 then return end
            tickTimeLast = tickTimeNow;

            for username, player in pairs(PlayerListener.players) do
                onPlayerTick(player, username);
            end
        end

        Events.OnClientCommand.Add(function(module, command, player, args)
            
            if module ~= MODULE_ID then return end

            local username = player:getUsername();

            local packet = Packet(module, command, args);

            packet:decrypt(playerKeys[username], function()
                onReceivePacket(player, packet.command, packet.data);
            end);

        end);

        Events.OnServerPlayerLogin.Add(onPlayerLogin);
        Events.OnServerPlayerLogout.Add(onPlayerLogout);
        Events.OnTickEvenPaused.Add(onTick);
    end

    Events.OnServerStarted.Add(run);
end)();
