-- 添加错误处理来检查WindUI加载
local WindUI
local success, error = pcall(function()
    local windUISource = game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua")
    WindUI = loadstring(windUISource)()
end)

if not success then
    warn("WindUI加载失败: " .. tostring(error))
    -- 创建简单的错误显示UI
    local errorGui = Instance.new("ScreenGui")
    errorGui.Name = "ErrorUI"
    errorGui.Parent = game:GetService("CoreGui")
    
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(0, 400, 0, 100)
    errorLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
    errorLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    errorLabel.TextColor3 = Color3.new(1, 1, 1)
    errorLabel.Text = "WindUI加载失败: " .. tostring(error)
    errorLabel.TextWrapped = true
    errorLabel.Parent = errorGui
    
    errorLabel.Text = errorLabel.Text .. "\n请检查网络连接或WindUI URL是否正确"
    return
end


local Window = WindUI:CreateWindow({
    Title = "Hokl4多功能脚本整合",
    Size = UDim2.fromOffset(500, 600),
    Theme = "Dark",
    Transparent = true,  -- 启用半透明
})

local Tabs = {
    Main = Window:Tab({ Title = "主菜单", Icon = "home" }),
    Common = Window:Tab({ Title = "通用功能", Icon = "settings" }),
    ESP = Window:Tab({ Title = "绘制功能", Icon = "eye" }),
    Aim = Window:Tab({ Title = "预判瞄准", Icon = "target" }),
    Game99Nights = Window:Tab({ Title = "99 Nights", Icon = "moon" }),
    GameBladeBall = Window:Tab({ Title = "Blade Ball", Icon = "sports_esports" }),
    GameDoors = Window:Tab({ Title = "Doors", Icon = "door_front" }),
    Translate = Window:Tab({ Title = "自动翻译", Icon = "language" })
}


-- 主菜单
Tabs.Main:Paragraph({
    Title = "Hokl4多功能脚本整合",
    Desc = "整合了AlienX冷脚本和矢井凛源码功能\n作者: Yux6 整合版",
    Color = "Blue"
})

Tabs.Main:Button({
    Title = "加载所有功能",
    Desc = "加载并初始化所有脚本功能",
    Callback = function()
        WindUI:Notify({
            Title = "Hokl4",
            Content = "所有功能已加载完成！",
            Duration = 3
        })
    end
})

-- 移除原有的基础和输入标签页内容，将功能整合到新的标签页中

-- 初始化变量
local lp = game:GetService("Players").LocalPlayer

-- 确保角色完全加载
local character
if lp.Character then
    character = lp.Character
else
    warn("等待角色加载...")
    character = lp.CharacterAdded:Wait()
    warn("角色已加载: " .. character.Name)
end

-- 确保关键部件存在
local humanoid, hrp
local success, error = pcall(function()
    humanoid = character:WaitForChild("Humanoid", 5)
    hrp = character:WaitForChild("HumanoidRootPart", 5)
end)

if not success or not humanoid or not hrp then
    warn("角色部件加载失败: " .. tostring(error))
    -- 创建错误提示
    local errorGui = Instance.new("ScreenGui")
    errorGui.Name = "CharacterErrorUI"
    errorGui.Parent = game:GetService("CoreGui")
    
    local errorLabel = Instance.new("TextLabel")
    errorLabel.Size = UDim2.new(0, 400, 0, 100)
    errorLabel.Position = UDim2.new(0.5, -200, 0.5, -50)
    errorLabel.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    errorLabel.TextColor3 = Color3.new(1, 1, 1)
    errorLabel.Text = "角色部件加载失败: " .. tostring(error)
    errorLabel.TextWrapped = true
    errorLabel.Parent = errorGui
    
    return
end

warn("角色初始化完成")

-- 存储所有事件连接，用于清理，防止内存泄漏
local eventConnections = {}

-- 通知函数
function Notify(title, text, duration)
    duration = duration or 3
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = duration
    })
end

-- 统一的错误处理函数
function SafeCall(func, moduleName)
    moduleName = moduleName or "Unknown Module"
    local success, err = pcall(func)
    if not success then
        local errorMsg = moduleName .. " 错误: " .. tostring(err)
        warn(errorMsg)
        return false, errorMsg
    end
    return true
end

