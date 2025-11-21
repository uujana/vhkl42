-- Hokl4 Main Script - 作者: Yux6 整合版
-- 整合了AlienX冷脚本和矢井凛源码功能

-- 初始化变量
local lp = game:GetService("Players").LocalPlayer
local character = lp.Character or lp.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

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
        -- 可选：在调试模式下显示通知
        -- Notify("错误", errorMsg, 5)
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
    end,
    
    -- 高级透视功能系统
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
            
            -- 移动端优化
            mobileOptimized = isMobileDevice,
            mobileSimplified = false, -- 移动端简化模式
        },
        
        -- 切换ESP功能
        Toggle = function(self, state)
            self.enabled = state
            if state then
                Notify("Hokl4", "高级透视系统已开启", 2)
                
                -- 根据设备类型应用优化
                if self.config.mobileOptimized then
                    self:ApplyMobileOptimizations()
                end
                
                -- 设置初始ESP
                self:SetupInitialESP()
                
                -- 开始更新循环
                self:StartUpdateLoop()
                
                -- 监听玩家加入
                game:GetService("Players").PlayerAdded:Connect(function(player)
                    player.CharacterAdded:Connect(function(char)
                        wait(0.5) -- 等待角色完全加载
                        if self.enabled then
                            self:AddESPToCharacter(char)
                        end
                    end)
                end)
            else
                Notify("Hokl4", "高级透视系统已关闭", 2)
                self:StopUpdateLoop()
                self:RemoveAllESP()
            end
        end,
        
        -- 应用移动端优化
        ApplyMobileOptimizations = function(self)
            self.config.updateInterval = 0.2 -- 降低更新频率
            self.config.maxDistance = 200 -- 减少最大距离
            self.config.showTracer = false -- 禁用追踪线
            self.config.boxTransparency = 0.5 -- 增加透明度减少渲染负担
            
            -- 如果是低性能移动设备，可以启用简化模式
            if workspace.CurrentCamera.ViewportSize.Y < 600 then
                self.config.mobileSimplified = true
                self.config.showHealth = false -- 禁用健康值显示
                self.config.showDistance = false -- 禁用距离显示
            end
        end,
        
        -- 设置初始ESP
        SetupInitialESP = function(self)
            -- 清理现有ESP
            self:RemoveAllESP()
            
            -- 为所有玩家设置ESP
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
            
            -- 如果角色已有ESP，先移除
            if self.parts[character] then
                self:RemoveESPFromCharacter(character)
            end
            
            -- 根据角色比例动态计算ESP大小
            local size = self:CalculateCharacterSize(character)
            
            -- 创建ESP部件表
            local espParts = {}
            
            -- 创建方框
            if self.config.showBox and not self.config.mobileSimplified then
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox"
                box.Adornee = character.HumanoidRootPart
                box.Size = size
                box.Color3 = self.config.boxColor
                box.AlwaysOnTop = true
                box.Transparency = self.config.boxTransparency
                box.ZIndex = 5
                box.Parent = character
                espParts.box = box
            end
            
            -- 创建信息标签
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESPInfo"
            billboard.AlwaysOnTop = true
            billboard.Size = UDim2.new(0, 250, 0, 100) -- 更大的尺寸以容纳更多信息
            billboard.StudsOffset = Vector3.new(0, size.Y/2 + 0.5, 0)
            billboard.Parent = character.HumanoidRootPart
            espParts.billboard = billboard
            
            -- 创建玩家名称标签
            if self.config.showName then
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Name = "NameLabel"
                nameLabel.Size = UDim2.new(1, 0, 0, 30)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = player.Name
                nameLabel.TextColor3 = self.config.nameColor
                nameLabel.TextSize = self.config.mobileOptimized and 12 or 14
                nameLabel.Font = Enum.Font.GothamBold
                nameLabel.TextStrokeTransparency = 0.5
                nameLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                nameLabel.Parent = billboard
                espParts.nameLabel = nameLabel
            end
            
            -- 创建距离标签
            if self.config.showDistance and not self.config.mobileSimplified then
                local distanceLabel = Instance.new("TextLabel")
                distanceLabel.Name = "DistanceLabel"
                distanceLabel.Size = UDim2.new(1, 0, 0, 20)
                distanceLabel.Position = UDim2.new(0, 0, 0, 30)
                distanceLabel.BackgroundTransparency = 1
                distanceLabel.Text = "距离: 0m"
                distanceLabel.TextColor3 = self.config.distanceColor
                distanceLabel.TextSize = self.config.mobileOptimized and 10 or 12
                distanceLabel.Font = Enum.Font.Gotham
                distanceLabel.TextStrokeTransparency = 0.5
                distanceLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                distanceLabel.Parent = billboard
                espParts.distanceLabel = distanceLabel
            end
            
            -- 创建健康值标签
            if self.config.showHealth and not self.config.mobileSimplified and character:FindFirstChild("Humanoid") then
                local healthLabel = Instance.new("TextLabel")
                healthLabel.Name = "HealthLabel"
                healthLabel.Size = UDim2.new(1, 0, 0, 20)
                healthLabel.Position = UDim2.new(0, 0, 0, 50)
                healthLabel.BackgroundTransparency = 1
                healthLabel.Text = "生命: 100%"
                healthLabel.TextColor3 = self.config.healthColor
                healthLabel.TextSize = self.config.mobileOptimized and 10 or 12
                healthLabel.Font = Enum.Font.Gotham
                healthLabel.TextStrokeTransparency = 0.5
                healthLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
                healthLabel.Parent = billboard
                espParts.healthLabel = healthLabel
            end
            
            -- 保存ESP部件引用
            self.parts[character] = espParts
        end,
        
        -- 计算角色大小
        CalculateCharacterSize = function(self, character)
            -- 基础大小
            local baseSize = Vector3.new(4, 5, 2)
            
            -- 尝试根据实际角色计算更准确的大小
            if character:FindFirstChild("Humanoid") then
                local humanoid = character.Humanoid
                local scale = humanoid.BodyHeightScale.Value or 1
                return baseSize * Vector3.new(1, scale, 1)
            end
            
            return baseSize
        end,
        
        -- 开始更新循环
        StartUpdateLoop = function(self)
            -- 停止现有循环
            self:StopUpdateLoop()
            
            -- 创建新的更新循环
            self.updateLoop = spawn(function()
                while self.enabled do
                    local updateStart = os.clock()
                    
                    -- 更新所有ESP
                    self:UpdateAllESP()
                    
                    -- 动态调整更新间隔以优化性能
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
                -- 在Roblox中，我们无法直接杀死协程，但设置enabled=false会让循环自然结束
                self.updateLoop = nil
            end
        end,
        
        -- 更新所有ESP
        UpdateAllESP = function(self)
            -- 清理不存在的角色ESP
            for character, _ in pairs(self.parts) do
                if not character or not character:FindFirstAncestorOfClass("Workspace") then
                    self:RemoveESPFromCharacter(character)
                end
            end
            
            -- 更新存在的ESP
            for character, parts in pairs(self.parts) do
                if character and character:FindFirstChild("HumanoidRootPart") then
                    self:UpdateCharacterESP(character, parts)
                end
            end
            
            -- 检查并添加新玩家的ESP
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
            
            -- 检查距离，如果超出范围则隐藏
            local distance = (hrp.Position - (character.Parent == workspace and hrp.Position or hrp.Position)).Magnitude
            local shouldShow = distance <= self.config.maxDistance
            
            -- 更新显示状态
            for _, part in pairs(parts) do
                if part then
                    part.Enabled = shouldShow
                end
            end
            
            if shouldShow then
                -- 更新距离标签
                if parts.distanceLabel then
                    parts.distanceLabel.Text = string.format("距离: %.1fm", distance)
                end
                
                -- 更新健康值标签
                if parts.healthLabel and character:FindFirstChild("Humanoid") then
                    local humanoid = character.Humanoid
                    local healthPercent = math.floor((humanoid.Health / humanoid.MaxHealth) * 100)
                    parts.healthLabel.Text = "生命: " .. healthPercent .. "%"
                    
                    -- 根据健康值改变颜色
                    if healthPercent > 70 then
                        parts.healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- 绿色
                    elseif healthPercent > 30 then
                        parts.healthLabel.TextColor3 = Color3.fromRGB(255, 255, 0) -- 黄色
                    else
                        parts.healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- 红色
                    end
                end
                
                -- 动态调整方框大小（如果角色比例改变）
                if parts.box then
                    local newSize = self:CalculateCharacterSize(character)
                    parts.box.Size = newSize
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
        end,
        
        -- 设置ESP颜色
        SetColor = function(self, element, color)
            if self.config[element .. "Color"] then
                self.config[element .. "Color"] = color
                
                -- 立即更新所有现有ESP
                for _, parts in pairs(self.parts) do
                    if parts[element .. "Label"] then
                        parts[element .. "Label"].TextColor3 = color
                    end
                    if element == "box" and parts.box then
                        parts.box.Color3 = color
                    end
                end
            end
        end,
        
        -- 设置ESP透明度
        SetTransparency = function(self, transparency)
            self.config.boxTransparency = math.clamp(transparency, 0, 1)
            
            -- 更新所有方框透明度
            for _, parts in pairs(self.parts) do
                if parts.box then
                    parts.box.Transparency = self.config.boxTransparency
                end
            end
        end,
        
        -- 切换特定ESP元素
        ToggleElement = function(self, element, state)
            if self.config["show" .. element:sub(1, 1):upper() .. element:sub(2)"] ~= nil then
                self.config["show" .. element:sub(1, 1):upper() .. element:sub(2)"] = state
                
                -- 更新现有ESP显示
                for character, parts in pairs(self.parts) do
                    local elementName = element == "box" and "box" or element .. "Label"
                    if parts[elementName] then
                        parts[elementName].Enabled = state
                    elseif not state then
                        -- 如果要关闭且该元素不存在，可能需要重新创建ESP
                        self:RemoveESPFromCharacter(character)
                        self:AddESPToCharacter(character)
                    end
                end
            end
        end,
        
        -- 获取ESP状态
        GetStatus = function(self)
            return {
                enabled = self.enabled,
                activeTargets = #self.parts,
                config = table.clone(self.config)
            }
        end
    },
    
    -- 兼容旧版ESP接口
    ESPEnabled = false,
    ESPParts = {},
    
    ToggleESP = function(self, state)
        self.ESPEnabled = state
        self.ESP:Toggle(state)
        -- 同步到旧版数据结构以保持兼容性
        self.ESPParts = self.ESP.parts
    end,
    
    SetupCharacterESP = function(self, char)
        if char then
            self.ESP:AddESPToCharacter(char)
        else
            self.ESP:SetupInitialESP()
        end
    end,
    
    AddESPToCharacter = function(self, character)
        self.ESP:AddESPToCharacter(character)
    end,
    
    RemovePlayerESP = function(self)
        self.ESP:RemoveAllESP()
    end,
    
    -- 配置方法，供兼容性管理器使用
    SetUpdateInterval = function(self, interval)
        if self.ESP and self.ESP.SetUpdateInterval then
            self.ESP:SetUpdateInterval(interval)
            Notify("Hokl4", "透视更新间隔已设置为 " .. tostring(interval) .. " 秒", 2)
        end
    end,
    
    SetMaxRenderDistance = function(self, distance)
        if self.ESP and self.ESP.SetMaxRenderDistance then
            self.ESP:SetMaxRenderDistance(distance)
            Notify("Hokl4", "透视最大渲染距离已设置为 " .. tostring(distance), 2)
        end
    end,
    
    SetVisualEffects = function(self, enabled)
        if self.ESP and self.ESP.SetVisualEffects then
            self.ESP:SetVisualEffects(enabled)
            Notify("Hokl4", "透视视觉效果已" .. (enabled and "开启" or "关闭"), 2)
        end
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
                        -- 杀戮光环逻辑 - 移动设备优化版本
                        if hrp then
                            -- 移动设备优化：使用区域搜索替代GetDescendants
                            local nearbyParts = workspace:FindPartsInRegion3(Region3.new(
                                hrp.Position - Vector3.new(20, 20, 20),
                                hrp.Position + Vector3.new(20, 20, 20)
                            ), character, 30)
                            
                            -- 存储已处理的模型，避免重复处理
                            local processedMobs = {}
                            
                            for _, part in pairs(nearbyParts) do
                                local mob = part:FindFirstAncestorWhichIsA("Model")
                                if mob and not processedMobs[mob] and mob:FindFirstChild("Humanoid") and mob:FindFirstChild("HumanoidRootPart") then
                                    processedMobs[mob] = true
                                    if (mob.HumanoidRootPart.Position - hrp.Position).Magnitude < 15 then
                                        -- 攻击逻辑
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
                        wait(0.2)  -- 降低频率以提高移动设备性能
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
                        -- 自动砍树逻辑
                        if hrp then
                            for _, tree in pairs(workspace:GetDescendants()) do
                                if tree:IsA("BasePart") and tree.Name == "Tree" then
                                    if (tree.Position - hrp.Position).Magnitude < 10 then
                                        -- 砍树逻辑
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
                        -- 自动进食逻辑
                        if lp.Character and lp.Character.Humanoid.Health < lp.Character.Humanoid.MaxHealth then
                            -- 使用食物逻辑
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
                        -- 自动击球逻辑
                        if hrp then
                            local ball = workspace:FindFirstChild("Ball")
                            if ball and ball:IsA("BasePart") then
                                if (ball.Position - hrp.Position).Magnitude < 10 then
                                    -- 击球逻辑
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
                
                -- 闪避配置参数
                local dodgeConfig = {
                    warningDistance = 15,      -- 开始预警的距离
                    criticalDistance = 8,      -- 开始强力闪避的距离
                    maxPredictionSteps = 10,   -- 预测步数
                    stepTime = 0.1,            -- 每步时间间隔
                    safeZoneRadius = 5,        -- 安全区域半径
                    movementSpeed = 40,        -- 移动速度
                    emergencySpeed = 50        -- 紧急情况下的移动速度
                }
                
                -- 预测球的运动轨迹
                local function predictBallTrajectory(ball, steps, stepTime)
                    local trajectory = {}
                    local currentPos = ball.Position
                    local currentVel = ball.Velocity
                    
                    for i = 1, steps do
                        table.insert(trajectory, currentPos)
                        currentPos = currentPos + currentVel * stepTime
                        -- 简单物理模拟：考虑重力影响
                        currentVel = currentVel - Vector3.new(0, 196.2 * stepTime, 0)
                    end
                    
                    return trajectory
                end
                
                -- 计算玩家到轨迹的最短距离
                local function getDistanceToTrajectory(playerPos, trajectory)
                    local minDist = math.huge
                    local collisionPoint = nil
                    
                    for i = 1, #trajectory - 1 do
                        local p1, p2 = trajectory[i], trajectory[i+1]
                        local dist, point = math.DistancePointToLineSegment(playerPos, p1, p2)
                        if dist < minDist then
                            minDist = dist
                            collisionPoint = point
                        end
                    end
                    
                    return minDist, collisionPoint
                end
                
                -- 查找最佳闪避位置
                local function findOptimalDodgePosition(playerPos, ball, trajectory)
                    -- 找出球前进方向的垂直方向
                    local ballDir = ball.Velocity.Unit
                    local perpendicular1 = Vector3.new(-ballDir.Z, 0, ballDir.X)
                    local perpendicular2 = Vector3.new(ballDir.Z, 0, -ballDir.X)
                    
                    -- 计算两个可能的闪避方向
                    local dodgePos1 = playerPos + perpendicular1 * 10
                    local dodgePos2 = playerPos + perpendicular2 * 10
                    
                    -- 检查哪个方向更安全
                    local dist1 = #(trajectory[1] - dodgePos1)
                    local dist2 = #(trajectory[1] - dodgePos2)
                    
                    -- 选择更远的那个方向
                    if dist1 > dist2 then
                        return dodgePos1
                    else
                        return dodgePos2
                    end
                end
                
                -- 检查是否可以安全移动到目标位置
                local function isSafeToMove(startPos, endPos)
                    local raycastParams = RaycastParams.new()
                    raycastParams.FilterDescendantsInstances = {game.Players.LocalPlayer.Character}
                    raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                    
                    local result = workspace:Raycast(startPos, endPos - startPos, raycastParams)
                    return not result or result.Distance > #(endPos - startPos) * 0.9
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
                                    
                                    -- 计算球与玩家的距离
                                    local distanceToBall = #(playerPos - ballPos)
                                    
                                    -- 只有当球有足够速度且距离合适时才进行预测
                                    if ballVel.Magnitude > 10 then
                                        -- 预测球的运动轨迹
                                        local trajectory = predictBallTrajectory(ball, dodgeConfig.maxPredictionSteps, dodgeConfig.stepTime)
                                        
                                        -- 计算到轨迹的最短距离
                                        local minDistance, collisionPoint = getDistanceToTrajectory(playerPos, trajectory)
                                        
                                        -- 根据风险等级采取不同的闪避策略
                                        if minDistance < dodgeConfig.criticalDistance then
                                            -- 紧急情况：立即快速闪避
                                            local optimalDodgePos = findOptimalDodgePosition(playerPos, ball, trajectory)
                                            if isSafeToMove(playerPos, optimalDodgePos) then
                                                currentHrp.Velocity = (optimalDodgePos - playerPos).Unit * dodgeConfig.emergencySpeed
                                            else
                                                -- 如果第一个方向不安全，尝试反方向
                                                local alternativeDodgePos = playerPos + (playerPos - optimalDodgePos)
                                                if isSafeToMove(playerPos, alternativeDodgePos) then
                                                    currentHrp.Velocity = (alternativeDodgePos - playerPos).Unit * dodgeConfig.emergencySpeed
                                                end
                                            end
                                        elseif minDistance < dodgeConfig.warningDistance then
                                            -- 警告情况：平滑移动到安全区域
                                            local safeZone = findOptimalDodgePosition(playerPos, ball, trajectory)
                                            if isSafeToMove(playerPos, safeZone) then
                                                humanoid:MoveTo(safeZone)
                                            end
                                        end
                                    end
                                end
                            end
                        end)
                        wait(0.05)
                    end
                end)
            else
                Notify("Hokl4", "自动闪避已关闭", 2)
                -- 停止任何正在进行的移动
                local character = game.Players.LocalPlayer.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:MoveTo(humanoid.RootPart.Position)
                end
            end
        end
    },
    
    -- AlienX模块
    AlienX = {
        -- 初始化状态
        Features = {
            KillAura = false,
            AutoChop = false,
            AutoEat = false,
            ESP = false,
            AutoCollect = false
        },
        
        -- ESP对象存储
        ESPObjects = {},
        
        -- 物品收集列表
        Collectibles = {
            -- 武器装备
            "枪", "剑", "刀", "弓", "盾", "盔甲", "护甲", "头盔", "靴子", "手套",
            -- 制作物品
            "木头", "石头", "金属", "布料", "绳索", "食物", "水", "药", "绷带", "子弹",
            -- 其他物品
            "宝箱", "钥匙", "金币", "钻石", "能量", "油", "燃料"
        },
        
        -- 杀戮光环
        ToggleKillAura = function(self, enabled)
            self.Features.KillAura = enabled
            Notify("AlienX", enabled and "杀戮光环已开启" or "杀戮光环已关闭", 2)
            
            if enabled then
                spawn(function()
                    while self.Features.KillAura do
                        SafeCall(function()","},{"old_str":"                                        pcall(function()","new_str":"                                        SafeCall(function()",
                            for _, v in pairs(workspace:GetChildren()) do
                                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name ~= Character.Name then
                                    local humanoid = v:FindFirstChild("Humanoid")
                                    if humanoid and humanoid.Health > 0 then
                                        -- 调用远程事件进行攻击
                                        local args = {v.HumanoidRootPart, Vector3.new(math.random(-100, 100), math.random(-100, 100), math.random(-100, 100))}
                                        pcall(function()
                                            local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
                                            if remoteEvent then
                                                    local weaponHitEvent = remoteEvent:FindFirstChild("WeaponHit")
                                if weaponHitEvent then
                                    weaponHitEvent:FireServer(unpack(args))
                                end
                                            end
                                        end)
                                    end
                                end
                            end
                        end, "KillAura")
                        wait(0.1)
                    end
                end)
            end
        end,
        
        -- 自动砍树
        ToggleAutoChop = function(self, enabled)
            self.Features.AutoChop = enabled
            Notify("AlienX", enabled and "自动砍树已开启" or "自动砍树已关闭", 2)
            
            if enabled then
                spawn(function()
                    while self.Features.AutoChop do
                        pcall(function()
                            for _, v in pairs(workspace:GetChildren()) do
                                if v.Name == "Tree" or v.Name == "树" then
                                    for _, part in pairs(v:GetChildren()) do
                                        if part:IsA("BasePart") then
                                            SafeCall(function()
                                                 local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
                                                 if remoteEvent then
                                                     local treeHitEvent = remoteEvent:FindFirstChild("TreeHit")
                                                      if treeHitEvent then
                                                          treeHitEvent:FireServer(part)
                                                      end
                                                 end
                                             end, "TreeHit")
                                            wait(0.1)
                                        end
                                    end
                                end
                            end
                        end, "WeaponHit")
                        wait(0.5)
                    end
                end)
            end
        end,
        
        -- 自动进食
        ToggleAutoEat = function(self, enabled)
            self.Features.AutoEat = enabled
            Notify("AlienX", enabled and "自动进食已开启" or "自动进食已关闭", 2)
            
            if enabled then
                spawn(function()
                    while self.Features.AutoEat do
                        pcall(function()
                            local character = Player.Character or Player.CharacterAdded:Wait()
                            local humanoid = character:FindFirstChild("Humanoid")
                            if humanoid and humanoid.Health < humanoid.MaxHealth then
                                for _, item in pairs(character:GetChildren()) do
                                    if item:IsA("Tool") and (item.Name:find("Food") or item.Name:find("食物")) then
                                        pcall(function()
                                            local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
                                            if remoteEvent then
                                                local useItemEvent = remoteEvent:FindFirstChild("UseItem")
                                                 if useItemEvent then
                                                     useItemEvent:FireServer(item)
                                                 end
                                            end
                                        end)
                                        wait(1)
                                    end
                                end
                            end
                        end)
                        wait(2)
                    end
                end)
            end
        end,
        
        -- ESP显示
        ToggleESP = function(self, enabled)
            self.Features.ESP = enabled
            Notify("AlienX", enabled and "ESP已开启" or "ESP已关闭", 2)
            
            if enabled then
                -- 清除现有ESP
                self:ClearESP()
                
                spawn(function()
                    while self.Features.ESP do
                        pcall(function()
                            for _, v in pairs(workspace:GetChildren()) do
                                if v:IsA("Model") and v:FindFirstChild("Humanoid") and v.Name ~= Character.Name then
                                    if not self.ESPObjects[v] then
                                        self:CreateESP(v)
                                    end
                                end
                            end
                        end)
                        wait(1)
                    end
                end)
            else
                self:ClearESP()
            end
        end,
        
        -- 创建ESP
        CreateESP = function(self, target)
            pcall(function()
                local box = Instance.new("BoxHandleAdornment")
                box.Name = "ESPBox"
                box.Adornee = target.HumanoidRootPart
                box.Size = target:GetExtentsSize() + Vector3.new(0.1, 0.1, 0.1)
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.Transparency = 0.5
                box.AlwaysOnTop = true
                
                local nameTag = Instance.new("BillboardGui")
                nameTag.Name = "ESPNameTag"
                nameTag.Adornee = target.HumanoidRootPart
                nameTag.Size = UDim2.new(0, 200, 0, 50)
                nameTag.AlwaysOnTop = true
                
                local nameLabel = Instance.new("TextLabel")
                nameLabel.Parent = nameTag
                nameLabel.Size = UDim2.new(1, 0, 1, 0)
                nameLabel.BackgroundTransparency = 1
                nameLabel.Text = target.Name
                nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                nameLabel.TextSize = 14
                nameLabel.Font = Enum.Font.GothamBold
                
                local holder = Instance.new("Folder")
                holder.Name = "ESPHolder"
                box.Parent = holder
                nameTag.Parent = holder
                holder.Parent = target
                
                self.ESPObjects[target] = holder
            end)
        end,
        
        -- 清除ESP
        ClearESP = function(self)
            for target, holder in pairs(self.ESPObjects) do
                pcall(function()
                    holder:Destroy()
                end)
            end
            self.ESPObjects = {}
        end,
        
        -- 物品收集
        ToggleAutoCollect = function(self, enabled)
            self.Features.AutoCollect = enabled
            Notify("AlienX", enabled and "自动收集已开启" or "自动收集已关闭", 2)
            
            if enabled then
                spawn(function()
                    while self.Features.AutoCollect do
                        pcall(function()
                            for _, v in pairs(workspace:GetChildren()) do
                                if v:IsA("BasePart") or v:IsA("Tool") then
                                    for _, itemName in ipairs(self.Collectibles) do
                                        if v.Name:find(itemName) then
                                            self:Collect(v)
                                            break
                                        end
                                    end
                                end
                            end
                        end)
                        wait(0.5)
                    end
                end)
            end
        end,
        
        -- 收集物品
        Collect = function(self, item)
            pcall(function()
                if item:IsA("Tool") then
                    pcall(function()
                        local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
                        if remoteEvent then
                            local pickupToolEvent = remoteEvent:FindFirstChild("PickupTool")
                            if pickupToolEvent then
                                pickupToolEvent:FireServer(item)
                            end
                        end
                    end)
                elseif item:IsA("BasePart") then
                    pcall(function()
                        local remoteEvent = game:GetService("ReplicatedStorage"):FindFirstChild("RemoteEvents")
                        if remoteEvent then
                            local pickupItemEvent = remoteEvent:FindFirstChild("PickupItem")
                            if pickupItemEvent then
                                pickupItemEvent:FireServer(item)
                            end
                        end
                    end)
                end
            end)
        end,
        
        -- 收集特定物品
        CollectSpecificItem = function(self, itemName)
            pcall(function()
                for _, v in pairs(workspace:GetChildren()) do
                    if v.Name == itemName then
                        self:Collect(v)
                        break
                    end
                end
            end)
        end,
        
        -- 统一的Toggle方法
        Toggle = function(self, feature, enabled)
            if feature == "KillAura" then
                self:ToggleKillAura(enabled)
            elseif feature == "AutoChop" then
                self:ToggleAutoChop(enabled)
            elseif feature == "AutoEat" then
                self:ToggleAutoEat(enabled)
            elseif feature == "ESP" then
                self:ToggleESP(enabled)
            elseif feature == "AutoCollect" then
                self:ToggleAutoCollect(enabled)
            end
        end
    }
}

