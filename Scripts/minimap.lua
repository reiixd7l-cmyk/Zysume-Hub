-- ==========================================
-- 🗺️ ASCII Minimap v3.0 (Fixed with EventMessage)
-- Works on Kontra uLua
-- ==========================================

local radar = {
    WIDTH = 20,
    HEIGHT = 10,
    RANGE = 60,
    UPDATE_TICK_RATE = 10, -- Update every 10 ticks (approx 3 times per second at 30tps)
    BASE_EVENT_ID = 55000 -- High number to avoid conflicts
}

-- Build ASCII box text
local function BuildRadar(centerPeer)
    local centerEntity = centerPeer.Player.NetworkEntityPlayer
    if not centerEntity or not centerEntity.transform or not centerEntity.transform.position then return "" end
    local centerPos = centerEntity.transform.position

    -- Create grid
    local grid = {}
    for y = 1, radar.HEIGHT do
        grid[y] = {}
        for x = 1, radar.WIDTH do
            grid[y][x] = "."
        end
    end

    local cx, cy = math.floor(radar.WIDTH / 2), math.floor(radar.HEIGHT / 2)
    grid[cy][cx] = "<color=#00FFFF>●</color>" -- you (cyan dot)

    -- Other players
    if not Server or not Server.playerSessions then return "" end
    for _, otherPeer in ipairs(Server.playerSessions) do
        if otherPeer and otherPeer.Player and otherPeer ~= centerPeer then
            local otherEntity = otherPeer.Player.NetworkEntityPlayer
            if otherEntity and not otherEntity:get_Dead() and otherEntity.transform and otherEntity.transform.position then
                local pos = otherEntity.transform.position
                local dx, dz = pos.x - centerPos.x, pos.z - centerPos.z

                if math.abs(dx) < radar.RANGE and math.abs(dz) < radar.RANGE then
                    local gx = math.floor((dx / radar.RANGE) * (radar.WIDTH / 2) + cx)
                    local gy = math.floor((-dz / radar.RANGE) * (radar.HEIGHT / 2) + cy)

                    gx = math.max(1, math.min(radar.WIDTH, gx))
                    gy = math.max(1, math.min(radar.HEIGHT, gy))

                    if not (gx == cx and gy == cy) then
                        local colorTag = "<color=#FF0000>R</color>" -- Red for enemy
                        if otherEntity.team == centerEntity.team then
                            colorTag = "<color=#00FF00>G</color>" -- Green for teammate
                        end
                        grid[gy][gx] = colorTag
                    end
                end
            end
        end
    end

    local top = " <color=#FFFFFF><--------------- ></color>\n"
    local bottom = " <color=#FFFFFF><--------------- ></color>"
    local body = ""
    for y = 1, radar.HEIGHT do
        body = body .. "<color=#FFFFFF>|</color> "
        for x = 1, radar.WIDTH do
            body = body .. grid[y][x]
        end
        body = body .. " <color=#FFFFFF>|</color>\n"
    end
    return top .. body .. bottom
end

Server = Server or {}

function Server:Start()
    print("ASCII Minimap v3.0 Initialized.")
end

-- Update on game tick
function Server:OnGameTick(gameTick)
    if gameTick % radar.UPDATE_TICK_RATE ~= 0 then return end
    if not Server or not Server.playerSessions then return end

    for _, peer in ipairs(Server.playerSessions) do
        if peer and peer.Player then
            local playerEntity = peer.Player.NetworkEntityPlayer
            if playerEntity and not playerEntity:get_Dead() then
                local mapText = BuildRadar(peer)
                if mapText ~= "" then
                    local eventId = radar.BASE_EVENT_ID + peer.Player.Id
                    local players = { peer }

                    ServerSendNetLib.EventMessage(players, {}, "", mapText, Util.EventType.None,
                        Color32(0,0,0,0), Color32(0,0,0,0), -- Colors are ignored due to tags in text
                        "", eventId, 2, 10, 10, 0, 0, 0, 12, 0, 0.1)
                end
            end
        end
    end
end

local function ClearMinimapForPlayer(player)
    if player and player.Id ~= nil then
        local peer = Server.playerSessions[player.Id + 1]
        if peer then
            local eventId = radar.BASE_EVENT_ID + player.Id
            -- Send an empty message with duration 0 to clear the event
            ServerSendNetLib.EventMessage({peer}, {}, "", "", Util.EventType.None, Color32(0,0,0,0), Color32(0,0,0,0), "", eventId, 0, 0,0,0,0,0,0,0,0)
        end
    end
end

function Server:OnPlayerDied(player, killer, weapon, headshot)
    ClearMinimapForPlayer(player)
end

function Server:OnPlayerLeft(player)
    ClearMinimapForPlayer(player)
end