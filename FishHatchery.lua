-- // Made by Nikoleto Scripts \\ --

local IsRoblox,_ = pcall(function()
	return game, workspace, typeof("")
end)

if not IsRoblox then
	print("twin ts NOT roblox luau 😭🥀")
	return
end

if workspace.DistributedGameTime < 3 then
	task.wait(3 - workspace.DistributedGameTime)
end

local Running = true

local function nsloadstring(Url, Argument)
	local Success, Result = pcall(function()
		return loadstring(game:HttpGet(Url))(Argument)
	end)

	return Success and Result or {Value = "Unknown"}
end

local clonefunctionFunction = clonefunction or clone_function or copyfunction or copy_function
local nsclonefunction = function(Function)
	if not clonefunctionFunction then
		return Function
	end

	local Success, Result = pcall(clonefunctionFunction, Function)
	return Success and Result or Function
end

local clonerefFunction = cloneref or clone_ref or clonereference or clone_reference
local nscloneref = function(Object)
	if not clonerefFunction then
		return Object
	end

	local Success, Result = pcall(clonerefFunction, Object)
	return Success and Result or Object
end

local GetServiceFunction = nsclonefunction(game.GetService)
local function GetService(ServiceName)
	return nscloneref(GetServiceFunction(game, ServiceName))
end

local CreateInstance = nsclonefunction(Instance.new)
local function Create(Type, Properties)
	if Properties then
		local Object = nscloneref(CreateInstance(Type))

		for Property, Value in next, Properties do
			local PropertySuccess, Error = pcall(function()
				Object[Property] = Value
			end)

			if not PropertySuccess then
				print("[DEBUG] Error setting", Property, "on", Type .. ":", Error)
			end
		end

		return Object
	else
		return nscloneref(CreateInstance(Type))
	end
end

local function GetPing(DataPing)
	return DataPing:GetValue()
end

local ReplicatedStorage = GetService("ReplicatedStorage")
local RunService = GetService("RunService")
local Players = GetService("Players")
local CoreGui = GetService("CoreGui")
local Debris = GetService("Debris")

local Fluent = nsloadstring("https://raw.githubusercontent.com/discoart/FluentPlus/refs/heads/main/Beta.lua")

task.spawn(function()
    local DataPing = GetService("Stats"):WaitForChild("Network").ServerStatsItem["Data Ping"]
    local Ping = CoreGui:FindFirstChild("Ping") or Create("NumberValue", {Name = "Ping", Parent = CoreGui})

    while true do
        local CurrentPing = GetPing(DataPing)

        if CurrentPing > 1000 or Ping.Value == CurrentPing then
            Fluent:Notify({
                Title = "Nikoleto Scripts",
                Content = "Ping freeze detected, current ping: " .. math.floor(CurrentPing) .. "ms",
                Duration = 3
            })
        end

        Ping.Value = CurrentPing
        task.wait(3)
    end
end)

local LocalPlayer = Players.LocalPlayer
local PlayerGui = nscloneref(LocalPlayer:WaitForChild("PlayerGui"))

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ClaimAquarium = Remotes:WaitForChild("ClaimAquarium")
local FishHarvestEvent = Remotes:WaitForChild("FishHarvestEvent")
local PoseidonWaveEvent = Remotes:WaitForChild("PoseidonWaveEvent")
local TriggerAbilityEvent = Remotes:WaitForChild("TriggerAbilityEvent")

local Connections = {RemoveAllWaves = nil, CFrameSpeed = nil, Lag = nil}

local Autofarm = {
    Enabled = false,
    TargetFishSlot = "1",
    TargetReef = "Freshwater",
    Power = 5,
    AuraFarm = false,
    AuraGhosting = 0.1,
    AuraDelay = 1,
    HideWaves = false
}

local TidalWave = {
    Enabled = false,
    WaitTime = 0.5,
}

local CFrameSpeed = {
    Enabled = false,
    Value = 50
}
local RemoveAllWaves = false
local Bleed = false

