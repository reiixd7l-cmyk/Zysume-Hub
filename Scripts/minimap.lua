-- Minimap Script
-- v2.0 - Refactored for performance and stability.

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

--[[
  Draws the static UI for the minimap (background and border) for a single player.
  This should only be called once per spawn.
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

--[[
  Clears the static minimap frame for a player.
]]
function ClearMinimapFrame(playerPeer)
    local players = { playerPeer }
    local startId = minimapConfig.frameBaseId
    local endId = startId + minimapConfig.maxFrameElements
    for i = startId, endId do
        ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.None, Color32(0,0,0,0), Color32(0,0,0,0), "", i, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    end
end

--[[
  Clears all player dots for a specific viewing player.
]]
function ClearAllDots(playerPeer)
    local players = { playerPeer }
    local startId = minimapConfig.dotsBaseId
    local endId = startId + minimapConfig.maxPlayers
    for i = startId, endId do
        ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.None, Color32(0,0,0,0), Color32(0,0,0,0), "", i, 0, 0, 0, 0, 0, 0, 0, 0, 0)
    end
end

--[[
  Clears the entire minimap (frame and dots) for a player.
]]
function ClearMinimap(playerPeer)
    ClearMinimapFrame(playerPeer)
    ClearAllDots(playerPeer)
end

--[[
  ============================================================================
  Core Logic
  ============================================================================
]]

--[[
  Calculates a player's position on the minimap relative to the local player.
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

--[[
  Draws a single player dot on the minimap.
  Uses a predictable event ID based on the dot-player's ID.
]]
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

    -- Use a predictable Event ID for each dot based on the player being drawn
    local dotEventId = config.dotsBaseId + otherPlayer.Id
    local players = { localPlayer.Peer }
    -- Duration should be slightly longer than the tick rate to avoid flickering
    local duration = config.dotTickRate + 0.05

    ServerSendNetLib.EventMessage(players, {}, "", "", Util.EventType.Box,
        dotColor, dotColor, "", dotEventId, duration,
        screenX, screenY, config.dotSize, config.dotSize, 0, 0,
        config.dotFadeIn, config.dotFadeOut)
end

--[[
  Main update loop for player dots.
]]
function UpdateMinimapDots(player)
    -- This clears all dot IDs. Since we're redrawing them immediately with a short duration,
    -- this is effectively a refresh, not a flicker.
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
  Event Handlers
  ============================================================================
]]
local minimap_handlers = {}

function minimap_handlers:OnGameTick(gameTick)
    local allPlayers = GameServer.GameManager.Instance.players
    for _, player in pairs(allPlayers) do
        if player and not player:IsDead() and not player:IsSpectator() then
            local state = playerMinimapState[player.Id]
            if state then
                -- Throttle dot updates for performance
                if gameTick > state.lastDotUpdate + minimapConfig.dotTickRate then
                    UpdateMinimapDots(player)
                    state.lastDotUpdate = gameTick
                end
            end
        end
    end
end

function minimap_handlers:OnPlayerSpawn(player)
    if player then
        playerMinimapState[player.Id] = { frameDrawn = true, lastDotUpdate = 0 }
        DrawMinimapFrame(player.Peer)
    end
end

function minimap_handlers:OnPlayerDied(player, killer, weapon, headshot)
    if player and playerMinimapState[player.Id] then
        ClearMinimap(player.Peer)
        playerMinimapState[player.Id] = nil
    end
end

function minimap_handlers:OnPlayerDisconnected(player)
    if player and playerMinimapState[player.Id] then
        -- No need to clear UI for a disconnected player, the client will handle it.
        playerMinimapState[player.Id] = nil
    end
end

function minimap_handlers:OnMatchStart()
    -- This is a good place to ensure all players get the frame.
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
    local handlerInstance = setmetatable({}, { __index = minimap_handlers })

    RegisterEventHandler("OnGameTick", "OnGameTick", handlerInstance)
    RegisterEventHandler("OnPlayerSpawn", "OnPlayerSpawn", handlerInstance)
    RegisterEventHandler("OnPlayerDied", "OnPlayerDied", handlerInstance)
    RegisterEventHandler("OnPlayerDisconnected", "OnPlayerDisconnected", handlerInstance)
    RegisterEventHandler("OnMatchStart", "OnMatchStart", handlerInstance)

    Log("Minimap Script v2.0 Initialized.")
end

Init()