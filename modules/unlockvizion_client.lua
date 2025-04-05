---[[
--- This file is for EtherHammerX.
---
--- This module checks the client for the presence of UnlockViZion.
---
--- @author asledgehammer, JabDoesThings 2025
---]]

--- @param square IsoGridSquare
--- @param radius number
--- @param northSouth boolean
---
--- @return IsoObject[] objects
local function getNearbyDoorsOrWindowsOrWindowFrames(square, radius, northSouth)
    local objects = {};
    local sx, sy, sz = square:getX(), square:getY(), square:getZ();

    local direction = IsoDirections.N;
    if not northSouth then direction = IsoDirections.W end

    if northSouth then
        local objectOrigin = square:getDoorOrWindowOrWindowFrame(direction, false);
        if objectOrigin then table.insert(objects, objectOrigin) end

        for o = 1, radius, 1 do
            local squareEast = getSquare(sx + o, sy, sz);
            local squareWest = getSquare(sx - o, sy, sz);
            if squareEast then
                local objectE = squareEast:getDoorOrWindowOrWindowFrame(IsoDirections.N, false);
                if objectE then table.insert(objects, objectE) end
            end
            if squareWest then
                local objectW = squareWest:getDoorOrWindowOrWindowFrame(IsoDirections.N, false);
                if objectW then table.insert(objects, objectW) end
            end
        end
    else
        local objectOrigin = square:getDoorOrWindowOrWindowFrame(direction, false);
        if objectOrigin then table.insert(objects, objectOrigin) end

        for o = 1, radius, 1 do
            local squareNorth = getSquare(sx, sy - o, sz);
            local squareSouth = getSquare(sx, sy + o, sz);
            if squareNorth then
                local objectN = squareNorth:getDoorOrWindowOrWindowFrame(IsoDirections.W, false);
                if objectN then table.insert(objects, objectN) end
            end
            if squareSouth then
                local objectS = squareSouth:getDoorOrWindowOrWindowFrame(IsoDirections.W, false);
                if objectS then table.insert(objects, objectS) end
            end
        end
    end

    return objects;
end

--- @param square IsoGridSquare
--- @param wall IsoObject
---
--- @return boolean result
local function isObjectVisuallyBlocking(square, wall, north)
    local result = false;
    local wallFlags = wall:getProperties():getFlagsList();
    if not north then
        local hasDoorFrame = wallFlags:contains(IsoFlagType.DoorWallN);
        if hasDoorFrame then
            local door = square:getIsoDoor();
            if not door then return false end
        end
        if wallFlags:contains(IsoFlagType.WallN) or wallFlags:contains(IsoFlagType.WallNW) then
            if not wallFlags:contains(IsoFlagType.trans) and not wallFlags:contains(IsoFlagType.transparentN) then
                return true;
            end
        end
    else
        local hasDoorFrame = wallFlags:contains(IsoFlagType.DoorWallW);
        if hasDoorFrame then
            local door = square:getIsoDoor();
            if not door then return false end
        end
        if wallFlags:contains(IsoFlagType.WallW) or wallFlags:contains(IsoFlagType.WallNW) then
            if not wallFlags:contains(IsoFlagType.trans) and not wallFlags:contains(IsoFlagType.transparentW) then
                return true;
            end
        end
    end
    return result;
end

--- @param origin IsoGridSquare
--- @param direction IsoDirections
--- @param ignoreOutside boolean
---
--- @return IsoGridSquare | nil, IsoGridSquare | nil result
local function getFirstBlockedSquare(origin, direction, ignoreOutside)
    local ox, oy, oz = origin:getX(), origin:getY(), origin:getZ();
    local offset = 1;
    --- @type IsoGridSquare | nil
    local current = nil;
    --- @type IsoGridSquare | nil
    local next = nil;
    local bFacingDirection = false;
    if direction == IsoDirections.E or direction == IsoDirections.W then
        bFacingDirection = true;
    end

    while current == nil do
        if direction == IsoDirections.N then
            current = getSquare(ox, oy - offset, oz);
            next = getSquare(ox, oy - (offset + 1), oz);
        elseif direction == IsoDirections.S then
            current = getSquare(ox, oy + offset, oz);
            next = getSquare(ox, oy + (offset + 1), oz);
        elseif direction == IsoDirections.E then
            current = getSquare(ox + offset, oy, oz);
            next = getSquare(ox + (offset + 1), oy, oz);
        elseif direction == IsoDirections.W then
            current = getSquare(ox - offset, oy, oz);
            next = getSquare(ox - (offset + 1), oy, oz);
        end

        -- Edge of loaded squares.
        if not current then
            return nil;
        elseif not next then
            return nil;
        end

        if not ignoreOutside or not next:isOutside() then
            local wall = current:getWall(not bFacingDirection);
            if wall ~= nil then
                local result = isObjectVisuallyBlocking(origin, wall, bFacingDirection);
                if result then
                    local test = true;
                    local objs = getNearbyDoorsOrWindowsOrWindowFrames(current, 5, not bFacingDirection);
                    if #objs then
                        for _, obj in ipairs(objs) do
                            local visionResult = tostring(obj:TestVision(origin, next));
                            if visionResult ~= 'Blocked' then
                                test = false;
                                break;
                            end
                        end
                    end
                    if test then
                        return current, next;
                    end
                end
            end
        end
        -- If not blocked, keep iterating until the square is nil when fetched or a blocked square
        -- is discovered.
        current = nil;
        offset = offset + 1;
    end

    return nil;
end

