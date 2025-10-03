-- Minimap Script
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
    frameBaseId = 21000, -- Range for the static frame
    dotsBaseId = 21100,  -- Range for player dots (up to 64 players)
    maxFrameElements = 100, -- Max elements for the frame, for clearing
    maxPlayers = 64, -- Max players supported for dot IDs
    -- Visuals
    borderThickness = 2,
    cornerSize = 15,
    dashLength = 10,
    dashGap = 8,
    dotSize = 6,
    playerColor = Color32(0, 255, 255, 255), -- Cyan
    teamColor = Color32(0, 255, 0, 255), -- Green
    enemyColor = Color32(255, 0, 0, 255), -- Red
    dotTickRate = 0.1, -- How often to update dots
    dotFadeIn = 0.0,
    dotFadeOut = 0.05
}

-- Tracks the state of the minimap for each player
-- e.g., { [playerId] = { frameDrawn = true, lastDotUpdate = 0 } }
local playerMinimapState = {}


--[[
  ============================================================================
  UI Drawing and Clearing Functions
  ============================================================================
]]

function DrawMinimapFrame(playerPeer)
    local players = { playerPeer }
    local spectators = {}
    local duration = 99999 -- "Infinite" duration
    local alignment = 0 -- Top-left
    local eventId = minimapConfig.frameBaseId

    local function getNextFrameEventId()
        eventId = eventId + 1
        return eventId
    end

    -- 1. Background
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, minimapConfig.bgColor, minimapConfig.bgColor, "", getNextFrameEventId(), duration, minimapConfig.x, minimapConfig.y, minimapConfig.size, minimapConfig.size, alignment, 0, 0, 0)

    -- 2. Corners and Dashes
    local cornerSize, thickness = minimapConfig.cornerSize, minimapConfig.borderThickness
    local mapX, mapY, mapSize = minimapConfig.x, minimapConfig.y, minimapConfig.size
    local borderColor = minimapConfig.borderColor

    -- Top-left
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX, mapY, cornerSize, thickness, alignment, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX, mapY, thickness, cornerSize, alignment, 0, 0, 0)
    -- Top-right
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX + mapSize - cornerSize, mapY, cornerSize, thickness, alignment, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX + mapSize - thickness, mapY, thickness, cornerSize, alignment, 0, 0, 0)
    -- Bottom-left
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX, mapY + mapSize - thickness, cornerSize, thickness, alignment, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX, mapY + mapSize - cornerSize, thickness, cornerSize, alignment, 0, 0, 0)
    -- Bottom-right
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX + mapSize - cornerSize, mapY + mapSize - thickness, cornerSize, thickness, alignment, 0, 0, 0)
    ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX + mapSize - thickness, mapY + mapSize - cornerSize, thickness, cornerSize, alignment, 0, 0, 0)

    -- Dashed Lines
    local dashLen, dashGap = minimapConfig.dashLength, minimapConfig.dashGap
    local totalDash = dashLen + dashGap
    -- Horizontal
    local startX = mapX + cornerSize + dashGap
    local endX = mapX + mapSize - cornerSize - dashGap
    for x = startX, endX, totalDash do
        local len = math.min(dashLen, endX - x)
        if len > 0 then
            ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, x, mapY, len, thickness, alignment, 0, 0, 0)
            ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, x, mapY + mapSize - thickness, len, thickness, alignment, 0, 0, 0)
        end
    end
    -- Vertical
    local startY = mapY + cornerSize + dashGap
    local endY = mapY + mapSize - cornerSize - dashGap
    for y = startY, endY, totalDash do
        local len = math.min(dashLen, endY - y)
        if len > 0 then
            ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX, y, thickness, len, alignment, 0, 0, 0)
            ServerSendNetLib.EventMessage(players, spectators, "", "", Util.EventType.Box, borderColor, borderColor, "", getNextFrameEventId(), duration, mapX + mapSize - thickness, y, thickness, len, alignment, 0, 0, 0)
        end
    end
end

function ClearMinimapFrame(playerPeer)
    local players = { playerPeer }
    local startId = minimapConfig.frameBaseId
    local endId = startId + minimapConfig.maxFrameElements
    for i = startId, endId do
        ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.None, Color32(0,0,0,0), Color32(0,0,0,0), "", i, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    end
