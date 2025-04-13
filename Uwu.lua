-- SETTINGS
local AimbotRange = 800
local ESPColor = Color3.fromRGB(255, 0, 0)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local espBoxes = {}

-----------------------------------
-- UI SCREEN TOP RIGHT - "Made by CeoOfDims"
local function createCreditUI()
    local gui = Instance.new("ScreenGui")
    gui.Name = "CreditUI"
    gui.Parent = game.CoreGui

    local textLabel = Instance.new("TextLabel", gui)
    textLabel.Size = UDim2.new(0, 200, 0, 30)
    textLabel.Position = UDim2.new(1, -210, 0, 10) -- di kanan atas
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 18
    textLabel.Text = "Made by CeoOfDims"
end

createCreditUI()

-----------------------------------
-- ANTI-LAG SYSTEM
for _, obj in pairs(Workspace:GetDescendants()) do
    if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Explosion") then
        obj:Destroy()
    elseif obj:IsA("Decal") or obj:IsA("Texture") then
        obj.Transparency = 1
    elseif obj:IsA("MeshPart") then
        obj.Material = Enum.Material.SmoothPlastic
        obj.Reflectance = 0
    elseif obj:IsA("Lighting") then
        obj.GlobalShadows = false
        obj.FogEnd = 100000
    end
end

Workspace.Terrain.WaterWaveSize = 0
Workspace.Terrain.WaterWaveSpeed = 0
Workspace.Terrain.WaterReflectance = 0
Workspace.Terrain.WaterTransparency = 1

-----------------------------------
-- ESP BOX (Kotak)
local function createBox(player)
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = ESPColor
    box.Thickness = 2
    box.Transparency = 1
    espBoxes[player] = box
end

local function removeBox(player)
    if espBoxes[player] then
        espBoxes[player]:Remove()
        espBoxes[player] = nil
    end
end

-- Event buat player baru join (otomatis pas Character muncul)
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        wait(1)
        if player.Team ~= LocalPlayer.Team then
            if not espBoxes[player] then
                createBox(player)
            end
        end
    end)
end)

-- ESP Loop (update tiap frame)
RunService.RenderStepped:Connect(function()
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team 
           and player.Character and player.Character:FindFirstChild("HumanoidRootPart") 
           and player.Character:FindFirstChild("Head") and player.Character:FindFirstChild("Humanoid") then
           
            if not espBoxes[player] then
                createBox(player)
            end

            local hum = player.Character.Humanoid
            local hrp = player.Character.HumanoidRootPart
            local head = player.Character.Head

            if hum.Health > 0 then
                local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local feetPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))

                if onScreen then
                    local height = math.abs(headPos.Y - feetPos.Y)
                    local width = height / 2.5
                    espBoxes[player].Size = Vector2.new(width, height)
                    espBoxes[player].Position = Vector2.new(pos.X - width/2, pos.Y - height/2)
                    espBoxes[player].Visible = true
                else
                    espBoxes[player].Visible = false
                end
            else
                espBoxes[player].Visible = false
            end
        else
            removeBox(player)
        end
    end
end)

-----------------------------------
-- WALLCHECK FUNCTION untuk Aimbot
local function isVisible(targetPart)
    local origin = Camera.CFrame.Position
    local targetPos = targetPart.Position
    local direction = (targetPos - origin).Unit * (targetPos - origin).Magnitude
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
    local result = Workspace:Raycast(origin, direction, raycastParams)

    -- Cek apakah raycast kena sesuatu yang bukan bagian dari target
    if result and result.Instance:IsDescendantOf(targetPart.Parent) then
        return true
    end
    return false
end

-----------------------------------
-- AIMBOT dengan Wallcheck
local currentTarget = nil

local function getClosestEnemy()
    local closest, shortest = nil, AimbotRange
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team
           and player.Character and player.Character:FindFirstChild("Humanoid") 
           and player.Character:FindFirstChild("HumanoidRootPart") then

            local hrp = player.Character.HumanoidRootPart
            if player.Character.Humanoid.Health > 0 and isVisible(hrp) then
                local distance = (Camera.CFrame.Position - hrp.Position).Magnitude
                if distance < shortest then
                    shortest = distance
                    closest = player
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if not currentTarget or not currentTarget.Character 
       or currentTarget.Character.Humanoid.Health <= 0 
       or not isVisible(currentTarget.Character.HumanoidRootPart) then
        currentTarget = getClosestEnemy()
    end

    if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChild("HumanoidRootPart") then
        local aimPos = currentTarget.Character.HumanoidRootPart.Position
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, aimPos)
    end
end)

-----------------------------------
-- INFINITE JUMP
UserInputService.JumpRequest:Connect(function()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState("Jumping")
    end
end)