local OwnedAquarium = nil

for _,Aquarium in ipairs(workspace:WaitForChild("Aquariums"):GetChildren()) do
    if Aquarium:WaitForChild("Ownership"):WaitForChild("SurfaceGui"):WaitForChild("TextLabel").Text == LocalPlayer.Name .. "'s Aquarium" then
        OwnedAquarium = Aquarium
        break
    end
end

if not OwnedAquarium then
    for _,Aquarium in ipairs(workspace:WaitForChild("Aquariums"):GetChildren()) do
        ClaimAquarium:InvokeServer(Aquarium)
        if Aquarium:WaitForChild("Ownership"):WaitForChild("SurfaceGui"):WaitForChild("TextLabel").Text == LocalPlayer.Name .. "'s Aquarium" then
            OwnedAquarium = Aquarium
            break
        end
    end
end

local IndexFish = {}

for _,Child in ipairs(PlayerGui:WaitForChild("Main"):WaitForChild("Main"):WaitForChild("IndexFrame"):WaitForChild("ScrollingFrame"):GetChildren()) do
    if not string.find(string.lower(Child.Name), "fish") then
        continue
    end

    local CurrentFish = Child.Name:gsub(" Fish", "")
    IndexFish[CurrentFish] = Child:WaitForChild("FishImage").Image
end

local FishPriority = {
    "Rabbit",
    "Rhythm",
    "Zombie",
    "Puppeteer",
    "Ghillie",
    "Sun",
    "Obsessed",
    "Angler",
    "Mirror",
    "Diver",
    "Basic"
}

local function UpdateFishSlot()
    local OwnedFish = {}
    local CurrentIteration = 1

    for _,Slot in ipairs(OwnedAquarium:WaitForChild("Slots"):GetChildren()) do
        local FishFaceTexture = Slot:WaitForChild("FishFace"):WaitForChild("FishFace").Texture

        if FishFaceTexture == "nil" then
            continue
        end

        local FishName = "Basic"

        for Fish, ImageId in next, IndexFish do
            if FishFaceTexture == ImageId then
                FishName = Fish
                break
            end
        end

        local CurrentSlot = Slot.Name:gsub("FishSlot", "")

        OwnedFish["Fish" .. tostring(CurrentIteration)] = {
            Name = FishName,
            Slot = CurrentSlot
        }

        CurrentIteration += 1
    end

    for _,DesiredFish in ipairs(FishPriority) do
        for _,FishData in pairs(OwnedFish) do
            if FishData.Name == DesiredFish then
                Autofarm.TargetFishSlot = FishData.Slot
                return
            end
        end
    end
end

task.spawn(function()
    while true do
        if not Running then
            break
        end

        UpdateFishSlot()
        task.wait(2.5)
    end
end)

local Reefs = table.create(5)

for _,ReefName in ipairs({"Freshwater", "Coral", "Sun", "Trash", "Runic"}) do
    Reefs[ReefName] = {
        OriginalName = ReefName .. " Reef",
        SelfInstance = nil,
        Collectibles = {}
    }

    local CurrentReef = Reefs[ReefName]
    CurrentReef.SelfInstance = workspace:WaitForChild(CurrentReef.OriginalName)

    local Collectibles = {}

    for _,Child in ipairs(CurrentReef.SelfInstance:GetChildren()) do
        if string.find(string.lower(Child.Name), "algae") then
            table.insert(Collectibles, Child)
        end
    end

    CurrentReef.Collectibles = table.clone(Collectibles)
end

local VFXController = nil
local CanRequire,_ = pcall(function()
    VFXController = require(game:GetService("Players").LocalPlayer:WaitForChild("PlayerScripts"):WaitForChild("Client"):WaitForChild("VFXController"))
end)

