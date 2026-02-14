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
local FishHarvestEvent = Remotes:WaitForChild("FishHarvestEvent")
local PoseidonWaveEvent = Remotes:WaitForChild("PoseidonWaveEvent")

local Autofarm = {
    Enabled = false,
    TargetFishSlot = "1",
    Fish = true,
    TidalWave = true,
    TargetReef = "Freshwater",
    Power = 5,
    TidalWaveWaitTime = 0.5,
    HideWaves = false
}

local TidalWave = {
    Enabled = false,
    WaitTime = 0.5,
}

local OwnedAquarium = nil

while not OwnedAquarium do
    for _,Aquarium in ipairs(workspace:WaitForChild("Aquariums"):GetChildren()) do
        if Aquarium:WaitForChild("Ownership"):WaitForChild("SurfaceGui"):WaitForChild("TextLabel").Text == LocalPlayer.Name .. "'s Aquarium" then
            OwnedAquarium = Aquarium
            break
        end
    end

    task.wait()
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

local AutofarmTidalWaveCFrames = {
    CFrame.new(
        -1.756241798400879, -41.40367889404297, 191.4381103515625,
        0.02269931137561798, -6.745948866182516e-08, -0.999742329120636,
        -4.42200125405634e-08, 1, -6.84808938444803e-08,
        0.999742329120636, 4.5763087541672576e-08, 0.02269931137561798
    ),
    CFrame.new(
        140.00296020507812, -41.403682708740234, 187.69577026367188,
        0.00968069490045309, -6.682029862759009e-08, 0.9999531507492065,
        -4.533760034064471e-08, 1, 6.726234857978852e-08,
        -0.9999531507492065, -4.59866242863427e-08, 0.00968069490045309
    ),
    CFrame.new(
        48.21647644042969, -41.403682708740234, 220.81695556640625,
        0.9998974204063416, -4.028627387242523e-08, 0.014322840608656406,
        4.067929637585621e-08, 1, -2.7148935544119013e-08,
        -0.014322840608656406, 2.7728793483561276e-08, 0.9998974204063416
    ),
    CFrame.new(
        47.56522750854492, -41.403682708740234, 161.9040069580078,
        -0.9998764395713806, -1.0644274794913144e-07, -0.015719223767518997,
        -1.0642960290851988e-07, 1, -1.6731991347995745e-09,
        0.015719223767518997, -1.6858566629420488e-15, -0.9998764395713806
    )
}

