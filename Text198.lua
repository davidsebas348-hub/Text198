-- ===============================
-- FOLLOW DETRÁS + CAMERA LOCK SOLO SI NO TENEMOS Knife
-- SOLO JUGADORES FUERA DE LOBBY + NPCs
-- ===============================

if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Camera = Workspace.CurrentCamera
local botsFolder = Workspace:WaitForChild("Bots")

local currentTarget = nil
local followDistance = 3
local firstTeleportDone = false
local followActive = false

-- ===============================
-- Funciones
-- ===============================

-- Comprobar si tenemos una herramienta equipada distinta a Knife
local function shouldFollow()
    local char = LocalPlayer.Character
    if not char then return false end

    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            if tool.Name ~= "Knife" then
                return true -- Activar seguimiento si no es Knife
            else
                return false -- No activar si es Knife
            end
        end
    end
    return false
end

-- Buscar siguiente objetivo válido
local function findNextTarget()
    -- Jugadores fuera de Lobby
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer 
           and plr.Team 
           and plr.Team.Name ~= "Lobby" 
           and plr.Character 
           and plr.Character:FindFirstChild("HumanoidRootPart") then
           
            local hum = plr.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                return plr.Character
            end
        end
    end

    -- NPCs (todos)
    for _, npc in pairs(botsFolder:GetChildren()) do
        if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
            local hum = npc:FindFirstChild("Humanoid")
            if not hum or hum.Health > 0 then
                return npc
            end
        end
    end

    return nil
end

-- Crear BodyPosition + BodyGyro
local function ensureBody(char)
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not hrp:FindFirstChild("FollowBP") then
        local bp = Instance.new("BodyPosition")
        bp.Name = "FollowBP"
        bp.MaxForce = Vector3.new(1e5,1e5,1e5)
        bp.P = 1e4
        bp.D = 100
        bp.Position = hrp.Position
        bp.Parent = hrp
    end

    if not hrp:FindFirstChild("FollowBG") then
        local bg = Instance.new("BodyGyro")
        bg.Name = "FollowBG"
        bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
        bg.P = 1e4
        bg.D = 100
        bg.CFrame = hrp.CFrame
        bg.Parent = hrp
    end
end

-- Detectar respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    firstTeleportDone = false
end)

-- ===============================
-- Loop principal
-- ===============================
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    -- Actualizar estado de seguimiento según Tool equipada
    followActive = shouldFollow()
    if not followActive then
        -- Si ya no debemos seguir, reiniciamos variables
        firstTeleportDone = false
        currentTarget = nil
        return
    end

    -- Cambiar objetivo si murió o desapareció
    if not currentTarget or not currentTarget.Parent or (currentTarget:FindFirstChild("Humanoid") and currentTarget.Humanoid.Health <= 0) then
        currentTarget = findNextTarget()
        firstTeleportDone = false
    end

    if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
        local targetHRP = currentTarget.HumanoidRootPart

        -- Primer teletransporte instantáneo detrás del objetivo
        if not firstTeleportDone then
            hrp.CFrame = targetHRP.CFrame - targetHRP.CFrame.LookVector * followDistance + Vector3.new(0,1,0)
            firstTeleportDone = true
        end

        -- Seguimiento suave
        ensureBody(char)
        local bp = hrp:FindFirstChild("FollowBP")
        local bg = hrp:FindFirstChild("FollowBG")

        if bp and bg then
            local backPos = targetHRP.Position - targetHRP.CFrame.LookVector * followDistance + Vector3.new(0,1,0)
            bp.Position = backPos
            bg.CFrame = CFrame.new(hrp.Position, targetHRP.Position)
        end

        -- Cámara lock al objetivo
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, targetHRP.Position)
    end
end)