local function VFXTidalWave(StartCFrame)
    local v233 = ReplicatedStorage:WaitForChild("VFX", 5)
    local v234 = v233 and v233:WaitForChild("Wave", 5)
    if v234 then
        v234 = v233.Wave:WaitForChild("Wave", 5)
    end
    if v234 then
        local v_u_235 = v234:Clone()
        v_u_235.Parent = workspace
        local v_u_236 = CFrame.Angles(1.5707963267948966, 0, 0)
        v_u_235:PivotTo(StartCFrame * CFrame.new(0, -15, 0) * v_u_236)
        v_u_235.Transparency = 1
        local v237 = v233.Wave:FindFirstChild("WaveSFX")
        if v237 then
            local v238 = v237:Clone()
            v238.Parent = v_u_235
            v238:Play()
        end
        v_u_235.Transparency = 0
        for _,v242 in ipairs(v_u_235:GetDescendants()) do
            if v242:IsA("Beam") or (v242:IsA("ParticleEmitter") or v242:IsA("Trail")) then
                v242.Enabled = true
            end
        end
        local v_u_244 = os.clock()
        local v_u_246 = nil
        v_u_246 = RunService.RenderStepped:Connect(function()
            if v_u_235 and v_u_235.Parent then
                local v247 = os.clock() - v_u_244
                local v248 = v247 * 40
                local v249 = v247 * 10
                local v250 = math.sin(v249) * -0.7
                local v251
                if v247 < 0.5 then
                    v251 = -15 + v247 / 0.5 * 15
                else
                    v251 = v247 <= 1.5 and 0 or 0 - (v247 - 1.5) / 0.5 * 15
                end
                local v252 = StartCFrame * CFrame.new(0, v251 + v250, -v248) * v_u_236
                v_u_235:PivotTo(v252)
                if v247 >= 2 then
                    if v_u_246 then
                        v_u_246:Disconnect()
                    end
                    v_u_235.Transparency = 1
                    for _, v258 in ipairs(v_u_235:GetDescendants()) do
                        if v258:IsA("ParticleEmitter") then
                            v258.Enabled = false
                        end
                        if v258:IsA("Beam") then
                            v258.Enabled = false
                        end
                        if v258:IsA("Trail") then
                            v258.Enabled = false
                        end
                    end
                    Debris:AddItem(v_u_235, 2)
                end
            elseif v_u_246 then
                v_u_246:Disconnect()
            end
        end)
        return
    end
end

local LocalCharacter = nil
local LocalHumanoid = nil
local LocalRoot = nil

local function CacheLocalPlayer()
    local CurrentCharacter = LocalPlayer.Character

    if not CurrentCharacter or not CurrentCharacter.Parent then
        LocalCharacter = nil
        return
    end

    LocalCharacter = CurrentCharacter

    if not LocalHumanoid or LocalHumanoid.Parent ~= LocalCharacter then
        LocalHumanoid = LocalCharacter:FindFirstChildOfClass("Humanoid")
    end

    if not LocalRoot or LocalRoot.Parent ~= LocalCharacter then
        LocalRoot = LocalCharacter.PrimaryPart
        if not LocalRoot then
            LocalRoot = LocalCharacter:FindFirstChild("HumanoidRootPart")
            if not LocalRoot then
                LocalRoot = LocalCharacter:FindFirstChild("Torso") or LocalCharacter:FindFirstChild("LowerTorso")
            end
        end
    end
end

task.spawn(function()
	while true do
		if not Running then
			break
		end

		CacheLocalPlayer()
		task.wait(0.1)
	end
end)

task.spawn(function()
    while true do
        if not Running then
            break
        end

        if Autofarm.Enabled then
            local TargetFishSlot = Autofarm.TargetFishSlot
            local Power = Autofarm.Power
            for Index, Collectible in next, Reefs[Autofarm.TargetReef].Collectibles do
                FishHarvestEvent:FireServer(TargetFishSlot, Collectible)

                if Index % Power == 0 then
                    task.wait()
                end

                if not Autofarm.Enabled then
                    break
                end
            end
        end

        task.wait(1)
    end
end)