task.spawn(function()
    while true do
        if not Running then
            break
        end

        if Autofarm.Enabled and Autofarm.Fish then
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

local LocalCharacter = nil
local LocalHumanoid = nil
local LocalHead = nil
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

    if not LocalHead or LocalHead.Parent ~= LocalCharacter then
        LocalHead = LocalCharacter:FindFirstChild("Head")
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

        if Autofarm.Enabled and Autofarm.TidalWave then
            for _,CFrameValue in next, AutofarmTidalWaveCFrames do
                PoseidonWaveEvent:FireServer(CFrameValue)
                if not Autofarm.HideWaves then
                    if CanRequire then
                        VFXController.Play("Wave", nil, {
                            ["StartCFrame"] = CFrameValue
                        })
                    else
                        VFXTidalWave(CFrameValue)
                    end
                end
            end
        end

        task.wait(Autofarm.TidalWaveWaitTime)
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

local MainTab = Window:AddTab({ Title = "Main", Icon = "" })

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
    Content = "Make sure you have atleast ONE fish. | Fish Mode only works when in Medium-Range of the Reef. | Tidal Waves may not do anything unless you are standing inside of the Reef."
})
MainTab:AddToggle("AutofarmToggle", {Title = "Enabled", Default = false}):OnChanged(function()
    Autofarm.Enabled = Options["AutofarmToggle"].Value
end)
MainTab:AddDropdown("AutofarmModes", {
    Title = "Modes",
    Values = {"Fish", "Tidal Wave [BUGGY]"},
    Multi = true,
    Search = false,
    Default = {"Fish", "Tidal Wave [BUGGY]"},
}):OnChanged(function(Values)
    Autofarm.Fish = Values["Fish"]
    Autofarm.TidalWave = Values["Tidal Wave [BUGGY]"]
end)
MainTab:AddDropdown("AutofarmReefDropdown", {
    Title = "Target Reef",
    Values = {"Freshwater Reef", "Coral Reef", "Sun Reef", "Trash Reef", "Runic Reef"},
    Multi = false,
    Search = true,
    Default = 1,
}):OnChanged(function(SelectedReef)
    local CorrectedReefName = SelectedReef:gsub(" Reef", "")
    if CorrectedReefName == "Freshwater" then
        AutofarmTidalWaveCFrames = {
            CFrame.new(
                -1.756241798400879, -41.40367889404297, 191.4381103515625,
                0.02269931137561798, -6.745948866182516e-08, -0.999742329120636,
                -4.42200125405634e-08, 1, -6.84808938444803e-08,
                0.999742329120636, 4.5763087541672576e-08, 0.02269931137561798
            ),
            CFrame.new(
                140.00296020507812, -41.403682708740234, 187.69577026367188,
                0.00968069490045309, -6.682029862759009e-08, 0.9999531507492065,
                -4.533760034064471e-08, 1, 6.726234857978852e-08,
                -0.9999531507492065, -4.59866242863427e-08, 0.00968069490045309
            ),
            CFrame.new(
                48.21647644042969, -41.403682708740234, 220.81695556640625,
                0.9998974204063416, -4.028627387242523e-08, 0.014322840608656406,
                4.067929637585621e-08, 1, -2.7148935544119013e-08,
                -0.014322840608656406, 2.7728793483561276e-08, 0.9998974204063416
            ),
            CFrame.new(
                47.56522750854492, -41.403682708740234, 161.9040069580078,
                -0.9998764395713806, -1.0644274794913144e-07, -0.015719223767518997,
                -1.0642960290851988e-07, 1, -1.6731991347995745e-09,
                0.015719223767518997, -1.6858566629420488e-15, -0.9998764395713806
            )
        }
    elseif CorrectedReefName == "Coral" then
        AutofarmTidalWaveCFrames = {
            CFrame.new(
                -55.61285400390625, -41.403682708740234, 281.758056640625,
                0.7428443431854248, 3.9228016390779885e-08, 0.6694641709327698,
                -1.1597668603258171e-08, 1, -4.572724421336716e-08,
                -0.6694641709327698, 2.620400252340005e-08, 0.7428443431854248
            ),
            CFrame.new(
                -97.00995635986328, -41.460594177246094, 227.90188598632812,
                -0.8271548748016357, -0.029434120282530785, -0.5612026453018188,
                -0.03034823015332222, 0.9995098114013672, -0.007692417129874229,
                0.5611539483070374, 0.010668686591088772, -0.8276426792144775
            ),
            CFrame.new(
                -98.77522277832031, -41.403682708740234, 282.5738830566406,
                0.7321361303329468, -6.038491373594468e-10, -0.6811583638191223,
                -1.9885737501113e-10, 1, -1.1002431188344985e-09,
                0.6811583638191223, 9.409810708405075e-10, 0.7321361303329468
            ),
            CFrame.new(
                -55.12545394897461, -41.403682708740234, 227.2285919189453,
                -0.7813646793365479, 7.454901407299985e-08, 0.6240747570991516,
                1.269226572730986e-07, 1, 3.9456583778019194e-08,
                -0.6240747570991516, 1.1003920263874534e-07, -0.7813646793365479
            )
        }
    elseif CorrectedReefName == "Sun" then
        AutofarmTidalWaveCFrames = {
            CFrame.new(
                218.0973663330078, -13.403681755065918, 200.8609161376953,
                -0.5056483745574951, 5.137969338875337e-08, -0.8627396821975708,
                3.5820875154968235e-08, 1, 3.855963726095979e-08,
                0.8627396821975708, -1.1406472211206165e-08, -0.5056483745574951
            ),
            CFrame.new(
                257.7535095214844, -13.403681755065918, 245.842041015625,
                0.5032373666763306, -4.3118173920220215e-08, 0.8641482591629028,
                -4.366950889789223e-08, 1, 7.53277049625467e-08,
                -0.8641482591629028, -7.56446425498325e-08, 0.5032373666763306
            )
        }
    elseif CorrectedReefName == "Trash" then
        AutofarmTidalWaveCFrames = {
            CFrame.new(
                77.00115966796875, -46.903682708740234, 340.37713623046875,
                -0.5733716487884521, -1.6302170280368955e-08, 0.8192954063415527,
                9.032089565153001e-08, 1, 8.310752264151233e-08,
                -0.8192954063415527, 1.2165098439709254e-07, -0.5733716487884521
            ),
            CFrame.new(
                10.314037322998047, -46.903682708740234, 386.12042236328125,
                0.5502718687057495, -4.864546809812964e-08, -0.8349855542182922,
                -1.842845520627634e-08, 1, -7.040376459599429e-08,
                0.8349855542182922, 5.412870507370826e-08, 0.5502718687057495
            ),
            CFrame.new(
                76.26141357421875, -46.903682708740234, 386.5351257324219,
                0.6872749328613281, 5.091568766601995e-08, 0.7263973951339722,
                -3.063244946588384e-08, 1, -4.1110791215714926e-08,
                -0.7263973951339722, 6.003082919647795e-09, 0.6872749328613281
            ),
            CFrame.new(
                9.675196647644043, -46.903682708740234, 340.46600341796875,
                -0.6488456130027771, 9.523725807980554e-09, -0.7609201073646545,
                9.987236637698516e-08, 1, -7.264628720804467e-08,
                0.7609201073646545, -1.231311159699544e-07, -0.6488456130027771
            )
        }
    elseif CorrectedReefName == "Runic" then
        AutofarmTidalWaveCFrames = {
            CFrame.new(
                -92.8479232788086, -58.653682708740234, 470.51123046875,
                -0.35943731665611267, 1.7787476380703993e-08, 0.9331692457199097,
                -2.4517401442381015e-08, 1, -2.8504953064611982e-08,
                -0.9331692457199097, -3.3124628373570886e-08, -0.35943731665611267
            ),
            CFrame.new(
                -197.79486083984375, -58.653682708740234, 459.2013854980469,
                -0.24148662388324738, 7.88187914935179e-09, -0.9704041481018066,
                -4.8835278043668495e-09, 1, 9.337537854037237e-09,
                0.9704041481018066, 6.9938859148521715e-09, -0.24148662388324738
            )
        }
    end
    Autofarm.TargetReef = CorrectedReefName
end)
MainTab:AddSlider("AutofarmPower", {
    Title = "Power",
    Description = "The more, the faster but laggier. The less, the slower.",
    Default = Autofarm.Power,
    Min = 1,
    Max = 10,
    Rounding = 1,
}):OnChanged(function(Value)
    Autofarm.Power = Value
end)
MainTab:AddSlider("AutofarmTidalWaveWaitTime", {
    Title = "Tidal Wave Wait Time",
    Description = "Time in seconds that it waits until it spawns a Tidal Wave",
    Default = Autofarm.TidalWaveWaitTime,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
}):OnChanged(function(Value)
    Autofarm.TidalWaveWaitTime = Value
end)
MainTab:AddToggle("AutofarmHideWaves", {Title = "Hide Waves", Default = false}):OnChanged(function()
    Autofarm.HideWaves = Options["AutofarmHideWaves"].Value
end)

MainTab:AddSection("Ability Abuse", "apple")
MainTab:AddToggle("InfiniteTidalWaveToggle", {Title = "Infinite Tidal Wave", Default = false}):OnChanged(function()
    TidalWave.Enabled = Options["InfiniteTidalWaveToggle"].Value
end)
MainTab:AddSlider("TidalWaveWaitTime", {
    Title = "Wait Time",
    Description = "Time in seconds that it waits until it spawns a Tidal Wave",
    Default = TidalWave.WaitTime,
    Min = 0.1,
    Max = 10,
    Rounding = 1,
}):OnChanged(function(Value)
    TidalWave.WaitTime = Value
end)
MainTab:AddToggle("HideWavesToggle", {Title = "Hide Waves", Default = false}):OnChanged(function()
   TidalWave.HideWaves = Options["HideWavesToggle"].Value
end)

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
end)
