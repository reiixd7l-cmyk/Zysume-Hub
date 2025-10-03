-- Minimap Script
-- v2.4 - Corrected player state checks (get_Dead).
-- Author: rei
-- confidential script for thunder!
--DO NOT SHARE,THIS IS ONLY PRIVATE

-- ₲₳₮Ɇ₭ɆɆ₱ ɎØɄⱤ ₵ØĐɆ..
--In lines and loops your craft does lie,
--A treasure hidden from prying eyes.
--Share too freely, the sly will creep,
--And steal the work you vowed to keep.

--Guard your logic, lock your gates,
--Protect the keys that open fates.
--For in this world of code and scheme,
--Only the careful hold the dream.
-- protect this at all cost.

--[[
  Configuration
]]
local minimapConfig = {
    x = 40,
    y = 40,
    size = 160,
    scale = 35.0, -- World units per pixel. Smaller number = more zoomed in.
    bgColor = Color32(0, 0, 0, 120),
    borderColor = Color32(200, 200, 200, 180),
    -- Event ID Ranges
    frameBaseId = 21000,
    dotsBaseId = 21100,
    maxFrameElements = 100,
    maxPlayers = 64,
    -- Visuals
    borderThickness = 2,
    cornerSize = 15,
    dashLength = 10,
    dashGap = 8,
    dotSize = 6,
    playerColor = Color32(0, 255, 255, 255), -- Cyan
    teamColor = Color32(0, 255, 0, 255), -- Green
    enemyColor = Color32(255, 0, 0, 255), -- Red
    dotTickRate = 0.1,
    dotFadeIn = 0.0,
    dotFadeOut = 0.05
}

local playerMinimapState = {}

--[[
  ============================================================================
  UI Drawing and Clearing Functions (Helper Functions)
  ============================================================================
]]

function DrawMinimapFrame(playerPeer)
    local players = { playerPeer }
    local eventId = minimapConfig.frameBaseId
    local function getNextFrameEventId()
        eventId = eventId + 1
        return eventId
    end

    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, minimapConfig.bgColor, minimapConfig.bgColor, "", getNextFrameEventId(), 99999, minimapConfig.x, minimapConfig.y, minimapConfig.size, minimapConfig.size, 0, 0, 0, 0)

    local cornerSize, thickness, borderColor = minimapConfig.cornerSize, minimapConfig.borderThickness, minimapConfig.borderColor
    local mapX, mapY, mapSize = minimapConfig.x, minimapConfig.y, minimapConfig.size

    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX, mapY, cornerSize, thickness, 0, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX, mapY, thickness, cornerSize, 0, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX + mapSize - cornerSize, mapY, cornerSize, thickness, 0, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX + mapSize - thickness, mapY, thickness, cornerSize, 0, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX, mapY + mapSize - thickness, cornerSize, thickness, 0, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX, mapY + mapSize - cornerSize, thickness, cornerSize, 0, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX + mapSize - cornerSize, mapY + mapSize - thickness, cornerSize, thickness, 0, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX + mapSize - thickness, mapY + mapSize - cornerSize, thickness, cornerSize, 0, 0, 0, 0)

    local dashLen, dashGap = minimapConfig.dashLength, minimapConfig.dashGap
    local totalDash = dashLen + dashGap
    local startX, endX = mapX + cornerSize + dashGap, mapX + mapSize - cornerSize - dashGap
    for x = startX, endX, totalDash do
        local len = math.min(dashLen, endX - x)
        if len > 0 then
            ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, x, mapY, len, thickness, 0, 0, 0, 0)
            ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, x, mapY + mapSize - thickness, len, thickness, 0, 0, 0, 0)
        end
    end
    local startY, endY = mapY + cornerSize + dashGap, mapY + mapSize - cornerSize - dashGap
    for y = startY, endY, totalDash do
        local len = math.min(dashLen, endY - y)
        if len > 0 then
            ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX, y, thickness, len, 0, 0, 0, 0)
            ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), 99999, mapX + mapSize - thickness, y, thickness, len, 0, 0, 0, 0)
        end
    end
end

function ClearMinimapFrame(playerPeer)
    local players = { playerPeer }
    for i = minimapConfig.frameBaseId, minimapConfig.frameBaseId + minimapConfig.maxFrameElements do
        ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.None, Color32(0,0,0,0), Color32(0,0,0,0), "", i, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    end
end

function ClearAllDots(playerPeer)
    local players = { playerPeer }
    for i = minimapConfig.dotsBaseId, minimapConfig.dotsBaseId + minimapConfig.maxPlayers do
        ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.None, Color32(0,0,0,0), Color32(0,0,0,0), "", i, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    end
end

function ClearMinimap(playerPeer)
    ClearMinimapFrame(playerPeer)
    ClearAllDots(playerPeer)