task.spawn(function()
    while true do
        if not Running then
            break
        end

        if TidalWave.Enabled then
            local LocalRootCFrame = LocalRoot and LocalRoot.CFrame
            if LocalRootCFrame then
                PoseidonWaveEvent:FireServer(LocalRootCFrame)
                if not TidalWave.HideWaves then
                    if CanRequire then
                        VFXController.Play("Wave", nil, {
                            ["StartCFrame"] = LocalRootCFrame
                        })
                    else
                        VFXTidalWave(LocalRootCFrame)
                    end
                end
            end
        end

        task.wait(TidalWave.WaitTime)
    end
end)



task.spawn(function()
    while true do
        if not Running then
            break
        end

        if TidalWave.Enabled then
            local LocalRootCFrame = LocalRoot and LocalRoot.CFrame
            if LocalRootCFrame then
                PoseidonWaveEvent:FireServer(LocalRootCFrame)
                if not TidalWave.HideWaves then
                    if CanRequire then
                        VFXController.Play("Wave", nil, {
                            ["StartCFrame"] = LocalRootCFrame
                        })
                    else
                        VFXTidalWave(LocalRootCFrame)
                    end
                end
            end
        end

        task.wait(TidalWave.WaitTime)
    end
end)

local Window = Fluent:CreateWindow({
    Title = "Fish Hatchery",
    SubTitle = "Made by Nikoleto Scripts",
    Search = true,
    Icon = "home",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl,
    UserInfo = true,
    UserInfoTop = false,
    UserInfoTitle = LocalPlayer.DisplayName,
    UserInfoSubtitle = "User",
    UserInfoSubtitleColor = Color3.fromRGB(71, 123, 255)
})

Fluent:Notify({
    Title = "Nikoleto Scripts",
    Content = "Loading script..",
    Duration = 2.5
})

local MainTab = Window:AddTab({Title = "Main", Icon = ""})
local MiscTab = Window:AddTab({Title = "Misc", Icon = ""})

Fluent:CreateMinimizer({
    Icon = "home",
    Size = UDim2.fromOffset(44, 44),
    Position = UDim2.new(0, 320, 0, 24),
    Acrylic = true,
    Corner = 10,
    Transparency = 1,
    Draggable = true,
    Visible = true
})

local Options = Fluent.Options
MainTab:AddSection("Autofarm", "apple")
MainTab:AddParagraph({
    Content = "Make sure you have atleast ONE fish. | Fish Mode only works when in Medium-Range of the Reef."
})
MainTab:AddToggle("AutofarmToggle", {Title = "Enabled", Default = false}):OnChanged(function()
    Autofarm.Enabled = Options["AutofarmToggle"].Value
end)

MainTab:AddDropdown("AutofarmReefDropdown", {
    Title = "Target Reef",
    Values = {"Freshwater Reef", "Coral Reef", "Sun Reef", "Trash Reef", "Runic Reef"},
    Multi = false,
    Search = true,
    Default = 1,
}):OnChanged(function(SelectedReef)
    local CorrectedReefName = SelectedReef:gsub(" Reef", "")
    Autofarm.TargetReef = CorrectedReefName
end)
MainTab:AddSlider("AutofarmPower", {
    Title = "Power",
    Description = "The more, the faster but laggier. The less, the slower.",
    Default = Autofarm.Power,
    Min = 1,
    Max = 10,
    Rounding = 0,
}):OnChanged(function(Value)
    Autofarm.Power = Value
end)
MainTab:AddSection("AuraFarm", "waves")
MainTab:AddToggle("AuraFarmToggle", {Title = "AuraFarm", Default = false}):OnChanged(function()
    Autofarm.AuraFarm = Options["AuraFarmToggle"].Value
    while Autofarm.AuraFarm do
        if not Running then
            break
        end

        local Position = LocalRoot and LocalRoot.Position
        if Position then
            for Index = 1,360 do
                if Index % 10 == 0 then
                    for i = 1, Autofarm.Power do
                        local FinalCFrame = CFrame.new(Position) * CFrame.Angles(0, math.rad(Index), 0)
                        PoseidonWaveEvent:FireServer(FinalCFrame)
                        if not Autofarm.HideWaves then
                            if CanRequire then
                                VFXController.Play("Wave", nil, {
                                    ["StartCFrame"] = FinalCFrame
                                })
                            else
                                VFXTidalWave(FinalCFrame)
                            end
                        end
                        if not Autofarm.AuraFarm then
                            break
                        end
                        if i == (Autofarm.Power)  and tonumber(Autofarm.AuraGhosting) > 0 then
                            task.wait(Autofarm.AuraGhosting)
                        end
                    end
                end
            end
        end

        task.wait(Autofarm.AuraDelay)
    end
end)

