local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled

local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "鸽子铺",
    Icon = "layout-dashboard",
    Author = "鸽子神制作",
    Folder = "MyPanel",
    Size = isMobile and UDim2.fromOffset(420, 340) or UDim2.fromOffset(580, 460),
    Theme = "Dark",
})

Window.IsOpenButtonEnabled = false

local rawOpen    = Window.Open
local rawClose   = Window.Close
local rawDialog  = Window.Dialog

-- 悬浮球
local gui = Instance.new("ScreenGui")
gui.Name = "FloatingBall"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.Position = UDim2.new(0, 16, 0.5, -26)
root.Size = UDim2.new(0, 52, 0, 52)
root.BackgroundTransparency = 1
root.Visible = false
root.ZIndex = 10
root.Parent = gui

local scale = Instance.new("UIScale")
scale.Parent = root

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
bg.BorderSizePixel = 0
bg.Active = false
bg.ZIndex = 1
bg.Parent = root

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(1, 0)
corner.Parent = bg

local grad = Instance.new("UIGradient")
grad.Rotation = 90
grad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 60, 68)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 18, 22)),
})
grad.Parent = bg

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(165, 165, 180)
stroke.Thickness = 1.5
stroke.Transparency = 0.25
stroke.Parent = bg

local ball = Instance.new("TextButton")
ball.Size = UDim2.fromScale(1, 1)
ball.BackgroundTransparency = 1
ball.AutoButtonColor = false
ball.Text = "鸽"
ball.Font = Enum.Font.GothamBlack
ball.TextSize = 24
ball.TextColor3 = Color3.fromRGB(255, 255, 255)
ball.ZIndex = 5
ball.Parent = root

local function setBallVisible(state)
    if state then
        root.Visible = true
        scale.Scale = 0.6
        TweenService:Create(scale, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    else
        TweenService:Create(scale, TweenInfo.new(0.15, Enum.EasingStyle.Quint), { Scale = 0 }):Play()
        task.delay(0.15, function()
            root.Visible = false
        end)
    end
end

local dragging, dragOffset, moved = false, Vector2.zero, false
local pressPos = Vector2.zero

ball.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        moved = false
        pressPos = Vector2.new(input.Position.X, input.Position.Y)
        dragOffset = pressPos - Vector2.new(root.AbsolutePosition.X, root.AbsolutePosition.Y)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.MouseMovement
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end

    local current = Vector2.new(input.Position.X, input.Position.Y)
    if not moved and (current - pressPos).Magnitude < 5 then
        return
    end
    moved = true

    local target = current - dragOffset
    local viewport = (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize) or Vector2.new(1920, 1080)
    local size = root.AbsoluteSize

    target = Vector2.new(
        math.clamp(target.X, 0, math.max(0, viewport.X - size.X)),
        math.clamp(target.Y, 0, math.max(0, viewport.Y - size.Y))
    )

    root.Position = UDim2.fromOffset(target.X, target.Y)
end)

UserInputService.InputEnded:Connect(function(input)
    if not dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
        if not moved and not Window.Destroyed then
            Window:Open()
        end
    end
end)

-- "—" 收起成悬浮球，"×" 确认后关闭
Window.Close = function(self, ...)
    local result = rawClose(self, ...)
    task.delay(0.05, function()
        if not self.Destroyed then
            setBallVisible(true)
        end
    end)
    return result
end

Window.Open = function(self, ...)
    setBallVisible(false)
    return rawOpen(self, ...)
end

Window:OnDestroy(function()
    if gui and gui.Parent then
        gui:Destroy()
    end
end)

-- 弹窗文案汉化（WindUI 内置英文）
local DialogText = {
    ["Close Window"] = "关闭窗口",
    ["Do you want to close this window? You will not be able to open it again."] =
        "确定要关闭这个窗口吗？关闭后将无法再次打开。",
    ["Cancel"] = "取消",
    ["Confirm"] = "确定",
    ["Apply"] = "应用",
    ["Error"] = "错误",
}

Window.Dialog = function(self, cfg, ...)
    if type(cfg) == "table" then
        if DialogText[cfg.Title] then cfg.Title = DialogText[cfg.Title] end
        if DialogText[cfg.Content] then cfg.Content = DialogText[cfg.Content] end
        if type(cfg.Buttons) == "table" then
            for _, btn in ipairs(cfg.Buttons) do
                if type(btn) == "table" and DialogText[btn.Title] then
                    btn.Title = DialogText[btn.Title]
                end
            end
        end
    end
    return rawDialog(self, cfg, ...)
end

-- 界面
-- 约定：所有 Section 默认收起（Opened = false），由用户点击标题展开；以后新增的区块也照这个规则
local Tab = Window:Tab({ Title = "设置", Icon = "settings" })
local BasicsTab = Window:Tab({ Title = "基础", Icon = "layout-dashboard" })

local dshStopAll
local dshClaimMissions
local halloweenMissionPara
local dshStopCandy
local dshStopChests
local dshStopEgg
local dshStopMood
local dshStopGhost
local dshStopSoul
local dshStopPlant
local dshMobStop

local hotkeySection = Tab:Section({ Title = "快捷按键", Opened = false })

hotkeySection:Paragraph({
    Title = "按 G 打开/关闭面板",
    Desc = "",
})

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then
        return
    end
    if input.KeyCode == Enum.KeyCode.G then
        pcall(function()
            if type(Window.Toggle) == "function" then
                Window:Toggle()
            elseif Window.Opened then
                Window:Close()
            else
                Window:Open()
            end
        end)
    end
end)

local section = BasicsTab:Section({ Title = "基础", Opened = false })

section:Button({
    Title = "一键停止所有活动",
    Desc = "停止传送刷、敲门、开宝箱、蛋兑换、抓幽灵、龙心情、灵魂灯笼、自动打植物、自动攻击周围怪物等所有正在运行的功能，并把龙送回开始位置",
    Callback = function()
        if dshStopAll then
            dshStopAll()
        else
            pcall(function()
                WindUI:Notify({
                    Title = "没有可停止的活动",
                    Content = "当前没有正在运行的功能",
                    Duration = 3,
                })
            end)
        end
    end,
})

if isMobile then
    section:Paragraph({
        Title = "手机提示",
        Desc = "面板支持触屏。开宝箱/打灯笼等需要模拟鼠标的功能依赖执行器的 VirtualInputManager；灵魂灯笼收集需要执行器支持 getgc。如果某项没反应，换支持这些函数的执行器。",
    })
end

local taskSection = BasicsTab:Section({ Title = "任务", Opened = false })

taskSection:Button({
    Title = "一键领取所有任务奖励",
    Desc = "领取所有已完成但未领取的任务奖励（每日/周常/活动）",
    Callback = function()
        if dshClaimMissions then
            task.spawn(function()
                dshClaimMissions()
            end)
        else
            pcall(function()
                WindUI:Notify({
                    Title = "功能未加载",
                    Content = "任务模块还没准备好",
                    Duration = 3,
                })
            end)
        end
    end,
})

halloweenMissionPara = taskSection:Paragraph({
    Title = "任务奖励",
    Desc = "正在读取…",
})

local function dshSetupDragonInfo()
    local dragonSection = BasicsTab:Section({ Title = "龙", Opened = false })
    local reviveState = { running = false, generation = 0 }

    local function dragonModel()
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local dragon = hum and hum.SeatPart and hum.SeatPart.Parent
        if dragon and dragon:IsA("Model") then
            return dragon
        end
        local chars = workspace:FindFirstChild("Characters")
        local me = chars and chars:FindFirstChild(player.Name)
        local dragons = me and me:FindFirstChild("Dragons")
        local first = dragons and dragons:GetChildren()[1]
        if first and first:IsA("Model") then
            return first
        end
        return nil
    end

    local cachedWrapper

    local function mountDragon(dragon)
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not (char and hum) then
            return false
        end
        if hum.SeatPart then
            return true
        end
        local wrapper = cachedWrapper
        if not wrapper or (rawget(wrapper, "DragonModel") or rawget(wrapper, "Model")) ~= dragon then
            wrapper = nil
            for _, obj in ipairs(getgc(true)) do
                if type(obj) == "table" then
                    local mc = rawget(obj, "MoverClass")
                    local dm = rawget(obj, "DragonModel") or rawget(obj, "Model")
                    if mc and dm == dragon then
                        wrapper = obj
                        break
                    end
                end
            end
            cachedWrapper = wrapper
        end
        if wrapper then
            local meta = getmetatable(wrapper)
            local sit = type(meta) == "table" and rawget(meta, "_sit") or nil
            if type(sit) == "function" then
                pcall(sit, wrapper)
                task.wait(0.6)
                if hum.SeatPart then
                    return true
                end
            end
        end
        local root = dragon:FindFirstChild("HumanoidRootPart") or dragon:FindFirstChild("RootPart") or dragon.PrimaryPart
        if not root then
            return false
        end
        pcall(function()
            char:MoveTo(root.Position + Vector3.new(0, 3, 0))
        end)
        local vimOk, vim = pcall(function()
            return game:GetService("VirtualInputManager")
        end)
        for i = 1, 6 do
            if hum.SeatPart then
                return true
            end
            if vimOk and vim then
                pcall(function()
                    vim:SendKeyEvent(Enum.KeyCode.E, true)
                end)
                task.wait(0.1)
                pcall(function()
                    vim:SendKeyEvent(Enum.KeyCode.E, false)
                end)
            end
            task.wait(0.4)
        end
        return hum.SeatPart ~= nil
    end

    local function ensureDragon()
        local dragon = dragonModel()
        if not dragon then
            return false
        end
        local hp = dragon:FindFirstChild("Health", true)
        local hpNum = hp and tonumber(hp.Value)
        if hpNum ~= nil and hpNum <= 0 then
            tryRevive()
            task.wait(0.6)
        end
        local char = player.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and not hum.SeatPart then
            mountDragon(dragon)
        end
        return true
    end

    local function tryRevive()
        local dragon = dragonModel()
        if not dragon then
            return false
        end
        local health = dragon:FindFirstChild("Health", true)
        local dead = dragon:FindFirstChild("Dead", true)
        local hp = health and tonumber(health.Value)
        local isDead = (hp ~= nil and hp <= 0) or (hp == nil and dead ~= nil and dead.Value == true)
        if not isDead then
            return false
        end
        local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        local remote = remotes and remotes:FindFirstChild("ReviveDragonRemote")
        if not remote then
            return false
        end
        for _, itemName in ipairs({ "DragonRevivalHeart", "GoldenRevivalHeart", "RevivalHeart" }) do
            local ok, res = pcall(function()
                return remote:InvokeServer(dragon.Name, itemName)
            end)
            if ok and res then
                return true
            end
        end
        return false
    end

    local function reviveStart()
        reviveState.running = true
        reviveState.generation = reviveState.generation + 1
        local gen = reviveState.generation
        task.spawn(function()
            while reviveState.running and gen == reviveState.generation do
                tryRevive()
                local dragon = dragonModel()
                if dragon then
                    local hp = dragon:FindFirstChild("Health", true)
                    local deadValue = dragon:FindFirstChild("Dead", true)
                    local hpNum = hp and tonumber(hp.Value)
                    local isDead = (hpNum ~= nil and hpNum <= 0) or (hpNum == nil and deadValue ~= nil and deadValue.Value == true)
                    if not isDead then
                        mountDragon(dragon)
                    end
                end
                task.wait(2)
            end
        end)
    end

    local function reviveStop()
        reviveState.running = false
        reviveState.generation = reviveState.generation + 1
    end

    dragonSection:Toggle({
        Title = "自动复活",
        Desc = "龙死亡后自动使用复活之心复活",
        Value = false,
        Callback = function(state)
            if state then
                reviveStart()
            else
                reviveStop()
            end
        end,
    })

    pcall(function()
        getgenv().DSH_Revive = { start = reviveStart, stop = reviveStop, mount = mountDragon, dragon = dragonModel, once = tryRevive, ensure = ensureDragon }
    end)
end

dshSetupDragonInfo()