-- 通用功能模块
CommonFeatures = {
    -- 飞行功能
    FlyEnabled = false,
    FlySpeed = 50,
    
    ToggleFly = function(self, state)
        self.FlyEnabled = state
        if state then
            Notify("Hokl4", "飞行模式已开启", 2)
            spawn(function()
                while self.FlyEnabled and hrp and character and character:IsDescendantOf(workspace) do
                    if hrp then
                        local moveDir = Vector3.new(
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) and 1 or 0) - 
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) and 1 or 0),
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) and 1 or 0) - 
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftControl) and 1 or 0),
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) and 1 or 0) - 
                            (game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) and 1 or 0)
                        )
                        
                        if hrp then
                            hrp.Velocity = moveDir.Unit * self.FlySpeed
                        wait(0.05)  -- 添加等待时间以避免性能问题
                        end
                    end
                    wait(0.05)  -- 降低更新频率以提高性能
                end
                if hrp then
                    hrp.Velocity = Vector3.new(0, 0, 0)
                end
            end)
        else
            Notify("Hokl4", "飞行模式已关闭", 2)
        end
    end,
    
    -- 无碰撞功能
    NoClipEnabled = false,
    
    ToggleNoClip = function(self, state)
        self.NoClipEnabled = state
        if state then
            Notify("Hokl4", "无碰撞已开启", 2)
            spawn(function()
                while self.NoClipEnabled do
                    for _, v in pairs(character:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CanCollide = false
                        end
                    end
                    wait(0.1)   -- 降低更新频率以提高性能
                end
                for _, v in pairs(character:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CanCollide = true
                    end
                end
            end)
        else
            Notify("Hokl4", "无碰撞已关闭", 2)
        end
    end,
    
    -- 夜视功能
    NightVisionEnabled = false,
    NightVisionEffect = nil,
    
    ToggleNightVision = function(self, state)
        self.NightVisionEnabled = state
        if state then
            Notify("Hokl4", "夜视已开启", 2)
            -- 创建夜视效果
            if not self.NightVisionEffect then
                local overlay = Instance.new("ScreenGui")
                overlay.Name = "NightVisionOverlay"
                overlay.Parent = game:GetService("CoreGui")
                
                local frame = Instance.new("Frame")
                frame.Size = UDim2.new(1, 0, 1, 0)
                frame.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
                frame.BackgroundTransparency = 0.9
                frame.Parent = overlay
                
                self.NightVisionEffect = overlay
            else
                self.NightVisionEffect.Enabled = true
            end
        else
            Notify("Hokl4", "夜视已关闭", 2)
            if self.NightVisionEffect then
                self.NightVisionEffect.Enabled = false
            end
        end
    end,
    
    -- 无限跳跃功能
    InfiniteJumpEnabled = false,
    JumpBind = nil,
    
    ToggleInfiniteJump = function(self, state)
        self.InfiniteJumpEnabled = state
        if state then
            Notify("Hokl4", "无限跳跃已开启", 2)
            self.JumpBind = game:GetService("UserInputService").JumpRequest:Connect(function()
                if self.InfiniteJumpEnabled and humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end)
        else
            Notify("Hokl4", "无限跳跃已关闭", 2)
            if self.JumpBind then
                self.JumpBind:Disconnect()
                self.JumpBind = nil
            end
        end
    end,
    
    -- 设置移动速度
    SetWalkSpeed = function(self, speed)
        if humanoid then
            humanoid.WalkSpeed = speed
            Notify("Hokl4", "移动速度已设置为 " .. speed, 1)
        end
    end,
    
    -- 设置跳跃力量
    SetJumpPower = function(self, power)
        if humanoid then
            humanoid.JumpPower = power
            Notify("Hokl4", "跳跃力量已设置为 " .. power, 1)
        end
    end
}

-- 高级透视功能系统 - 整合并优化老外绘制2.lua
ESP = {
    enabled = false,
    parts = {},
    updateLoop = nil,
    
    -- ESP配置
    config = {
        -- 视觉配置
        boxColor = Color3.fromRGB(255, 0, 0),
        boxTransparency = 0.3,
        nameColor = Color3.fromRGB(255, 255, 255),
        distanceColor = Color3.fromRGB(0, 255, 255),
        healthColor = Color3.fromRGB(0, 255, 0),
        
        -- 功能开关
        showBox = true,
        showName = true,
        showDistance = true,
        showHealth = true,
        showTracer = false,
        
        -- 性能优化设置
        updateInterval = 0.1, -- 更新间隔（秒）
        maxDistance = 300, -- 最大显示距离
        dynamicUpdateRate = true, -- 动态更新频率
    },
    
    -- 切换ESP功能
    Toggle = function(self, state)
        self.enabled = state
        if state then
            Notify("Hokl4", "高级透视系统已开启", 2)
            self:SetupInitialESP()
            self:StartUpdateLoop()
        else
            Notify("Hokl4", "高级透视系统已关闭", 2)
            self:StopUpdateLoop()
            self:RemoveAllESP()
        end
    end,
    
    -- 设置初始ESP
    SetupInitialESP = function(self)
        self:RemoveAllESP()
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                self:AddESPToCharacter(player.Character)
            end
        end
    end,
    
    -- 添加ESP到角色
    AddESPToCharacter = function(self, character)
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local player = game:GetService("Players"):GetPlayerFromCharacter(character)
        if not player then return end
        
        if self.parts[character] then
            self:RemoveESPFromCharacter(character)
        end
        
        local espParts = {}
        
        if self.config.showBox then
            local box = Instance.new("BoxHandleAdornment")
            box.Name = "ESPBox"
            box.Adornee = character.HumanoidRootPart
            box.Size = Vector3.new(4, 6, 2)
            box.Color3 = self.config.boxColor
            box.AlwaysOnTop = true
            box.Transparency = self.config.boxTransparency
            box.ZIndex = 5
            box.Parent = character
            espParts.box = box
        end
        
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPInfo"
        billboard.AlwaysOnTop = true
        billboard.Size = UDim2.new(0, 250, 0, 100)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.Parent = character.HumanoidRootPart
        espParts.billboard = billboard
        
        if self.config.showName then
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Name = "NameLabel"
            nameLabel.Size = UDim2.new(1, 0, 0, 30)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = player.Name
            nameLabel.TextColor3 = self.config.nameColor
            nameLabel.TextSize = 14
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextStrokeTransparency = 0.5
            nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            nameLabel.Parent = billboard
            espParts.nameLabel = nameLabel
        end
        
        if self.config.showDistance then
            local distanceLabel = Instance.new("TextLabel")
            distanceLabel.Name = "DistanceLabel"
            distanceLabel.Size = UDim2.new(1, 0, 0, 20)
            distanceLabel.Position = UDim2.new(0, 0, 0, 30)
            distanceLabel.BackgroundTransparency = 1
            distanceLabel.Text = "距离: 0m"
            distanceLabel.TextColor3 = self.config.distanceColor
            distanceLabel.TextSize = 12
            distanceLabel.Font = Enum.Font.Gotham
            distanceLabel.TextStrokeTransparency = 0.5
            distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            distanceLabel.Parent = billboard
            espParts.distanceLabel = distanceLabel
        end
        
        if self.config.showHealth and character:FindFirstChild("Humanoid") then
            local healthLabel = Instance.new("TextLabel")
            healthLabel.Name = "HealthLabel"
            healthLabel.Size = UDim2.new(1, 0, 0, 20)
            healthLabel.Position = UDim2.new(0, 0, 0, 50)
            healthLabel.BackgroundTransparency = 1
            healthLabel.Text = "生命: 100%"
            healthLabel.TextColor3 = self.config.healthColor
            healthLabel.TextSize = 12
            healthLabel.Font = Enum.Font.Gotham
            healthLabel.TextStrokeTransparency = 0.5
            healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
            healthLabel.Parent = billboard
            espParts.healthLabel = healthLabel
        end
        
        self.parts[character] = espParts
    end,
    
    -- 开始更新循环
    StartUpdateLoop = function(self)
        self:StopUpdateLoop()
        
        self.updateLoop = spawn(function()
            while self.enabled do
                local updateStart = os.clock()
                self:UpdateAllESP()
                
                if self.config.dynamicUpdateRate then
                    local updateTime = os.clock() - updateStart
                    local targetInterval = math.max(0.05, self.config.updateInterval)
                    wait(math.max(0, targetInterval - updateTime))
                else
                    wait(self.config.updateInterval)
                end
            end
        end)
    end,
    
    -- 停止更新循环
    StopUpdateLoop = function(self)
        if self.updateLoop then
            self.updateLoop = nil
        end
    end,
    
    -- 更新所有ESP
    UpdateAllESP = function(self)
        for character, _ in pairs(self.parts) do
            if not character or not character:FindFirstAncestorOfClass("Workspace") then
                self:RemoveESPFromCharacter(character)
            end
        end
        
        for character, parts in pairs(self.parts) do
            if character and character:FindFirstChild("HumanoidRootPart") then
                self:UpdateCharacterESP(character, parts)
            end
        end
        
        for _, player in pairs(game:GetService("Players"):GetPlayers()) do
            if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not self.parts[player.Character] then
                self:AddESPToCharacter(player.Character)
            end
        end
    end,
    
    -- 更新单个角色的ESP
    UpdateCharacterESP = function(self, character, parts)
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        -- 修复距离计算，使用玩家位置作为参考点
        local playerPos = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not playerPos then return end
        
        local distance = (hrp.Position - playerPos.Position).Magnitude
        local shouldShow = distance <= self.config.maxDistance
        
        for _, part in pairs(parts) do
            if part then
                part.Enabled = shouldShow
            end
        end
        
        if shouldShow then
            if parts.distanceLabel then
                parts.distanceLabel.Text = string.format("距离: %.1fm", distance)
            end
            
            if parts.healthLabel and character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                parts.healthLabel.Text = "生命: " .. healthPercent .. "%"
                
                if healthPercent > 70 then
                    parts.healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
                elseif healthPercent > 30 then
                    parts.healthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
                else
                    parts.healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
                end
            end
        end
    end,
    
    -- 从角色移除ESP
    RemoveESPFromCharacter = function(self, character)
        if self.parts[character] then
            for _, part in pairs(self.parts[character]) do
                if part and part.Parent then
                    part:Destroy()
                end
            end
            self.parts[character] = nil
        end
    end,
    
    -- 移除所有ESP
    RemoveAllESP = function(self)
        for character, _ in pairs(self.parts) do
            self:RemoveESPFromCharacter(character)
        end
        self.parts = {}
    end
}

-- 游戏特定模块
GameModules = {
    -- 99 Nights 模块
    Night99 = {
        KillAuraEnabled = false,
        AutoTreeEnabled = false,
        AutoEatEnabled = false,
        GodModeEnabled = false,
        
        ToggleKillAura = function(self, state)
            self.KillAuraEnabled = state
            if state then
                Notify("Hokl4", "杀戮光环已开启", 2)
                spawn(function()
                    while self.KillAuraEnabled and hrp and character and character:IsDescendantOf(workspace) do
                        if hrp then
                            local nearbyParts = workspace:FindPartsInRegion3(Region3.new(
                                hrp.Position - Vector3.new(20, 20, 20),
                                hrp.Position + Vector3.new(20, 20, 20)
                            ), character, 30)
                            
                            local processedMobs = {}
                            
                            for _, part in pairs(nearbyParts) do
                                local mob = part:FindFirstAncestorWhichIsA("Model")
                                if mob and not processedMobs[mob] and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
                                    processedMobs[mob] = true
                                    if (mob.HumanoidRootPart.Position - hrp.Position).Magnitude < 15 then
                                        local hitMobEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") 
                                        if hitMobEvent then
                                            hitMobEvent = hitMobEvent:FindFirstChild("HitMob")
                                            if hitMobEvent then
                                                hitMobEvent:FireServer(mob)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        wait(0.2)
                    end
                end)
            else
                Notify("Hokl4", "杀戮光环已关闭", 2)
            end
        end,
        
        ToggleAutoTree = function(self, state)
            self.AutoTreeEnabled = state
            if state then
                Notify("Hokl4", "自动砍树已开启", 2)
                spawn(function()
                    while self.AutoTreeEnabled do
                        if hrp then
                            for _, tree in pairs(workspace:GetDescendants()) do
                                if tree:IsA("BasePart") and tree.Name == "Tree" then
                                    if (tree.Position - hrp.Position).Magnitude < 10 then
                                        local chopTreeEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("ChopTree")
                                        if chopTreeEvent then
                                            chopTreeEvent:FireServer(tree)
                                        end
                                    end
                                end
                            end
                        end
                        wait(0.5)
                    end
                end)
            else
                Notify("Hokl4", "自动砍树已关闭", 2)
            end
        end,
        
        ToggleAutoEat = function(self, state)
            self.AutoEatEnabled = state
            if state then
                Notify("Hokl4", "自动进食已开启", 2)
                spawn(function()
                    while self.AutoEatEnabled do
                        if lp.Character and lp.Character.Humanoid.Health < lp.Character.Humanoid.MaxHealth then
                            for _, food in pairs(lp.Backpack:GetChildren()) do
                                if food.Name:find("Food") then
                                    food.Parent = lp.Character
                                    wait(0.1)
                                    break
                                end
                            end
                        end
                        wait(1)
                    end
                end)
            else
                Notify("Hokl4", "自动进食已关闭", 2)
            end
        end,
        
        ToggleGodMode = function(self, state)
            self.GodModeEnabled = state
            if state then
                Notify("Hokl4", "无敌模式已开启", 2)
                spawn(function()
                    while self.GodModeEnabled do
                        if humanoid then
                            humanoid.Health = humanoid.MaxHealth
                        end
                        wait(0.1)
                    end
                end)
            else
                Notify("Hokl4", "无敌模式已关闭", 2)
            end
        end
    },
    
    -- Blade Ball 模块
    BladeBall = {
        AutoHitEnabled = false,
        AutoDodgeEnabled = false,
        
        ToggleAutoHit = function(self, state)
            self.AutoHitEnabled = state
            if state then
                Notify("Hokl4", "自动击球已开启", 2)
                spawn(function()
                    while self.AutoHitEnabled do
                        if hrp then
                            local ball = workspace:FindFirstChild("Ball")
                            if ball and ball:IsA("BasePart") then
                                if (ball.Position - hrp.Position).Magnitude < 10 then
                                    local hitBallEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("HitBall")
                                    if hitBallEvent then
                                        hitBallEvent:FireServer()
                                    end
                                end
                            end
                        end
                        wait(0.05)
                    end
                end)
            else
                Notify("Hokl4", "自动击球已关闭", 2)
            end
        end,
        
        ToggleAutoDodge = function(self, state)
            self.AutoDodgeEnabled = state
            if state then
                Notify("Hokl4", "自动闪避已开启", 2)
                
                local dodgeConfig = {
                    warningDistance = 15,
                    criticalDistance = 8,
                    maxPredictionSteps = 10,
                    stepTime = 0.1,
                    safeZoneRadius = 5,
                    movementSpeed = 40,
                    emergencySpeed = 50
                }
                
                local function predictBallTrajectory(ball, steps, stepTime)
                    local trajectory = {}
                    local currentPos = ball.Position
                    local currentVel = ball.Velocity
                    
                    for i = 1, steps do
                        table.insert(trajectory, currentPos)
                        currentPos = currentPos + currentVel * stepTime
                        currentVel = currentVel - Vector3.new(0, 196.2 * stepTime, 0)
                    end
                    
                    return trajectory
                end
                
                local function findOptimalDodgePosition(playerPos, ball, trajectory)
                    local ballDir = ball.Velocity.Unit
                    local perpendicular1 = Vector3.new(-ballDir.Z, 0, ballDir.X)
                    local perpendicular2 = Vector3.new(ballDir.Z, 0, -ballDir.X)
                    
                    local dodgePos1 = playerPos + perpendicular1 * 10
                    local dodgePos2 = playerPos + perpendicular2 * 10
                    
                    local dist1 = #(trajectory[1] - dodgePos1)
                    local dist2 = #(trajectory[1] - dodgePos2)
                    
                    if dist1 > dist2 then
                        return dodgePos1
                    else
                        return dodgePos2
                    end
                end
                
                spawn(function()
                    while self.AutoDodgeEnabled do
                        SafeCall(function()
                            local character = game.Players.LocalPlayer.Character
                            local currentHrp = character and character:FindFirstChild("HumanoidRootPart")
                            local humanoid = character and character:FindFirstChild("Humanoid")
                            
                            if currentHrp and humanoid then
                                local ball = workspace:FindFirstChild("Ball")
                                if ball and ball:IsA("BasePart") then
                                    local ballPos = ball.Position
                                    local ballVel = ball.Velocity
                                    local playerPos = currentHrp.Position
                                    
                                    local distanceToBall = #(playerPos - ballPos)
                                    
                                    if ballVel.Magnitude > 10 then
                                        local trajectory = predictBallTrajectory(ball, dodgeConfig.maxPredictionSteps, dodgeConfig.stepTime)
                                        local optimalDodgePos = findOptimalDodgePosition(playerPos, ball, trajectory)
                                        currentHrp.Velocity = (optimalDodgePos - playerPos).Unit * dodgeConfig.movementSpeed
                                    end
                                end
                            end
                        end)
                        wait(0.05)
                    end
                end)
            else
                Notify("Hokl4", "自动闪避已关闭", 2)
                local character = game.Players.LocalPlayer.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:MoveTo(humanoid.RootPart.Position)
                end
            end
        end
    },
    
    -- Doors 功能
    Doors = {
        AutoCollect = false,
        GodMode = false,
        damageLog = {},  -- 记录被拦截的伤害
        godModeConnection = nil,
        
        ToggleAutoCollect = function(self, state)
            self.AutoCollect = state
            if state then
                Notify("Hokl4", "Doors自动收集已开启", 2)
                spawn(function()
                    while self.AutoCollect and hrp and character and character:IsDescendantOf(workspace) do
                        if hrp then
                            local nearbyParts = workspace:FindPartsInRegion3(Region3.new(
                                hrp.Position - Vector3.new(20, 20, 20),
                                hrp.Position + Vector3.new(20, 20, 20)
                            ), nil, 50)
                            
                            for _, item in pairs(nearbyParts) do
                                if (item.Name:find("Key") or item.Name:find("Item")) then
                                    if (item.Position - hrp.Position).Magnitude < 15 then
                                        hrp.CFrame = CFrame.new(item.Position)
                                        wait(0.5)
                                        break
                                    end
                                end
                            end
                        end
                        wait(0.2)
                    end
                end)
            else
                Notify("Hokl4", "Doors自动收集已关闭", 2)
            end
        end,
        
        ToggleGodMode = function(self, state)
            self.GodMode = state
            if state then
                Notify("Hokl4", "Doors无敌模式已开启", 2)
                if self.godModeConnection then
                    self.godModeConnection:Disconnect()
                end
                self.godModeConnection = humanoid.HealthChanged:Connect(function(health)
                    if self.GodMode and health < humanoid.MaxHealth then
                        humanoid.Health = humanoid.MaxHealth
                    end
                end)
            else
                Notify("Hokl4", "Doors无敌模式已关闭", 2)
                if self.godModeConnection then
                    self.godModeConnection:Disconnect()
                    self.godModeConnection = nil
                end
            end
        end
    }
}

-- 预判瞄准功能 - 完善版，增加墙壁检测和头部/身体选择
AimBot = {
    active = false,
    aimDuration = 1.7,
    aimTargets = { "Jason", "c00lkidd", "JohnDoe", "1x1x1x1", "Noli" },
    trackedAnimations = {
        ["103601716322988"] = true,
        ["133491532453922"] = true,
        ["86371356500204"] = true,
        ["76649505662612"] = true,
        ["81698196845041"] = true
    },
    predictionValue = 4,
    aimTargetType = "body", -- "head" or "body"
    
    Humanoid = nil,
    HRP = nil,
    lastTriggerTime = 0,
    aiming = false,
    originalWS = nil,
    originalJP = nil,
    originalAutoRotate = nil,
    
    -- 墙壁检测函数
    IsLineOfSight = function(self, from, to)
        local raycastParams = RaycastParams.new()
        raycastParams.FilterDescendantsInstances = {character}
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        
        local result = workspace:Raycast(from, to - from, raycastParams)
        return not result or (result.Position - from).Magnitude > (to - from).Magnitude * 0.9
    end,
    
    -- 获取有效目标
    getValidTarget = function(self)
        local killersFolder = workspace:FindFirstChild("Players") and workspace.Players:FindFirstChild("Killers")
        if killersFolder then
            for _, name in ipairs(self.aimTargets) do
                local target = killersFolder:FindFirstChild(name)
                if target and target:FindFirstChild("HumanoidRootPart") then
                    local targetPos = target.HumanoidRootPart.Position
                    if self.aimTargetType == "head" then
                        local head = target:FindFirstChild("Head")
                        if head then
                            targetPos = head.Position
                        end
                    end
                    
                    if self:IsLineOfSight(hrp.Position, targetPos) then
                        return target, targetPos
                    end
                end
            end
        end
        return nil, nil
    end,
    
    -- 获取播放中的动画ID
    getPlayingAnimationIds = function(self)
        local ids = {}
        if self.Humanoid then
            for _, track in ipairs(self.Humanoid:GetPlayingAnimationTracks()) do
                if track.Animation and track.Animation.AnimationId then
                    local id = track.Animation.AnimationId:match("%d+")
                    if id then
                        ids[id] = true
                    end
                end
            end
        end
        return ids
    end,
    
    -- 设置角色
    setupCharacter = function(self, char)
        self.Humanoid = char:WaitForChild("Humanoid")
        self.HRP = char:WaitForChild("HumanoidRootPart")
    end,
    
    -- 切换瞄准功能
    Toggle = function(self, state)
        self.active = state
        Notify("Hokl4", "预判瞄准 " .. (state and "已开启" or "已关闭"), 2)
    end,
    
    -- 设置预判值
    SetPrediction = function(self, value)
        self.predictionValue = value
        Notify("Hokl4", "预判值已设置为 " .. value, 1)
    end,
    
    -- 设置瞄准目标类型
    SetTargetType = function(self, type)
        self.aimTargetType = type
        Notify("Hokl4", "瞄准目标已设置为 " .. (type == "head" and "头部" or "身体"), 2)
    end
}

-- 初始化瞄准功能
if lp.Character then
    AimBot:setupCharacter(lp.Character)
end
lp.CharacterAdded:Connect(function(char)
    AimBot:setupCharacter(char)
end)

-- 瞄准功能主循环
game:GetService("RunService").RenderStepped:Connect(function()
    if not AimBot.active or not AimBot.Humanoid or not AimBot.HRP then return end

    local playing = AimBot:getPlayingAnimationIds()
    local triggered = false
    for id in pairs(AimBot.trackedAnimations) do
        if playing[id] then
            triggered = true
            break
        end
    end

    if triggered then
        AimBot.lastTriggerTime = tick()
        AimBot.aiming = true
    end

    if AimBot.aiming and tick() - AimBot.lastTriggerTime <= AimBot.aimDuration then
        if not AimBot.originalWS then
            AimBot.originalWS = AimBot.Humanoid.WalkSpeed
            AimBot.originalJP = AimBot.Humanoid.JumpPower
            AimBot.originalAutoRotate = AimBot.Humanoid.AutoRotate
        end

        AimBot.Humanoid.AutoRotate = false
        AimBot.HRP.AssemblyAngularVelocity = Vector3.zero

        local target, targetPos = AimBot:getValidTarget()
        if target and targetPos then
            local prediction = AimBot.predictionValue
            local predictedPos = targetPos + (target.HumanoidRootPart.CFrame.LookVector * prediction)
            local direction = (predictedPos - AimBot.HRP.Position).Unit
            local yRot = math.atan2(-direction.X, -direction.Z)
            AimBot.HRP.CFrame = CFrame.new(AimBot.HRP.Position) * CFrame.Angles(0, yRot, 0)
        end
    elseif AimBot.aiming then
        AimBot.aiming = false
        if AimBot.originalWS and AimBot.originalJP and AimBot.originalAutoRotate ~= nil then
            AimBot.Humanoid.WalkSpeed = AimBot.originalWS
            AimBot.Humanoid.JumpPower = AimBot.originalJP
            AimBot.Humanoid.AutoRotate = AimBot.originalAutoRotate
            AimBot.originalWS, AimBot.originalJP, AimBot.originalAutoRotate = nil, nil, nil
        end
    end
end)

-- 通用功能UI
Tabs.Common:Toggle({
    Title = "飞行模式",
    Desc = "启用或禁用飞行功能",
    Value = false,
    Callback = function(state)
        CommonFeatures:ToggleFly(state)
    end
})

Tabs.Common:Slider({
    Title = "飞行速度",
    Desc = "调整飞行速度",
    Value = {Min = 10, Max = 200, Default = 50},
    Callback = function(value)
        CommonFeatures.FlySpeed = value
        Notify("Hokl4", "飞行速度已设置为 " .. value, 1)
    end
})

Tabs.Common:Toggle({
    Title = "无碰撞",
    Desc = "启用或禁用无碰撞功能",
    Value = false,
    Callback = function(state)
        CommonFeatures:ToggleNoClip(state)
    end
})

Tabs.Common:Toggle({
    Title = "夜视",
    Desc = "启用或禁用夜视功能",
    Value = false,
    Callback = function(state)
        CommonFeatures:ToggleNightVision(state)
    end
})

Tabs.Common:Toggle({
    Title = "无限跳跃",
    Desc = "启用或禁用无限跳跃功能",
    Value = false,
    Callback = function(state)
        CommonFeatures:ToggleInfiniteJump(state)
    end
})

Tabs.Common:Slider({
    Title = "移动速度",
    Desc = "调整角色移动速度",
    Value = {Min = 16, Max = 200, Default = 16},
    Callback = function(value)
        CommonFeatures:SetWalkSpeed(value)
    end
})

Tabs.Common:Slider({
    Title = "跳跃力量",
    Desc = "调整角色跳跃力量",
    Value = {Min = 50, Max = 500, Default = 50},
    Callback = function(value)
        CommonFeatures:SetJumpPower(value)
    end
})

-- ESP绘制功能UI
Tabs.ESP:Toggle({
    Title = "启用ESP",
    Desc = "启用或禁用高级透视系统",
    Value = false,
    Callback = function(state)
        ESP:Toggle(state)
    end
})

Tabs.ESP:Toggle({
    Title = "显示方框",
    Desc = "显示或隐藏ESP方框",
    Value = true,
    Callback = function(state)
        ESP.config.showBox = state
    end
})

Tabs.ESP:Toggle({
    Title = "显示名称",
    Desc = "显示或隐藏玩家名称",
    Value = true,
    Callback = function(state)
        ESP.config.showName = state
    end
})

Tabs.ESP:Toggle({
    Title = "显示距离",
    Desc = "显示或隐藏距离信息",
    Value = true,
    Callback = function(state)
        ESP.config.showDistance = state
    end
})

Tabs.ESP:Toggle({
    Title = "显示生命值",
    Desc = "显示或隐藏生命值信息",
    Value = true,
    Callback = function(state)
        ESP.config.showHealth = state
    end
})

-- 预判瞄准功能UI
Tabs.Aim:Toggle({
    Title = "预判瞄准",
    Desc = "启用或禁用预判瞄准功能，带有墙壁检测",
    Value = false,
    Callback = function(state)
        AimBot:Toggle(state)
    end
})

Tabs.Aim:Slider({
    Title = "预判值",
    Desc = "调整目标位置预判距离",
    Value = {Min = 0, Max = 10, Default = 4},
    Callback = function(value)
        AimBot:SetPrediction(value)
    end
})

Tabs.Aim:Dropdown({
    Title = "瞄准部位",
    Desc = "选择瞄准头部或身体",
    Values = {"body", "head"},
    Value = "body",
    Callback = function(selected)
        AimBot:SetTargetType(selected)
    end
})

-- 99 Nights游戏功能UI
Tabs.Game99Nights:Toggle({
    Title = "杀戮光环",
    Desc = "自动攻击附近的敌人",
    Value = false,
    Callback = function(state)
        GameModules.Night99:ToggleKillAura(state)
    end
})

Tabs.Game99Nights:Toggle({
    Title = "自动砍树",
    Desc = "自动砍伐附近的树木",
    Value = false,
    Callback = function(state)
        GameModules.Night99:ToggleAutoTree(state)
    end
})

Tabs.Game99Nights:Toggle({
    Title = "自动进食",
    Desc = "自动使用食物恢复生命值",
    Value = false,
    Callback = function(state)
        GameModules.Night99:ToggleAutoEat(state)
    end
})

Tabs.Game99Nights:Toggle({
    Title = "无敌模式",
    Desc = "保持生命值满值",
    Value = false,
    Callback = function(state)
        GameModules.Night99:ToggleGodMode(state)
    end
})

-- Blade Ball游戏功能UI
Tabs.GameBladeBall:Toggle({
    Title = "自动击球",
    Desc = "自动击打靠近的球",
    Value = false,
    Callback = function(state)
        GameModules.BladeBall:ToggleAutoHit(state)
    end
})

Tabs.GameBladeBall:Toggle({
    Title = "自动闪避",
    Desc = "自动闪避飞来的球",
    Value = false,
    Callback = function(state)
        GameModules.BladeBall:ToggleAutoDodge(state)
    end
})

-- Doors游戏功能UI
Tabs.GameDoors:Toggle({
    Title = "自动收集",
    Desc = "自动收集钥匙和物品",
    Value = false,
    Callback = function(state)
        GameModules.Doors:ToggleAutoCollect(state)
    end
})

Tabs.GameDoors:Toggle({
    Title = "无敌模式",
    Desc = "保持生命值满值",
    Value = false,
    Callback = function(state)
        GameModules.Doors:ToggleGodMode(state)
    end
})

-- 自动翻译功能
Tabs.Translate:Button({
    Title = "加载自动翻译",
    Desc = "加载并启用自动翻译功能",
    Callback = function()
        local success, error = pcall(function()
            TX = "TX Script"
            Script = "全自动翻译"
            loadstring(game:HttpGet("https://raw.githubusercontent.com/JsYb666/Item/refs/heads/main/Auto-language"))()
            WindUI:Notify({
                Title = "自动翻译",
                Content = "自动翻译功能已加载",
                Duration = 3
            })
        end)
        if not success then
            WindUI:Notify({
                Title = "自动翻译",
                Content = "加载失败: " .. error,
                Duration = 3
            })
        end
    end
})

Tabs.Translate:Paragraph({
    Title = "翻译功能说明",
    Desc = "点击按钮加载自动翻译脚本，该功能将自动翻译游戏内文本。",
    Color = "Grey"
})

Window:SelectTab(1)


WindUI:Notify({
    Title = "UI就绪",
    Content = "Hokl4多功能脚本整合已加载",
    Duration = 3
})