MainTab:AddSlider("AuraFarmGhostingTime", {
    Title = "Ghosting Time",
    Description = "Delay between each wave",
    Default = Autofarm.AuraGhosting,
    Min = 0,
    Max = 0.1,
    Rounding = 3,
}):OnChanged(function(Value)
    Autofarm.AuraGhosting = Value
end)
MainTab:AddSlider("AuraFarmDelay", {
    Title = "Delay Time",
    Description = "Time in seconds that it waits until it spawns a Aura Farming Wave of waves",
    Default = Autofarm.AuraDelay,
    Min = 0.01,
    Max = 10,
    Rounding = 1,
}):OnChanged(function(Value)
    Autofarm.AuraDelay = Value
end)
MainTab:AddToggle("HideWavesToggle", {Title = "Hide Waves", Default = false}):OnChanged(function()
   TidalWave.HideWaves = Options["HideWavesToggle"].Value
end)

MainTab:AddSection("Ability Abuse", "apple")
MainTab:AddToggle("InfiniteTidalWaveToggle", {Title = "Infinite Tidal Wave", Default = false}):OnChanged(function()
    TidalWave.Enabled = Options["InfiniteTidalWaveToggle"].Value
end)
MainTab:AddSlider("TidalWaveWaitTime", {
    Title = "Wait Time",
    Description = "Time in seconds that it waits until it spawns a Tidal Wave",
    Default = TidalWave.WaitTime,
    Min = 0.01,
    Max = 10,
    Rounding = 1,
}):OnChanged(function(Value)
    TidalWave.WaitTime = Value
end)
MainTab:AddToggle("AuraFarmHideWavesToggle", {Title = "Hide Waves", Default = false}):OnChanged(function()
   Autofarm.HideWaves = Options["AuraFarmHideWavesToggle"].Value
end)


MiscTab:AddToggle("CFrameSpeed", {Title = "CFrame Speed", Default = false}):OnChanged(function()
    local Value = Options["CFrameSpeed"].Value

    if not Value then
        if Connections.CFrameSpeed then
            Connections.CFrameSpeed:Disconnect()
            Connections.CFrameSpeed = nil
        end
        return
    end

    Connections.CFrameSpeed = RunService.Heartbeat:Connect(function(Child)
        if LocalHumanoid and LocalRoot then
            local MoveDirection = LocalHumanoid.MoveDirection
            if MoveDirection.Magnitude > 0 then
                LocalRoot.CFrame += MoveDirection * CFrameSpeed.Value
            end
        end
    end)
end)
MiscTab:AddSlider("CFrameSpeedValue", {
    Title = "Speed Value",
    Default = 2,
    Min = 0,
    Max = 10,
    Rounding = 0,
}):OnChanged(function(Value)
    CFrameSpeed.Value = Value
end)