-- 左侧边栏新增标签页
local DragonTab = Window:Tab({ Title = "龙养成", Icon = "sparkles" })
local HalloweenTab = Window:Tab({ Title = "万圣节活动", Icon = "ghost" })

-- 骑行点传送刷（实测：传送到圆圈再发远程，每个 +3 经验）
local dragonSection = DragonTab:Section({ Title = "骑行点", Opened = false })
local moodSection = DragonTab:Section({ Title = "龙心情", Opened = false })
local plantSection

------------------------------------------------------------------
-- 圆圈扫描（只保留功能：控制台 / getgenv().DSH_Scan，不占面板 UI）
------------------------------------------------------------------

local function dshScanRings()
    local interactions = workspace:FindFirstChild("Interactions")
    local rr = interactions and interactions:FindFirstChild("RidingRings")
    if not rr then
        print("[圆圈扫描] 未找到 workspace.Interactions.RidingRings")
        return nil
    end
    local groups = {}
    local total = 0
    local numbers = {}
    for _, g in ipairs(rr:GetChildren()) do
        local count = 0
        for _, c in ipairs(g:GetChildren()) do
            if c:IsA("BasePart") then
                count = count + 1
                local n = tonumber(c.Name)
                if n then
                    numbers[n] = true
                end
            end
        end
        groups[g.Name] = count
        total = total + count
    end
    local groupTexts = {}
    for name, count in pairs(groups) do
        groupTexts[#groupTexts + 1] = name .. "×" .. count
    end
    table.sort(groupTexts)
    local unique = 0
    for _ in pairs(numbers) do
        unique = unique + 1
    end
    local text = string.format(
        "[圆圈扫描] 共 %d 个圆圈（唯一编号 %d 个）· %s",
        total,
        unique,
        table.concat(groupTexts, "，")
    )
    print(text)
    return text, groups
end

pcall(function()
    getgenv().DSH_Scan = {
        run = dshScanRings,
    }
end)

task.defer(function()
    dshScanRings()
end)

------------------------------------------------------------------
-- 骑行点（实测有效）
-- 游戏穿圈时会向 RidingRingTouchedRemote 发送
-- RidingRings/<Ground|Flying>/<编号>；服务器会校验角色与圆圈的距离。
-- 这里把龙传送到圆圈位置再发送，实测每圈 +3 骑行经验。
------------------------------------------------------------------

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RIDE_REMOTE_NAME = "RidingRingTouchedRemote"
local FARM_GROUPS = { "Ground", "Flying" }

local farm = {
    running = false,
    roundOnly = false,
    interval = 0.55,
    cooldown = 30,
    restore = true,
    generation = 0,
    success = 0,
    gained = 0,
    levelUps = 0,
    startCFrame = nil,
    lastAttempt = {},
    markers = {},
    current = "无",
    statusClock = 0,
}

local farmToggle
local farmStatusPara

local function farmNotify(title, content)
    pcall(function()
        WindUI:Notify({
            Title = title,
            Content = content,
            Duration = 4,
        })
    end)
end

local function farmSyncToggle(state)
    if farmToggle then
        pcall(function()
            farmToggle:Set(state, false)
        end)
    end
end

local function farmGetDragon()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local dragon = seat and seat.Parent
    if dragon and dragon:IsA("Model") then
        return dragon, char, hum
    end
    return nil, char, hum
end

local function farmGetRiding(dragon)
    if not dragon then
        return nil
    end
    local dataValue = dragon:FindFirstChild("DataValue")
    local data = dataValue and dataValue.Value
    if not data then
        local pg = player:FindFirstChild("PlayerGui")
        local pdg = pg and pg:FindFirstChild("PlayerDataGui")
        local dragons = pdg and pdg.Data and pdg.Data:FindFirstChild("Dragons")
        data = dragons and dragons:FindFirstChild(dragon.Name)
    end
    local skills = data and data:FindFirstChild("Skills")
    return skills and skills:FindFirstChild("Riding")
end

local function farmReadRiding(dragon)
    local riding = farmGetRiding(dragon)
    if not riding then
        return nil, nil
    end
    local exp = riding:FindFirstChild("Experience")
    return riding.Value, exp and exp.Value
end

local function farmCollectMarkers()
    local list = {}
    local interactions = workspace:FindFirstChild("Interactions")
    local rr = interactions and interactions:FindFirstChild("RidingRings")
    if not rr then
        return list
    end
    for _, gname in ipairs(FARM_GROUPS) do
        local group = rr:FindFirstChild(gname)
        if group then
            for _, c in ipairs(group:GetChildren()) do
                if c:IsA("BasePart") then
                    list[#list + 1] = {
                        part = c,
                        group = gname,
                        name = c.Name,
                        key = gname .. "|" .. string.format("%06d", tonumber(c.Name) or 999999),
                    }
                end
            end
        end
    end
    table.sort(list, function(a, b)
        return a.key < b.key
    end)
    return list
end

local function farmStatusText()
    local dragon = farmGetDragon()
    local level, exp = farmReadRiding(dragon)
    local state = "已停止"
    if farm.running then
        state = "运行中"
    elseif farm.roundOnly then
        state = "刷一轮中"
    end
    local lines = {
        string.format("%s · 骑行等级 %s · 经验 %s", state, tostring(level or "?"), tostring(exp or "?")),
        string.format("成功 %d 个圆圈 · 本次 +%d 经验 · 升级 %d 次", farm.success, farm.gained, farm.levelUps),
        string.format("当前：%s · 已加载圆圈 %d 个", farm.current, #farm.markers),
    }
    return table.concat(lines, "\n")
end

local function farmUpdateStatus(force)
    if not farmStatusPara then
        return
    end
    local now = os.clock()
    if not force and now - farm.statusClock < 0.5 then
        return
    end
    farm.statusClock = now
    local text = farmStatusText()
    pcall(function()
        farmStatusPara:SetDesc(text)
    end)
end

local function farmRefresh()
    farm.markers = farmCollectMarkers()
    farmUpdateStatus(true)
    return #farm.markers
end

local function farmTeleport(dragon, part)
    local ok = pcall(function()
        dragon:PivotTo(CFrame.new(part.Position + Vector3.new(0, 22, 0)))
    end)
    if ok then
        local hrp = dragon:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
    return ok
end

local function farmFire(part)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild(RIDE_REMOTE_NAME)
    if not remote then
        return false
    end
    local ok = pcall(function()
        remote:FireServer(part)
    end)
    return ok
end

local function farmProcess(entry, dragon)
    local part = entry.part
    if not part or not part.Parent then
        return false
    end
    local levelBefore, expBefore = farmReadRiding(dragon)
    if levelBefore == nil then
        return false
    end
    if not farmTeleport(dragon, part) then
        return false
    end
    task.wait(0.35)
    farmFire(part)
    task.wait(math.max(farm.interval - 0.35, 0.05))
    local levelAfter, expAfter = farmReadRiding(dragon)
    if levelAfter and levelBefore and levelAfter > levelBefore then
        farm.levelUps = farm.levelUps + 1
        farm.success = farm.success + 1
        return true
    end
    if expAfter and expBefore and expAfter > expBefore then
        farm.gained = farm.gained + (expAfter - expBefore)
        farm.success = farm.success + 1
        return true
    end
    return false
end

local function farmRestore()
    if not farm.restore or not farm.startCFrame then
        return
    end
    local dragon = farmGetDragon()
    if dragon then
        pcall(function()
            dragon:PivotTo(farm.startCFrame)
        end)
    end
end

local function farmOneRound()
    local dragon = farmGetDragon()
    if not dragon then
        farmNotify("没有骑龙", "先骑上一条龙再开始")
        return 0
    end
    if not farmGetRiding(dragon) then
        farmNotify("不是龙坐骑", "当前坐的不是龙，先骑上龙再开始")
        return 0
    end
    farm.markers = farmCollectMarkers()
    if #farm.markers == 0 then
        farmNotify("没有圆圈", "当前没有加载到 Ground/Flying 圆圈")
        return 0
    end
    local count = 0
    for _, entry in ipairs(farm.markers) do
        if not farm.running and not farm.roundOnly then
            break
        end
        local part = entry.part
        if part and part.Parent then
            local last = farm.lastAttempt[part]
            if not last or os.clock() - last >= farm.cooldown then
                farm.lastAttempt[part] = os.clock()
                farm.current = entry.group .. "." .. entry.name
                farmUpdateStatus(false)
                if farmProcess(entry, dragon) then
                    count = count + 1
                end
                local nowDragon = farmGetDragon()
                if nowDragon ~= dragon then
                    farm.running = false
                    farm.roundOnly = false
                    break
                end
            end
        end
    end
    farmUpdateStatus(true)
    return count
end

local function farmStart()
    if farm.running then
        return
    end
    local dragon = farmGetDragon()
    if not dragon then
        farmNotify("没有骑龙", "先骑上一条龙再开始")
        farmSyncToggle(false)
        return
    end
    if not farmGetRiding(dragon) then
        farmNotify("不是龙坐骑", "当前坐的不是龙，先骑上龙再开始")
        farmSyncToggle(false)
        return
    end
    farm.running = true
    farm.roundOnly = false
    farm.startCFrame = dragon:GetPivot()
    farm.generation = farm.generation + 1
    local gen = farm.generation
    task.spawn(function()
        while farm.running and gen == farm.generation do
            farmOneRound()
            if farm.running and gen == farm.generation then
                task.wait(0.5)
            end
        end
        farm.running = false
        farmRestore()
        farmSyncToggle(false)
        farmUpdateStatus(true)
    end)
end

local function farmStop()
    farm.running = false
    farm.roundOnly = false
    farm.generation = farm.generation + 1
    farmRestore()
    farmUpdateStatus(true)
end

-- 设置页「一键停止所有活动」的入口
dshStopAll = function()
    local hadRunning = farm.running or farm.roundOnly
    farm.running = false
    farm.roundOnly = false
    farm.generation = farm.generation + 1
    farmRestore()
    farmSyncToggle(false)
    farm.current = "无"
    farmUpdateStatus(true)
    if dshStopCandy then
        dshStopCandy()
    end
    if dshStopChests then
        dshStopChests()
    end
    if dshStopEgg then
        dshStopEgg()
    end
    if dshStopMood then
        dshStopMood()
    end
    if dshStopGhost then
        dshStopGhost()
    end
    if dshStopSoul then
        dshStopSoul()
    end
    if dshStopPlant then
        dshStopPlant()
    end
    if dshMobStop then
        dshMobStop()
    end
    farmNotify("已停止", "所有活动已停止，龙已回到原位")
end

local function farmRunOnce()
    if farm.running or farm.roundOnly then
        farmNotify("正在运行", "等当前这一轮结束")
        return
    end
    local dragon = farmGetDragon()
    if not dragon then
        farmNotify("没有骑龙", "先骑上一条龙再开始")
        return
    end
    if not farmGetRiding(dragon) then
        farmNotify("不是龙坐骑", "当前坐的不是龙，先骑上龙再开始")
        return
    end
    farm.roundOnly = true
    farm.startCFrame = dragon:GetPivot()
    task.spawn(function()
        local count = farmOneRound()
        farm.roundOnly = false
        farmRestore()
        farmUpdateStatus(true)
        farmNotify("这一轮完成", string.format("成功 %d 个圆圈，本次 +%d 经验", count, farm.gained))
    end)
end

local function farmCreateSlider(parent, primaryConfig, fallbackConfig)
    local ok, slider = pcall(function()
        return parent:Slider(primaryConfig)
    end)
    if ok and slider then
        return slider
    end
    local ok2, slider2 = pcall(function()
        return parent:Slider(fallbackConfig)
    end)
    if ok2 then
        return slider2
    end
    return nil
end

dragonSection:Paragraph({
    Title = "骑行点",
    Desc = "实测有效：把龙传送到圆圈位置，再发送穿圈事件，每个圆圈 +3 骑行经验，可升级骑行等级。需要先骑龙。传送可能被服务器检测，建议先用较大的间隔测试，被踢或回弹就调大间隔。",
})

farmStatusPara = dragonSection:Paragraph({
    Title = "状态",
    Desc = "已停止 · 点击“刷新圆圈列表”",
})

farmToggle = dragonSection:Toggle({
    Title = "开始传送刷",
    Desc = "循环传送并发送 Ground/Flying 圆圈",
    Value = false,
    Callback = function(state)
        if state then
            farmStart()
        else
            farmStop()
        end
    end,
})

farmCreateSlider(dragonSection, {
    Title = "每圈间隔（秒）",
    Desc = "传送+发送的总耗时，太短可能被检测",
    Value = { Min = 0.3, Max = 2, Default = 0.55 },
    Step = 0.05,
    Callback = function(value)
        farm.interval = tonumber(value) or 0.55
    end,
}, {
    Title = "每圈间隔（秒）",
    Desc = "传送+发送的总耗时，太短可能被检测",
    Value = 0.55,
    Min = 0.3,
    Max = 2,
    Step = 0.05,
    Callback = function(value)
        farm.interval = tonumber(value) or 0.55
    end,
})

farmCreateSlider(dragonSection, {
    Title = "同一圆圈冷却（秒）",
    Desc = "同一个圆圈两次尝试之间至少隔多久",
    Value = { Min = 5, Max = 120, Default = 30 },
    Step = 1,
    Callback = function(value)
        farm.cooldown = tonumber(value) or 30
    end,
}, {
    Title = "同一圆圈冷却（秒）",
    Desc = "同一个圆圈两次尝试之间至少隔多久",
    Value = 30,
    Min = 5,
    Max = 120,
    Step = 1,
    Callback = function(value)
        farm.cooldown = tonumber(value) or 30
    end,
})

dragonSection:Toggle({
    Title = "结束后回到原位",
    Desc = "停止时把龙传送回开始的位置",
    Value = true,
    Callback = function(state)
        farm.restore = state
    end,
})

dragonSection:Button({
    Title = "刷一轮",
    Desc = "把所有已加载的 Ground/Flying 圆圈刷一遍",
    Callback = function()
        farmRunOnce()
    end,
})

dragonSection:Button({
    Title = "刷新圆圈列表",
    Desc = "重新扫描当前加载的 Ground/Flying 圆圈",
    Callback = function()
        local count = farmRefresh()
        farmNotify("圆圈已刷新", string.format("当前加载 %d 个圆圈", count))
    end,
})

dragonSection:Button({
    Title = "统计归零",
    Desc = "清零成功/经验/升级统计",
    Callback = function()
        farm.success = 0
        farm.gained = 0
        farm.levelUps = 0
        farmUpdateStatus(true)
        farmNotify("已归零", "统计已清零")
    end,
})

------------------------------------------------------------------
-- 万圣节活动
------------------------------------------------------------------

local halloweenSection = HalloweenTab:Section({ Title = "万圣节活动", Opened = false })

local halloweenStatusPara

local HALLOWEEN_EVENT_NAME = "EventHalloween"
local HALLOWEEN_MISSION_TYPES = {
    { folder = "Daily", index = 1, label = "每日" },
    { folder = "Weekly", index = 2, label = "周常" },
}
local HALLOWEEN_MISSION_LABELS = {
    CollectCandy = "收集糖果",
    GhostlyDoorReward = "幽灵门奖励",
    HatchEgg = "孵化龙蛋",
    LevelUpDragonSkill = "升级龙技能",
    CollectLanterns = "收集南瓜灯",
    BondDragon = "与龙互动",
    MergeLab = "融合实验室",
    SpinEventWheel = "转活动转盘",
    SpendEventCurrency = "花费活动货币",
    EggTomb = "蛋墓",
    PumpkinSmashEvent = "砸南瓜",
    GhostCatcherEvent = "抓幽灵",
    KillMobs = "击杀怪物",
    OpenLanternDoor = "打开南瓜灯门",
}

local function halloweenEventData()
    local pg = player:FindFirstChild("PlayerGui")
    local pdg = pg and pg:FindFirstChild("PlayerDataGui")
    local data = pdg and pdg.Data
    return data and data:FindFirstChild("HalloweenEvent2026")
end

local function halloweenPassData()
    local event = halloweenEventData()
    return event and event:FindFirstChild("EventSeasonPass")
end

local function halloweenMissionsData()
    local pass = halloweenPassData()
    return pass and pass:FindFirstChild("Missions")
end

local function halloweenValue(event, name)
    local v = event and (event:FindFirstChild(name) or event:FindFirstChild(name, true))
    if v and v:IsA("ValueBase") then
        return tostring(v.Value)
    end
    return "?"
end

local function halloweenMissionName(raw)
    local name = tostring(raw or "")
    return HALLOWEEN_MISSION_LABELS[name] or name
end

local function halloweenStatusText()
    local event = halloweenEventData()
    if not event then
        return "未找到 HalloweenEvent2026 活动数据\n（可能活动已结束，或数据还没加载）"
    end
    local completed, total = 0, 0
    for _, c in ipairs(event:GetChildren()) do
        if c:IsA("BoolValue") then
            total = total + 1
            if c.Value then
                completed = completed + 1
            end
        end
    end
    local pass = halloweenPassData()
    local points = pass and pass:FindFirstChild("Points")
    return string.format(
        "糖果：%s · 转盘券：%s\n捣蛋：%s · 南瓜灯：%s\n种子：%s · BOSS：%s\n赛季积分：%s\n任务标记：%d/%d",
        halloweenValue(event, "HalloweenCandy"),
        halloweenValue(event, "HalloweenSpinToken"),
        halloweenValue(event, "Tricks"),
        halloweenValue(event, "HalloweenLanterns"),
        halloweenValue(event, "Seed"),
        halloweenValue(event, "BossPaid"),
        points and tostring(points.Value) or "?",
        completed,
        total
    )
end

local function halloweenMissionText()
    local missions = halloweenMissionsData()
    if not missions then
        return "未找到任务数据"
    end
    local parts = {}
    for _, mt in ipairs(HALLOWEEN_MISSION_TYPES) do
        local folder = missions:FindFirstChild(mt.folder)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                local completed = m:FindFirstChild("Completed")
                local claimed = m:FindFirstChild("Claimed")
                if completed and claimed and completed.Value and not claimed.Value then
                    local raw = m:IsA("StringValue") and m.Value or m.Name
                    parts[#parts + 1] = string.format("%s #%s · %s", mt.label, m.Name, halloweenMissionName(raw))
                end
            end
        end
    end
    if #parts == 0 then
        return "当前没有已完成、未领取的任务奖励"
    end
    return string.format("可领取 %d 个：\n%s", #parts, table.concat(parts, "\n"))
end

local function halloweenRefresh()
    if halloweenStatusPara then
        pcall(function()
            halloweenStatusPara:SetDesc(halloweenStatusText())
        end)
    end
    if halloweenMissionPara then
        pcall(function()
            halloweenMissionPara:SetDesc(halloweenMissionText())
        end)
    end
end

local function halloweenClaimMissions()
    local missions = halloweenMissionsData()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local remote = remotes and remotes:FindFirstChild("ClaimEventSeasonMissionRemote")
    if not (missions and remote) then
        return 0
    end
    local claimed = 0
    for _, mt in ipairs(HALLOWEEN_MISSION_TYPES) do
        local folder = missions:FindFirstChild(mt.folder)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                local completed = m:FindFirstChild("Completed")
                local claimedValue = m:FindFirstChild("Claimed")
                if completed and claimedValue and completed.Value and not claimedValue.Value then
                    local missionIndex = tonumber(m.Name) or m.Name
                    local ok, result = pcall(function()
                        return remote:InvokeServer(HALLOWEEN_EVENT_NAME, mt.index, missionIndex)
                    end)
                    if ok and result then
                        claimed = claimed + 1
                    end
                    task.wait(0.25)
                end
            end
        end
    end
    return claimed
end

-- 设置页「一键领取任务奖励」入口（与万圣节页共用）
dshClaimMissions = function()
    local claimed = halloweenClaimMissions()
    halloweenRefresh()
    pcall(function()
        WindUI:Notify({
            Title = claimed > 0 and "领取完成" or "没有可领取",
            Content = claimed > 0 and string.format("成功领取 %d 个任务奖励", claimed)
                or "当前没有已完成、未领取的任务奖励",
            Duration = 3,
        })
    end)
    return claimed
end

halloweenStatusPara = halloweenSection:Paragraph({
    Title = "活动状态",
    Desc = "正在读取…",
})

halloweenSection:Button({
    Title = "刷新活动数据",
    Desc = "重新读取糖果/任务/赛季积分状态",
    Callback = function()
        halloweenRefresh()
        pcall(function()
            WindUI:Notify({
                Title = "已刷新",
                Content = "万圣节活动数据已更新",
                Duration = 3,
            })
        end)
    end,
})

halloweenSection:Button({
    Title = "复制全部活动数据",
    Desc = "把 HalloweenEvent2026 的所有字段复制到剪贴板",
    Callback = function()
        local event = halloweenEventData()
        if not event then
            pcall(function()
                WindUI:Notify({
                    Title = "没有活动数据",
                    Content = "未找到 HalloweenEvent2026",
                    Duration = 3,
                })
            end)
            return
        end
        local dataLines = {}
        for _, d in ipairs(event:GetDescendants()) do
            if d:IsA("ValueBase") then
                dataLines[#dataLines + 1] = d:GetFullName() .. "=" .. tostring(d.Value)
            end
        end
        table.sort(dataLines)
        local text = table.concat(dataLines, "\n")
        local ok = pcall(function()
            if setclipboard then
                setclipboard(text)
            elseif toclipboard then
                toclipboard(text)
            else
                error("no clipboard")
            end
        end)
        if ok then
            pcall(function()
                WindUI:Notify({
                    Title = "已复制",
                    Content = string.format("共 %d 个活动字段已复制", #dataLines),
                    Duration = 3,
                })
            end)
        else
            print(text)
            pcall(function()
                WindUI:Notify({
                    Title = "复制失败",
                    Content = "已打印到控制台",
                    Duration = 3,
                })
            end)
        end
    end,
})

------------------------------------------------------------------
-- 宝箱（SpookyChest）：传送 + 模拟左键咬开
------------------------------------------------------------------

local chestStatusPara

local chestState = {
    running = false,
    generation = 0,
    opened = 0,
    total = 0,
    interval = 3.2,
    current = "无",
    statusClock = 0,
    skipped = {},
}

local function chestTreasureFolder()
    local interactions = workspace:FindFirstChild("Interactions")
    local nodes = interactions and interactions:FindFirstChild("Nodes")
    return nodes and nodes:FindFirstChild("Treasure")
end

local function chestList()
    local list = {}
    local folder = chestTreasureFolder()
    if folder then
        for _, node in ipairs(folder:GetChildren()) do
            local chest = node:FindFirstChild("SpookyChest")
            if chest then
                list[#list + 1] = { node = node, chest = chest }
            end
        end
    end
    table.sort(list, function(a, b)
        return (tonumber(a.node.Name) or 999999) < (tonumber(b.node.Name) or 999999)
    end)
    return list
end

local function chestHealth(chest)
    local hrp = chest and chest:FindFirstChild("HumanoidRootPart")
    return hrp and hrp:FindFirstChild("Health")
end

local function chestAlive(chest)
    local hrp = chest and chest:FindFirstChild("HumanoidRootPart")
    local health = hrp and hrp:FindFirstChild("Health")
    local dead = hrp and hrp:FindFirstChild("Dead")
    if not health then
        return false
    end
    if dead and dead.Value then
        return false
    end
    return health.Value > 0
end

local function chestStatusText()
    local list = chestList()
    local alive, cooling, ignored = 0, 0, 0
    for _, item in ipairs(list) do
        if chestState.skipped[item.node.Name] then
            ignored = ignored + 1
        elseif chestAlive(item.chest) then
            alive = alive + 1
        else
            cooling = cooling + 1
        end
    end
    local state = chestState.running and "开宝箱中" or "已停止"
    return string.format(
        "%s · 可开 %d/%d（冷却 %d · 忽略 %d）\n本次已开 %d 个 · 当前：%s",
        state,
        alive,
        #list,
        cooling,
        ignored,
        chestState.opened,
        chestState.current
    )
end

local function chestUpdateStatus(force)
    if not chestStatusPara then
        return
    end
    local now = os.clock()
    if not force and now - chestState.statusClock < 0.5 then
        return
    end
    chestState.statusClock = now
    local text = chestStatusText()
    pcall(function()
        chestStatusPara:SetDesc(text)
    end)
end

local function chestRefresh()
    local list = chestList()
    chestState.total = #list
    chestUpdateStatus(true)
    return #list
end

local function chestClickAt(x, y)
    local ok, vim = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if not (ok and vim) then
        return
    end
    pcall(function()
        vim:SendMouseButtonEvent(math.floor(x), math.floor(y), 0, true, game, 0)
    end)
    task.wait(0.05)
    pcall(function()
        vim:SendMouseButtonEvent(math.floor(x), math.floor(y), 0, false, game, 0)
    end)
end

local function chestOpenAll()
    if chestState.running then
        return
    end
    local revEnsure = getgenv().DSH_Revive
    if revEnsure and revEnsure.ensure then
        pcall(revEnsure.ensure)
        task.wait(0.5)
    end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local dragon = hum and hum.SeatPart and hum.SeatPart.Parent
    local mover = (dragon and dragon:IsA("Model")) and dragon or char
    if not mover then
        pcall(function()
            WindUI:Notify({ Title = "没有角色", Content = "角色还没加载", Duration = 3 })
        end)
        return
    end
    local list = chestList()
    if #list == 0 then
        pcall(function()
            WindUI:Notify({ Title = "没有宝箱", Content = "当前没有加载到宝箱", Duration = 3 })
        end)
        return
    end
    local aliveCount = 0
    for _, item in ipairs(list) do
        if chestAlive(item.chest) then
            aliveCount = aliveCount + 1
        end
    end
    if aliveCount == 0 then
        pcall(function()
            WindUI:Notify({ Title = "没有可开的宝箱", Content = "宝箱都在冷却/已开，等刷新后再点", Duration = 3 })
        end)
        return
    end
    chestState.running = true
    chestState.opened = 0
    chestState.total = #list
    chestState.generation = chestState.generation + 1
    local gen = chestState.generation
    local cam = workspace.CurrentCamera
    local oldType = cam.CameraType
    local oldCFrame = cam.CFrame
    local orig = mover:GetPivot()
    chestUpdateStatus(true)
    task.spawn(function()
        pcall(function()
            cam.CameraType = Enum.CameraType.Scriptable
        end)
        for pass = 1, 3 do
            if not chestState.running or gen ~= chestState.generation then
                break
            end
            local processed = false
            for _, item in ipairs(chestList()) do
                if not chestState.running or gen ~= chestState.generation then
                    break
                end
                local chest = item.chest
                local health = chestHealth(chest)
                local hrp = chest:FindFirstChild("HumanoidRootPart")
                if chestAlive(chest) and not chestState.skipped[item.node.Name] and health and hrp then
                    processed = true
                    chestState.current = "节点 " .. item.node.Name
                    chestUpdateStatus(false)
                    local pos = hrp.Position
                    local dragonPos = pos + Vector3.new(0, 6, 14)
                    pcall(function()
                        mover:PivotTo(CFrame.lookAt(dragonPos, pos))
                    end)
                    local camPos = dragonPos + Vector3.new(0, 6, 10)
                    local conn = game:GetService("RunService").RenderStepped:Connect(function()
                        cam.CFrame = CFrame.lookAt(camPos, pos)
                    end)
                    task.wait(0.3)
                    local screen, onScreen = cam:WorldToViewportPoint(pos)
                    if onScreen then
                        for attempt = 1, 2 do
                            chestClickAt(screen.X, screen.Y)
                            task.wait(0.6)
                            if health.Value <= 0 then
                                break
                            end
                        end
                    end
                    if conn then
                        conn:Disconnect()
                    end
                    if health.Value <= 0 then
                        chestState.opened = chestState.opened + 1
                    else
                        chestState.skipped[item.node.Name] = true
                    end
                    chestUpdateStatus(false)
                    task.wait(math.max(chestState.interval - 0.95, 0.2))
                end
            end
            if not chestState.running or gen ~= chestState.generation then
                break
            end
            task.wait(1)
        end
        pcall(function()
            cam.CameraType = oldType
            cam.CFrame = oldCFrame
        end)
        pcall(function()
            mover:PivotTo(orig)
        end)
        chestState.running = false
        chestUpdateStatus(true)
        local remaining = 0
        for _, item in ipairs(chestList()) do
            if chestAlive(item.chest) and not chestState.skipped[item.node.Name] then
                remaining = remaining + 1
            end
        end
        pcall(function()
            WindUI:Notify({
                Title = "宝箱处理完成",
                Content = string.format("打开了 %d 个宝箱，剩余 %d 个冷却中", chestState.opened, remaining),
                Duration = 3,
            })
        end)
    end)
end

dshStopChests = function()
    chestState.running = false
    chestState.generation = chestState.generation + 1
end

local chestSection = HalloweenTab:Section({ Title = "万圣节宝箱", Opened = false })

chestStatusPara = chestSection:Paragraph({
    Title = "宝箱",
    Desc = "正在读取…",
})

chestSection:Button({
    Title = "一键打开全部宝箱",
    Desc = "自动传送到每个宝箱前并模拟点击咬开（需要先骑龙，约 3 秒一个）",
    Callback = function()
        task.spawn(function()
            chestOpenAll()
        end)
    end,
})

chestSection:Button({
    Title = "刷新宝箱列表",
    Desc = "重新扫描 HalloweenEvent 的宝箱（SpookyChest）",
    Callback = function()
        local count = chestRefresh()
        pcall(function()
            WindUI:Notify({ Title = "宝箱已刷新", Content = string.format("当前加载 %d 个宝箱", count), Duration = 3 })
        end)
    end,
})

local function chestCreateSlider(parent, primaryConfig, fallbackConfig)
    local ok, slider = pcall(function()
        return parent:Slider(primaryConfig)
    end)
    if ok and slider then
        return slider
    end
    local ok2, slider2 = pcall(function()
        return parent:Slider(fallbackConfig)
    end)
    if ok2 then
        return slider2
    end
    return nil
end

chestCreateSlider(chestSection, {
    Title = "每个宝箱间隔（秒）",
    Desc = "咬一口后有冷却，默认 3.2 秒",
    Value = { Min = 1, Max = 6, Default = 3.2 },
    Step = 0.1,
    Callback = function(value)
        chestState.interval = tonumber(value) or 3.2
    end,
}, {
    Title = "每个宝箱间隔（秒）",
    Desc = "咬一口后有冷却，默认 3.2 秒",
    Value = 3.2,
    Min = 1,
    Max = 6,
    Step = 0.1,
    Callback = function(value)
        chestState.interval = tonumber(value) or 3.2
    end,
})

pcall(function()
    getgenv().DSH_Chests = {
        open = chestOpenAll,
        stop = dshStopChests,
        refresh = chestRefresh,
        status = chestStatusText,
    }
end)

task.defer(function()
    chestUpdateStatus(true)
end)

------------------------------------------------------------------
-- 万圣节蛋兑换（区块）
------------------------------------------------------------------

local eggSection = HalloweenTab:Section({ Title = "万圣节蛋兑换", Opened = false })

local eggStatusPara
local eggState = {
    lastClick = 0,
    running = false,
    exchanged = 0,
    spent = 0,
    generation = 0,
}

local EGG_KEY = "PossessedEgg"
local EGG_COST = 150

local function eggEventData()
    local pg = player:FindFirstChild("PlayerGui")
    local pdg = pg and pg:FindFirstChild("PlayerDataGui")
    local data = pdg and pdg.Data
    return data and data:FindFirstChild("HalloweenEvent2026")
end

local function eggCountOf(name)
    local pg = player:FindFirstChild("PlayerGui")
    local pdg = pg and pg:FindFirstChild("PlayerDataGui")
    local eggs = pdg and pdg.Data and pdg.Data:FindFirstChild("Eggs")
    local v = eggs and eggs:FindFirstChild(name)
    return v and v.Value or 0
end

local function eggCount()
    return eggCountOf("PossessedEgg2026")
end

local function eggStatusText()
    local ev = eggEventData()
    if not ev then
        return "未找到万圣节活动数据"
    end
    local candy = ev:FindFirstChild("HalloweenCandy")
    return string.format(
        "糖果：%s · Possessed Egg 2026：%d\nPossessed：%d 糖果/个 · 烈焰蛋：450 糖果 + 1 个万圣节蛋\n已兑换：%d 个 · 花费：%d 糖果",
        candy and tostring(candy.Value) or "?",
        eggCount(),
        EGG_COST,
        eggState.exchanged,
        eggState.spent
    )
end

local function eggRefresh()
    if not eggStatusPara then
        return
    end
    local text = eggStatusText()
    pcall(function()
        eggStatusPara:SetDesc(text)
    end)
end

local function eggExchangeOne(key, cost, label, reqEgg)
    key = key or EGG_KEY
    cost = cost or EGG_COST
    label = label or "Possessed Egg"
    local now = os.clock()
    if now - eggState.lastClick < 3 then
        pcall(function()
            WindUI:Notify({ Title = "点太快了", Content = "每 3 秒只能兑换 1 个", Duration = 2 })
        end)
        return
    end
    eggState.lastClick = now
    local ev = eggEventData()
    local candy = ev and ev:FindFirstChild("HalloweenCandy")
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local spawn = remotes and remotes:FindFirstChild("SpawnEggRemote")
    local get = remotes and remotes:FindFirstChild("GetEggRemote")
    if not (candy and spawn and get) then
        pcall(function()
            WindUI:Notify({ Title = "未找到蛋兑换接口", Content = "活动的 SpawnEggRemote / GetEggRemote 不存在", Duration = 3 })
        end)
        return
    end
    if candy.Value < cost then
        pcall(function()
            WindUI:Notify({ Title = "糖果不够", Content = string.format("兑换 1 个 %s 需要 %d 糖果", label, cost), Duration = 3 })
        end)
        return
    end
    if reqEgg and eggCountOf(reqEgg) < 1 then
        pcall(function()
            WindUI:Notify({ Title = "缺少材料", Content = "烈焰蛋需要 1 个万圣节蛋（Possessed Egg 2026）", Duration = 3 })
        end)
        return
    end
    local before = candy.Value
    local ok, id = pcall(function()
        return spawn:InvokeServer(key)
    end)
    if not (ok and id ~= nil) then
        pcall(function()
            WindUI:Notify({ Title = "兑换失败", Content = "服务器没有返回蛋数据", Duration = 3 })
        end)
        return
    end
    task.wait(0.2)
    local gok, got = pcall(function()
        return get:InvokeServer(id)
    end)
    if not (gok and got) then
        pcall(function()
            WindUI:Notify({ Title = "领取失败", Content = "GetEggRemote 返回失败", Duration = 3 })
        end)
        return
    end
    eggState.exchanged = eggState.exchanged + 1
    eggState.spent = eggState.spent + (before - candy.Value)
    eggRefresh()
    pcall(function()
        WindUI:Notify({ Title = "兑换成功", Content = string.format("获得 1 个 %s（花费 %d 糖果）", label, before - candy.Value), Duration = 2 })
    end)
end

dshStopEgg = function()
    eggState.lastClick = 0
end

eggStatusPara = eggSection:Paragraph({
    Title = "蛋兑换",
    Desc = "正在读取…",
})

eggSection:Button({
    Title = "兑换 1 个万圣节蛋",
    Desc = string.format("点一次兑换 1 个 Possessed Egg 2026（%d 糖果），3 秒内只能点一次", EGG_COST),
    Callback = function()
        task.spawn(function()
            eggExchangeOne()
        end)
    end,
})

eggSection:Button({
    Title = "兑换 1 个烈焰蛋",
    Desc = "点一次兑换 1 个 Balefire Egg 2026（450 糖果 + 1 个万圣节蛋），3 秒内只能点一次",
    Callback = function()
        task.spawn(function()
            eggExchangeOne("BalefireEgg", 450, "烈焰蛋", "PossessedEgg2026")
        end)
    end,
})

pcall(function()
    getgenv().DSH_Egg = {
        refresh = eggRefresh,
        status = eggStatusText,
        exchange = eggExchangeOne,
        exchangeBalefire = function()
            return eggExchangeOne("BalefireEgg", 450, "烈焰蛋", "PossessedEgg2026")
        end,
        stop = dshStopEgg,
    }
end)

task.defer(function()
    eggRefresh()
end)

------------------------------------------------------------------
-- 抓幽灵（区块）
------------------------------------------------------------------

local ghostSection = HalloweenTab:Section({ Title = "抓幽灵", Opened = false })

local ghostStatusPara
local ghostToggle
local ghostState = {
    running = false,
    generation = 0,
    interval = 0.5,
    count = 0,
    statusClock = 0,
    origin = nil,
}

local function ghostEvent()
    return ReplicatedStorage:FindFirstChild("RandomEvent")
end

local function ghostRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("CatchGhostRemote")
end

local function ghostEventName()
    local ev = ghostEvent()
    local v = ev and ev:FindFirstChild("Event")
    return v and v.Value or ""
end

local function ghostStarted()
    local ev = ghostEvent()
    local v = ev and ev:FindFirstChild("EventStarted")
    return v and v.Value or false
end

local function ghostCooldownLeft()
    local cd = player:GetAttribute("GhostCatchCooldownEnd")
    if type(cd) ~= "number" then
        return 0
    end
    return math.max(cd - os.time(), 0)
end

local function ghostMover()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local dragon = hum and hum.SeatPart and hum.SeatPart.Parent
    return (dragon and dragon:IsA("Model")) and dragon or char
end

local function ghostModels()
    local cam = workspace.CurrentCamera
    local list = {}
    if cam then
        for _, c in ipairs(cam:GetDescendants()) do
            if c:IsA("Model") and c.PrimaryPart then
                list[#list + 1] = c
            end
        end
    end
    return list
end

local function ghostStatusText()
    local name = ghostEventName()
    local started = ghostStarted()
    local state = ghostState.running and "运行中" or "已停止"
    return string.format(
        "%s · 事件：%s%s\n已抓 %d 次 · 冷却 %d 秒",
        state,
        name ~= "" and name or "无",
        started and "（进行中）" or "",
        ghostState.count,
        ghostCooldownLeft()
    )
end

local function ghostUpdateStatus(force)
    if not ghostStatusPara then
        return
    end
    local now = os.clock()
    if not force and now - ghostState.statusClock < 0.5 then
        return
    end
    ghostState.statusClock = now
    local text = ghostStatusText()
    pcall(function()
        ghostStatusPara:SetDesc(text)
    end)
end

local function ghostTouchTarget(ghost)
    local best = ghost.PrimaryPart
    for _, d in ipairs(ghost:GetDescendants()) do
        if d:IsA("BasePart") and d.CanTouch and (not best or d.Size.Magnitude > best.Size.Magnitude) then
            best = d
        end
    end
    return best
end

local function ghostCatchOnce()
    local remote = ghostRemote()
    if not remote then
        return false
    end
    local mover = ghostMover()
    local ghost = ghostModels()[1]
    if not (mover and ghost) then
        return false
    end
    local part = ghostTouchTarget(ghost)
    if not part then
        return false
    end
    local target = part.Position
    pcall(function()
        mover:PivotTo(CFrame.new(target))
    end)
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        pcall(function()
            root.CFrame = CFrame.new(target)
        end)
    end
    task.wait(0.2)
    local ok, res = pcall(function()
        return remote:InvokeServer()
    end)
    if ok and res then
        ghostState.count = ghostState.count + 1
    end
    ghostUpdateStatus(true)
    return ok and res
end

local function ghostStart()
    if ghostState.running then
        return
    end
    if not ghostRemote() then
        pcall(function()
            WindUI:Notify({ Title = "找不到抓幽灵接口", Content = "CatchGhostRemote 不存在", Duration = 3 })
        end)
        return
    end
    ghostState.running = true
    ghostState.generation = ghostState.generation + 1
    local gen = ghostState.generation
    local mover = ghostMover()
    if mover then
        ghostState.origin = mover:GetPivot()
    end
    ghostUpdateStatus(true)
    task.spawn(function()
        while ghostState.running and gen == ghostState.generation do
            ghostCatchOnce()
            task.wait(math.max(ghostState.interval, 0.2))
        end
        ghostState.running = false
        if ghostToggle then
            pcall(function()
                ghostToggle:Set(false, false)
            end)
        end
        ghostUpdateStatus(true)
    end)
end

local function ghostStop()
    ghostState.running = false
    ghostState.generation = ghostState.generation + 1
    if ghostState.origin then
        local mover = ghostMover()
        if mover then
            pcall(function()
                mover:PivotTo(ghostState.origin)
            end)
        end
    end
    if ghostToggle then
        pcall(function()
            ghostToggle:Set(false, false)
        end)
    end
    ghostUpdateStatus(true)
end

dshStopGhost = ghostStop

ghostSection:Paragraph({
    Title = "抓幽灵",
    Desc = "检测到幽灵事件时自动调用 CatchGhostRemote 抓幽灵；事件没开也可以先开着，等事件开始。",
})

ghostStatusPara = ghostSection:Paragraph({
    Title = "幽灵状态",
    Desc = "正在读取…",
})

ghostToggle = ghostSection:Toggle({
    Title = "自动抓幽灵",
    Desc = "按间隔自动调用抓幽灵接口",
    Value = false,
    Callback = function(state)
        if state then
            ghostStart()
        else
            ghostStop()
        end
    end,
})

local function ghostCreateSlider(parent, primaryConfig, fallbackConfig)
    local ok, slider = pcall(function()
        return parent:Slider(primaryConfig)
    end)
    if ok and slider then
        return slider
    end
    local ok2, slider2 = pcall(function()
        return parent:Slider(fallbackConfig)
    end)
    if ok2 then
        return slider2
    end
    return nil
end

pcall(function()
    getgenv().DSH_Ghost = {
        start = ghostStart,
        stop = ghostStop,
        once = ghostCatchOnce,
        status = ghostStatusText,
    }
end)

task.defer(function()
    ghostUpdateStatus(true)
end)

pcall(function()
    getgenv().DSH_Halloween = {
        claim = halloweenClaimMissions,
        claimAll = dshClaimMissions,
        refresh = halloweenRefresh,
    }
    getgenv().DSH_ClaimMissions = dshClaimMissions
end)

task.defer(function()
    halloweenRefresh()
end)

------------------------------------------------------------------
-- 糖果获取（万圣节糖果门）
------------------------------------------------------------------

local candySection = HalloweenTab:Section({ Title = "敲门", Opened = false })

local candy = {
    running = false,
    roundOnly = false,
    generation = 0,
    interval = 5,
    restore = true,
    gained = 0,
    success = 0,
    startCFrame = nil,
    doors = {},
    current = "无",
    statusClock = 0,
}

local candyStatusPara
local candyToggle

local function candyEventData()
    local pg = player:FindFirstChild("PlayerGui")
    local pdg = pg and pg:FindFirstChild("PlayerDataGui")
    local data = pdg and pdg.Data
    return data and data:FindFirstChild("HalloweenEvent2026")
end

local function candyCount()
    local ev = candyEventData()
    local v = ev and ev:FindFirstChild("HalloweenCandy")
    return v and v.Value or nil
end

local function candyDoorsData()
    local ev = candyEventData()
    return ev and ev:FindFirstChild("TrickOrTreatDoors")
end

local function candyFolder()
    local interactions = workspace:FindFirstChild("Interactions")
    local halloween = interactions and interactions:FindFirstChild("HalloweenEvent")
    return halloween and halloween:FindFirstChild("TrickOrTreatDoors")
end

local function candyMover()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local seat = hum and hum.SeatPart
    local dragon = seat and seat.Parent
    if dragon and dragon:IsA("Model") then
        return dragon
    end
    return char
end

local function candyCollectDoors()
    local list = {}
    local folder = candyFolder()
    if folder then
        for _, d in ipairs(folder:GetChildren()) do
            if d:IsA("Model") and d:FindFirstChild("Door") then
                list[#list + 1] = d
            end
        end
    end
    table.sort(list, function(a, b)
        return (tonumber(a.Name) or 999999) < (tonumber(b.Name) or 999999)
    end)
    return list
end

local function candyDoorReady(door)
    local data = candyDoorsData()
    local v = data and data:FindFirstChild(door.Name)
    if not v or not v:IsA("ValueBase") then
        return true
    end
    local nextTime = tonumber(v.Value) or 0
    return os.time() >= nextTime
end

local function candyReadyCount(doors)
    local count = 0
    for _, d in ipairs(doors) do
        if candyDoorReady(d) then
            count = count + 1
        end
    end
    return count
end

local function candyStatusText()
    local candyValue = candyCount()
    local ready = candyReadyCount(candy.doors)
    local state = "已停止"
    if candy.running then
        state = "运行中"
    elseif candy.roundOnly then
        state = "刷一轮中"
    end
    return string.format(
        "%s · 糖果 %s\n本轮 +%d · 可刷门 %d/%d\n当前：%s",
        state,
        tostring(candyValue or "?"),
        candy.gained,
        ready,
        #candy.doors,
        candy.current
    )
end

local function candyUpdateStatus(force)
    if not candyStatusPara then
        return
    end
    local now = os.clock()
    if not force and now - candy.statusClock < 0.5 then
        return
    end
    candy.statusClock = now
    local text = candyStatusText()
    pcall(function()
        candyStatusPara:SetDesc(text)
    end)
end

local function candyRefresh()
    candy.doors = candyCollectDoors()
    candyUpdateStatus(true)
    return #candy.doors
end

local function candyRemote()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("TrickOrTreatDoorRemote")
end

local function candyTeleport(mover, door)
    local part = door:FindFirstChild("Door")
    if not mover or not part then
        return false
    end
    local ok = pcall(function()
        mover:PivotTo(CFrame.new(part.Position + Vector3.new(0, 12, 0)))
    end)
    if ok then
        local hrp = mover:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function()
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end)
        end
    end
    return ok
end

local function candyRestore()
    if not candy.restore or not candy.startCFrame then
        return
    end
    local mover = candyMover()
    if mover then
        pcall(function()
            mover:PivotTo(candy.startCFrame)
        end)
    end
end

local function candyRound()
    local mover = candyMover()
    local remote = candyRemote()
    if not (mover and remote) then
        return 0, 0
    end
    candy.doors = candyCollectDoors()
    if #candy.doors == 0 then
        return 0, 0
    end
    if not candy.startCFrame then
        candy.startCFrame = mover:GetPivot()
    end
    local processed, gained = 0, 0
    for _, door in ipairs(candy.doors) do
        if not (candy.running or candy.roundOnly) then
            break
        end
        if candyDoorReady(door) then
            local before = candyCount()
            candy.current = "门 " .. door.Name
            candyUpdateStatus(false)
            if candyTeleport(mover, door) then
                task.wait(0.35)
                pcall(function()
                    remote:InvokeServer(door.Name)
                end)
                task.wait(0.45)
                local after = candyCount()
                local delta = 0
                if before and after and after > before then
                    delta = after - before
                end
                if delta > 0 then
                    candy.gained = candy.gained + delta
                    candy.success = candy.success + 1
                    gained = gained + delta
                end
                processed = processed + 1
                candyUpdateStatus(false)
                task.wait(math.max(candy.interval - 0.8, 0.05))
            end
        end
    end
    candyUpdateStatus(true)
    return processed, gained
end

local function candyStart()
    if candy.running then
        return
    end
    local mover = candyMover()
    if not mover then
        pcall(function()
            WindUI:Notify({ Title = "没有角色", Content = "角色还没加载", Duration = 3 })
        end)
        return
    end
    candy.running = true
    candy.roundOnly = false
    candy.startCFrame = mover:GetPivot()
    candy.generation = candy.generation + 1
    local gen = candy.generation
    task.spawn(function()
        while candy.running and gen == candy.generation do
            local processed = candyRound()
            if candy.running and gen == candy.generation then
                task.wait(processed > 0 and 2 or 20)
            end
        end
        candy.running = false
        candyRestore()
        if candyToggle then
            pcall(function()
                candyToggle:Set(false, false)
            end)
        end
        candyUpdateStatus(true)
    end)
end

local function candyStop()
    candy.running = false
    candy.roundOnly = false
    candy.generation = candy.generation + 1
    candyRestore()
    if candyToggle then
        pcall(function()
            candyToggle:Set(false, false)
        end)
    end
    candyUpdateStatus(true)
end

dshStopCandy = candyStop

local function candyCreateSlider(parent, primaryConfig, fallbackConfig)
    local ok, slider = pcall(function()
        return parent:Slider(primaryConfig)
    end)
    if ok and slider then
        return slider
    end
    local ok2, slider2 = pcall(function()
        return parent:Slider(fallbackConfig)
    end)
    if ok2 then
        return slider2
    end
    return nil
end

candyToggle = candySection:Toggle({
    Title = "自动刷糖果门",
    Desc = "循环传送并敲门，每扇门间隔 5 秒，没门可刷时每 20 秒检查一次",
    Value = false,
    Callback = function(state)
        if state then
            candyStart()
        else
            candyStop()
        end
    end,
})

candySection:Toggle({
    Title = "结束后回到原位",
    Desc = "停止时把角色/龙传送回开始位置",
    Value = true,
    Callback = function(state)
        candy.restore = state
    end,
})

candySection:Button({
    Title = "统计归零",
    Desc = "清零本轮糖果/成功次数",
    Callback = function()
        candy.gained = 0
        candy.success = 0
        candyUpdateStatus(true)
    end,
})

pcall(function()
    getgenv().DSH_Candy = {
        start = candyStart,
        stop = candyStop,
        refresh = candyRefresh,
        status = candyStatusText,
    }
end)

task.defer(function()
    candyRefresh()
end)

------------------------------------------------------------------
-- 龙心情（自动发送 BondingExpRemote 抚摸动作）
------------------------------------------------------------------

local moodStatusPara
local moodToggle
local moodState = {
    running = false,
    generation = 0,
    interval = 1,
    action = "Bored",
    count = 0,
    statusClock = 0,
}

local function moodDragonsFolder()
    local pg = player:FindFirstChild("PlayerGui")
    local pdg = pg and pg:FindFirstChild("PlayerDataGui")
    local data = pdg and pdg.Data
    return data and data:FindFirstChild("Dragons")
end

local function moodDragonData()
    local dragons = moodDragonsFolder()
    if not dragons then
        return nil
    end
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local dragon = hum and hum.SeatPart and hum.SeatPart.Parent
    local idx = "1"
    if dragon and dragon.Parent and dragon.Parent.Name == "Dragons" then
        idx = dragon.Name
    end
    return dragons:FindFirstChild(idx) or dragons:GetChildren()[1]
end

local function moodValue(name)
    local d = moodDragonData()
    local v = d and d:FindFirstChild(name)
    return v and v.Value or nil
end

local function moodBondLevel()
    local d = moodDragonData()
    local bonding = d and d:FindFirstChild("Bonding")
    local v = bonding and bonding:FindFirstChild("BondLevel")
    return v and v.Value or nil
end

local function moodStatusText()
    local happiness = moodValue("Happiness")
    local bond = moodBondLevel()
    local state = moodState.running and "运行中" or "已停止"
    return string.format(
        "%s · 心情 %s · 羁绊等级 %s\n已发送 %d 次 · 动作：%s",
        state,
        happiness ~= nil and tostring(happiness) or "?",
        bond ~= nil and tostring(bond) or "?",
        moodState.count,
        moodState.action
    )
end

local function moodUpdateStatus(force)
    if not moodStatusPara then
        return
    end
    local now = os.clock()
    if not force and now - moodState.statusClock < 0.5 then
        return
    end
    moodState.statusClock = now
    local text = moodStatusText()
    pcall(function()
        moodStatusPara:SetDesc(text)
    end)
end

local function moodRemote()
    local remotes = player:FindFirstChild("Remotes")
    return remotes and remotes:FindFirstChild("BondingExpRemote")
end

local function moodFireOnce()
    local remote = moodRemote()
    local d = moodDragonData()
    if not (remote and d) then
        return false
    end
    local ok = pcall(function()
        remote:FireServer(d, moodState.action)
    end)
    if ok then
        moodState.count = moodState.count + 1
    end
    moodUpdateStatus(true)
    return ok
end

local function moodStart()
    if moodState.running then
        return
    end
    if not (moodRemote() and moodDragonData()) then
        pcall(function()
            WindUI:Notify({ Title = "没有龙", Content = "先骑上龙再开", Duration = 3 })
        end)
        return
    end
    moodState.running = true
    moodState.generation = moodState.generation + 1
    local gen = moodState.generation
    moodUpdateStatus(true)
    task.spawn(function()
        while moodState.running and gen == moodState.generation do
            moodFireOnce()
            task.wait(math.max(moodState.interval, 0.2))
        end
        moodState.running = false
        if moodToggle then
            pcall(function()
                moodToggle:Set(false, false)
            end)
        end
        moodUpdateStatus(true)
    end)
end

local function moodStop()
    moodState.running = false
    moodState.generation = moodState.generation + 1
    if moodToggle then
        pcall(function()
            moodToggle:Set(false, false)
        end)
    end
    moodUpdateStatus(true)
end

dshStopMood = moodStop

moodSection:Paragraph({
    Title = "龙心情",
    Desc = "发送 BondingExpRemote 的 “Bored” 抚摸动作，增加龙的羁绊/心情。需要先骑龙，并且处于可以互动的状态。",
})

moodStatusPara = moodSection:Paragraph({
    Title = "心情状态",
    Desc = "正在读取…",
})

moodToggle = moodSection:Toggle({
    Title = "自动长心情",
    Desc = "每隔一段时间发送一次抚摸动作",
    Value = false,
    Callback = function(state)
        if state then
            moodStart()
        else
            moodStop()
        end
    end,
})

local function moodCreateSlider(parent, primaryConfig, fallbackConfig)
    local ok, slider = pcall(function()
        return parent:Slider(primaryConfig)
    end)
    if ok and slider then
        return slider
    end
    local ok2, slider2 = pcall(function()
        return parent:Slider(fallbackConfig)
    end)
    if ok2 then
        return slider2
    end
    return nil
end

moodCreateSlider(moodSection, {
    Title = "发送间隔（秒）",
    Desc = "默认 1 秒",
    Value = { Min = 0.3, Max = 5, Default = 1 },
    Step = 0.1,
    Callback = function(value)
        moodState.interval = tonumber(value) or 1
    end,
}, {
    Title = "发送间隔（秒）",
    Desc = "默认 1 秒",
    Value = 1,
    Min = 0.3,
    Max = 5,
    Step = 0.1,
    Callback = function(value)
        moodState.interval = tonumber(value) or 1
    end,
})

moodSection:Button({
    Title = "长一次心情",
    Desc = "手动发送一次抚摸动作",
    Callback = function()
        task.spawn(function()
            moodFireOnce()
        end)
    end,
})

pcall(function()
    getgenv().DSH_Mood = {
        start = moodStart,
        stop = moodStop,
        once = moodFireOnce,
        status = moodStatusText,
    }
end)

task.defer(function()
    moodUpdateStatus(true)
end)

------------------------------------------------------------------
-- 灵魂灯笼（区块）
------------------------------------------------------------------

local soulSection = HalloweenTab:Section({ Title = "灵魂灯笼", Opened = false })

local soulStatusPara
local soulToggle
local soulCollectToggle
local soulOpenToggle
local soulState = {
    running = false,
    generation = 0,
    opened = 0,
    current = "无",
    statusClock = 0,
    attacking = false,
    attackGeneration = 0,
    attacked = 0,
    distance = 25,
    height = 8,
    attackOrigin = nil,
    healthText = "?",
    skipped = {},
    ids = {},
    usedLanterns = {},
    gcList = nil,
    auto = false,
    usedDoors = {},
    wait = 1,
    doorWait = 60,
    collecting = false,
    opening = false,
    waitingDoors = false,
}

local function soulDataValue()
    local pg = player:FindFirstChild("PlayerGui")
    local pdg = pg and pg:FindFirstChild("PlayerDataGui")
    local data = pdg and pdg.Data
    local ev = data and data:FindFirstChild("HalloweenEvent2026")
    return ev and ev:FindFirstChild("HalloweenLanterns")
end

local function soulDoorFolder()
    local interactions = workspace:FindFirstChild("Interactions")
    local halloween = interactions and interactions:FindFirstChild("HalloweenEvent")
    return halloween and halloween:FindFirstChild("LanternDoors")
end

local function soulDoors()
    local list = {}
    for _, d in ipairs(workspace:GetDescendants()) do
        if d:IsA("Model") and d.Name == "LanternDoor" and d:FindFirstChild("RootPart") then
            local parentName = d.Parent and d.Parent.Name or ""
            if not string.find(parentName, "LanternDoorRoom", 1, true) then
                local visible = false
                for _, part in ipairs(d:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency < 1 then
                        local n = part.Name
                        if n == "Door_Left_Neon" or n == "Door_Right_Neon" or n == "OpenEffect" then
                            visible = true
                            break
                        end
                    end
                end
                if visible then
                    list[#list + 1] = d
                end
            end
        end
    end
    return list
end

local function soulLanternFolder()
    local interactions = workspace:FindFirstChild("Interactions")
    local halloween = interactions and interactions:FindFirstChild("HalloweenEvent")
    return halloween and halloween:FindFirstChild("GhostLanterns")
end

local function soulStatusText()
    local lanterns = soulDataValue()
    local doors = soulDoors()
    local lanternCount = lanterns and (tonumber(lanterns.Value) or 0) or 0
    local state
    if soulState.attacking then
        state = "打灯笼中"
    elseif soulState.collecting then
        state = "收集中"
    elseif soulState.opening then
        if soulState.waitingDoors then
            state = "等门刷新"
        elseif lanternCount <= 0 then
            state = "等灯笼"
        else
            state = "开门中"
        end
    elseif soulState.running then
        state = "运行中"
    else
        state = "已停止"
    end
    return string.format(
        "%s · 灯笼 %s · 幽灵门 %d 扇\n已开 %d 扇 · 已打 %d 下 · 血量 %s · 当前：%s",
        state,
        lanterns and tostring(lanterns.Value) or "?",
        #doors,
        soulState.opened,
        soulState.attacked,
        soulState.healthText,
        soulState.current
    )
end

local function soulUpdateStatus(force)
    if not soulStatusPara then
        return
    end
    local now = os.clock()
    if not force and now - soulState.statusClock < 0.5 then
        return
    end
    soulState.statusClock = now
    local text = soulStatusText()
    pcall(function()
        soulStatusPara:SetDesc(text)
    end)
end

local function soulMover()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local dragon = hum and hum.SeatPart and hum.SeatPart.Parent
    return (dragon and dragon:IsA("Model")) and dragon or char
end

local function soulTeleportLantern()
    local folder = soulLanternFolder()
    local first = folder and folder:GetChildren()[1]
    local model = first and first:FindFirstChild("GhostLantern")
    local part = model and model:FindFirstChild("BillboardPart", true)
    local mover = soulMover()
    if not (part and mover) then
        return false
    end
    pcall(function()
        mover:PivotTo(CFrame.new(part.Position + Vector3.new(0, 6, 0)))
    end)
    return true
end

local function soulLanternId(part)
    if type(getgc) ~= "function" then
        return nil
    end
    if soulState.ids[part] then
        return soulState.ids[part]
    end
    local found
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" and rawget(obj, "PrimaryPart") == part and rawget(obj, "ClientDestructibleIdentifier") ~= nil then
            found = obj.ClientDestructibleIdentifier
            break
        end
    end
    soulState.ids[part] = found
    return found
end

local function soulAttackLantern()
    if soulState.attacking then
        return
    end
    if type(getgc) ~= "function" then
        pcall(function()
            WindUI:Notify({ Title = "执行器不支持 getgc", Content = "手机端需要支持 getgc 才能读取灯笼ID", Duration = 3 })
        end)
        return
    end
    local list = {}
    for _, obj in ipairs(getgc(true)) do
        if type(obj) == "table" then
            local id = rawget(obj, "ClientDestructibleIdentifier")
            local part = rawget(obj, "PrimaryPart")
            if id ~= nil and typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
                list[#list + 1] = { id = tostring(id), part = part }
            end
        end
    end
    if #list == 0 then
        pcall(function()
            WindUI:Notify({ Title = "没有灯笼", Content = "客户端没有找到灵魂灯笼组件", Duration = 3 })
        end)
        return
    end
    local mover = soulMover()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local breath = mover and mover:FindFirstChild("Remotes") and mover.Remotes:FindFirstChild("BreathFireRemote")
    local hit = remotes and remotes:FindFirstChild("ClientDestructibleHitRemote")
    local grab = remotes and remotes:FindFirstChild("GrabLanternRemote")
    if not (mover and hit and grab) then
        pcall(function()
            WindUI:Notify({ Title = "找不到灯笼接口", Content = "BreathFireRemote / Hit / Grab 不存在", Duration = 3 })
        end)
        return
    end
    local data = soulDataValue()
    local before = data and (tonumber(data.Value) or 0) or 0
    soulState.attacking = true
    soulState.attackGeneration = soulState.attackGeneration + 1
    local gen = soulState.attackGeneration
    soulState.attacked = 0
    soulState.attackOrigin = mover:GetPivot()
    soulUpdateStatus(true)
    task.spawn(function()
        for _, item in ipairs(list) do
            if not soulState.attacking or gen ~= soulState.attackGeneration then
                break
            end
            local part = item.part
            if part and part.Parent then
                local pos = part.Position
                soulState.current = part:GetFullName()
                soulState.attacked = soulState.attacked + 1
                pcall(function()
                    mover:PivotTo(CFrame.lookAt(pos + Vector3.new(0, 6, 22), pos))
                end)
                task.wait(0.2)
                if breath then
                    pcall(function()
                        breath:FireServer(true)
                    end)
                end
                task.wait(0.3)
                pcall(function()
                    hit:FireServer(item.id)
                end)
                task.wait(0.2)
                pcall(function()
                    grab:FireServer(item.id)
                end)
                task.wait(0.2)
                if breath then
                    pcall(function()
                        breath:FireServer(false)
                    end)
                end
                soulState.healthText = tostring(data and data.Value or "?")
                soulUpdateStatus(false)
                task.wait(0.35)
            end
        end
        soulState.attacking = false
        soulUpdateStatus(true)
        local after = data and (tonumber(data.Value) or 0) or 0
        pcall(function()
            WindUI:Notify({
                Title = "抓灯笼完成",
                Content = string.format("处理 %d 个，灯笼 %d -> %d", soulState.attacked, before, after),
                Duration = 3,
            })
        end)
    end)
end

local function soulLanternCount()
    local v = soulDataValue()
    return v and (tonumber(v.Value) or 0) or 0
end

local function soulGrabOne()
    if type(getgc) ~= "function" then
        return false
    end
    local list = soulState.gcList
    if not list then
        list = {}
        for _, obj in ipairs(getgc(true)) do
            if type(obj) == "table" then
                local id = rawget(obj, "ClientDestructibleIdentifier")
                local part = rawget(obj, "PrimaryPart")
                if id ~= nil and typeof(part) == "Instance" and part:IsA("BasePart") and part.Parent then
                    list[#list + 1] = { id = tostring(id), part = part }
                end
            end
        end
        soulState.gcList = list
    end
    local mover = soulMover()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local breath = mover and mover:FindFirstChild("Remotes") and mover.Remotes:FindFirstChild("BreathFireRemote")
    local hit = remotes and remotes:FindFirstChild("ClientDestructibleHitRemote")
    local grab = remotes and remotes:FindFirstChild("GrabLanternRemote")
    if not (mover and hit and grab) then
        return false
    end
    local data = soulDataValue()
    local before = data and (tonumber(data.Value) or 0) or 0
    for _, item in ipairs(list) do
        if not soulState.usedLanterns[item.id] then
            local pos = item.part.Position
            local health = item.part:FindFirstChild("Health")
            pcall(function()
                mover:PivotTo(CFrame.lookAt(pos + Vector3.new(0, 6, 22), pos))
            end)
            task.wait(0.1)
            local cam = workspace.CurrentCamera
            local vimOk, vim = pcall(function()
                return game:GetService("VirtualInputManager")
            end)
            local screen = cam:WorldToViewportPoint(pos)
            local sx, sy = math.floor(screen.X), math.floor(screen.Y)
            if vimOk and vim then
                pcall(function()
                    vim:SendMouseButtonEvent(sx, sy, 0, true, game, 0)
                end)
            end
            for k = 1, 40 do
                if health and health.Value <= 0 then
                    break
                end
                pcall(function()
                    hit:FireServer(item.id)
                end)
                task.wait(0.1)
            end
            if vimOk and vim then
                pcall(function()
                    vim:SendMouseButtonEvent(sx, sy, 0, false, game, 0)
                end)
            end
            pcall(function()
                grab:FireServer(item.id)
            end)
            task.wait(0.1)
            soulState.usedLanterns[item.id] = true
            local after = data and (tonumber(data.Value) or 0) or 0
            if after > before then
                return true
            end
        end
    end
    return false
end

local function soulCollectStart()
    if soulState.collecting then
        return
    end
    soulState.collecting = true
    soulUpdateStatus(true)
    task.spawn(function()
        while soulState.collecting do
            local rev = getgenv().DSH_Revive
            if rev and rev.ensure then
                pcall(rev.ensure)
            end
            if soulGrabOne() then
                task.wait(0.05)
            else
                task.wait(1)
            end
        end
        soulUpdateStatus(true)
    end)
end

local function soulCollectStop()
    soulState.collecting = false
    soulUpdateStatus(true)
end

local function soulRoomMobs(room)
    local list = {}
    for _, d in ipairs(room:GetDescendants()) do
        if d:IsA("Model") then
            local n = string.lower(d.Name)
            if string.find(n, "bat", 1, true) or d:FindFirstChildOfClass("Humanoid") then
                list[#list + 1] = d
            end
        end
    end
    return list
end

local function soulFightRoom(room, mover)
    local deadline = os.clock() + 20
    local vimOk, vim = pcall(function()
        return game:GetService("VirtualInputManager")
    end)
    if not vimOk then
        vim = nil
    end
    local cam = workspace.CurrentCamera
    while os.clock() < deadline do
        local mobs = soulRoomMobs(room)
        if #mobs == 0 then
            return true
        end
        local mob = mobs[1]
        local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
        if part then
            pcall(function()
                mover:PivotTo(CFrame.new(part.Position))
            end)
            task.wait(0.3)
            local oldType = cam.CameraType
            pcall(function()
                cam.CameraType = Enum.CameraType.Scriptable
                cam.CFrame = CFrame.lookAt(part.Position + Vector3.new(0, 5, 10), part.Position)
            end)
            local screen = cam:WorldToViewportPoint(part.Position)
            pcall(function()
                vim:SendMouseButtonEvent(math.floor(screen.X), math.floor(screen.Y), 0, true, game, 0)
            end)
            task.wait(0.8)
            pcall(function()
                vim:SendMouseButtonEvent(math.floor(screen.X), math.floor(screen.Y), 0, false, game, 0)
            end)
            pcall(function()
                cam.CameraType = oldType
            end)
        else
            task.wait(0.3)
        end
    end
    return false
end

local function soulOpenStart()
    if soulState.opening then
        return
    end
    local mover = soulMover()
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local use = remotes and remotes:FindFirstChild("UseLanternRemote")
    local claim = remotes and remotes:FindFirstChild("ClaimLanternRoomRemote")
    local leave = remotes and remotes:FindFirstChild("LeaveLanternDoorRoomRemote")
    local getDrops = remotes and remotes:FindFirstChild("GetLanternDropsRemote")
    if not (mover and use and claim and leave) then
        pcall(function()
            WindUI:Notify({ Title = "找不到灯笼接口", Content = "UseLanternRemote 等不存在", Duration = 3 })
        end)
        return
    end
    soulState.opening = true
    soulState.usedDoors = {}
    soulUpdateStatus(true)
    local orig = mover:GetPivot()
    task.spawn(function()
        local lastReset = os.clock()
        while soulState.opening do
            if os.clock() - lastReset >= (soulState.doorWait or 60) then
                soulState.usedDoors = {}
                lastReset = os.clock()
            end
            local origin = mover:GetPivot().Position
            local candidates = {}
            for _, door in ipairs(soulDoors()) do
                if not soulState.usedDoors[door] then
                    local root = door:FindFirstChild("RootPart")
                    if root then
                        candidates[#candidates + 1] = {
                            door = door,
                            root = root,
                            dist = (root.Position - origin).Magnitude,
                        }
                    end
                end
            end
            table.sort(candidates, function(a, b)
                return a.dist < b.dist
            end)
            if #candidates == 0 then
                soulState.waitingDoors = true
                task.wait(2)
            elseif soulLanternCount() <= 0 then
                soulState.waitingDoors = false
                task.wait(2)
            else
                soulState.waitingDoors = false
                local door = candidates[1].door
                local root = candidates[1].root
                local interact = root:FindFirstChild("Interact")
                local target = (interact and interact.WorldPosition) or root.Position
                soulState.current = door:GetFullName()
                soulUpdateStatus(false)
                pcall(function()
                    mover:PivotTo(CFrame.new(target + Vector3.new(0, 6, 0)))
                end)
                task.wait(math.max(soulState.wait, 0.1))
                local ok, res, drops = pcall(function()
                    return use:InvokeServer(door)
                end)
                if ok and res then
                    if res == "TrickRoom" or res == "TrickRoom2" or res == "TreatRoom" then
                        task.wait(3.5)
                        local env = workspace:FindFirstChild("Environment")
                        local room = env and env:FindFirstChild("LanternDoorRoom_" .. player.Name)
                        if room then
                            soulFightRoom(room, mover)
                        end
                    else
                        task.wait(1.5)
                    end
                    if getDrops then
                        pcall(function()
                            getDrops:FireServer()
                        end)
                    end
                    task.wait(0.5)
                    pcall(function()
                        claim:InvokeServer()
                    end)
                    task.wait(0.5)
                    if getDrops then
                        pcall(function()
                            getDrops:FireServer()
                        end)
                    end
                    task.wait(0.5)
                    pcall(function()
                        leave:FireServer()
                    end)
                    soulState.opened = soulState.opened + 1
                end
                soulState.usedDoors[door] = true
                soulUpdateStatus(false)
            end
        end
        soulState.opening = false
        pcall(function()
            mover:PivotTo(orig)
        end)
        soulUpdateStatus(true)
    end)
end

local function soulOpenStop()
    soulState.opening = false
    soulUpdateStatus(true)
end

local function soulStop()
    soulState.auto = false
    soulState.collecting = false
    soulState.opening = false
    soulState.running = false
    soulState.generation = soulState.generation + 1
    soulState.attacking = false
    soulState.attackGeneration = soulState.attackGeneration + 1
    if soulState.attackOrigin then
        local mover = soulMover()
        if mover then
            pcall(function()
                mover:PivotTo(soulState.attackOrigin)
            end)
        end
    end
    soulUpdateStatus(true)
end

dshStopSoul = soulStop

soulSection:Paragraph({
    Title = "灵魂灯笼",
    Desc = "把灵魂灯笼送到幽灵门并开门，一盏灯笼只能开一扇门。可以先点“传送去灵魂灯笼”去拿灯笼，再点“一键开幽灵门”。",
})

soulStatusPara = soulSection:Paragraph({
    Title = "灵魂灯笼状态",
    Desc = "正在读取…",
})

soulCollectToggle = soulSection:Toggle({
    Title = "收集灵魂灯笼",
    Desc = "自动打灵魂灯笼并拾取，循环收集",
    Value = false,
    Callback = function(state)
        if state then
            soulCollectStart()
        else
            soulCollectStop()
        end
    end,
})

soulOpenToggle = soulSection:Toggle({
    Title = "打开灵魂门",
    Desc = "用灯笼开幽灵门，门刷新后继续",
    Value = false,
    Callback = function(state)
        if state then
            soulOpenStart()
        else
            soulOpenStop()
        end
    end,
})

pcall(function()
    getgenv().DSH_Soul = {
        collectStart = soulCollectStart,
        collectStop = soulCollectStop,
        openStart = soulOpenStart,
        openStop = soulOpenStop,
        open = soulOpenStart,
        stop = soulStop,
        lantern = soulTeleportLantern,
        attack = soulAttackLantern,
        status = soulStatusText,
    }
end)

task.defer(function()
    soulUpdateStatus(true)
end)

------------------------------------------------------------------
-- 自动打植物（HarvestNode / LargeHarvestNode）
------------------------------------------------------------------

local function dshSetupPlant()
local plantStatusPara
local plantToggle
local plantState = {
    running = false,
    generation = 0,
    current = "无",
    attacked = 0,
    statusClock = 0,
}

local function plantNodes()
    local list = {}
    local cs = game:GetService("CollectionService")
    for _, tag in ipairs({ "HarvestNode", "LargeHarvestNode" }) do
        for _, inst in ipairs(cs:GetTagged(tag)) do
            if inst:IsA("Model") then
                list[#list + 1] = inst
            end
        end
    end
    return list
end

local function plantPumpkins()
    local list = {}
    for _, t in ipairs(game:GetService("CollectionService"):GetTagged("SpawnedMeteor")) do
        local h = t:FindFirstChild("Health")
        if h and h.Value > 0 then
            list[#list + 1] = t
        end
    end
    return list
end

local function plantStatusText()
    local state = plantState.running and "运行中" or "已停止"
    return string.format(
        "%s · 南瓜 %d 个 · 植物 %d 个\n已打 %d 次 · 当前：%s",
        state,
        #plantPumpkins(),
        #plantNodes(),
        plantState.attacked,
        plantState.current
    )
end

local function plantUpdateStatus(force)
    if not plantStatusPara then
        return
    end
    local now = os.clock()
    if not force and now - plantState.statusClock < 0.5 then
        return
    end
    plantState.statusClock = now
    pcall(function()
        plantStatusPara:SetDesc(plantStatusText())
    end)
end

local function plantMover()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local dragon = hum and hum.SeatPart and hum.SeatPart.Parent
    return (dragon and dragon:IsA("Model")) and dragon or char
end

local function plantStart()
    if plantState.running then
        return
    end
    plantState.running = true
    plantState.generation = plantState.generation + 1
    local gen = plantState.generation
    plantUpdateStatus(true)
    task.spawn(function()
        while plantState.running and gen == plantState.generation do
            local rev = getgenv().DSH_Revive
            if rev and rev.ensure then
                pcall(rev.ensure)
            end
            local pumpkins = plantPumpkins()
            if #pumpkins > 0 then
                local pumpkin = pumpkins[1]
                local health = pumpkin:FindFirstChild("Health")
                local damage = pumpkin:FindFirstChild("DamageRemote")
                plantState.current = pumpkin:GetFullName()
                plantUpdateStatus(false)
                local mover = plantMover()
                if mover then
                    pcall(function()
                        mover:PivotTo(CFrame.new(pumpkin.WorldPosition + Vector3.new(0, 3, 0)))
                    end)
                    task.wait(0.2)
                end
                if damage then
                    for k = 1, 80 do
                        if health and health.Value <= 0 then
                            break
                        end
                        pcall(function()
                            damage:FireServer()
                        end)
                        task.wait(0.1)
                    end
                    plantState.attacked = plantState.attacked + 1
                end
                task.wait(0.2)
            else
                local nodes = plantNodes()
                if #nodes == 0 then
                    task.wait(2)
                else
                    local mover = plantMover()
                    local remotes = mover and mover:FindFirstChild("Remotes")
                    local breath = remotes and remotes:FindFirstChild("BreathFireRemote")
                    local node = nodes[1]
                    if mover and breath then
                        local pivot = node:GetPivot()
                        plantState.current = node:GetFullName()
                        pcall(function()
                            mover:PivotTo(CFrame.lookAt(pivot.Position + Vector3.new(0, 6, 15), pivot.Position))
                        end)
                        task.wait(0.3)
                        pcall(function()
                            breath:FireServer(true)
                        end)
                        task.wait(1.5)
                        pcall(function()
                            breath:FireServer(false)
                        end)
                        plantState.attacked = plantState.attacked + 1
                        task.wait(0.4)
                    else
                        task.wait(1)
                    end
                end
            end
            plantUpdateStatus(false)
        end
        plantState.running = false
        plantUpdateStatus(true)
    end)
end

local function plantStop()
    plantState.running = false
    plantState.generation = plantState.generation + 1
    plantUpdateStatus(true)
end

dshStopPlant = plantStop

plantSection = HalloweenTab:Section({ Title = "击碎南瓜", Opened = false })

plantToggle = plantSection:Toggle({
    Title = "击碎南瓜",
    Desc = "没有南瓜事件开启时会自动击碎地图上的所有南瓜",
    Value = false,
    Callback = function(state)
        if state then
            plantStart()
        else
            plantStop()
        end
    end,
})

HalloweenTab:Section({ Title = "击碎水晶", Opened = false })

pcall(function()
    getgenv().DSH_Plant = {
        start = plantStart,
        stop = plantStop,
        status = plantStatusText,
    }
end)

task.defer(function()
    plantUpdateStatus(true)
end)
end

dshSetupPlant()

------------------------------------------------------------------
-- 自动攻击周围怪物（基础页）
------------------------------------------------------------------

local function dshMobSetup()
local mobToggle
local mobState = {
    running = false,
    generation = 0,
    attacked = 0,
    current = "无",
}

local function mobMover()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local dragon = hum and hum.SeatPart and hum.SeatPart.Parent
    if dragon and dragon:IsA("Model") then
        return dragon
    end
    local chars = workspace:FindFirstChild("Characters")
    local me = chars and chars:FindFirstChild(player.Name)
    local dragons = me and me:FindFirstChild("Dragons")
    local first = dragons and dragons:GetChildren()[1]
    if first and first:IsA("Model") then
        return first
    end
    return char
end

local function mobNearest()
    local folder = workspace:FindFirstChild("MobFolder")
    local mover = mobMover()
    local origin = mover and mover:GetPivot().Position or Vector3.zero
    local best, bestDist
    if folder then
        for _, m in ipairs(folder:GetChildren()) do
            local h = m:FindFirstChild("Health", true)
            if h and h.Value > 0 then
                local part = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                if part then
                    local dist = (part.Position - origin).Magnitude
                    if dist < 5000 and (not bestDist or dist < bestDist) then
                        best, bestDist = m, dist
                    end
                end
            end
        end
    end
    return best
end

local function mobStart()
    if mobState.running then
        return
    end
    mobState.running = true
    mobState.target = nil
    mobState.generation = mobState.generation + 1
    local gen = mobState.generation
    task.spawn(function()
        while mobState.running and gen == mobState.generation do
            local rev = getgenv().DSH_Revive
            if rev and rev.dragon then
                local dragon = rev.dragon()
                if dragon then
                    local hp = dragon:FindFirstChild("Health", true)
                    local hpNum = hp and tonumber(hp.Value)
                    local char = player.Character
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local seated = hum and hum.SeatPart ~= nil
                    if hpNum ~= nil and hpNum <= 0 then
                        if rev.once then
                            pcall(rev.once)
                        end
                        task.wait(0.6)
                        if rev.mount then
                            pcall(rev.mount, dragon)
                        end
                    elseif not seated and rev.mount then
                        pcall(rev.mount, dragon)
                    end
                end
            end
            local mob = mobNearest()
            if not mob then
                mobState.target = nil
                task.wait(2)
            else
                local mover = mobMover()
                local remotes = mover and mover:FindFirstChild("Remotes")
                local breath = remotes and remotes:FindFirstChild("BreathFireRemote")
                local part = mob.PrimaryPart or mob:FindFirstChildWhichIsA("BasePart")
                if mover and breath and part then
                    mobState.current = mob:GetFullName()
                    if mobState.target ~= mob then
                        mobState.target = mob
                        local mp = mob:GetPivot()
                        local above = mp.Position + Vector3.new(0, 10, 0)
                        pcall(function()
                            mover:PivotTo(CFrame.new(above))
                        end)
                        task.wait(0.9)
                    end
                    local cam = workspace.CurrentCamera
                    local vimOk, vim = pcall(function()
                        return game:GetService("VirtualInputManager")
                    end)
                    local sx, sy = 0, 0
                    pcall(function()
                        local screen = cam:WorldToViewportPoint(part.Position)
                        sx, sy = math.floor(screen.X), math.floor(screen.Y)
                    end)
                    if vimOk and vim then
                        pcall(function()
                            vim:SendMouseMoveEvent(sx, sy, game)
                        end)
                        task.wait(0.05)
                        pcall(function()
                            vim:SendMouseButtonEvent(sx, sy, 0, true, game, 0)
                        end)
                    end
                    pcall(function()
                        breath:FireServer(true)
                    end)
                    task.wait(0.8)
                    pcall(function()
                        breath:FireServer(false)
                    end)
                    if vimOk and vim then
                        pcall(function()
                            vim:SendMouseButtonEvent(sx, sy, 0, false, game, 0)
                        end)
                    end
                    mobState.attacked = mobState.attacked + 1
                    task.wait(0.12)
                else
                    task.wait(1)
                end
            end
        end
        mobState.running = false
    end)
end

local function mobStop()
    mobState.running = false
    mobState.generation = mobState.generation + 1
    if mobToggle then
        pcall(function()
            mobToggle:Set(false, false)
        end)
    end
end

dshMobStop = mobStop

mobToggle = section:Toggle({
    Title = "自动攻击周围怪物",
    Desc = "自动找附近的怪，传送过去吐息攻击，没怪时原地等待",
    Value = false,
    Callback = function(state)
        if state then
            mobStart()
        else
            mobStop()
        end
    end,
})

pcall(function()
    getgenv().DSH_Mob = {
        start = mobStart,
        stop = mobStop,
        state = mobState,
        nearest = mobNearest,
        mover = mobMover,
    }
end)


end

dshMobSetup()

------------------------------------------------------------------
-- 防 AFK（防止 20 分钟无操作被踢）
------------------------------------------------------------------

local function dshSetupAntiAfk()
    local vu
    pcall(function()
        vu = game:GetService("VirtualUser")
    end)
    local conn = nil

    local function pulse()
        if not vu then
            return
        end
        pcall(function()
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
        task.wait(1)
        pcall(function()
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end)
    end

    local function start()
        if conn or not vu then
            return
        end
        conn = player.Idled:Connect(function()
            pulse()
        end)
        task.spawn(function()
            while conn do
                task.wait(60)
                if conn then
                    pulse()
                end
            end
        end)
    end

    local function stop()
        if conn then
            conn:Disconnect()
            conn = nil
        end
    end

    local afkSection = BasicsTab:Section({ Title = "防 AFK", Opened = false })
    afkSection:Toggle({
        Title = "防止闲置踢出",
        Desc = "每 60 秒模拟一次点击，避免 20 分钟无操作被踢出",
        Value = true,
        Callback = function(state)
            if state then
                start()
            else
                stop()
            end
        end,
    })

    start()

    pcall(function()
        getgenv().DSH_AntiAfk = { start = start, stop = stop }
    end)
end

dshSetupAntiAfk()

-- 调试/自动化入口：其他脚本可以 getgenv().DSH_Farm.round() / .start() / .stop()
pcall(function()
    getgenv().DSH_Farm = {
        start = farmStart,
        stop = farmStop,
        round = farmRunOnce,
        refresh = farmRefresh,
        status = farmStatusText,
        stopAll = dshStopAll,
    }
    getgenv().DSH_StopAll = dshStopAll
end)

task.defer(function()
    farmRefresh()
end)

Window:SelectTab(1)