-- 新增游戏模块 - 整合AlienX冷脚本和矢井凛源码功能
GameModules = setmetatable(GameModules, {
    __index = function(self, key)
        return rawget(self, key) or {
            -- 默认空模块
        }
    end
})

-- 加载冷脚本功能
function LoadColdScripts()
    -- Doors 功能
    GameModules.Doors = {
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
                        -- 自动收集逻辑 - 优化版本
                        if hrp then
                            -- 移动设备优化：使用更精确的搜索范围
                            local nearbyParts = workspace:FindPartsInRegion3(Region3.new(
                                hrp.Position - Vector3.new(20, 20, 20),
                                hrp.Position + Vector3.new(20, 20, 20)
                            ), nil, 50)
                            
                            for _, item in pairs(nearbyParts) do
                                if (item.Name:find("Key") or item.Name:find("Item")) then
                                    if (item.Position - hrp.Position).Magnitude < 15 then
                                        hrp.CFrame = CFrame.new(item.Position)
                                        wait(0.5)
                                        break  -- 找到一个就处理，提高效率
                                    end
                                end
                            end
                        end
                        wait(2)  -- 降低频率以提高移动设备性能
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
                self:ApplyAdvancedGodMode()
            else
                Notify("Hokl4", "Doors无敌模式已关闭", 2)
                self:RemoveGodMode()
            end
        end,
        
        -- 应用高级无敌模式
        ApplyAdvancedGodMode = function(self)
            -- 先移除可能存在的旧连接
            self:RemoveGodMode()
            
            if not character or not character:FindFirstChild("Humanoid") then
                Notify("Hokl4", "无法找到角色，无敌模式启用失败", 3)
                return
            end
            
            local humanoid = character.Humanoid
            
            -- 更高效的无敌模式实现：通过Humanoid.HealthChanged事件拦截伤害
            self.godModeConnection = humanoid.HealthChanged:Connect(function(newHealth)
                -- 只在生命值降低时进行干预
                if newHealth < humanoid.Health then
                    local damage = humanoid.Health - newHealth
                    
                    -- 记录被拦截的伤害
                    table.insert(self.damageLog, {
                        damage = damage,
                        time = os.time(),
                        source = "未知来源"
                    })
                    
                    -- 防止生命值降低
                    humanoid.Health = humanoid.MaxHealth
                    
                    -- 限制日志大小，避免内存占用过大
                    if #self.damageLog > 1000 then
                        table.remove(self.damageLog, 1)
                    end
                end
            end)
            
            -- 立即设置为满血
            humanoid.Health = humanoid.MaxHealth
            
            -- 添加状态恢复逻辑，以防角色被移除或重置
            self:SetupCharacterRespawnProtection()
        end,
        
        -- 设置角色重生保护
        SetupCharacterRespawnProtection = function(self)
            spawn(function()
                while self.GodMode do
                    -- 检查角色是否存在且有Humanoid
                    if character and character:FindFirstChild("Humanoid") then
                        local humanoid = character.Humanoid
                        
                        -- 确保生命值始终是满的
                        if humanoid.Health < humanoid.MaxHealth then
                            humanoid.Health = humanoid.MaxHealth
                        end
                    end
                    
                    -- 使用较低频率检查以减少资源占用
                    wait(0.5)
                end
            end)
        end,
        
        -- 移除无敌模式
        RemoveGodMode = function(self)
            -- 断开HealthChanged连接
            if self.godModeConnection then
                self.godModeConnection:Disconnect()
                self.godModeConnection = nil
            end
        end,
        
        -- 获取无敌模式统计信息
        GetGodModeStats = function(self)
            local totalDamage = 0
            for _, entry in pairs(self.damageLog) do
                totalDamage = totalDamage + entry.damage
            end
            
            return {
                enabled = self.GodMode,
                damageIntercepted = #self.damageLog,
                totalDamageIntercepted = totalDamage,
                isActive = self.godModeConnection ~= nil
            }
        end
    }
    
    -- 伐木大亨功能
    GameModules.LoggingTycoon = {
        AutoChop = false,
        AutoSell = false,
        
        ToggleAutoChop = function(self, state)
            self.AutoChop = state
            if state then
                Notify("Hokl4", "伐木大亨自动砍树已开启", 2)
                spawn(function()
                    while self.AutoChop do
                        -- 自动砍树逻辑
                        if hrp then
                            -- 优化：只搜索特定区域内的树木，减少性能消耗
                            local treesInRange = {}
                            for _, tree in pairs(workspace:GetDescendants()) do
                                if tree:IsA("Model") and tree:FindFirstChild("Trunk") and tree.Trunk:IsA("BasePart") then
                                    if (tree.Trunk.Position - hrp.Position).Magnitude < 8 then
                                        table.insert(treesInRange, tree)
                                    end
                                end
                            end
                            
                            -- 优先砍最近的树
                            if #treesInRange > 0 then
                                -- 找到最近的树
                                local closestTree = treesInRange[1]
                                local minDistance = math.huge
                                
                                for _, tree in pairs(treesInRange) do
                                    local distance = (tree.Trunk.Position - hrp.Position).Magnitude
                                    if distance < minDistance then
                                        minDistance = distance
                                        closestTree = tree
                                    end
                                end
                                
                                -- 移动到树附近
                                if (closestTree.Trunk.Position - hrp.Position).Magnitude > 5 then
                                    hrp.CFrame = CFrame.new(closestTree.Trunk.Position) * CFrame.new(0, 0, 3) -- 稍微偏移，避免卡在树上
                                    wait(0.5)
                                end
                                
                                -- 执行砍树动作
                                local chopEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Chop")
                                if chopEvent then
                                    chopEvent:FireServer(closestTree)
                                else
                                    -- 备选方案：如果找不到RemoteEvent，尝试其他可能的砍树方法
                                    local tool = character:FindFirstChildOfClass("Tool")
                                    if tool and tool:FindFirstChild("Remote") then
                                        tool.Remote:FireServer(closestTree)
                                    end
                                end
                                
                                wait(2) -- 砍树间隔
                            end
                        end
                        wait(0.5) -- 搜索间隔
                    end
                end)
            else
                Notify("Hokl4", "伐木大亨自动砍树已关闭", 2)
            end
        end,
        
        ToggleAutoSell = function(self, state)
            self.AutoSell = state
            if state then
                Notify("Hokl4", "伐木大亨自动出售已开启", 2)
                spawn(function()
                    while self.AutoSell do
                        -- 自动出售逻辑
                        if hrp then
                            local sellPart = workspace:FindFirstChild("SellArea")
                            if sellPart then
                                hrp.CFrame = CFrame.new(sellPart.Position)
                                local sellEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Sell")
                        if sellEvent then
                            sellEvent:FireServer()
                        end
                            end
                        end
                        wait(5)
                    end
                end)
            else
                Notify("Hokl4", "伐木大亨自动出售已关闭", 2)
            end
        end
    }
    
    -- 俄亥俄州功能
    GameModules.Ohio = {
        AutoLoot = false,
        SpeedBoost = false,
        
        ToggleAutoLoot = function(self, state)
            self.AutoLoot = state
            if state then
                Notify("Hokl4", "俄亥俄州自动拾取已开启", 2)
                spawn(function()
                    while self.AutoLoot do
                        -- 自动拾取逻辑
                        if hrp then
                            for _, item in pairs(workspace:GetDescendants()) do
                                if item:IsA("BasePart") and item.Name:find("Loot") then
                                    if (item.Position - hrp.Position).Magnitude < 20 then
                                        hrp.CFrame = CFrame.new(item.Position)
                                        wait(0.2)
                                    end
                                end
                            end
                        end
                        wait(1)
                    end
                end)
            else
                Notify("Hokl4", "俄亥俄州自动拾取已关闭", 2)
            end
        end,
        
        ToggleSpeedBoost = function(self, state)
            self.SpeedBoost = state
            if state then
                Notify("Hokl4", "俄亥俄州速度提升已开启", 2)
                if humanoid then
                    humanoid.WalkSpeed = 100
                end
            else
                Notify("Hokl4", "俄亥俄州速度提升已关闭", 2)
                if humanoid then
                    humanoid.WalkSpeed = 16
                end
            end
        end
    }
    
    -- 火箭发射模拟器功能
    GameModules.RocketSimulator = {
        AutoBuild = false,
        AutoLaunch = false,
        
        ToggleAutoBuild = function(self, state)
            self.AutoBuild = state
            if state then
                Notify("Hokl4", "火箭模拟器自动建造已开启", 2)
                spawn(function()
                    while self.AutoBuild do
                        -- 自动建造逻辑
                        local buildParts = workspace:FindFirstChild("BuildParts")
                        if buildParts then
                            for _, part in pairs(buildParts:GetChildren()) do
                                if part:IsA("BasePart") then
                                    -- 建造逻辑
                                    local buildEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Build")
                        if buildEvent then
                            buildEvent:FireServer(part)
                        end
                                    wait(0.5)
                                end
                            end
                        end
                        wait(2)
                    end
                end)
            else
                Notify("Hokl4", "火箭模拟器自动建造已关闭", 2)
            end
        end,
        
        ToggleAutoLaunch = function(self, state)
            self.AutoLaunch = state
            if state then
                Notify("Hokl4", "火箭模拟器自动发射已开启", 2)
                spawn(function()
                    while self.AutoLaunch do
                        -- 自动发射逻辑
                        if hrp then
                            local launchButton = workspace:FindFirstChild("LaunchButton")
                            if launchButton then
                                hrp.CFrame = CFrame.new(launchButton.Position)
                                local launchEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Launch")
                        if launchEvent then
                            launchEvent:FireServer()
                        end
                            end
                        end
                        wait(10)
                    end
                end)
            else
                Notify("Hokl4", "火箭模拟器自动发射已关闭", 2)
            end
        end
    }
    
    -- 力量传奇功能
    GameModules.PowerLegend = {
        AutoTrain = false,
        AutoRebirth = false,
        
        ToggleAutoTrain = function(self, state)
            self.AutoTrain = state
            if state then
                Notify("Hokl4", "力量传奇自动训练已开启", 2)
                spawn(function()
                    while self.AutoTrain do
                        -- 自动训练逻辑
                        if hrp then
                            local trainingAreas = workspace:FindFirstChild("TrainingAreas")
                            if trainingAreas then
                                for _, area in pairs(trainingAreas:GetChildren()) do
                                    hrp.CFrame = CFrame.new(area.Position)
                                    wait(2)
                                end
                            end
                        end
                        wait(1)
                    end
                end)
            else
                Notify("Hokl4", "力量传奇自动训练已关闭", 2)
            end
        end,
        
        ToggleAutoRebirth = function(self, state)
            self.AutoRebirth = state
            if state then
                Notify("Hokl4", "力量传奇自动重生已开启", 2)
                spawn(function()
                    while self.AutoRebirth do
                        -- 自动重生逻辑
                        local rebirthEvent = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("Rebirth")
                        if rebirthEvent then
                            rebirthEvent:FireServer()
                        end
                        wait(10)
                    end
                end)
            else
                Notify("Hokl4", "力量传奇自动重生已关闭", 2)
            end
        end
    }
    
    -- 矢井凛源码功能 - AI智能瞄准系统
    GameModules.AimAssist = {
        -- 核心配置
        config = {
            enabled = false,
            aimSensitivity = 0.5,
            predictionStrength = 1.0,
            bulletSpeed = 100,
            aimSmoothness = 0.8,
            maxPredictionTime = 0.5,
            targetAcquisitionRange = 120,
            autoFireEnabled = false,
            fireDelay = 0.1
        },
        
        -- 状态变量
        targetData = {},
        aimingAt = nil,
        lastPredictionTime = os.clock(),
        aimHistory = {},
        
        -- 武器数据
        weaponData = {
            default = { bulletSpeed = 100, gravity = 0 },
            rifle = { bulletSpeed = 120, gravity = 0.1 },
            pistol = { bulletSpeed = 80, gravity = 0.2 },
            sniper = { bulletSpeed = 200, gravity = 0.05 }
        },
        
        -- 当前武器类型
        currentWeapon = "default",
        
        -- 切换AI瞄准
        ToggleAimAssist = function(self, state)
            self.config.enabled = state
            if state then
                Notify("Hokl4", "AI智能瞄准系统已开启", 2)
                self:StartAimLoop()
            else
                Notify("Hokl4", "AI智能瞄准系统已关闭", 2)
                self.aimingAt = nil
            end
        end,
        
        -- 设置武器类型
        SetWeaponType = function(self, weaponType)
            if self.weaponData[weaponType] then
                self.currentWeapon = weaponType
                self.config.bulletSpeed = self.weaponData[weaponType].bulletSpeed
                Notify("Hokl4", "武器类型已设置为: " .. weaponType, 2)
            else
                Notify("Hokl4", "未知武器类型", 2)
            end
        end,
        
        -- 设置预测强度
        SetPredictionStrength = function(self, strength)
            self.config.predictionStrength = math.clamp(strength, 0.1, 2.0)
            Notify("Hokl4", "预测强度已设置为: " .. tostring(strength), 2)
        end,
        
        -- 设置瞄准平滑度
        SetAimSmoothness = function(self, smoothness)
            self.config.aimSmoothness = math.clamp(smoothness, 0.1, 0.99)
            Notify("Hokl4", "瞄准平滑度已设置为: " .. tostring(smoothness), 2)
        end,
        
        -- 切换自动射击
        ToggleAutoFire = function(self, state)
            self.config.autoFireEnabled = state
            Notify("Hokl4", "自动射击已" .. (state and "开启" or "关闭"), 2)
        end,
        
        -- 开始瞄准循环
        StartAimLoop = function(self)
            spawn(function()
                while self.config.enabled do
                    if hrp then
                        -- 智能目标选择
                        local bestTarget = self:SelectBestTarget()
                        
                        if bestTarget then
                            self.aimingAt = bestTarget
                            -- 高级目标预测
                            local predictedPos = self:AdvancedPredictTarget(bestTarget)
                            
                            if predictedPos then
                                -- 平滑瞄准
                                self:SmoothAimTo(predictedPos)
                                
                                -- 自动射击逻辑
                                if self.config.autoFireEnabled then
                                    self:AutoFireAtTarget()
                                end
                            end
                        else
                            self.aimingAt = nil
                        end
                    end
                    
                    -- 智能调节更新频率以优化性能
                    local updateInterval = 0.05 * (1 + (1 - self.config.aimSensitivity))
                    wait(updateInterval)
                end
            end)
        end,
        
        -- 智能目标选择
        SelectBestTarget = function(self)
            local players = game:GetService("Players"):GetPlayers()
            local potentialTargets = {}
            
            -- 收集所有可瞄准的目标
            for _, player in pairs(players) do
                if player ~= lp and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local character = player.Character
                    local hrp = character.HumanoidRootPart
                    local distance = (hrp.Position - hrp.Position).Magnitude
                    
                    -- 检查是否在射程内
                    if distance <= self.config.targetAcquisitionRange then
                        -- 检查是否有障碍物
                        if not self:IsTargetObstructed(hrp.Position) then
                            -- 计算目标优先级分数
                            local priorityScore = self:CalculateTargetPriority(player, distance)
                            table.insert(potentialTargets, { player = player, score = priorityScore, distance = distance })
                        end
                    end
                end
            end
            
            -- 按优先级排序
            table.sort(potentialTargets, function(a, b) return a.score > b.score end)
            
            return #potentialTargets > 0 and potentialTargets[1].player or nil
        end,
        
        -- 计算目标优先级
        CalculateTargetPriority = function(self, player, distance)
            local score = 0
            
            -- 距离因素：越近优先级越高
            score = score + (100 / math.max(1, distance)) * 2
            
            -- 移动状态：静止目标优先级略高
            if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local velocity = player.Character.HumanoidRootPart.Velocity
                local speed = velocity.Magnitude
                score = score + (10 / math.max(1, speed))
            end
            
            -- 健康状态：受伤目标优先级更高
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                local healthPercent = player.Character.Humanoid.Health / player.Character.Humanoid.MaxHealth
                score = score + (1 - healthPercent) * 20
            end
            
            -- 目标历史：保持锁定连续性
            if self.aimingAt == player then
                score = score + 50
            end
            
            return score
        end,
        
        -- 检查目标是否被遮挡
        IsTargetObstructed = function(self, targetPos)
            local camera = workspace.CurrentCamera
            local startPos = camera.CFrame.Position
            
            -- 射线检测
            local rayParams = RaycastParams.new()
            rayParams.FilterDescendantsInstances = {lp.Character}
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
            
            local result = workspace:Raycast(startPos, targetPos - startPos, rayParams)
            
            -- 如果射线命中了物体，且不是目标本身，则被遮挡
            return result and (result.Position - targetPos).Magnitude > 1
        end,
        
        -- 高级目标预测算法
        AdvancedPredictTarget = function(self, player)
            if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
                return nil
            end
            
            local character = player.Character
            local hrp = character.HumanoidRootPart
            local currentPos = hrp.Position
            local currentVel = hrp.Velocity
            local currentTime = os.clock()
            
            -- 记录目标历史数据
            if not self.targetData[player.UserId] then
                self.targetData[player.UserId] = { history = {} }
            end
            
            local targetHistory = self.targetData[player.UserId].history
            table.insert(targetHistory, { pos = currentPos, vel = currentVel, time = currentTime })
            
            -- 保持历史记录长度
            while #targetHistory > 10 do
                table.remove(targetHistory, 1)
            end
            
            -- 计算距离和预估时间
            local distance = (currentPos - hrp.Position).Magnitude
            local travelTime = distance / self.config.bulletSpeed
            travelTime = math.min(travelTime * self.config.predictionStrength, self.config.maxPredictionTime)
            
            -- 基于历史数据预测未来位置
            if #targetHistory >= 3 then
                -- 计算加速度和方向变化趋势
                local acceleration = (targetHistory[#targetHistory].vel - targetHistory[#targetHistory - 1].vel).Magnitude
                local directionChange = (targetHistory[#targetHistory].vel.Unit - targetHistory[#targetHistory - 1].vel.Unit).Magnitude
                
                -- 预测未来位置
                local predictedPos = currentPos + (currentVel * travelTime)
                
                -- 添加重力影响
                local gravity = self.weaponData[self.currentWeapon].gravity
                if gravity > 0 then
                    predictedPos = predictedPos + Vector3.new(0, -0.5 * gravity * travelTime^2, 0)
                end
                
                -- 考虑目标移动模式（如果检测到蛇形移动，增加补偿）
                if directionChange > 0.2 then
                    predictedPos = predictedPos + (currentVel:Cross(Vector3.new(0, 1, 0)).Unit * acceleration * 0.1)
                end
                
                return predictedPos
            else
                -- 简单预测作为后备
                return currentPos + (currentVel * travelTime)
            end
        end,
        
        -- 平滑瞄准到目标位置
        SmoothAimTo = function(self, targetPos)
            local camera = workspace.CurrentCamera
            local currentCF = camera.CFrame
            local targetCF = CFrame.new(currentCF.Position, targetPos)
            
            -- 平滑过渡
            local smoothedCF = currentCF:Lerp(targetCF, 1 - self.config.aimSmoothness)
            camera.CFrame = smoothedCF
            
            -- 记录瞄准历史用于优化
            table.insert(self.aimHistory, { pos = targetPos, time = os.clock() })
            if #self.aimHistory > 50 then
                table.remove(self.aimHistory, 1)
            end
        end,
        
        -- 自动射击逻辑
        AutoFireAtTarget = function(self)
            -- 这里可以根据游戏实现自动射击
            -- 示例实现，需要根据实际游戏修改
            local tool = lp.Character and lp.Character:FindFirstChildWhichIsA("Tool")
            if tool and tool:FindFirstChild("Handle") then
                -- 模拟鼠标点击或触发工具
                local args = {[1] = true}
                -- 尝试各种常见的射击远程事件名称
                pcall(function() tool:FireServer(unpack(args)) end)
                pcall(function() game.ReplicatedStorage:FindFirstChild("Fire"):FireServer(unpack(args)) end)
                pcall(function() game.ReplicatedStorage.Events:FindFirstChild("Fire"):FireServer(unpack(args)) end)
            end
        end,
        
        -- 暂停瞄准功能（用于性能优化）
        Pause = function(self)
            self.wasEnabled = self.config.enabled
            if self.config.enabled then
                self.config.enabled = false
                self.aimingAt = nil
                -- 清理目标数据以节省内存
                self.targetData = {}
            end
        end,
        
        -- 恢复瞄准功能
        Resume = function(self)
            if self.wasEnabled then
                self.config.enabled = true
                self:StartAimLoop()
                self.wasEnabled = nil
            end
        end,
        
        -- 获取瞄准状态
        GetAimStatus = function(self)
            return {
                enabled = self.config.enabled,
                currentTarget = self.aimingAt,
                predictionQuality = self.config.predictionStrength,
                targetRange = self.config.targetAcquisitionRange
            }
        end
    }
end

-- 坐标管理功能
GameModules.Coordinates = {
    savedCoords = {},
    
    -- 获取当前坐标
    GetCurrentCoord = function(self)
        if hrp then
            local pos = hrp.Position
            return {x = pos.X, y = pos.Y, z = pos.Z}
        end
        return nil
    end,
    
    -- 保存坐标
    SaveCoord = function(self, name, x, y, z)
        -- 支持两种调用方式：SaveCoord(name, coordTable) 或 SaveCoord(name, x, y, z)
        local coord
        if type(x) == "table" then
            coord = x
        else
            coord = {x = x, y = y, z = z}
        end
        
        self.savedCoords[name] = coord
        Notify("Hokl4", "已保存坐标: " .. name, 2)
        return true
    end,
    
    -- 删除坐标
    DeleteCoord = function(self, name)
        if self.savedCoords[name] then
            self.savedCoords[name] = nil
            Notify("Hokl4", "已删除坐标: " .. name, 2)
            return true
        end
        Notify("Hokl4", "未找到坐标: " .. name, 2)
        return false
    end,
    
    -- 获取所有坐标列表
    GetCoordList = function(self)
        local coordsList = {}
        for name, coord in pairs(self.savedCoords) do
            table.insert(coordsList, {
                name = name,
                x = coord.x,
                y = coord.y,
                z = coord.z
            })
        end
        return coordsList
    end,
    
    -- 传送到指定坐标
    TeleportToCoord = function(self, name)
        if not hrp then
            Notify("Hokl4", "无法获取玩家位置，传送失败", 2)
            return false
        end
        
        if self.savedCoords[name] then
            local coord = self.savedCoords[name]
            hrp.CFrame = CFrame.new(coord.x, coord.y, coord.z)
            Notify("Hokl4", "已传送到: " .. name, 2)
            return true
        end
        Notify("Hokl4", "未找到坐标: " .. name, 2)
        return false
    end
}

-- AI智能性能调度模块 - 增强版
GameModules.PerformanceManager = {
    -- 配置参数
    config = {
        enabled = true,
        monitoringInterval = 0.5, -- 性能监控间隔（秒）
        lowFpsThreshold = 30,
        veryLowFpsThreshold = 15,
        maxTasksPerUpdate = 10,
        optimizationAggressiveness = 2, -- 1-5，优化激进程度
        taskProcessingInterval = 0.05, -- 任务处理间隔
        
        -- AI功能特定配置
        aiConfig = {
            aimAssistEnabled = true,
            aimAssistSmoothness = 0.8, -- 根据性能动态调整
            predictionQuality = "high", -- high, medium, low
            targetAcquisitionRange = 120, -- 根据性能动态调整
            dynamicUpdateRate = true,
            performanceAdaptive = true
        }
    },
    
    -- 性能数据
    performanceData = {
        fps = 60,
        memory = 0,
        memoryUsage = 0, -- 兼容之前实现的优化功能
        lastFrameTime = os.clock(),
        frameCount = 0,
        
        -- 增强性能指标
        cpuLoad = 0,
        gpuLoad = 0,
        networkLatency = 0,
        frameTimeVariance = 0,
        averageFrameTime = 0
    },
    
    -- 任务和优化相关数据
    activeTasks = {},
    monitoringRunning = false,
    resourceUsageHistory = {},
    optimizationHistory = {},
    lastCleanupTime = 0,
    
    -- 任务优先级定义
    taskPriorities = {
        critical = 4,
        high = 3,
        medium = 2,
        low = 1
    },
    
    -- AI模块引用
    aiModules = {},
    
    -- AI功能性能配置
    aiPerformanceProfiles = {
        high = { aimAssistSmoothness = 0.8, predictionQuality = "high", targetAcquisitionRange = 120 },
        medium = { aimAssistSmoothness = 0.6, predictionQuality = "medium", targetAcquisitionRange = 80 },
        low = { aimAssistSmoothness = 0.4, predictionQuality = "low", targetAcquisitionRange = 50 }
    },
    
    -- 初始化性能管理器
    Init = function(self)
        -- 注册AI模块
        self:RegisterAIModules()
        
        -- 开始性能监控
        self:StartMonitoring()
        -- 初始化任务处理
        self:InitTaskProcessor()
        
        -- 初始化AI性能配置
        self:InitAIPerformanceConfig()
        
        Notify("Hokl4", "AI性能管理系统初始化完成", 2)
    end,
    
    -- 注册AI模块
    RegisterAIModules = function(self)
        self.aiModules = {
            aimAssist = GameModules.AimAssist,
            -- 可以在这里添加更多AI模块
        }
    end,
    
    -- 初始化AI性能配置
    InitAIPerformanceConfig = function(self)
        -- 根据设备性能初始化AI配置
        local devicePerformance = self:EvaluateDevicePerformance()
        self:SetAIPerformanceProfile(devicePerformance)
    end,
    
    -- 评估设备性能
    EvaluateDevicePerformance = function(self)
        -- 简单的设备性能评估
        -- 在实际使用中会根据监控数据调整
        local screenSize = workspace.CurrentCamera.ViewportSize
        local isMobile = isMobileDevice or screenSize.Y < 800
        
        if isMobile then
            return "medium" -- 移动设备默认使用中等性能配置
        else
            return "high" -- PC设备默认使用高性能配置
        end
    end,
    
    -- 设置AI性能配置
    SetAIPerformanceProfile = function(self, profileName)
        local profile = self.aiPerformanceProfiles[profileName] or self.aiPerformanceProfiles.medium
        self.config.aiConfig = table.clone(profile)
        self.config.aiConfig.predictionQuality = profileName
        
        -- 应用到各个AI模块
        self:ApplyAIPerformanceSettings()
        
        Notify("Hokl4", "AI性能配置已设置为: " .. profileName, 2)
    end,
    
    -- 应用AI性能设置
    ApplyAIPerformanceSettings = function(self)
        -- 应用到瞄准辅助模块
        if self.aiModules.aimAssist then
            self.aiModules.aimAssist.config.aimSmoothness = self.config.aiConfig.aimAssistSmoothness
            self.aiModules.aimAssist.config.targetAcquisitionRange = self.config.aiConfig.targetAcquisitionRange
            
            -- 根据预测质量设置预测强度
            if self.config.aiConfig.predictionQuality == "high" then
                self.aiModules.aimAssist.config.predictionStrength = 1.0
            elseif self.config.aiConfig.predictionQuality == "medium" then
                self.aiModules.aimAssist.config.predictionStrength = 0.7
            else
                self.aiModules.aimAssist.config.predictionStrength = 0.4
            end
        end
    end,
    
    -- 启用/禁用性能管理
    SetEnabled = function(self, enabled)
        self.config.enabled = enabled
        if enabled then
            Notify("Hokl4", "AI性能调度已启用", 3)
            self:RestartMonitoring()
        else
            Notify("Hokl4", "AI性能调度已禁用", 3)
            self:StopMonitoring()
        end
    end,
    
    -- 设置优化激进程度
    SetAggressiveness = function(self, level)
        self.config.optimizationAggressiveness = math.clamp(level, 1, 5)
        Notify("Hokl4", "优化激进程度已设置为: " .. level, 3)
    end,
    
    -- 获取性能数据
    GetPerformanceData = function(self)
        return {
            fps = math.floor(self.performanceData.fps or 0),
            memory = string.format("%.2f", (self.performanceData.memoryUsage or 0) / 1024),
            activeTasks = #(self.activeTasks or {}),
            queuedTasks = #(self.taskQueue or {}),
            isEnabled = self.config.enabled,
            aggressionLevel = self.config.optimizationAggressiveness
        }
    end,
    
    -- 开始性能监控
    StartMonitoring = function(self)
        self.monitoringRunning = true
        self.resourceUsageHistory = {}
        self.optimizationHistory = {}
        
        -- FPS监控循环
        spawn(function()
            while self.monitoringRunning do
                wait(self.config.monitoringInterval)
                self:UpdateFPS()
                self:UpdateMemoryUsage()
                
                if self.config.enabled then
                    self:AdjustPerformanceBasedOnMetrics()
                    self:MonitorResources()
                    self:OptimizeClient()
                end
            end
            table.insert(eventConnections, dragInputChangedConn)
        end)
        table.insert(eventConnections, inputChangedConn)
        table.insert(eventConnections, inputEndedConn)
    end,
    
    -- 监控资源使用
    MonitorResources = function(self)
        local currentUsage = {
            timestamp = os.time(),
            fps = self.performanceData.fps or 0,
            memory = self.performanceData.memoryUsage or 0,
            activeTasks = #(self.activeTasks or {}),
            cpuLoad = self.performanceData.cpuLoad or 0,
            gpuLoad = self.performanceData.gpuLoad or 0,
            networkLatency = self.performanceData.networkLatency or 0,
            averageFrameTime = self.performanceData.averageFrameTime or 0
        }
        
        -- 记录使用历史
        table.insert(self.resourceUsageHistory, currentUsage)
        
        -- 保持历史记录长度
        if #self.resourceUsageHistory > 120 then
            table.remove(self.resourceUsageHistory, 1)
        end
        
        -- 实时调整AI性能
        if self.config.aiConfig.performanceAdaptive then
            self:AdjustAIPerformanceDynamically()
        end
    end,
    
    -- 动态调整AI性能
    AdjustAIPerformanceDynamically = function(self)
        local fps = self.performanceData.fps or 0
        local memory = self.performanceData.memoryUsage or 0
        
        -- 性能状态判断
        if fps < self.config.veryLowFpsThreshold then
            -- 极低FPS，切换到低性能配置
            if self.config.aiConfig.predictionQuality ~= "low" then
                self:SetAIPerformanceProfile("low")
                self:LogOptimization("性能过低，AI配置已降至低模式")
            end
        elseif fps < self.config.lowFpsThreshold then
            -- 低FPS，切换到中等性能配置
            if self.config.aiConfig.predictionQuality == "high" then
                self:SetAIPerformanceProfile("medium")
                self:LogOptimization("性能降低，AI配置已降至中模式")
            end
        elseif fps > 45 and self.config.aiConfig.predictionQuality == "low" then
            -- 良好FPS，提升到中等性能配置
            self:SetAIPerformanceProfile("medium")
            self:LogOptimization("性能良好，AI配置已提升至中模式")
        elseif fps > 55 and self.config.aiConfig.predictionQuality == "medium" then
            -- 优秀FPS，提升到高性能配置
            self:SetAIPerformanceProfile("high")
            self:LogOptimization("性能优秀，AI配置已提升至高模式")
        end
    end,
    
    -- AI自动优化客户端
    OptimizeClient = function(self)
        -- 根据使用模式进行预测性优化
        self:AnalyzeUsagePatterns()
        
        -- 清理不必要的对象和缓存
        self:CleanupUnusedResources()
        
        -- 动态调整功能参数
        self:DynamicallyAdjustFeatures()
    end,
    
    -- 分析使用模式
    AnalyzeUsagePatterns = function(self)
        if #self.resourceUsageHistory < 30 then return end
        
        -- 计算平均FPS和内存使用
        local totalFPS = 0
        local totalMemory = 0
        local count = 0
        
        for i = math.max(1, #self.resourceUsageHistory - 30), #self.resourceUsageHistory do
            totalFPS = totalFPS + self.resourceUsageHistory[i].fps
            totalMemory = totalMemory + self.resourceUsageHistory[i].memory
            count = count + 1
        end
        
        local avgFPS = totalFPS / count
        local avgMemory = totalMemory / count
        
        -- 预测性能趋势
        if avgFPS < 25 and self.config.optimizationAggressiveness < 4 then
            -- FPS持续低，提高优化激进程度
            self:SetAggressiveness(self.config.optimizationAggressiveness + 1)
            self:LogOptimization("自动提高优化激进程度: FPS过低")
        elseif avgFPS > 50 and self.config.optimizationAggressiveness > 2 then
            -- 性能良好，可降低优化激进程度以提高功能体验
            self:SetAggressiveness(self.config.optimizationAggressiveness - 1)
            self:LogOptimization("自动降低优化激进程度: 性能良好")
        end
    end,
    
    -- 清理未使用资源
    CleanupUnusedResources = function(self)
        -- 清理任务队列中的过期任务
        local currentTime = os.time()
        local validTasks = {}
        
        for _, task in ipairs(self.taskQueue or {}) do
            if not task.expiryTime or task.expiryTime > currentTime then
                table.insert(validTasks, task)
            end
        end
        
        self.taskQueue = validTasks
        
        -- 定期进行内存清理
        if (self.lastCleanupTime or 0) + 300 < os.time() then
            collectgarbage("collect")
            self.lastCleanupTime = os.time()
            self:LogOptimization("执行垃圾回收")
        end
    end,
    
    -- 动态调整功能参数
    DynamicallyAdjustFeatures = function(self)
        -- 根据性能状态调整各功能模块的行为
        local currentFPS = self.performanceData.fps or 0
        
        if currentFPS < 20 then
            -- 极端低FPS情况，暂停所有非关键任务
            self:DisableNonCriticalFeatures()
            -- 暂停AI功能
            self:PauseAIFeatures()
        elseif currentFPS < 30 then
            -- 低FPS情况，减少任务执行频率
            self.config.taskProcessingInterval = 0.1
            -- 降低AI功能优先级
            self:ReduceAIFeatureIntensity()
        else
            -- 正常性能，恢复正常执行频率
            self.config.taskProcessingInterval = 0.05
            -- 恢复AI功能
            self:ResumeAIFeatures()
        end
    end,
    
    -- 暂停AI功能
    PauseAIFeatures = function(self)
        -- 暂停瞄准辅助
        if self.aiModules.aimAssist and self.aiModules.aimAssist.config.enabled then
            self.aiModules.aimAssist:Pause()
            self:LogOptimization("已暂停AI瞄准功能以提高性能")
        end
    end,
    
    -- 恢复AI功能
    ResumeAIFeatures = function(self)
        -- 恢复瞄准辅助
        if self.aiModules.aimAssist and self.aiModules.aimAssist.wasEnabled then
            self.aiModules.aimAssist:Resume()
            self:LogOptimization("已恢复AI瞄准功能")
        end
    end,
    
    -- 降低AI功能强度
    ReduceAIFeatureIntensity = function(self)
        -- 降低瞄准辅助强度
        if self.aiModules.aimAssist then
            self.aiModules.aimAssist.config.targetAcquisitionRange = math.max(50, self.aiModules.aimAssist.config.targetAcquisitionRange * 0.7)
            self:LogOptimization("已降低AI瞄准功能强度")
        end
    end,
    
    -- 禁用非关键功能
    DisableNonCriticalFeatures = function(self)
        -- 可以在这里实现禁用某些非关键功能模块
        -- 例如：减少视觉效果、禁用部分自动化功能等
        self:LogOptimization("已禁用非关键功能以提高性能")
    end,
    
    -- 记录优化操作
    LogOptimization = function(self, action)
        local logEntry = {
            timestamp = os.time(),
            action = action,
            fps = self.performanceData.fps or 0,
            memory = self.performanceData.memoryUsage or 0
        }
        
        table.insert(self.optimizationHistory, logEntry)
        
        -- 保持历史记录长度
        if #self.optimizationHistory > 50 then
            table.remove(self.optimizationHistory, 1)
        end
    end,
    
    -- 停止性能监控
    StopMonitoring = function(self)
        self.monitoringRunning = false
        -- 清理AI相关状态
        self:CleanupAIStates()
    end,
    
    -- 清理AI状态
    CleanupAIStates = function(self)
        -- 清理目标数据
        if self.aiModules.aimAssist then
            self.aiModules.aimAssist.targetData = {}
            self.aiModules.aimAssist.aimHistory = {}
        end
    end,
    
    -- 获取AI性能状态
    GetAIPerformanceStatus = function(self)
        return {
            aiEnabled = self.config.aiConfig.aimAssistEnabled,
            performanceProfile = self.config.aiConfig.predictionQuality,
            adaptiveMode = self.config.aiConfig.performanceAdaptive,
            aimAssistActive = self.aiModules.aimAssist and self.aiModules.aimAssist.config.enabled or false
        }
    end
    
    -- 重启监控
    RestartMonitoring = function(self)
        self:StopMonitoring()
        wait(0.1)
        self:StartMonitoring()
    end,
    
    -- 更新FPS
    UpdateFPS = function(self)
        local currentTime = os.clock()
        local deltaTime = currentTime - self.performanceData.lastFrameTime
        self.performanceData.lastFrameTime = currentTime
        
        self.performanceData.fps = 1 / deltaTime
        self.performanceData.frameCount = 0
    end,
    
    -- 更新内存使用
    UpdateMemoryUsage = function(self)
        -- 简化版本，实际内存监控在Roblox中较复杂
        local memValue = collectgarbage("count")
        self.performanceData.memory = memValue / 1024 -- 转换为MB显示
        self.performanceData.memoryUsage = memValue -- 兼容优化功能，保持原始KB值
    end,
    
    -- 根据性能指标调整策略
    AdjustPerformanceBasedOnMetrics = function(self)
        local fps = self.performanceData.fps
        
        -- 根据FPS调整最大任务数
        if fps < self.config.veryLowFpsThreshold then
            -- 非常低的FPS，减少任务数量
            local reduceFactor = 0.3 + (self.config.optimizationAggressiveness * 0.1)
            self.config.maxTasksPerUpdate = math.max(1, math.floor(self.config.maxTasksPerUpdate * reduceFactor))
        elseif fps < self.config.lowFpsThreshold then
            -- 低FPS，适度减少任务数量
            local reduceFactor = 0.5 + (self.config.optimizationAggressiveness * 0.05)
            self.config.maxTasksPerUpdate = math.max(3, math.floor(self.config.maxTasksPerUpdate * reduceFactor))
        else
            -- FPS良好，可以增加任务数量
            self.config.maxTasksPerUpdate = math.min(20, self.config.maxTasksPerUpdate + 1)
        end
        
        -- 低性能时暂停非关键任务
        if fps < self.config.lowFpsThreshold then
            self:PauseLowPriorityTasks()
        else
            self:ResumePausedTasks()
        end
        
        -- 内存优化
        if self.performanceData.memory > 100 then -- 如果内存使用超过100MB
            collectgarbage("collect")
        end
    end,
    
    -- 初始化任务处理器
    InitTaskProcessor = function(self)
        spawn(function()
            while true do
                wait(0.05) -- 20Hz处理任务
                if self.config.enabled then
                    self:ProcessTaskQueue()
                end
            end
        end)
    end,
    
    -- 添加任务到队列
    AddTask = function(self, task, priority, moduleName)
        priority = priority or "medium"
        local priorityValue = self.taskPriorities[priority] or self.taskPriorities.medium
        
        table.insert(self.taskQueue, {
            task = task,
            priority = priorityValue,
            module = moduleName or "Unknown",
            addedTime = tick()
        })
        
        -- 按优先级排序任务队列
        table.sort(self.taskQueue, function(a, b)
            return a.priority > b.priority
        end)
    end,
    
    -- 处理任务队列
    ProcessTaskQueue = function(self)
        local processedCount = 0
        
        while #self.taskQueue > 0 and processedCount < self.config.maxTasksPerUpdate do
            local task = table.remove(self.taskQueue, 1)
            
            -- 记录活跃任务
            local taskId = tostring(task.addedTime)
            self.activeTasks[taskId] = {
                module = task.module,
                startTime = tick()
            }
            
            -- 执行任务
            local success = SafeCall(task.task, "Task: " .. tostring(task.name or taskId))
            
            -- 清理活跃任务
            self.activeTasks[taskId] = nil
            
            processedCount = processedCount + 1
        end
    end,
    
    -- 暂停低优先级任务
    PauseLowPriorityTasks = function(self)
        -- 移除低优先级任务
        local newQueue = {}
        for _, task in ipairs(self.taskQueue) do
            if task.priority > self.taskPriorities.low then -- 保留中高优先级任务
                table.insert(newQueue, task)
            end
        end
        self.taskQueue = newQueue
    end,
    
    -- 恢复暂停的任务
    ResumePausedTasks = function(self)
        -- 这里可以从历史记录恢复暂停的任务，简化版本暂不实现
    end,
    
    -- 获取当前性能数据
    GetPerformanceData = function(self)
        return {
            fps = math.round(self.performanceData.fps),
            memory = math.round(self.performanceData.memory * 10) / 10,
            activeTasks = #self.activeTasks,
            queuedTasks = #self.taskQueue,
            maxTasksPerUpdate = self.config.maxTasksPerUpdate
        }
    end
}

-- 初始化性能管理器
GameModules.PerformanceManager:Init()

-- 为现有模块添加任务调度功能
local originalNotify = Notify
Notify = function(title, message, duration)
    -- 通过性能管理器调度通知
    GameModules.PerformanceManager:AddTask(function()
        originalNotify(title, message, duration)
    end, "medium", "Notification")
end

-- 测试模块
function TestAllModules()
    Notify("Hokl4 测试系统", "开始测试所有功能模块...", 5)
    
    -- 测试坐标管理模块
    local success = true
    local errorMessages = {}
    
    -- 测试坐标管理功能
    local testCoord = GameModules.Coordinates:GetCurrentCoord()
    if not testCoord then
        success = false
        table.insert(errorMessages, "坐标管理: 获取当前坐标失败")
    else
        -- 测试保存坐标
        local saveResult = GameModules.Coordinates:SaveCoord("测试坐标", testCoord)
        if not saveResult then
            success = false
            table.insert(errorMessages, "坐标管理: 保存测试坐标失败")
        else
            Notify("Hokl4 测试", "坐标管理功能测试通过", 3)
        end
    end
    
    -- 测试性能管理器
    if not GameModules.PerformanceManager then
        success = false
        table.insert(errorMessages, "性能管理器: 模块未加载")
    else
        -- 测试性能数据获取
        local perfData = GameModules.PerformanceManager:GetPerformanceData()
        if not perfData then
            success = false
            table.insert(errorMessages, "性能管理器: 获取性能数据失败")
        else
            Notify("Hokl4 测试", "性能管理器功能测试通过", 3)
        end
    end
    
    -- 测试任务调度
    if GameModules.PerformanceManager then
        local testTaskId = GameModules.PerformanceManager:AddTask(function()
            Notify("Hokl4 测试", "任务调度功能测试通过", 3)
        end, {priority = "medium"})
        
        if not testTaskId then
            success = false
            table.insert(errorMessages, "任务调度: 添加测试任务失败")
        end
    end
    
    -- 显示测试结果
    if success then
        Notify("Hokl4 测试系统", "所有功能模块测试通过！", 5)
    else
        Notify("Hokl4 测试系统", "测试失败，请检查以下错误:", 10)
        for _, errorMsg in ipairs(errorMessages) do
            Notify("Hokl4 测试错误", errorMsg, 5)
        end
    end
    
    return success, errorMessages
end

-- 加载冷脚本功能
LoadColdScripts()

-- 启动自动测试
spawn(function()
    wait(5) -- 等待所有模块初始化完成
    TestAllModules()
end)

-- 传送功能
function GameModules:TeleportToPlayer(playerName)
    if not hrp then
        Notify("Hokl4", "无法获取玩家位置，传送失败", 2)
        return
    end
    local targetPlayer = game:GetService("Players"):FindFirstChild(playerName)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        hrp.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame + Vector3.new(0, 3, 0)
        Notify("Hokl4", "已传送到 " .. playerName, 3)
    else
        Notify("Hokl4", "无法找到玩家 " .. playerName, 3)
    end
end

function GameModules:TeleportToCoords(x, y, z)
    if not hrp then
        Notify("Hokl4", "无法获取玩家位置，传送失败", 2)
        return
    end
    hrp.CFrame = CFrame.new(x, y, z)
    Notify("Hokl4", "已传送到坐标: " .. x .. ", " .. y .. ", " .. z, 3)
end

-- 玩家列表
function GameModules:GetPlayerList()
    local players = {}
    for _, player in pairs(game:GetService("Players"):GetPlayers()) do
        table.insert(players, player.Name)
    end
    return players
end

-- 检查是否为移动设备
function IsMobileDevice()
    local userInputService = game:GetService("UserInputService")
    return userInputService.TouchEnabled and not userInputService.KeyboardEnabled
end

-- 兼容性管理模块
local CompatibilityManager = {
    -- 设备信息
    DeviceInfo = {
        IsMobile = false,
        IsTablet = false,
        IsPC = false,
        ScreenSize = Vector2.new(0, 0),
        DevicePerformance = "medium" -- low, medium, high
    },
    
    -- 兼容性设置
    Settings = {
        -- 移动端优化设置
        Mobile = {
            ESPUpdateInterval = 0.3,    -- 透视更新间隔
            MaxESPRenderDistance = 50,  -- 最大透视渲染距离
            DisableAdvancedFeatures = false, -- 是否禁用高级功能
            ReduceVisualEffects = true, -- 是否减少视觉效果
            LowerParticleLimit = true  -- 是否降低粒子效果限制
        },
        -- PC端优化设置
        PC = {
            ESPUpdateInterval = 0.1,    -- 透视更新间隔
            MaxESPRenderDistance = 100, -- 最大透视渲染距离
            DisableAdvancedFeatures = false, -- 是否禁用高级功能
            ReduceVisualEffects = false, -- 是否减少视觉效果
            LowerParticleLimit = false  -- 是否降低粒子效果限制
        }
    },
    
    -- 初始化兼容性管理器
    Init = function(self)
        -- 检测设备类型
        self:DetectDeviceType()
        -- 根据设备类型调整设置
        self:ApplyDeviceSettings()
        -- 注册设备状态变化监听
        self:RegisterDeviceListeners()
        
        Notify("兼容性管理器", "设备检测完成: " .. self:GetDeviceTypeString(), 3)
    end,
    
    -- 检测设备类型
    DetectDeviceType = function(self)
        local userInputService = game:GetService("UserInputService")
        local guiService = game:GetService("GuiService")
        local screenSize = workspace.CurrentCamera.ViewportSize
        
        -- 设置屏幕尺寸
        self.DeviceInfo.ScreenSize = screenSize
        
        -- 检测是否为移动设备
        self.DeviceInfo.IsMobile = userInputService.TouchEnabled and not userInputService.KeyboardEnabled
        self.DeviceInfo.IsTablet = self.DeviceInfo.IsMobile and screenSize.X >= 600 and screenSize.Y >= 400
        self.DeviceInfo.IsPC = not self.DeviceInfo.IsMobile
        
        -- 简单性能评估
        self:EvaluateDevicePerformance()
    end,
    
    -- 评估设备性能
    EvaluateDevicePerformance = function(self)
        -- 基于屏幕分辨率和设备类型简单评估性能
        local resolution = self.DeviceInfo.ScreenSize.X * self.DeviceInfo.ScreenSize.Y
        
        if self.DeviceInfo.IsPC then
            if resolution > 2073600 then -- 1920x1080
                self.DeviceInfo.DevicePerformance = "high"
            else
                self.DeviceInfo.DevicePerformance = "medium"
            end
        else
            -- 移动设备默认性能设为medium或low
            if self.DeviceInfo.IsTablet and resolution > 1334000 then -- 1280x1024
                self.DeviceInfo.DevicePerformance = "medium"
            else
                self.DeviceInfo.DevicePerformance = "low"
            end
        end
    end,
    
    -- 应用设备特定设置
    ApplyDeviceSettings = function(self)
        -- 确保GameModules表存在
        if not GameModules then
            GameModules = {}
        end
        
        -- 根据设备类型选择相应的设置
        local activeSettings = self.DeviceInfo.IsMobile and self.Settings.Mobile or self.Settings.PC
        
        -- 将设置应用到全局配置
        -- 首先尝试使用CommonFeatures作为透视模块
        if CommonFeatures then
            if CommonFeatures.SetUpdateInterval then
                CommonFeatures:SetUpdateInterval(activeSettings.ESPUpdateInterval)
            end
            if CommonFeatures.SetMaxRenderDistance then
                CommonFeatures:SetMaxRenderDistance(activeSettings.MaxESPRenderDistance)
            end
            if CommonFeatures.SetVisualEffects then
                CommonFeatures:SetVisualEffects(not activeSettings.ReduceVisualEffects)
            end
        end
        
        -- 同时也支持GameModules.AdvancedESP（如果存在）
        if GameModules and GameModules.AdvancedESP then
            if GameModules.AdvancedESP.SetUpdateInterval then
                GameModules.AdvancedESP:SetUpdateInterval(activeSettings.ESPUpdateInterval)
            end
            if GameModules.AdvancedESP.SetMaxRenderDistance then
                GameModules.AdvancedESP:SetMaxRenderDistance(activeSettings.MaxESPRenderDistance)
            end
            if GameModules.AdvancedESP.SetVisualEffects then
                GameModules.AdvancedESP:SetVisualEffects(not activeSettings.ReduceVisualEffects)
            end
        end
        
        if GameModules.MobilePacketCapture then
            if GameModules.MobilePacketCapture.SetDeviceType then
                GameModules.MobilePacketCapture:SetDeviceType(self.DeviceInfo.IsMobile)
            end
        end
        
        if GameModules.AimAssist and GameModules.AimAssist.Config then
            -- 根据设备性能调整AI瞄准参数
            local aimAssistSettings = GameModules.AimAssist.Config
            if self.DeviceInfo.DevicePerformance == "low" then
                aimAssistSettings.PredictionIntensity = math.max(0.5, aimAssistSettings.PredictionIntensity or 0.7)
                aimAssistSettings.Smoothness = math.min(0.8, aimAssistSettings.Smoothness or 0.5)
            elseif self.DeviceInfo.DevicePerformance == "high" then
                aimAssistSettings.PredictionIntensity = math.min(1.0, aimAssistSettings.PredictionIntensity or 0.7)
                aimAssistSettings.Smoothness = math.max(0.3, aimAssistSettings.Smoothness or 0.5)
            end
        end
        
        if self.DeviceInfo.IsMobile then
            -- 为移动端应用额外的优化
            self:ApplyMobileOptimizations()
        end
    end,
    
    -- 应用移动端特定优化
    ApplyMobileOptimizations = function(self)
        -- 降低UI复杂度
        local UI = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Hokl4UI")
        if UI then
            -- 简化UI布局
            for _, frame in pairs(UI:GetDescendants()) do
                if frame:IsA("Frame") or frame:IsA("ScrollingFrame") then
                    frame.BackgroundTransparency = math.min(0.8, frame.BackgroundTransparency)
                end
                if frame:IsA("TextLabel") then
                    frame.TextSize = math.max(12, frame.TextSize - 2)
                end
            end
        end
        
        -- 减少同时运行的功能数量
        if GameModules.PerformanceManager and GameModules.PerformanceManager.SetMaxConcurrentFeatures then
            GameModules.PerformanceManager:SetMaxConcurrentFeatures(5) -- 移动端限制同时运行的功能数量
        end
    end,
    
    -- 注册设备状态变化监听
    RegisterDeviceListeners = function(self)
        -- 监听窗口大小变化
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
            -- 重新检测设备类型
            self:DetectDeviceType()
            -- 重新应用设置
            self:ApplyDeviceSettings()
        end)
        
        -- 监听输入方式变化
        game:GetService("UserInputService"):GetPropertyChangedSignal("KeyboardEnabled"):Connect(function()
            self:DetectDeviceType()
            self:ApplyDeviceSettings()
        end)
    end,
    
    -- 获取设备类型字符串
    GetDeviceTypeString = function(self)
        if self.DeviceInfo.IsMobile then
            return self.DeviceInfo.IsTablet and "平板设备" or "移动设备" .. " (性能: " .. self.DeviceInfo.DevicePerformance .. ")"
        else
            return "PC设备" .. " (性能: " .. self.DeviceInfo.DevicePerformance .. ")"
        end
    end,
    
    -- 获取当前设备的设置
    GetCurrentSettings = function(self)
        return self.DeviceInfo.IsMobile and self.Settings.Mobile or self.Settings.PC
    end,
    
    -- 检查功能是否兼容当前设备
    IsFeatureCompatible = function(self, featureName)
        -- 某些高级功能可能在低端设备上不兼容
        if self.DeviceInfo.DevicePerformance == "low" then
            local intensiveFeatures = {
                "AdvancedAimPrediction", -- 高级瞄准预测
                "HighDetailESP",         -- 高细节透视
                "RealTimePacketAnalysis" -- 实时数据包分析
            }
            
            for _, intensiveFeature in ipairs(intensiveFeatures) do
                if string.find(string.lower(featureName), string.lower(intensiveFeature)) then
                    return false
                end
            end
        end
        
        return true
    end,
    
    -- 动态调整功能参数以适应设备
    AdjustFeatureForDevice = function(self, featureModule)
        -- 为不同性能级别设备调整功能参数
        if self.DeviceInfo.DevicePerformance == "low" and featureModule and type(featureModule) == "table" then
            -- 降低更新频率
            if featureModule.SetUpdateRate then
                local currentRate = featureModule:GetUpdateRate and featureModule:GetUpdateRate() or 0.1
                featureModule:SetUpdateRate(currentRate * 2)
            end
            
            -- 减少计算复杂度
            if featureModule.SetComplexityLevel then
                featureModule:SetComplexityLevel("low")
            end
        end
    end
}

-- 确保GameModules表存在
if not GameModules then
    GameModules = {}
end

-- 将兼容性管理器添加到GameModules
GameModules.CompatibilityManager = CompatibilityManager

-- 初始化兼容性管理器
CompatibilityManager:Init()

-- 移动端抓包功能模块
GameModules.MobilePacketCapture = {
    Enabled = false,
    CapturedPackets = {},
    MaxPackets = 100,
    CaptureInterval = 0.1,
    FilterType = "all", -- all, incoming, outgoing
    FilterKeyword = "",
    AutoSave = false,
    SaveInterval = 300, -- 5分钟自动保存
    LastSaveTime = os.time(),
    IsAnalyzing = false,
    AnalysisResults = {},
    ConnectionHandlers = {},
    
    -- 初始化抓包功能
    Init = function(self)
        self:SetupConnections()
        Notify("Hokl4", "移动端抓包模块已初始化", 2)
    end,
    
    -- 设置设备类型
    SetDeviceType = function(self, isMobile)
        self.IsMobileDevice = isMobile
        
        -- 根据设备类型调整抓包参数
        if isMobile then
            -- 移动端优化：降低捕获频率，减少内存占用
            self.CaptureInterval = 0.2
            self.MaxPackets = 50
            self.AutoSave = true
            self.SaveInterval = 180 -- 3分钟
        else
            -- PC端：提高性能，增加功能
            self.CaptureInterval = 0.1
            self.MaxPackets = 200
            self.AutoSave = false
            self.SaveInterval = 300 -- 5分钟
        end
        
        Notify("移动端抓包", "已根据设备类型调整参数", 2)
    end,
    
    -- 设置连接监听
    SetupConnections = function(self)
        -- 监听RemoteEvent
        local remoteEvents = {};
        
        -- 递归查找所有RemoteEvent
        local function findRemoteEvents(parent)
            for _, child in pairs(parent:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    table.insert(remoteEvents, child)
                    self:HookRemoteEvent(child)
                end
                if child:IsA("Folder") or child:IsA("Configuration") then
                    findRemoteEvents(child)
                end
            end
        end
        
        -- 监听服务中的RemoteEvent
        findRemoteEvents(game:GetService("ReplicatedStorage"))
        findRemoteEvents(game:GetService("StarterPlayer"))
        findRemoteEvents(game:GetService("StarterPack"))
        
        -- 监听新添加的RemoteEvent
        game.DescendantAdded:Connect(function(descendant)
            if descendant:IsA("RemoteEvent") then
                self:HookRemoteEvent(descendant)
            end
        end)
    end,
    
    -- 挂钩RemoteEvent
    HookRemoteEvent = function(self, remoteEvent)
        if self.ConnectionHandlers[remoteEvent] then
            return
        end
        
        -- 监听FireServer（客户端发送到服务器）
        local originalFireServer = remoteEvent.FireServer
        remoteEvent.FireServer = function(...) 
            local args = {...}
            if self.Enabled then
                self:CapturePacket("outgoing", remoteEvent, args)
            end
            return originalFireServer(unpack(args))
        end
        
        -- 监听OnClientEvent（服务器发送到客户端）
        local clientEventConnection = remoteEvent.OnClientEvent:Connect(function(...) 
            if self.Enabled then
                self:CapturePacket("incoming", remoteEvent, {...})
            end
        end)
        
        self.ConnectionHandlers[remoteEvent] = {
            clientEventConnection = clientEventConnection
        }
    end,
    
    -- 捕获数据包
    CapturePacket = function(self, direction, event, args)
        if not self.Enabled then return end
        
        -- 检查过滤器
        if self.FilterType ~= "all" and self.FilterType ~= direction then
            return
        end
        
        local eventName = event:GetFullName()
        if self.FilterKeyword ~= "" and not eventName:find(self.FilterKeyword) then
            return
        end
        
        -- 创建数据包记录
        local packet = {
            timestamp = os.time(),
            direction = direction,
            event = eventName,
            arguments = self:SerializeArguments(args),
            playerPosition = hrp and hrp.Position or Vector3.new(0, 0, 0)
        }
        
        -- 添加到捕获列表
        table.insert(self.CapturedPackets, packet)
        
        -- 限制最大数据包数量
        if #self.CapturedPackets > self.MaxPackets then
            table.remove(self.CapturedPackets, 1)
        end
        
        -- 自动保存检查
        if self.AutoSave and os.time() - self.LastSaveTime > self.SaveInterval then
            self:SavePackets()
            self.LastSaveTime = os.time()
        end
    end,
    
    -- 序列化参数
    SerializeArguments = function(self, args)
        local serialized = {}
        for i, arg in ipairs(args) do
            if typeof(arg) == "Vector3" then
                serialized[i] = string.format("Vector3(%.2f, %.2f, %.2f)", arg.X, arg.Y, arg.Z)
            elseif typeof(arg) == "CFrame" then
                serialized[i] = "CFrame(...)" -- 简化显示
            elseif typeof(arg) == "Instance" then
                serialized[i] = arg.ClassName .. ": " .. arg:GetFullName()
            elseif typeof(arg) == "table" then
                serialized[i] = "Table(" .. self:GetTableSize(arg) .. " entries)"
            else
                serialized[i] = tostring(arg)
            end
        end
        return serialized
    end,
    
    -- 获取表大小
    GetTableSize = function(self, tbl)
        local count = 0
        for _ in pairs(tbl) do
            count = count + 1
        end
        return count
    end,
    
    -- 启用/禁用抓包
    ToggleCapture = function(self, state)
        self.Enabled = state
        if state then
            Notify("Hokl4", "移动端抓包已开启", 3)
            if IsMobileDevice() then
                Notify("Hokl4", "移动模式优化已启用", 2)
            end
        else
            Notify("Hokl4", "移动端抓包已关闭", 3)
        end
    end,
    
    -- 设置过滤器
    SetFilter = function(self, filterType, keyword)
        self.FilterType = filterType or "all"
        self.FilterKeyword = keyword or ""
        Notify("Hokl4", "过滤器已设置: " .. self.FilterType .. ", 关键词: " .. self.FilterKeyword, 2)
    end,
    
    -- 清除捕获的数据包
    ClearPackets = function(self)
        self.CapturedPackets = {}
        Notify("Hokl4", "已清除所有捕获的数据包", 2)
    end,
    
    -- 保存数据包
    SavePackets = function(self)
        local saveData = {
            timestamp = os.time(),
            packetCount = #self.CapturedPackets,
            packets = self.CapturedPackets
        }
        
        -- 在Roblox环境中，我们将数据转换为字符串并通知用户
        local saveInfo = string.format("数据包保存于 %s，共 %d 个数据包", os.date(), #self.CapturedPackets)
        Notify("Hokl4", saveInfo, 5)
        
        return true
    end,
    
    -- 分析数据包
    AnalyzePackets = function(self)
        if self.IsAnalyzing then
            Notify("Hokl4", "分析已在进行中", 2)
            return
        end
        
        self.IsAnalyzing = true
        self.AnalysisResults = {}
        
        spawn(function()
            -- 事件频率分析
            local eventFrequency = {}
            local directionCount = {incoming = 0, outgoing = 0}
            
            for _, packet in ipairs(self.CapturedPackets) do
                -- 统计事件频率
                if not eventFrequency[packet.event] then
                    eventFrequency[packet.event] = 0
                end
                eventFrequency[packet.event] = eventFrequency[packet.event] + 1
                
                -- 统计方向
                directionCount[packet.direction] = directionCount[packet.direction] + 1
            end
            
            -- 找出最频繁的事件
            local topEvents = {}
            for event, count in pairs(eventFrequency) do
                table.insert(topEvents, {event = event, count = count})
            end
            
            table.sort(topEvents, function(a, b)
                return a.count > b.count
            end)
            
            -- 保存分析结果
            self.AnalysisResults = {
                totalPackets = #self.CapturedPackets,
                directionCount = directionCount,
                topEvents = {unpack(topEvents, 1, 5)},
                analysisTime = os.time()
            }
            
            self.IsAnalyzing = false
            Notify("Hokl4", "数据包分析完成", 3)
        end)
    end,
    
    -- 获取分析结果
    GetAnalysisResults = function(self)
        return self.AnalysisResults
    end,
    
    -- 获取数据包列表
    GetCapturedPackets = function(self)
        return self.CapturedPackets
    end,
    
    -- 设置最大数据包数量
    SetMaxPackets = function(self, maxCount)
        self.MaxPackets = maxCount
        
        -- 如果当前数据包超过最大值，删除旧的
        while #self.CapturedPackets > self.MaxPackets do
            table.remove(self.CapturedPackets, 1)
        end
        
        Notify("Hokl4", "最大数据包数已设置为 " .. maxCount, 2)
    end,
    
    -- 启用/禁用自动保存
    ToggleAutoSave = function(self, state, interval)
        self.AutoSave = state
        if interval then
            self.SaveInterval = interval
        end
        
        if state then
            Notify("Hokl4", "自动保存已开启，间隔 " .. self.SaveInterval .. " 秒", 3)
            self.LastSaveTime = os.time()
        else
            Notify("Hokl4", "自动保存已关闭", 3)
        end
    end
}

-- 初始化移动端抓包模块
GameModules.MobilePacketCapture:Init()

-- 初始化UI
function InitUI()
    -- 创建ScreenGui
    local gui = Instance.new("ScreenGui")
    gui.Name = "Hokl4_GUI"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = game:GetService("CoreGui")
    
    -- 检测设备类型
    local isMobile = IsMobileDevice()
    
    -- 创建主框架
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    
    -- 根据设备类型设置窗口大小
    if isMobile then
        -- 移动设备使用屏幕比例
        mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        mainFrame.Size = UDim2.new(0.9, 0, 0.8, 0)
        mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    else
        -- 电脑保持原大小
        mainFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
        mainFrame.Size = UDim2.new(0, 400, 0, 500)
    end
    
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mainFrame.BackgroundTransparency = 0.8
    mainFrame.BorderColor3 = Color3.fromRGB(60, 180, 240)
    mainFrame.BorderSizePixel = 2
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = gui
    
    -- 创建标题栏
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Position = UDim2.new(0, 0, 0, 0)
    titleBar.Size = UDim2.new(1, 0, 0, 30)
    titleBar.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
    titleBar.Parent = mainFrame
    
    -- 标题文本
    local titleText = Instance.new("TextLabel")
    titleText.Name = "TitleText"
    titleText.Position = UDim2.new(0, 5, 0, 0)
    titleText.Size = UDim2.new(1, -10, 1, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "Hokl4 - 整合版脚本"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 14
    titleText.Font = Enum.Font.GothamBold
    titleText.Parent = titleBar
    
    -- 关闭按钮
    local closeButton = Instance.new("TextButton")
    closeButton.Name = "CloseButton"
    closeButton.Position = UDim2.new(1, -30, 0, 0)
    closeButton.Size = UDim2.new(0, 30, 0, 30)
    closeButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 16
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Parent = titleBar
    
    closeButton.MouseButton1Click:Connect(function()
        gui:Destroy()
    end)
    
    -- Tab 容器
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Position = UDim2.new(0, 0, 0, 30)
    tabContainer.Size = UDim2.new(1, 0, 0, 30)
    tabContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    tabContainer.Parent = mainFrame
    
    -- 内容容器
    local contentContainer = Instance.new("ScrollingFrame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Position = UDim2.new(0, 0, 0, 60)
    contentContainer.Size = UDim2.new(1, 0, 1, -60)
    contentContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    contentContainer.BackgroundTransparency = 1
    contentContainer.ScrollBarThickness = 5
    contentContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    contentContainer.Parent = mainFrame
    
    -- 创建Tabs - 增加新游戏功能标签
    local tabs = {
        {name = "通用功能", module = CommonFeatures},
        {name = "AlienX", module = GameModules.AlienX},
        {name = "99 Nights", module = GameModules.Night99},
        {name = "Blade Ball", module = GameModules.BladeBall},
        {name = "传送", module = GameModules.Teleport or GameModules.Coordinates},
        {name = "坐标管理", module = GameModules.Coordinates},
        {name = "AI性能", module = GameModules.PerformanceManager},
        {name = "Doors", module = GameModules.Doors},
        {name = "伐木大亨", module = GameModules.LoggingTycoon},
        {name = "俄亥俄州", module = GameModules.Ohio},
        {name = "火箭模拟器", module = GameModules.RocketSimulator},
        {name = "力量传奇", module = GameModules.PowerLegend},
        {name = "矢井凛功能", module = GameModules.AimAssist},
        {name = "移动端抓包", module = GameModules.MobilePacketCapture}
    }
    
    local currentTab = nil
    local tabButtons = {}
    local tabContents = {}
    
    -- 创建Tab按钮和内容（使用滚动标签栏）
    local tabScrollFrame = Instance.new("ScrollingFrame")
    tabScrollFrame.Name = "TabScrollFrame"
    tabScrollFrame.Size = UDim2.new(1, 0, 1, 0)
    tabScrollFrame.CanvasSize = UDim2.new(0, #tabs * 100, 0, 0)
    tabScrollFrame.BackgroundTransparency = 1
    tabScrollFrame.ScrollBarThickness = 0
    tabScrollFrame.Parent = tabContainer
    
    -- 创建Tab按钮和内容
    for i, tab in ipairs(tabs) do
        -- 创建Tab按钮
        local tabButton = Instance.new("TextButton")
        tabButton.Name = tab.name .. "Button"
        tabButton.Position = UDim2.new(0, (i-1)*100, 0, 0)
        tabButton.Size = UDim2.new(0, 100, 1, 0)
        tabButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        tabButton.Text = tab.name
        tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
        tabButton.TextSize = 12
        tabButton.Font = Enum.Font.Gotham
        tabButton.Parent = tabScrollFrame
        tabButtons[tab.name] = tabButton
        
        -- 创建Tab内容
        local tabContent = Instance.new("Frame")
        tabContent.Name = tab.name .. "Content"
        tabContent.Position = UDim2.new(0, 0, 0, 0)
        tabContent.Size = UDim2.new(1, 0, 1, 0)
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.Parent = contentContainer
        tabContents[tab.name] = tabContent
        
        -- Tab按钮点击事件
        tabButton.MouseButton1Click:Connect(function()
            if currentTab then
                tabButtons[currentTab].BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                tabButtons[currentTab].TextColor3 = Color3.fromRGB(200, 200, 200)
                tabContents[currentTab].Visible = false
            end
            
            currentTab = tab.name
            tabButton.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
            tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tabContent.Visible = true
            
            -- 调整CanvasSize以适应内容
            local totalHeight = 0
            for _, child in pairs(tabContent:GetChildren()) do
                if child:IsA("GuiObject") then
                    totalHeight = math.max(totalHeight, child.Position.Y.Offset + child.Size.Y.Offset)
                end
            end
            contentContainer.CanvasSize = UDim2.new(0, 0, 0, totalHeight + 20)
        end)
    end
    
    -- 通用功能Tab内容
    local commonContent = tabContents["通用功能"]
    local yPos = 10
    
    -- 飞行开关
    local flyToggle = CreateToggle(commonContent, "飞行模式", "FlyToggle", function(state)
        CommonFeatures:ToggleFly(state)
    end)
    flyToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无碰撞开关
    local noclipToggle = CreateToggle(commonContent, "无碰撞", "NoClipToggle", function(state)
        CommonFeatures:ToggleNoClip(state)
    end)
    noclipToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 夜视开关
    local nightVisionToggle = CreateToggle(commonContent, "夜视", "NightVisionToggle", function(state)
        CommonFeatures:ToggleNightVision(state)
    end)
    nightVisionToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无限跳跃开关
    local infiniteJumpToggle = CreateToggle(commonContent, "无限跳跃", "InfiniteJumpToggle", function(state)
        CommonFeatures:ToggleInfiniteJump(state)
    end)
    infiniteJumpToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 透视开关
    local espToggle = CreateToggle(commonContent, "透视", "ESPToggle", function(state)
        CommonFeatures:ToggleESP(state)
    end)
    espToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 移动速度滑块
    local speedLabel = CreateLabel(commonContent, "移动速度", UDim2.new(0, 10, 0, yPos))
    yPos = yPos + 20
    local speedSlider = CreateSlider(commonContent, "SpeedSlider", 16, 16, 500, function(value)
        CommonFeatures:SetWalkSpeed(value)
    end)
    speedSlider.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 跳跃力量滑块
    local jumpLabel = CreateLabel(commonContent, "跳跃力量", UDim2.new(0, 10, 0, yPos))
    yPos = yPos + 20
    local jumpSlider = CreateSlider(commonContent, "JumpSlider", 50, 50, 500, function(value)
        CommonFeatures:SetJumpPower(value)
    end)
    jumpSlider.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 99 Nights Tab内容
    local night99Content = tabContents["99 Nights"]
    yPos = 10
    
    -- 杀戮光环开关
    local killAuraToggle = CreateToggle(night99Content, "杀戮光环", "KillAuraToggle", function(state)
        GameModules.Night99:ToggleKillAura(state)
    end)
    killAuraToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动砍树开关
    local autoTreeToggle = CreateToggle(night99Content, "自动砍树", "AutoTreeToggle", function(state)
        GameModules.Night99:ToggleAutoTree(state)
    end)
    autoTreeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动进食开关
    local autoEatToggle = CreateToggle(night99Content, "自动进食", "AutoEatToggle", function(state)
        GameModules.Night99:ToggleAutoEat(state)
    end)
    autoEatToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无敌模式开关
    local godModeToggle = CreateToggle(night99Content, "无敌模式", "GodModeToggle", function(state)
        GameModules.Night99:ToggleGodMode(state)
    end)
    godModeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- Blade Ball Tab内容
    local bladeBallContent = tabContents["Blade Ball"]
    yPos = 10
    
    -- 自动击球开关
    local autoHitToggle = CreateToggle(bladeBallContent, "自动击球", "AutoHitToggle", function(state)
        GameModules.BladeBall:ToggleAutoHit(state)
    end)
    autoHitToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动闪避开关
    local autoDodgeToggle = CreateToggle(bladeBallContent, "自动闪避", "AutoDodgeToggle", function(state)
        GameModules.BladeBall:ToggleAutoDodge(state)
    end)
    autoDodgeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- AlienX Tab内容
    local alienXContent = tabContents["AlienX"]
    yPos = 10
    
    -- 杀戮光环开关
    local alienXKillAuraToggle = CreateToggle(alienXContent, "杀戮光环", "AlienXKillAuraToggle", function(state)
        GameModules.AlienX:ToggleKillAura(state)
    end)
    alienXKillAuraToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动砍树开关
    local alienXAutoChopToggle = CreateToggle(alienXContent, "自动砍树", "AlienXAutoChopToggle", function(state)
        GameModules.AlienX:ToggleAutoChop(state)
    end)
    alienXAutoChopToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动进食开关
    local alienXAutoEatToggle = CreateToggle(alienXContent, "自动进食", "AlienXAutoEatToggle", function(state)
        GameModules.AlienX:ToggleAutoEat(state)
    end)
    alienXAutoEatToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- ESP显示开关
    local alienXESPToggle = CreateToggle(alienXContent, "ESP显示", "AlienXESPToggle", function(state)
        GameModules.AlienX:ToggleESP(state)
    end)
    alienXESPToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动收集开关
    local alienXAutoCollectToggle = CreateToggle(alienXContent, "自动收集", "AlienXAutoCollectToggle", function(state)
        GameModules.AlienX:ToggleAutoCollect(state)
    end)
    alienXAutoCollectToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 传送Tab内容
    local teleportContent = tabContents["传送"]
    yPos = 10
    
    -- 玩家列表下拉菜单
    local playerDropdown = CreateDropdown(teleportContent, "选择玩家", "PlayerDropdown", GameModules:GetPlayerList(), function(selected)
        teleportContent.PlayerName = selected
    end)
    playerDropdown.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 传送到玩家按钮
    local teleportButton = CreateButton(teleportContent, "传送到玩家", "TeleportButton", function()
        if teleportContent.PlayerName then
            GameModules:TeleportToPlayer(teleportContent.PlayerName)
        else
            Notify("Hokl4", "请先选择玩家", 3)
        end
    end)
    teleportButton.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 刷新玩家列表按钮
    local refreshButton = CreateButton(teleportContent, "刷新玩家列表", "RefreshButton", function()
        -- 重新创建下拉菜单
        if teleportContent:FindFirstChild("PlayerDropdown") then
            teleportContent.PlayerDropdown:Destroy()
        end
        
        local newDropdown = CreateDropdown(teleportContent, "选择玩家", "PlayerDropdown", GameModules:GetPlayerList(), function(selected)
            teleportContent.PlayerName = selected
        end)
        newDropdown.Position = UDim2.new(0, 10, 0, 10)
    end)
    refreshButton.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 坐标管理Tab内容
    local coordsContent = tabContents["坐标管理"]
    yPos = 10
    
    -- 获取当前坐标按钮
    local getCoordButton = CreateButton(coordsContent, "获取当前坐标", "GetCoordButton", function()
        local coord = GameModules.Coordinates:GetCurrentCoord()
        if coord then
            Notify("Hokl4", "当前坐标: X=" .. coord.x .. ", Y=" .. coord.y .. ", Z=" .. coord.z, 3)
            -- 显示在UI上
            if coordsContent:FindFirstChild("CurrentCoordLabel") then
                coordsContent.CurrentCoordLabel:Destroy()
            end
            local coordLabel = CreateLabel(coordsContent, "当前坐标: X=" .. coord.x .. ", Y=" .. coord.y .. ", Z=" .. coord.z, UDim2.new(0, 10, 0, 40))
            coordLabel.Name = "CurrentCoordLabel"
            coordLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
            -- 保存当前坐标到临时变量，以便保存按钮使用
            coordsContent.currentCoord = coord
        else
            Notify("Hokl4", "无法获取当前坐标", 3)
        end
    end)
    getCoordButton.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 坐标名称输入框
    local coordNameLabel = CreateLabel(coordsContent, "坐标名称:", UDim2.new(0, 10, 0, yPos))
    yPos = yPos + 20
    local coordNameBox = Instance.new("TextBox")
    coordNameBox.Name = "CoordNameBox"
    coordNameBox.Position = UDim2.new(0, 10, 0, yPos)
    coordNameBox.Size = UDim2.new(0, 200, 0, 25)
    coordNameBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    coordNameBox.BorderColor3 = Color3.fromRGB(60, 180, 240)
    coordNameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
    coordNameBox.PlaceholderText = "输入坐标名称"
    coordNameBox.TextSize = 14
    coordNameBox.Font = Enum.Font.Gotham
    coordNameBox.Parent = coordsContent
    yPos = yPos + 30
    
    -- 保存坐标按钮
    local saveCoordButton = CreateButton(coordsContent, "保存当前坐标", "SaveCoordButton", function()
        local coordName = coordNameBox.Text
        if coordName and coordName ~= "" then
            if coordsContent.currentCoord then
                GameModules.Coordinates:SaveCoord(coordName, coordsContent.currentCoord.x, coordsContent.currentCoord.y, coordsContent.currentCoord.z)
                -- 刷新坐标列表
                updateCoordList()
            else
                Notify("Hokl4", "请先获取当前坐标", 3)
            end
        else
            Notify("Hokl4", "请输入坐标名称", 3)
        end
    end)
    saveCoordButton.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 40
    
    -- 坐标列表标签
    local coordsListLabel = CreateLabel(coordsContent, "已保存坐标:", UDim2.new(0, 10, 0, yPos))
    yPos = yPos + 20
    
    -- 创建坐标列表的滚动框
    local coordsListFrame = Instance.new("ScrollingFrame")
    coordsListFrame.Name = "CoordsListFrame"
    coordsListFrame.Position = UDim2.new(0, 10, 0, yPos)
    coordsListFrame.Size = UDim2.new(0, 380, 0, 200)
    coordsListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    coordsListFrame.ScrollBarThickness = 5
    coordsListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    coordsListFrame.Parent = coordsContent
    
    -- 更新坐标列表的函数
    function updateCoordList()
        -- 清空现有列表
        for _, child in pairs(coordsListFrame:GetChildren()) do
            if child:IsA("Frame") then
                child:Destroy()
            end
        end
        
        -- 获取坐标列表
        local coordsList = GameModules.Coordinates:GetCoordList()
        local listYPos = 0
        
        if #coordsList == 0 then
            local emptyLabel = CreateLabel(coordsListFrame, "暂无保存的坐标", UDim2.new(0, 10, 0, 10))
            coordsListFrame.CanvasSize = UDim2.new(0, 0, 0, 30)
        else
            -- 创建每个坐标的行
            for _, coord in ipairs(coordsList) do
                local coordRow = Instance.new("Frame")
                coordRow.Position = UDim2.new(0, 0, 0, listYPos)
                coordRow.Size = UDim2.new(1, 0, 0, 40)
                coordRow.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                coordRow.Parent = coordsListFrame
                
                -- 坐标信息标签
                local coordInfo = CreateLabel(coordRow, coord.name .. ": X=" .. coord.x .. ", Y=" .. coord.y .. ", Z=" .. coord.z, UDim2.new(0, 10, 0, 10))
                coordInfo.Size = UDim2.new(0, 250, 0, 20)
                coordInfo.TextSize = 12
                
                -- 传送按钮
                local tpButton = Instance.new("TextButton")
                tpButton.Name = "TPButton"
                tpButton.Position = UDim2.new(1, -120, 0, 5)
                tpButton.Size = UDim2.new(0, 50, 0, 30)
                tpButton.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
                tpButton.Text = "传送"
                tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                tpButton.TextSize = 12
                tpButton.Font = Enum.Font.Gotham
                tpButton.Parent = coordRow
                
                tpButton.MouseButton1Click:Connect(function()
                    GameModules.Coordinates:TeleportToCoord(coord.name)
                end)
                
                -- 删除按钮
                local delButton = Instance.new("TextButton")
                delButton.Name = "DelButton"
                delButton.Position = UDim2.new(1, -65, 0, 5)
                delButton.Size = UDim2.new(0, 50, 0, 30)
                delButton.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
                delButton.Text = "删除"
                delButton.TextColor3 = Color3.fromRGB(255, 255, 255)
                delButton.TextSize = 12
                delButton.Font = Enum.Font.Gotham
                delButton.Parent = coordRow
                
                delButton.MouseButton1Click:Connect(function()
                    if GameModules.Coordinates:DeleteCoord(coord.name) then
                        updateCoordList()
                    end
                end)
                
                listYPos = listYPos + 45
            end
            
            coordsListFrame.CanvasSize = UDim2.new(0, 0, 0, listYPos)
        end
    end
    
    -- 初始更新坐标列表
    updateCoordList()
    
    -- 刷新坐标列表按钮
    local refreshCoordsButton = CreateButton(coordsContent, "刷新坐标列表", "RefreshCoordsButton", function()
        updateCoordList()
    end)
    refreshCoordsButton.Position = UDim2.new(0, 10, 0, yPos + 210)
    
    -- AI性能Tab内容
    local perfContent = tabContents["AI性能"]
    yPos = 10
    
    -- 性能管理器启用开关
    local perfEnabledToggle = CreateToggle(perfContent, "启用AI性能管理", "PerfEnabledToggle", function(state)
        GameModules.PerformanceManager:SetEnabled(state)
    end)
    perfEnabledToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 优化激进程度标签
    local aggLabel = CreateLabel(perfContent, "优化激进程度: 2", UDim2.new(0, 10, 0, yPos))
    aggLabel.Name = "AggressivenessLabel"
    yPos = yPos + 20
    
    -- 优化激进程度滑块
    local aggSlider = Instance.new("Frame")
    aggSlider.Name = "AggressivenessSlider"
    aggSlider.Position = UDim2.new(0, 10, 0, yPos)
    aggSlider.Size = UDim2.new(0, 300, 0, 10)
    aggSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    aggSlider.Parent = perfContent
    
    local aggSliderHandle = Instance.new("Frame")
    aggSliderHandle.Name = "Handle"
    aggSliderHandle.Position = UDim2.new(0.3, -5, 0, -5)
    aggSliderHandle.Size = UDim2.new(0, 20, 0, 20)
    aggSliderHandle.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
    aggSliderHandle.Shape = Enum.PartType.Ball
    aggSliderHandle.Parent = aggSlider
    
    -- 滑块拖动功能
    local isDragging = false
    aggSliderHandle.MouseButton1Down:Connect(function()
        isDragging = true
    end)
    
    local mouseUpConn = game:GetService("UserInputService").MouseButton1Up:Connect(function()
        isDragging = false
    end)
    table.insert(eventConnections, mouseUpConn)
    
    local mouseMoveConn = game:GetService("UserInputService").MouseMovement:Connect(function()
        if isDragging then
            local mousePos = game:GetService("UserInputService").MouseLocation
            local absPos = perfContent.AbsolutePosition
            local sliderPos = (mousePos.X - absPos.X - 10) / 300
            sliderPos = math.clamp(sliderPos, 0, 1)
            aggSliderHandle.Position = UDim2.new(sliderPos, -10, 0, -5)
            
            local level = math.round(sliderPos * 4) + 1 -- 1-5范围
            perfContent:FindFirstChild("AggressivenessLabel").Text = "优化激进程度: " .. level
            
        end
    end)
    table.insert(eventConnections, mouseMoveConn)
              
              -- 更新优化激进程度
              GameModules.PerformanceManager:SetAggressiveness(level)
        end
    end)
    
    yPos = yPos + 40
    
    -- 性能监控面板
    local monitorPanel = Instance.new("Frame")
    monitorPanel.Name = "PerformanceMonitorPanel"
    monitorPanel.Position = UDim2.new(0, 10, 0, yPos)
    monitorPanel.Size = UDim2.new(1, -20, 0, 150)
    monitorPanel.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    monitorPanel.BorderColor3 = Color3.fromRGB(50, 50, 50)
    monitorPanel.BorderSizePixel = 1
    monitorPanel.Parent = perfContent
    
    -- 性能监控标题
    local monitorTitle = CreateLabel(monitorPanel, "实时性能监控", UDim2.new(0, 10, 0, 10))
    
    -- 性能指标标签
    local fpsLabel = CreateLabel(monitorPanel, "FPS: 0", UDim2.new(0, 10, 0, 40))
    fpsLabel.Name = "FPSLabel"
    
    local memoryLabel = CreateLabel(monitorPanel, "内存: 0 MB", UDim2.new(0, 10, 0, 70))
    memoryLabel.Name = "MemoryLabel"
    
    local tasksLabel = CreateLabel(monitorPanel, "活跃任务: 0 / 队列任务: 0", UDim2.new(0, 10, 0, 100))
    tasksLabel.Name = "TasksLabel"
    
    -- 刷新性能数据按钮
    local refreshPerfButton = CreateButton(monitorPanel, "刷新性能数据", "RefreshPerfButton", function()
        updatePerfData()
    end)
    refreshPerfButton.Position = UDim2.new(0, 10, 0, 115)
    
    -- 更新性能数据的函数
    function updatePerfData()
        local perfData = GameModules.PerformanceManager:GetPerformanceData()
        
        if perfData then
            monitorPanel:FindFirstChild("FPSLabel").Text = "FPS: " .. perfData.fps
            monitorPanel:FindFirstChild("MemoryLabel").Text = "内存: " .. perfData.memory .. " MB"
            monitorPanel:FindFirstChild("TasksLabel").Text = "活跃任务: " .. perfData.activeTasks .. " / 队列任务: " .. perfData.queuedTasks
        end
    end
    
    -- 初始更新
    updatePerfData()
    
    -- 自动更新性能数据
    spawn(function()
        while true do
            wait(1)
            updatePerfData()
        end
    end)
    
    -- Doors Tab内容
    local doorsContent = tabContents["Doors"]
    yPos = 10
    
    -- 自动收集开关
    local autoCollectToggle = CreateToggle(doorsContent, "自动收集", "DoorsAutoCollectToggle", function(state)
        GameModules.Doors:ToggleAutoCollect(state)
    end)
    autoCollectToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 无敌模式开关
    local doorsGodModeToggle = CreateToggle(doorsContent, "无敌模式", "DoorsGodModeToggle", function(state)
        GameModules.Doors:ToggleGodMode(state)
    end)
    doorsGodModeToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 伐木大亨Tab内容
    local loggingContent = tabContents["伐木大亨"]
    yPos = 10
    
    -- 自动砍树开关
    local loggingAutoChopToggle = CreateToggle(loggingContent, "自动砍树", "LoggingAutoChopToggle", function(state)
        GameModules.LoggingTycoon:ToggleAutoChop(state)
    end)
    loggingAutoChopToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动出售开关
    local loggingAutoSellToggle = CreateToggle(loggingContent, "自动出售", "LoggingAutoSellToggle", function(state)
        GameModules.LoggingTycoon:ToggleAutoSell(state)
    end)
    loggingAutoSellToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 俄亥俄州Tab内容
    local ohioContent = tabContents["俄亥俄州"]
    yPos = 10
    
    -- 自动拾取开关
    local ohioAutoLootToggle = CreateToggle(ohioContent, "自动拾取", "OhioAutoLootToggle", function(state)
        GameModules.Ohio:ToggleAutoLoot(state)
    end)
    ohioAutoLootToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 速度提升开关
    local ohioSpeedBoostToggle = CreateToggle(ohioContent, "速度提升", "OhioSpeedBoostToggle", function(state)
        GameModules.Ohio:ToggleSpeedBoost(state)
    end)
    ohioSpeedBoostToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 火箭模拟器Tab内容
    local rocketContent = tabContents["火箭模拟器"]
    yPos = 10
    
    -- 自动建造开关
    local rocketAutoBuildToggle = CreateToggle(rocketContent, "自动建造", "RocketAutoBuildToggle", function(state)
        GameModules.RocketSimulator:ToggleAutoBuild(state)
    end)
    rocketAutoBuildToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动发射开关
    local rocketAutoLaunchToggle = CreateToggle(rocketContent, "自动发射", "RocketAutoLaunchToggle", function(state)
        GameModules.RocketSimulator:ToggleAutoLaunch(state)
    end)
    rocketAutoLaunchToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 力量传奇Tab内容
    local powerContent = tabContents["力量传奇"]
    yPos = 10
    
    -- 自动训练开关
    local powerAutoTrainToggle = CreateToggle(powerContent, "自动训练", "PowerAutoTrainToggle", function(state)
        GameModules.PowerLegend:ToggleAutoTrain(state)
    end)
    powerAutoTrainToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 自动重生开关
    local powerAutoRebirthToggle = CreateToggle(powerContent, "自动重生", "PowerAutoRebirthToggle", function(state)
        GameModules.PowerLegend:ToggleAutoRebirth(state)
    end)
    powerAutoRebirthToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 矢井凛功能Tab内容
    local aimContent = tabContents["矢井凛功能"]
    yPos = 10
    
    -- 机会预判瞄准开关
    local aimPredictionToggle = CreateToggle(aimContent, "机会预判瞄准", "AimPredictionToggle", function(state)
        GameModules.AimAssist:TogglePrediction(state)
    end)
    aimPredictionToggle.Position = UDim2.new(0, 10, 0, yPos)
    yPos = yPos + 30
    
    -- 选择第一个Tab
    tabButtons[tabs[1].name]:FireEvent("MouseButton1Click")
    
    -- 创建工具函数
    function CreateLabel(parent, text, position)
        local isMobile = IsMobileDevice()
        local label = Instance.new("TextLabel")
        label.Name = text .. "Label"
        label.Position = position
        label.Size = UDim2.new(1, -20, 0, isMobile and 30 or 20)
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = isMobile and 18 or 14
        label.Font = Enum.Font.Gotham
        label.Parent = parent
        return label
    end
    
    function CreateToggle(parent, text, name, callback)
        local isMobile = IsMobileDevice()
        local toggle = Instance.new("Frame")
        toggle.Name = name
        toggle.Size = UDim2.new(1, -20, 0, isMobile and 40 or 25)
        toggle.BackgroundTransparency = 1
        toggle.Parent = parent
        
        local toggleLabel = Instance.new("TextLabel")
        toggleLabel.Name = "Label"
        toggleLabel.Position = UDim2.new(0, 0, 0, 0)
        toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
        toggleLabel.BackgroundTransparency = 1
        toggleLabel.Text = text
        toggleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleLabel.TextSize = isMobile and 18 or 14
        toggleLabel.Font = Enum.Font.Gotham
        toggleLabel.Parent = toggle
        
        local toggleButton = Instance.new("TextButton")
        toggleButton.Name = "Button"
        toggleButton.Position = UDim2.new(0.75, 0, 0, isMobile and 5 or 2.5)
        toggleButton.Size = UDim2.new(0.2, 0, 0, isMobile and 30 or 20)
        toggleButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        toggleButton.Text = "关"
        toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleButton.TextSize = isMobile and 16 or 12
        toggleButton.Font = Enum.Font.GothamBold
        toggleButton.Parent = toggle
        
        local isEnabled = false
        
        -- 创建点击处理函数，支持鼠标和触摸
        local function handleClick()
            isEnabled = not isEnabled
            toggleButton.BackgroundColor3 = isEnabled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(50, 50, 50)
            toggleButton.Text = isEnabled and "开" or "关"
            callback(isEnabled)
        end
        
        -- 连接点击事件
        toggleButton.MouseButton1Click:Connect(handleClick)
        toggleButton.TouchTap:Connect(handleClick)
        
        return toggle
    end
    
    function CreateButton(parent, text, name, callback)
        local isMobile = IsMobileDevice()
        local button = Instance.new("TextButton")
        button.Name = name
        button.Size = UDim2.new(1, -20, 0, isMobile and 45 or 30)
        button.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
        button.Text = text
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = isMobile and 18 or 14
        button.Font = Enum.Font.GothamBold
        button.Parent = parent
        
        -- 创建点击处理函数，支持鼠标和触摸
        local function handleClick()
            callback()
        end
        
        -- 连接点击事件
        button.MouseButton1Click:Connect(handleClick)
        button.TouchTap:Connect(handleClick)
        
        button.MouseEnter:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
        end)
        
        button.MouseLeave:Connect(function()
            button.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
        end)
        
        return button
    end
    
    function CreateSlider(parent, name, defaultValue, minValue, maxValue, callback)
        local isMobile = IsMobileDevice()
        local slider = Instance.new("Frame")
        slider.Name = name
        slider.Size = UDim2.new(1, -20, 0, isMobile and 45 or 30)
        slider.BackgroundTransparency = 1
        slider.Parent = parent
        
        local sliderTrack = Instance.new("Frame")
        sliderTrack.Name = "Track"
        sliderTrack.Position = UDim2.new(0, 0, 0, isMobile and 20 or 12.5)
        sliderTrack.Size = UDim2.new(1, 0, 0, isMobile and 8 or 5)
        sliderTrack.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        sliderTrack.Parent = slider
        
        local sliderHandle = Instance.new("Frame")
        sliderHandle.Name = "Handle"
        sliderHandle.Size = UDim2.new(0, isMobile and 25 or 15, 0, isMobile and 25 or 15)
        sliderHandle.BackgroundColor3 = Color3.fromRGB(60, 180, 240)
        sliderHandle.AnchorPoint = Vector2.new(0.5, 0.5)
        sliderHandle.Parent = slider
        
        -- 计算初始位置
        local valueRange = maxValue - minValue
        local initialValue = defaultValue - minValue
        local initialPercent = initialValue / valueRange
        sliderHandle.Position = UDim2.new(initialPercent, 0, 0.5, 0)
        
        -- 创建值显示标签
        local valueLabel = Instance.new("TextLabel")
        valueLabel.Name = "ValueLabel"
        valueLabel.Position = UDim2.new(1, -60, 0, 0)
        valueLabel.Size = UDim2.new(0, 60, 1, 0)
        valueLabel.BackgroundTransparency = 1
        valueLabel.Text = tostring(defaultValue)
        valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        valueLabel.TextSize = isMobile and 16 or 12
        valueLabel.Font = Enum.Font.Gotham
        valueLabel.Parent = slider
        
        -- 拖动处理
        local dragging = false
        local uis = game:GetService("UserInputService")
        
        -- 处理输入开始（鼠标和触摸）
        sliderHandle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                if not isMobile then -- 移动设备不需要隐藏鼠标
                    uis:SetMouseIconEnabled(false)
                end
            end
        end)
        
        -- 处理输入结束（鼠标和触摸）
        local inputEndedConn = uis.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
                if not isMobile then
                    uis:SetMouseIconEnabled(true)
                end
            end
        end)
        
        -- 处理输入变化（鼠标移动和触摸移动）
        local inputChangedConn = uis.InputChanged:Connect(function(input)
            if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local pos = input.Position
                local absPos = slider.AbsolutePosition
                local absSize = slider.AbsoluteSize
                
                -- 计算相对位置
                local relX = math.clamp((pos.X - absPos.X) / absSize.X, 0, 1)
                sliderHandle.Position = UDim2.new(relX, 0, 0.5, 0)
                
                -- 计算值
                local value = math.floor(relX * valueRange + minValue)
                valueLabel.Text = tostring(value)
                callback(value)
            end
        end)
        
        return slider
    end
    
    function CreateDropdown(parent, text, name, options, callback)
        local isMobile = IsMobileDevice()
        local optionHeight = isMobile and 40 or 25
        local dropdown = Instance.new("Frame")
        dropdown.Name = name
        dropdown.Size = UDim2.new(1, -20, 0, isMobile and 40 or 25)
        dropdown.BackgroundTransparency = 1
        dropdown.Parent = parent
        
        local dropdownLabel = Instance.new("TextLabel")
        dropdownLabel.Name = "Label"
        dropdownLabel.Position = UDim2.new(0, 0, 0, 0)
        dropdownLabel.Size = UDim2.new(0.4, 0, 1, 0)
        dropdownLabel.BackgroundTransparency = 1
        dropdownLabel.Text = text
        dropdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownLabel.TextSize = isMobile and 18 or 14
        dropdownLabel.Font = Enum.Font.Gotham
        dropdownLabel.Parent = dropdown
        
        local dropdownButton = Instance.new("TextButton")
        dropdownButton.Name = "Button"
        dropdownButton.Position = UDim2.new(0.4, 0, 0, 0)
        dropdownButton.Size = UDim2.new(0.6, 0, 1, 0)
        dropdownButton.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdownButton.Text = options[1] or "无选项"
        dropdownButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        dropdownButton.TextSize = isMobile and 16 or 12
        dropdownButton.Font = Enum.Font.Gotham
        dropdownButton.Parent = dropdown
        
        local dropdownList = Instance.new("ScrollingFrame")
        dropdownList.Name = "List"
        dropdownList.Position = UDim2.new(0.4, 0, 1, 0)
        dropdownList.Size = UDim2.new(0.6, 0, 0, isMobile and 200 or 100)
        dropdownList.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        dropdownList.BackgroundTransparency = 0
        dropdownList.Visible = false
        dropdownList.ScrollBarThickness = isMobile and 10 or 5
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, #options * optionHeight)
        dropdownList.Parent = dropdown
        
        -- 选项点击处理函数
        local function handleOptionSelect(option)
            dropdownButton.Text = option
            dropdownList.Visible = false
            callback(option)
        end
        
        -- 创建选项
        for i, option in ipairs(options) do
            local optionButton = Instance.new("TextButton")
            optionButton.Name = "Option" .. i
            optionButton.Position = UDim2.new(0, 0, 0, (i-1)*optionHeight)
            optionButton.Size = UDim2.new(1, 0, 0, optionHeight)
            optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            optionButton.Text = option
            optionButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            optionButton.TextSize = isMobile and 16 or 12
            optionButton.Font = Enum.Font.Gotham
            optionButton.Parent = dropdownList
            
            -- 连接鼠标和触摸事件
            optionButton.MouseButton1Click:Connect(function()
                handleOptionSelect(option)
            end)
            optionButton.TouchTap:Connect(function()
                handleOptionSelect(option)
            end)
            
            if not isMobile then
                -- 移动设备不需要悬停效果
                optionButton.MouseEnter:Connect(function()
                    optionButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                end)
                
                optionButton.MouseLeave:Connect(function()
                    optionButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
                end)
            end
        end
        
        -- 切换下拉列表函数
        local function toggleDropdown()
            dropdownList.Visible = not dropdownList.Visible
        end
        
        -- 连接按钮点击事件
        dropdownButton.MouseButton1Click:Connect(toggleDropdown)
        dropdownButton.TouchTap:Connect(toggleDropdown)
        
        -- 点击外部关闭
        local dropdownInputConn = game:GetService("UserInputService").InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                local pos = input.Position
                local absPos = dropdown.AbsolutePosition
                local absSize = dropdown.AbsoluteSize
                
                -- 检查是否点击在下拉框外部
                if pos.X < absPos.X or pos.X > absPos.X + absSize.X or
                   pos.Y < absPos.Y or pos.Y > absPos.Y + absSize.Y then
                    -- 如果下拉列表可见，则关闭
                    if dropdownList.Visible then
                        -- 检查是否点击在下拉列表内部
                        local listAbsPos = dropdownList.AbsolutePosition
                        local listAbsSize = dropdownList.AbsoluteSize
                        if pos.X < listAbsPos.X or pos.X > listAbsPos.X + listAbsSize.X or
                           pos.Y < listAbsPos.Y or pos.Y > listAbsPos.Y + listAbsSize.Y then
                            dropdownList.Visible = false
                        end
                    end
                end
            end
        end)
        table.insert(eventConnections, dropdownInputConn)
        
        return dropdown
    end
    
    -- 窗口拖动功能
    local dragging = false
    local dragInput
    local dragStart
    local startPos
    local isMobile = IsMobileDevice()
    
    titleBar.InputBegan:Connect(function(input)
        -- 支持鼠标和触摸输入
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            local dragInputChangedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    titleBar.InputChanged:Connect(function(input)
        -- 支持鼠标移动和触摸移动
        if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    -- 增加触摸结束检测
    titleBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- 初始化脚本
Notify("Hokl4", "脚本加载成功! 作者: Yux6", 3)

-- 初始化UI
task.spawn(function()
    pcall(InitUI)
end)

-- 清理事件连接的函数，防止内存泄漏
local function cleanupConnections()
    for _, conn in pairs(eventConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    eventConnections = {}
end

-- 定期检查并清理事件连接
spawn(function()
    while true do
        wait(300)  -- 每5分钟检查一次
        pcall(cleanupConnections)
    end
end)

-- 当角色重生时重新初始化引用
lp.CharacterAdded:Connect(function(newChar)
    -- 先清理旧的连接
    pcall(cleanupConnections)
    
    -- 重新获取角色引用
    character = newChar
    humanoid = newChar:WaitForChild("Humanoid")
    hrp = newChar:WaitForChild("HumanoidRootPart")
end)

-- 保持脚本运行
while true do
    wait(60)
end