MiscTab:AddToggle("RemoveAllWaves", {Title = "Remove All Waves", Default = false}):OnChanged(function()
    RemoveAllWaves = Options["RemoveAllWaves"].Value
    if not RemoveAllWaves then
        if Connections.RemoveAllWaves then
            Connections.RemoveAllWaves:Disconnect()
            Connections.RemoveAllWavesnnection = nil
        end
        return
    end

    for _,Child in ipairs(workspace:GetChildren()) do
        if Child.Name == "Wave"  or Child.Name == "PoseidonHitbox" then
            Child:Destroy()
        end
    end

    Connections.RemoveAllWaves = workspace.ChildAdded:Connect(function(Child)
        if Child.Name == "Wave" or Child.Name == "PoseidonHitbox" then
            Child:Destroy()
        end
    end)

end)
MiscTab:AddToggle("EarBleed", {Title = "Ear Bleed", Default = false}):OnChanged(function()
    Bleed = Options["EarBleed"].Value
    while Bleed do
        if not Running then
            break
        end

        if LocalRoot then
            for _ = 1, 2 do
                TriggerAbilityEvent:FireServer(
                    nil,
                    "Rabbit Fish",
                    LocalRoot.Position,
                    "RabbitEnter"
                )
            end
        end

        task.wait()
    end
end)

MiscTab:AddButton({
    Title = "Lag Server",
    Description = "This lags the server what a surprise!!!",
    Callback = function()
        if Connections.Lag then
            Connections.Lag:Disconnect()
            Connections.Lag = nil
        end

        Connections.Lag = workspace.ChildAdded:Connect(function(Child)
            if Child.Name == "RabbitSFX" then
                Child:Destroy()
            end
        end)

        task.spawn(function()
            for Index = 1, 5000000 do
                TriggerAbilityEvent:FireServer(
                    nil,
                    "Rabbit Fish",
                    LocalRoot.Position,
                    "RabbitEnter"
                )

                if Index % 250 == 0 then
                    task.wait(0.001)
                end
            end
        end)
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Nikoleto Scripts",
    Content = "The script has been loaded.",
    Duration = 2.5
})

task.spawn(function()
    local FileFunctions = {
        listfiles = listfiles or list_files or function(...)
            return {}
        end,
        makefolder = makefolder or make_folder or createfolder or create_folder or function(...)
            return true
        end,
        isfolder = isfolder or is_folder or function(...)
            return false
        end,
        isfile = isfile or is_file or function(...)
            return false
        end,
        readfile = readfile or read_file or readfileasync or readfile_async or read_file_async or function(...)
            return "{}"
        end,
        writefile = writefile or write_file or writefileasync or writefile_async or write_file_async or function(...)
            return true
        end,
        delfile = delfile or del_file or deletefile or delete_file or function(...)
            return true
        end
    }
    local HttpService = GetService("HttpService")
	local httprequest = httprequest or http_request or request or HttpPost or (http and http.request) or (syn and syn.request) or function(...)
		return (...)
	end

	local function Invite(InviteCode)
		httprequest({
			Url = 'http://127.0.0.1:6463/rpc?v=1',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				Origin = 'https://discord.com'
			},
			Body = HttpService:JSONEncode({
				cmd = 'INVITE_BROWSER',
				nonce = HttpService:GenerateGUID(false),
				args = {code = InviteCode}
			})
		})
	end

	local VerifyChannelInvite = "DwRT2nH93D"
	local RulesChannelInvite = "jjEtFhA8PA"

	if FileFunctions.isfile("combat.cc/code") then
		if FileFunctions.readfile("combat.cc/code") == VerifyChannelInvite then
			FileFunctions.writefile("combat.cc/code", RulesChannelInvite)
		elseif FileFunctions.readfile("combat.cc/code") == RulesChannelInvite then
			Invite(RulesChannelInvite)
			return
		else
			FileFunctions.writefile("combat.cc/code", RulesChannelInvite)
			Invite(RulesChannelInvite)
			return
		end
	else
		FileFunctions.writefile("combat.cc/code", VerifyChannelInvite)
	end
	Invite(VerifyChannelInvite)
end)

task.spawn(function()
    repeat task.wait(0.5) until Fluent.Unloaded
    Running = false
    for Index, Connection in next, Connections do
        if Connection then
            Connection:Disconnect()
            Connections[Index] = nil
        end
    end
end)