end

function WorldToMinimap(otherPlayerPos, localPlayer, config)
    local localPos = localPlayer.position
    local localYawRad = math.rad(localPlayer.rotation.y)
    local cosYaw, sinYaw = math.cos(localYawRad), math.sin(localYawRad)
    local deltaPos = otherPlayerPos - localPos
    local rotatedX = deltaPos.x * cosYaw + deltaPos.z * sinYaw
    local rotatedZ = -deltaPos.x * sinYaw + deltaPos.z * cosYaw
    return rotatedX / config.scale, -rotatedZ / config.scale
end

function DrawPlayerDot(localPlayerPeer, localPlayer, otherPlayer, config)
    local mapX, mapY = WorldToMinimap(otherPlayer.position, localPlayer, config)
    local halfSize = config.size / 2
    local clampedX = math.max(-halfSize, math.min(halfSize, mapX))
    local clampedY = math.max(-halfSize, math.min(halfSize, mapY))

    local dotColor = config.enemyColor
    if otherPlayer.Id == localPlayer.Id then
        dotColor = config.playerColor
    elseif otherPlayer.team == localPlayer.team then
        dotColor = config.teamColor
    end

    local screenX = config.x + halfSize + clampedX - (config.dotSize / 2)
    local screenY = config.y + halfSize + clampedY - (config.dotSize / 2)

    local dotEventId = config.dotsBaseId + otherPlayer.Id
    local players = { localPlayerPeer }
    local duration = config.dotTickRate + 0.05

    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box,
        dotColor, dotColor, "", dotEventId, duration,
        screenX, screenY, config.dotSize, config.dotSize, 0, 0,
        config.dotFadeIn, config.dotFadeOut)
end

function UpdateMinimapDots(localPlayerPeer)
    if not localPlayerPeer or not localPlayerPeer.Player then return end
    local localPlayer = localPlayerPeer.Player:get_NetworkEntityPlayer()
    if not localPlayer then return end

    ClearAllDots(localPlayerPeer)

    if not Server or not Server.playerSessions then return end
    for _, otherPeer in ipairs(Server.playerSessions) do
        if otherPeer and otherPeer.Player then
            local otherPlayer = otherPeer.Player:get_NetworkEntityPlayer()
            if otherPlayer and not otherPlayer:get_Dead() then
                DrawPlayerDot(localPlayerPeer, localPlayer, otherPlayer, minimapConfig)
            end
        end
    end
end

--[[
  ============================================================================
  Event Handlers (Attached to Server Table)
  ============================================================================
]]

-- Create the main Server table if it doesn't exist
Server = Server or {}

function Server:Start()
    print("Minimap Script v2.4 Initialized.")
end

function Server:Stop()
    playerMinimapState = {}
    print("Minimap Script Stopped and Cleaned Up.")
end

function Server:OnGameTick(gameTick)
    if not Server or not Server.playerSessions then return end
    for _, peer in ipairs(Server.playerSessions) do
        if peer and peer.Player then
            local player = peer.Player:get_NetworkEntityPlayer()
            if player and not player:get_Dead() then
                local state = playerMinimapState[player.Id]
                if state and gameTick > state.lastDotUpdate + minimapConfig.dotTickRate then
                    UpdateMinimapDots(peer)
                    state.lastDotUpdate = gameTick
                end
            end
        end
    end
end

function Server:OnPlayerSpawn(player)
    if player and player.Id ~= nil then
        local peer = Server.playerSessions[player.Id + 1]
        if peer then
            playerMinimapState[player.Id] = { frameDrawn = true, lastDotUpdate = 0 }
            DrawMinimapFrame(peer)
        end
    end
end

function Server:OnPlayerDied(player, killer, weapon, headshot)
    if player and player.Id ~= nil and playerMinimapState[player.Id] then
        local peer = Server.playerSessions[player.Id + 1]
        if peer then
            ClearMinimap(peer)
        end
        playerMinimapState[player.Id] = nil
    end
end

function Server:OnPlayerLeft(player)
    if player and player.Id ~= nil and playerMinimapState[player.Id] then
        playerMinimapState[player.Id] = nil
    end
end

function Server:RoomStateChanged(roomState)
    if roomState == 6 then -- matchActive
        if not Server or not Server.playerSessions then return end
        for _, peer in ipairs(Server.playerSessions) do
            if peer and peer.Player then
                local player = peer.Player:get_NetworkEntityPlayer()
                if player and not player:get_Dead() then
                    if not playerMinimapState[player.Id] then
                         playerMinimapState[player.Id] = { frameDrawn = true, lastDotUpdate = 0 }
                    end
                    DrawMinimapFrame(peer)
                end
            end
        end
    end
end