--- Tests whether a player (Who is currently inside of a tree square), can see around them. If this
--- is the case, the player is likely using a visibility cheat.
---
--- @param square IsoGridSquare The square to test around.
---
--- @return boolean result True if the player is detected as cheating.
local function testInsideTree(square)
    local level = square:getLightLevel(0);
    local squareN = square:getAdjacentPathSquare(IsoDirections.N);
    local levelN = squareN:getLightLevel(0);
    if level <= levelN then return true end
    local squareS = square:getAdjacentPathSquare(IsoDirections.S);
    local levelS = squareS:getLightLevel(0);
    if level <= levelS then return true end
    local squareE = square:getAdjacentPathSquare(IsoDirections.E);
    local levelE = squareE:getLightLevel(0);
    if level <= levelE then return true end
    local squareW = square:getAdjacentPathSquare(IsoDirections.W);
    local levelW = squareW:getLightLevel(0);
    if level <= levelW then return true end
    return false;
end

--- NOTE: This is ran once.
---
--- @param api EtherHammerXClientAPI Use this to gain access to EtherHammerX's API.
--- @param options table<string, any> Options passed to the module.
return function(api, options)
    --- @type number, number, number
    local pastSquareX, pastSquareY, pastSquareZ = -1, -1, -1;
    --- @type number
    local performedTreeTest = 0;
    --- @type IsoGridSquare | nil
    local squareLast = nil;

    --- @type function
    local onEveryMinuteStructureCheck;
    --- @type function
    local onTickTreeTest;

    local function addEvents()
        Events.OnTickEvenPaused.Add(onTickTreeTest);
        Events.EveryOneMinute.Add(onEveryMinuteStructureCheck);
    end

    local function removeEvents()
        Events.OnTickEvenPaused.Remove(onTickTreeTest);
        Events.EveryOneMinute.Remove(onEveryMinuteStructureCheck);
    end

    --- Tests whether a player (Who is currently outside of any structures), can see behind them. If
    --- this is the case, the player is likely using a visibility cheat.
    ---
    --- @param square IsoGridSquare The center square to test from.
    ---
    --- @return boolean, IsoDirections | nil, number | nil results True if the player is detected as cheating.
    local function testOutsideOcclusion(square)
        -- Check after first tick inside of square. Sometimes the light values haven't changed prior to
        -- executing this code, causing a false-positive result.
        if square ~= squareLast then
            squareLast = square;
            return false;
        end
        squareLast = square;

        local blockedSquareN, nextSquareN = getFirstBlockedSquare(square, IsoDirections.N, true);
        if blockedSquareN and nextSquareN then
            local level = nextSquareN:getLightLevel(0);
            if level > 0.33 then
                return true, IsoDirections.N, level;
            end
        end

        local blockedSquareS, nextSquareS = getFirstBlockedSquare(square, IsoDirections.S, true);
        if blockedSquareS and nextSquareS then
            local level = nextSquareS:getLightLevel(0);
            if level > 0.33 then
                return true, IsoDirections.S, level;
            end
        end

        local blockedSquareE, nextSquareE = getFirstBlockedSquare(square, IsoDirections.E, true);
        if blockedSquareE and nextSquareE then
            local level = nextSquareE:getLightLevel(0);
            if level > 0.33 then
                return true, IsoDirections.E, level;
            end
        end

        local blockedSquareW, nextSquareW = getFirstBlockedSquare(square, IsoDirections.W, true);
        if blockedSquareW and nextSquareW then
            local level = nextSquareW:getLightLevel(0);
            if level > 0.33 then
                return true, IsoDirections.W, level;
            end
        end

        return false, nil, nil;
    end

    onTickTreeTest = function()
        local ourPlayer = getPlayer();
        if not ourPlayer then return end

        -- (Issues with false-positives when inside a vehicle)
        if ourPlayer:isSeatedInVehicle() then
            return
            -- (Issues with false-positives on structure-checks)
        elseif ourPlayer:getZ() > 0 then
            return
        end

        --- @type IsoGridSquare
        local square = ourPlayer:getCurrentSquare();
        --- @type number, number, number
        local squareX, squareY, squareZ = square:getX(), square:getY(), square:getZ();

        if not square:getTree() then
            pastSquareX = squareX;
            pastSquareY = squareY;
            pastSquareZ = squareZ;
            performedTreeTest = 0;
            return;
        end

        if squareX == pastSquareX and squareY == pastSquareY and squareZ == pastSquareZ then
            if performedTreeTest == 20 then
                -- Check to see if the player is inside a tree. This becomes a simple check.
                if testInsideTree(square) then
                    api.report('UnlockViZion ', 'Inside Tree', true);
                    removeEvents();
                    return;
                end
                performedTreeTest = 21;
                -- performedTreeTest = true;
            else
                performedTreeTest = performedTreeTest + 1;
            end
        else
            pastSquareX = squareX;
            pastSquareY = squareY;
            pastSquareZ = squareZ;
            performedTreeTest = 0;
        end
    end

    onEveryMinuteStructureCheck = function()
        local ourPlayer = getPlayer();
        if not ourPlayer then return end

        -- (Issues with false-positives when inside a vehicle)
        if ourPlayer:isSeatedInVehicle() then
            return
            -- (Issues with false-positives on structure-checks)
        elseif ourPlayer:getZ() > 0 then
            return
        end

        --- @type IsoGridSquare
        local square = ourPlayer:getCurrentSquare();
        if square:isOutside() then
            local result = testOutsideOcclusion(square);
            if result then
                api.report('UnlockViZion', 'Structure Check #1', true);
                removeEvents();
                return;
            end
        end
    end

    addEvents();
end;