end

function ClearAllDots(playerPeer)
    local players = { playerPeer }
    local startId = minimapConfig.dotsBaseId
    local endId = startId + minimapConfig.maxPlayers
    for i = startId, endId do
        ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.None, Color32(0,0,0,0), Color32(0,0,0,0), "", i, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    end
end

function ClearMinimap(playerPeer)
    ClearMinimapFrame(playerPeer)
    ClearAllDots(playerPeer)
end

--[[
  ============================================================================
  Core Logic
  ============================================================================
]]

function WorldToMinimap(otherPlayerPos, localPlayer, config)
    local localPos = localPlayer.position
    local localYawRad = math.rad(localPlayer.rotation.y)
    local cosYaw, sinYaw = math.cos(localYawRad), math.sin(localYawRad)
    local deltaPos = otherPlayerPos - localPos
    local rotatedX = deltaPos.x * cosYaw + deltaPos.z * sinYaw
    local rotatedZ = -deltaPos.x * sinYaw + deltaPos.z * cosYaw
    return rotatedX / config.scale, -rotatedZ / config.scale
end

function DrawPlayerDot(localPlayer, otherPlayer, config)
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
    local players = { localPlayer.Peer }
    local duration = config.dotTickRate + 0.05

    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box,
        dotColor, dotColor, "", dotEventId, duration,
        screenX, screenY, config.dotSize, config.dotSize, 0, 0,
        config.dotFadeIn, config.dotFadeOut)
end

function UpdateMinimapDots(player)
    ClearAllDots(player.Peer)

    local allPlayers = GameServer.GameManager.Instance.players
    for _, otherPlayer in pairs(allPlayers) do
        if otherPlayer and not otherPlayer:IsDead() and not otherPlayer:IsSpectator() then
            DrawPlayerDot(player, otherPlayer, minimapConfig)
        end
    end
end

--[[
  ============================================================================
  Event Handlers (Global)
  ============================================================================
]]

function Minimap_OnGameTick(gameTick)
    local allPlayers = GameServer.GameManager.Instance.players
    for _, player in pairs(allPlayers) do
        if player and not player:IsDead() and not player:IsSpectator() then
            local state = playerMinimapState[player.Id]
            if state then
                if gameTick > state.lastDotUpdate + minimapConfig.dotTickRate then
                    UpdateMinimapDots(player)
                    state.lastDotUpdate = gameTick
                end
            end
        end
    end
end

function Minimap_OnPlayerSpawn(player)
    if player then
        playerMinimapState[player.Id] = { frameDrawn = true, lastDotUpdate = 0 }
        DrawMinimapFrame(player.Peer)
    end
end

function Minimap_OnPlayerDied(player, killer, weapon, headshot)
    if player and playerMinimapState[player.Id] then
        ClearMinimap(player.Peer)
        playerMinimapState[player.Id] = nil
    end
end

function Minimap_OnPlayerDisconnected(player)
    if player and playerMinimapState[player.Id] then
        playerMinimapState[player.Id] = nil
    end
end

function Minimap_OnMatchStart()
    local allPlayers = GameServer.GameManager.Instance.players
    for _, player in pairs(allPlayers) do
        if player and not player:IsDead() and not player:IsSpectator() then
            if not playerMinimapState[player.Id] then
                 playerMinimapState[player.Id] = { frameDrawn = true, lastDotUpdate = 0 }
            end
            DrawMinimapFrame(player.Peer)
        end
    end
end

--[[
  Initialization
]]
function Init()
    RegisterEvent("OnGameTick", "Minimap_OnGameTick")
    RegisterEvent("OnPlayerSpawn", "Minimap_OnPlayerSpawn")
    RegisterEvent("OnPlayerDied", "Minimap_OnPlayerDied")
    RegisterEvent("OnPlayerDisconnected", "Minimap_OnPlayerDisconnected")
    RegisterEvent("OnMatchStart", "Minimap_OnMatchStart")

    Log("Minimap Script v2.1 Initialized.")
end

Init()