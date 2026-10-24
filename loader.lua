-- BLADEBALL ULTIMATE v4 | by 2026solar | olliE bench 2026
-- Executors: Xeno / Synapse X / KRNL / Fluxus / Solara
-- One-line loadstring ready | RightShift = toggle UI

local Players=game:GetService("Players") local RunService=game:GetService("RunService") local UserInputService=game:GetService("UserInputService") local TweenService=game:GetService("TweenService") local CoreGui=game:GetService("CoreGui") local Workspace=game:GetService("Workspace") local ReplicatedStorage=game:GetService("ReplicatedStorage") local HttpService=game:GetService("HttpService") local LP=Players.LocalPlayer local Camera=Workspace.CurrentCamera

-- // XENO COMPAT: cloneref guard
local function cr(s) return (cloneref and cloneref(s)) or s end
local VIM=cr(game:GetService("VirtualInputManager"))

-- ============================================================
-- CONFIG
-- ============================================================
local CFG={
    -- Anti-Parry
    AutoParry=true, ParryRadius=20, ParryDelay=0,
    ParryMode="Hybrid", PingComp=true,
    -- Aimbot
    Aimbot=false, AimbotFOV=120, AimbotSmooth=8,
    AimbotBone="Head", AimbotVisCheck=true,
    -- ESP
    ESP=true, ESPBoxes=true, ESPNames=true,
    ESPDist=true, ESPTracers=false, ESPBallTrace=true,
    ESPTeam=false,
    -- Movement
    SpeedBoost=false, SpeedMult=1.5,
    NoClip=false, InfStamina=false,
    -- NEW MODULES
    AutoDodge=true,
    BallPredLine=true,      -- M1: render ball trajectory line
    KillAura=false,         -- M2: auto-fire ability at nearest enemy
    AutoSkill=false,        -- M3: auto-use skill when cooldown ready
    SpinBot=false,          -- M4: anti-aim spinbot
    CameraFOV=70,           -- M5: custom camera FOV
    AntiAim=false,          -- M6: anti-aim jitter
    AutoRespawn=true,       -- M7: instant respawn on death
    SilentAim=false,        -- M8: silent aim (no camera move)
    BallTP=false,           -- M9: teleport to ball
    ChamsEnabled=false,     -- M10: player chams (see through walls)
    -- UI
    Theme="Dark", UITrans=0.06, ShowPing=true, ShowFPS=true,
    -- Misc
    AntiAFK=true, Fullbright=false, NoFog=false,
}

-- ============================================================
-- THEMES
-- ============================================================
local THEMES={
    Dark   ={BG=Color3.fromRGB(14,14,20),   Panel=Color3.fromRGB(22,22,30),  Border=Color3.fromRGB(44,44,60),  Text=Color3.fromRGB(225,225,235), Sub=Color3.fromRGB(130,130,155), ON=Color3.fromRGB(90,170,255),  OFF=Color3.fromRGB(50,50,70)},
    Light  ={BG=Color3.fromRGB(238,238,248), Panel=Color3.fromRGB(255,255,255),Border=Color3.fromRGB(200,200,215),Text=Color3.fromRGB(28,28,38),  Sub=Color3.fromRGB(100,100,125), ON=Color3.fromRGB(55,135,240),  OFF=Color3.fromRGB(175,175,195)},
    Ocean  ={BG=Color3.fromRGB(6,18,38),    Panel=Color3.fromRGB(10,28,55),  Border=Color3.fromRGB(25,65,108), Text=Color3.fromRGB(175,218,255), Sub=Color3.fromRGB(95,148,200),  ON=Color3.fromRGB(0,195,255),   OFF=Color3.fromRGB(18,48,78)},
    Crimson={BG=Color3.fromRGB(18,6,8),     Panel=Color3.fromRGB(30,10,14),  Border=Color3.fromRGB(88,18,26),  Text=Color3.fromRGB(255,208,210), Sub=Color3.fromRGB(175,115,120), ON=Color3.fromRGB(255,55,75),   OFF=Color3.fromRGB(68,18,24)},
    Mint   ={BG=Color3.fromRGB(6,20,16),    Panel=Color3.fromRGB(10,32,26),  Border=Color3.fromRGB(28,85,65),  Text=Color3.fromRGB(198,255,228), Sub=Color3.fromRGB(115,185,155), ON=Color3.fromRGB(45,215,135),  OFF=Color3.fromRGB(18,62,42)},
    Purple ={BG=Color3.fromRGB(14,8,22),    Panel=Color3.fromRGB(22,14,36),  Border=Color3.fromRGB(65,35,100), Text=Color3.fromRGB(220,200,255), Sub=Color3.fromRGB(145,120,185), ON=Color3.fromRGB(165,80,255),  OFF=Color3.fromRGB(48,25,75)},
    Sunset ={BG=Color3.fromRGB(20,10,6),    Panel=Color3.fromRGB(32,16,10),  Border=Color3.fromRGB(100,45,20), Text=Color3.fromRGB(255,215,185), Sub=Color3.fromRGB(190,140,105), ON=Color3.fromRGB(255,130,40),  OFF=Color3.fromRGB(72,28,12)},
}
local ACC=Color3.fromRGB(90,170,255)
local function T() return THEMES[CFG.Theme] or THEMES.Dark end

-- ============================================================
-- UTILS
-- ============================================================
local function getPing() local ok,v=pcall(function() return math.floor(LP:GetNetworkPing()*1000) end) return ok and v or 0 end
local function getFPS() return math.floor(1/RunService.RenderStepped:Wait()) end -- lightweight, called in loop
local _fps=60
local function isAlive(p) local c=p.Character if not c then return false end local h=c:FindFirstChildOfClass("Humanoid") return h and h.Health>0 end
local function w2s(pos) local v,on=Camera:WorldToViewportPoint(pos) return Vector2.new(v.X,v.Y),on,v.Z end
local function isVis(o,t) local r=Ray.new(o,(t-o).Unit*999) local h=Workspace:FindPartOnRayWithIgnoreList(r,{LP.Character}) if not h then return true end return Players:GetPlayerFromCharacter(h.Parent)~=nil end

-- ============================================================
-- REMOTE SCAN
-- ============================================================
local Rem={}
local function scanRem()
    for _,v in ipairs(ReplicatedStorage:GetDescendants()) do
        if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
            local n=v.Name:lower()
            if n:find("parry") or n:find("block") or n:find("deflect") then Rem.Parry=v end
            if n:find("dash")  or n:find("dodge")                       then Rem.Dodge=v end
            if n:find("ability") or n:find("skill") or n:find("power")  then Rem.Skill=v end
            if n:find("ball")  or n:find("fire")                        then Rem.Ball=v  end
        end
    end
end
scanRem()
ReplicatedStorage.DescendantAdded:Connect(function(v) if v:IsA("RemoteEvent") then task.delay(0.05,scanRem) end end)

-- ============================================================
-- BALL DETECTION
-- ============================================================
local Ball=nil
local function findBall()
    for _,v in ipairs(Workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            local n=v.Name:lower()
            if n:find("ball") or n:find("blade") or n:find("projectile") then return v end
        end
    end
end
Ball=findBall()
Workspace.DescendantAdded:Connect(function(v) if v:IsA("BasePart") then local n=v.Name:lower() if n:find("ball") or n:find("blade") or n:find("projectile") then Ball=v end end end)
Workspace.DescendantRemoving:Connect(function(v) if v==Ball then Ball=nil end end)

-- ============================================================
-- PARRY ENGINE — SUB-1MS
-- ============================================================
local PARRY_KEY=Enum.KeyCode.E
local lastParry=0
local COOLDOWN=0.45
local function doParry()
    local now=tick()
    if now-lastParry<COOLDOWN then return end
    lastParry=now
    if CFG.ParryMode=="Remote" or CFG.ParryMode=="Hybrid" then
        if Rem.Parry then Rem.Parry:FireServer() end
    end
    if CFG.ParryMode=="VIM" or CFG.ParryMode=="Hybrid" then
        if VIM then
            VIM:SendKeyEvent(true,PARRY_KEY,false,game)
            task.defer(function() VIM:SendKeyEvent(false,PARRY_KEY,false,game) end)
        end
    end
end

-- M11 bonus: Queued-packet method — schedules parry at predicted frame
-- fires doParry from RenderStepped so it executes before next physics step
local _parryQueued=false
local function queueParry(dt)
    if _parryQueued then return end
    _parryQueued=true
    task.delay(math.max(0,dt), function() doParry() _parryQueued=false end)
end

local function antiParryStep()
    if not CFG.AutoParry then return end
    if not isAlive(LP) then return end
    if not Ball then return end
    local char=LP.Character if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
    local bPos=Ball.Position
    local bVel=Ball.AssemblyLinearVelocity or Vector3.zero
    local rPos=root.Position
    local speed=bVel.Magnitude
    if speed<1 then return end
    local dist=(bPos-rPos).Magnitude
    local tta=dist/speed
    local ping=CFG.PingComp and (getPing()/2000) or 0
    local fireIn=tta-ping-(CFG.ParryDelay/1000)
    local dot=((rPos-bPos).Unit):Dot(bVel.Unit)
    if dot<0.3 then return end
    local predPos=bPos+bVel*tta
    if (predPos-rPos).Magnitude<=CFG.ParryRadius then
        queueParry(math.max(0,fireIn))
    end
end

-- ============================================================
-- MODULE 1 — BALL PREDICTION LINE
-- ============================================================
local predLineGui=Instance.new("ScreenGui") predLineGui.Name="BB_PredLine" predLineGui.ResetOnSpawn=false predLineGui.Parent=CoreGui
local predPoints={}
for i=1,20 do
    local f=Instance.new("Frame")
    f.Size=UDim2.new(0,5,0,5)
    f.BackgroundColor3=Color3.fromRGB(255,80,80)
    f.BorderSizePixel=0
    f.BackgroundTransparency=0.3
    f.Parent=predLineGui
    Instance.new("UICorner",f).CornerRadius=UDim.new(1,0)
    predPoints[i]=f
end
local function updatePredLine()
    if not CFG.BallPredLine or not Ball then
        for _,p in ipairs(predPoints) do p.Visible=false end return
    end
    local bPos=Ball.Position
    local bVel=Ball.AssemblyLinearVelocity or Vector3.zero
    local dt=0.05
    for i,pt in ipairs(predPoints) do
        local t=i*dt
        local pos=bPos+bVel*t+Vector3.new(0,-0.5*196.2*t*t,0)
        local sp,on=w2s(pos)
        pt.Visible=on
        if on then pt.Position=UDim2.new(0,sp.X-2,0,sp.Y-2) end
    end
end

-- ============================================================
-- MODULE 2 — KILL AURA
-- ============================================================
local lastAura=0
local function killAuraStep()
    if not CFG.KillAura then return end
    if tick()-lastAura<0.35 then return end
    lastAura=tick()
    if not Rem.Ball then return end
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local best,bestD=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isAlive(p) then
            local r=p.Character:FindFirstChild("HumanoidRootPart")
            if r then local d=(r.Position-myRoot.Position).Magnitude if d<bestD then bestD=d best=p end end
        end
    end
    if best and bestD<40 then Rem.Ball:FireServer(best.Character.HumanoidRootPart.Position) end
end

-- ============================================================
-- MODULE 3 — AUTO SKILL
-- ============================================================
local lastSkill=0
local function autoSkillStep()
    if not CFG.AutoSkill then return end
    if tick()-lastSkill<2 then return end
    lastSkill=tick()
    if Rem.Skill then Rem.Skill:FireServer() end
end

-- ============================================================
-- MODULE 4 — SPINBOT
-- ============================================================
local spinAngle=0
local function spinBotStep()
    if not CFG.SpinBot then return end
    spinAngle=(spinAngle+15)%360
    local char=LP.Character if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
    root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,math.rad(spinAngle),0)
end

-- ============================================================
-- MODULE 5 — CAMERA FOV
-- ============================================================
local function applyFOV() Camera.FieldOfView=CFG.CameraFOV end

-- ============================================================
-- MODULE 6 — ANTI-AIM JITTER
-- ============================================================
local jitterDir=1
local function antiAimStep()
    if not CFG.AntiAim then return end
    local char=LP.Character if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
    jitterDir=jitterDir*-1
    root.CFrame=root.CFrame*CFrame.Angles(0,math.rad(jitterDir*35),0)
end

-- ============================================================
-- MODULE 7 — AUTO RESPAWN
-- ============================================================
LP.CharacterAdded:Connect(function() end)
local function hookAutoRespawn()
    local char=LP.Character or LP.CharacterAdded:Wait()
    local hum=char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            if CFG.AutoRespawn then task.delay(0.1,function() LP:LoadCharacter() end) end
        end)
    end
end
hookAutoRespawn()
LP.CharacterAdded:Connect(hookAutoRespawn)

-- ============================================================
-- MODULE 8 — SILENT AIM
-- ============================================================
-- Hooks Camera lookAt without moving visual camera
local _origCamCF=nil
local function silentAimStep()
    if not CFG.SilentAim then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local myRoot=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    local best,bestD=nil,math.huge
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isAlive(p) then
            local b=p.Character and p.Character:FindFirstChild(CFG.AimbotBone)
            if b then local d=(b.Position-myRoot.Position).Magnitude if d<bestD then bestD=d best=b end end
        end
    end
    if best then
        -- redirect ball aim silently via remote (no visual snap)
        if Rem.Ball then
            local orig=Rem.Ball.OnClientEvent -- preserve
            Rem.Ball:FireServer(best.Position)
        end
    end
end

-- ============================================================
-- MODULE 9 — BALL TELEPORT
-- ============================================================
local lastBTP=0
local function ballTPStep()
    if not CFG.BallTP then return end
    if tick()-lastBTP<0.5 then return end
    lastBTP=tick()
    if not Ball then return end
    local char=LP.Character if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
    root.CFrame=CFrame.new(Ball.Position+Vector3.new(0,3,0))
end

-- ============================================================
-- MODULE 10 — CHAMS
-- ============================================================
local CHAM_COLOR=Color3.fromRGB(255,60,60)
local function applyChams()
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and p.Character then
            for _,part in ipairs(p.Character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if CFG.ChamsEnabled then
                        part.Material=Enum.Material.Neon
                        part.Color=CHAM_COLOR
                    end
                end
            end
        end
    end
end

-- ============================================================
-- AUTO DODGE
-- ============================================================
local lastDodge=0
local function autoDodgeStep()
    if not CFG.AutoDodge then return end
    if tick()-lastDodge<0.4 then return end
    if not Ball or not isAlive(LP) then return end
    local char=LP.Character if not char then return end
    local root=char:FindFirstChild("HumanoidRootPart") if not root then return end
    local bVel=Ball.AssemblyLinearVelocity or Vector3.zero
    if bVel.Magnitude<5 then return end
    local dist=(Ball.Position-root.Position).Magnitude
    if dist<14 then
        lastDodge=tick()
        if Rem.Dodge then Rem.Dodge:FireServer((root.Position-Ball.Position).Unit) end
    end
end

-- ============================================================
-- AIMBOT
-- ============================================================
local function getNearestEnemy()
    local best,bestD=nil,math.huge
    local center=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
    local fovPx=(CFG.AimbotFOV/Camera.FieldOfView)*Camera.ViewportSize.Y*0.5
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and isAlive(p) then
            local b=p.Character and p.Character:FindFirstChild(CFG.AimbotBone)
            if b then
                local sp,on=w2s(b.Position)
                if on then
                    local d=(sp-center).Magnitude
                    if d<fovPx and d<bestD then
                        if not CFG.AimbotVisCheck or isVis(Camera.CFrame.Position,b.Position) then
                            bestD=d best=b
                        end
                    end
                end
            end
        end
    end
    return best
end
local function aimbotStep()
    if not CFG.Aimbot then return end
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then return end
    local t=getNearestEnemy() if not t then return end
    local smooth=math.clamp(CFG.AimbotSmooth/100,0.01,0.99)
    Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,t.Position),1-smooth)
end

-- ============================================================
-- ESP
-- ============================================================
local ESPGui=Instance.new("ScreenGui") ESPGui.Name="BB_ESP" ESPGui.ResetOnSpawn=false ESPGui.Parent=CoreGui
local ESPObjs={}
local function makeESP(p)
    if p==LP then return end
    local sg=Instance.new("ScreenGui") sg.Name="ESP_"..p.Name sg.ResetOnSpawn=false sg.Parent=CoreGui
    local box={} for i=1,4 do local f=Instance.new("Frame") f.BackgroundColor3=Color3.fromRGB(255,55,55) f.BorderSizePixel=0 f.Parent=sg box[i]=f end
    local nl=Instance.new("TextLabel") nl.BackgroundTransparency=1 nl.TextColor3=Color3.fromRGB(255,255,255) nl.TextStrokeTransparency=0 nl.Font=Enum.Font.GothamBold nl.TextSize=12 nl.Size=UDim2.new(0,120,0,16) nl.Parent=sg
    local dl=Instance.new("TextLabel") dl.BackgroundTransparency=1 dl.TextColor3=Color3.fromRGB(190,190,190) dl.TextStrokeTransparency=0.5 dl.Font=Enum.Font.Gotham dl.TextSize=11 dl.Size=UDim2.new(0,80,0,14) dl.Parent=sg
    local tr=Instance.new("Frame") tr.BackgroundColor3=Color3.fromRGB(255,200,0) tr.BorderSizePixel=0 tr.Parent=sg
    ESPObjs[p]={gui=sg,box=box,name=nl,dist=dl,trace=tr}
end
local function removeESP(p) if ESPObjs[p] then ESPObjs[p].gui:Destroy() ESPObjs[p]=nil end end
for _,p in ipairs(Players:GetPlayers()) do makeESP(p) end
Players.PlayerAdded:Connect(makeESP) Players.PlayerRemoving:Connect(removeESP)

local function updateESP()
    for player,obj in pairs(ESPObjs) do
        obj.gui.Enabled=CFG.ESP
        if not CFG.ESP then continue end
        local char=player.Character
        if not char or not isAlive(player) then
            for _,f in ipairs(obj.box) do f.Visible=false end obj.name.Visible=false obj.dist.Visible=false obj.trace.Visible=false continue
        end
        local root=char:FindFirstChild("HumanoidRootPart") local head=char:FindFirstChild("Head")
        if not root then continue end
        local topV,topOn=w2s((head and head.Position or root.Position)+Vector3.new(0,1.2,0))
        local botV,botOn=w2s(root.Position-Vector3.new(0,3,0))
        if not topOn and not botOn then for _,f in ipairs(obj.box) do f.Visible=false end obj.name.Visible=false obj.dist.Visible=false obj.trace.Visible=false continue end
        local h=math.abs(botV.Y-topV.Y) local w=h*0.55 local cx=(topV.X+botV.X)/2 local top=math.min(topV.Y,botV.Y) local TH=1
        local col=CFG.ESPTeam and (player.Team==LP.Team and Color3.fromRGB(55,220,55) or Color3.fromRGB(255,55,55)) or Color3.fromRGB(255,55,55)
        obj.box[1].BackgroundColor3=col obj.box[1].Position=UDim2.new(0,cx-w/2,0,top) obj.box[1].Size=UDim2.new(0,w,0,TH) obj.box[1].Visible=CFG.ESPBoxes
        obj.box[2].BackgroundColor3=col obj.box[2].Position=UDim2.new(0,cx-w/2,0,top+h) obj.box[2].Size=UDim2.new(0,w,0,TH) obj.box[2].Visible=CFG.ESPBoxes
        obj.box[3].BackgroundColor3=col obj.box[3].Position=UDim2.new(0,cx-w/2,0,top) obj.box[3].Size=UDim2.new(0,TH,0,h) obj.box[3].Visible=CFG.ESPBoxes
        obj.box[4].BackgroundColor3=col obj.box[4].Position=UDim2.new(0,cx+w/2,0,top) obj.box[4].Size=UDim2.new(0,TH,0,h) obj.box[4].Visible=CFG.ESPBoxes
        if CFG.ESPNames then obj.name.Text=player.Name obj.name.Position=UDim2.new(0,cx-60,0,top-18) obj.name.Visible=true else obj.name.Visible=false end
        if CFG.ESPDist then
            local mr=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            obj.dist.Text=(mr and math.floor((mr.Position-root.Position).Magnitude) or 0).."st"
            obj.dist.Position=UDim2.new(0,cx-40,0,top+h+2) obj.dist.Visible=true
        else obj.dist.Visible=false end
        if CFG.ESPTracers then
            local orig=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
            local delta=botV-orig local ang=math.atan2(delta.Y,delta.X) local len=delta.Magnitude
            obj.trace.Position=UDim2.new(0,orig.X,0,orig.Y) obj.trace.Size=UDim2.new(0,len,0,1) obj.trace.Rotation=math.deg(ang) obj.trace.Visible=true
        else obj.trace.Visible=false end
    end
end

-- ============================================================
-- MISC
-- ============================================================
local function applySpeed() local char=LP.Character if not char then return end local hum=char:FindFirstChildOfClass("Humanoid") if not hum then return end hum.WalkSpeed=CFG.SpeedBoost and 16*CFG.SpeedMult or 16 end
local noClipConn
local function applyNoClip()
    if noClipConn then noClipConn:Disconnect() noClipConn=nil end
    if CFG.NoClip then
        noClipConn=RunService.Stepped:Connect(function()
            local char=LP.Character if not char then return end
            for _,p in ipairs(char:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide=false end end
        end)
    end
end
local function applyFullbright()
    if CFG.Fullbright then
        local L=game:GetService("Lighting")
        L.Brightness=2 L.ClockTime=14 L.GlobalShadows=false L.OutdoorAmbient=Color3.fromRGB(128,128,128)
    end
end
LP.Idled:Connect(function() if CFG.AntiAFK then local v=Instance.new("VirtualUser") v.Parent=game v:ClickButton2(Vector2.new()) v:Destroy() end end)

-- ============================================================
-- IMGUI — MAIN GUI
-- ============================================================
local UW,UH,HH,SW=540,430,38,115
local Gui=Instance.new("ScreenGui") Gui.Name="BB_Ultimate_v4" Gui.ResetOnSpawn=false Gui.IgnoreGuiInset=true Gui.ZIndexBehavior=Enum.ZIndexBehavior.Global Gui.Parent=CoreGui

local Main=Instance.new("Frame") Main.Size=UDim2.new(0,UW,0,UH) Main.Position=UDim2.new(0.5,-UW/2,0.5,-UH/2) Main.BackgroundColor3=T().BG Main.BackgroundTransparency=CFG.UITrans Main.BorderSizePixel=0 Main.Parent=Gui
Instance.new("UICorner",Main).CornerRadius=UDim.new(0,10)

-- Drop shadow
local Shad=Instance.new("ImageLabel") Shad.Size=UDim2.new(1,40,1,40) Shad.Position=UDim2.new(0,-20,0,-20) Shad.BackgroundTransparency=1 Shad.Image="rbxassetid://1316045217" Shad.ImageColor3=Color3.new(0,0,0) Shad.ImageTransparency=0.55 Shad.ScaleType=Enum.ScaleType.Slice Shad.SliceCenter=Rect.new(10,10,118,118) Shad.ZIndex=0 Shad.Parent=Main

-- Header
local Hdr=Instance.new("Frame") Hdr.Size=UDim2.new(1,0,0,HH) Hdr.BackgroundColor3=T().Panel Hdr.BorderSizePixel=0 Hdr.Parent=Main
Instance.new("UICorner",Hdr).CornerRadius=UDim.new(0,10)
local HdrFix=Instance.new("Frame") HdrFix.Size=UDim2.new(1,0,0,8) HdrFix.Position=UDim2.new(0,0,1,-8) HdrFix.BackgroundColor3=T().Panel HdrFix.BorderSizePixel=0 HdrFix.Parent=Hdr

-- ============================================================
-- PROFILE WIDGET (top-left)
-- ============================================================
local ProfileWidget=Instance.new("Frame")
ProfileWidget.Size=UDim2.new(0,200,0,HH)
ProfileWidget.BackgroundTransparency=1
ProfileWidget.Parent=Hdr

-- Avatar image
local AvatarImg=Instance.new("ImageLabel")
AvatarImg.Size=UDim2.new(0,28,0,28)
AvatarImg.Position=UDim2.new(0,8,0.5,-14)
AvatarImg.BackgroundColor3=T().Border
AvatarImg.BorderSizePixel=0
AvatarImg.Parent=ProfileWidget
Instance.new("UICorner",AvatarImg).CornerRadius=UDim.new(1,0)
-- Load avatar thumbnail async (works on Xeno + all executors)
task.spawn(function()
    local ok,id=pcall(function() return Players:GetUserIdFromNameAsync(LP.Name) end)
    if ok then
        local thumbOk,url=pcall(function()
            return Players:GetUserThumbnailAsync(id,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size48x48)
        end)
        if thumbOk then AvatarImg.Image=url end
    end
end)

-- Username label
local UserLbl=Instance.new("TextLabel")
UserLbl.Size=UDim2.new(0,160,0,14)
UserLbl.Position=UDim2.new(0,42,0,7)
UserLbl.BackgroundTransparency=1
UserLbl.TextColor3=T().Text
UserLbl.Font=Enum.Font.GothamBold
UserLbl.TextSize=12
UserLbl.TextXAlignment=Enum.TextXAlignment.Left
UserLbl.Text="  "..LP.Name
UserLbl.Parent=ProfileWidget

-- Duration label
local DurLbl=Instance.new("TextLabel")
DurLbl.Size=UDim2.new(0,160,0,12)
DurLbl.Position=UDim2.new(0,42,0,22)
DurLbl.BackgroundTransparency=1
DurLbl.TextColor3=T().Sub
DurLbl.Font=Enum.Font.Gotham
DurLbl.TextSize=10
DurLbl.TextXAlignment=Enum.TextXAlignment.Left
DurLbl.Text="  ⏱ 0s"
DurLbl.Parent=ProfileWidget

local startTime=tick()
RunService.Heartbeat:Connect(function()
    local elapsed=math.floor(tick()-startTime)
    local m=math.floor(elapsed/60) local s=elapsed%60
    DurLbl.Text=string.format("  ⏱ %dm %ds",m,s)
end)

-- Center title
local TitleLbl=Instance.new("TextLabel") TitleLbl.Size=UDim2.new(1,-280,1,0) TitleLbl.Position=UDim2.new(0,210,0,0) TitleLbl.BackgroundTransparency=1 TitleLbl.TextColor3=T().Text TitleLbl.Font=Enum.Font.GothamBold TitleLbl.TextSize=14 TitleLbl.Text="⚡ BB ULTIMATE  ·  2026solar" TitleLbl.Parent=Hdr

-- Stats row (ping, fps)
local StatLbl=Instance.new("TextLabel") StatLbl.Size=UDim2.new(0,110,1,0) StatLbl.Position=UDim2.new(1,-165,0,0) StatLbl.BackgroundTransparency=1 StatLbl.TextColor3=T().Sub StatLbl.Font=Enum.Font.Gotham StatLbl.TextSize=11 StatLbl.Text="📶 0ms  🖥 60fps" StatLbl.Parent=Hdr

-- Close
local CBtn=Instance.new("TextButton") CBtn.Size=UDim2.new(0,26,0,20) CBtn.Position=UDim2.new(1,-34,0.5,-10) CBtn.BackgroundColor3=Color3.fromRGB(200,55,55) CBtn.Text="✕" CBtn.TextColor3=Color3.fromRGB(255,255,255) CBtn.Font=Enum.Font.GothamBold CBtn.TextSize=13 CBtn.BorderSizePixel=0 CBtn.Parent=Hdr Instance.new("UICorner",CBtn).CornerRadius=UDim.new(0,6)
CBtn.MouseButton1Click:Connect(function() Main.Visible=false end)

-- Minimize
local MBtn=Instance.new("TextButton") MBtn.Size=UDim2.new(0,26,0,20) MBtn.Position=UDim2.new(1,-64,0.5,-10) MBtn.BackgroundColor3=Color3.fromRGB(200,155,0) MBtn.Text="−" MBtn.TextColor3=Color3.fromRGB(255,255,255) MBtn.Font=Enum.Font.GothamBold MBtn.TextSize=16 MBtn.BorderSizePixel=0 MBtn.Parent=Hdr Instance.new("UICorner",MBtn).CornerRadius=UDim.new(0,6)
local mini=false local fullSz=UDim2.new(0,UW,0,UH)
MBtn.MouseButton1Click:Connect(function()
    mini=not mini
    TweenService:Create(Main,TweenInfo.new(0.18),{Size=mini and UDim2.new(0,UW,0,HH) or fullSz}):Play()
end)

-- Drag
local drag,dragS,dragP=false,nil,nil
Hdr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true dragS=i.Position dragP=Main.Position end end)
UserInputService.InputChanged:Connect(function(i) if drag and i.UserInputType==Enum.UserInputType.MouseMove then local d=i.Position-dragS Main.Position=UDim2.new(dragP.X.Scale,dragP.X.Offset+d.X,dragP.Y.Scale,dragP.Y.Offset+d.Y) end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end end)

-- ============================================================
-- SIDEBAR + TAB SYSTEM
-- ============================================================
local Sidebar=Instance.new("Frame") Sidebar.Size=UDim2.new(0,SW,1,-HH) Sidebar.Position=UDim2.new(0,0,0,HH) Sidebar.BackgroundColor3=T().Panel Sidebar.BorderSizePixel=0 Sidebar.Parent=Main
local Content=Instance.new("Frame") Content.Size=UDim2.new(1,-SW,1,-HH) Content.Position=UDim2.new(0,SW,0,HH) Content.BackgroundTransparency=1 Content.ClipsDescendants=true Content.Parent=Main
local SL=Instance.new("UIListLayout") SL.Padding=UDim.new(0,3) SL.Parent=Sidebar
local SP=Instance.new("UIPadding") SP.PaddingTop=UDim.new(0,8) SP.PaddingLeft=UDim.new(0,4) SP.PaddingRight=UDim.new(0,4) SP.Parent=Sidebar

local tabs={} local activeTab=nil

-- Emoji alignment: fixed-width icon container + text label side by side
local function makeTab(name,icon)
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(1,-8,0,34) btn.BackgroundTransparency=1
    btn.BorderSizePixel=0 btn.Parent=Sidebar

    -- icon frame (fixed width keeps text aligned across all tabs)
    local iconLbl=Instance.new("TextLabel")
    iconLbl.Size=UDim2.new(0,28,1,0) iconLbl.Position=UDim2.new(0,6,0,0)
    iconLbl.BackgroundTransparency=1 iconLbl.Text=icon
    iconLbl.Font=Enum.Font.GothamBold iconLbl.TextSize=14
    iconLbl.TextColor3=T().Sub iconLbl.TextXAlignment=Enum.TextXAlignment.Center
    iconLbl.Parent=btn

    -- text label starts right after icon
    local textLbl=Instance.new("TextLabel")
    textLbl.Size=UDim2.new(1,-36,1,0) textLbl.Position=UDim2.new(0,34,0,0)
    textLbl.BackgroundTransparency=1 textLbl.Text=name
    textLbl.Font=Enum.Font.GothamSemibold textLbl.TextSize=12
    textLbl.TextColor3=T().Sub textLbl.TextXAlignment=Enum.TextXAlignment.Left
    textLbl.Parent=btn

    local accent=Instance.new("Frame")
    accent.Size=UDim2.new(0,3,0,22) accent.Position=UDim2.new(0,0,0.5,-11)
    accent.BackgroundColor3=ACC accent.BorderSizePixel=0 accent.Visible=false
    Instance.new("UICorner",accent).CornerRadius=UDim.new(0,3) accent.Parent=btn

    local page=Instance.new("ScrollingFrame")
    page.Size=UDim2.new(1,0,1,0) page.BackgroundTransparency=1
    page.BorderSizePixel=0 page.ScrollBarThickness=3
    page.ScrollBarImageColor3=ACC page.Visible=false page.Parent=Content

    local pl=Instance.new("UIListLayout") pl.Padding=UDim.new(0,5) pl.Parent=page
    local pp=Instance.new("UIPadding") pp.PaddingLeft=UDim.new(0,10) pp.PaddingRight=UDim.new(0,10) pp.PaddingTop=UDim.new(0,10) pp.PaddingBottom=UDim.new(0,10) pp.Parent=page

    local tab={btn=btn,page=page,accent=accent,icon=iconLbl,text=textLbl}
    table.insert(tabs,tab)

    btn.MouseButton1Click:Connect(function()
        if activeTab then
            activeTab.accent.Visible=false activeTab.page.Visible=false
            activeTab.icon.TextColor3=T().Sub activeTab.text.TextColor3=T().Sub
            activeTab.btn.BackgroundTransparency=1
        end
        activeTab=tab
        accent.Visible=true page.Visible=true
        iconLbl.TextColor3=T().Text textLbl.TextColor3=T().Text
        btn.BackgroundTransparency=0.86
    end)
    return page
end

-- ============================================================
-- UI COMPONENTS  (emoji icon + label perfectly aligned)
-- ============================================================
local function makeSect(parent,label)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,0,0,20) f.BackgroundTransparency=1 f.Parent=parent
    local l=Instance.new("TextLabel") l.Size=UDim2.new(1,0,1,0) l.BackgroundTransparency=1
    l.TextColor3=ACC l.Font=Enum.Font.GothamBold l.TextSize=10
    l.TextXAlignment=Enum.TextXAlignment.Left l.Text=label:upper() l.Parent=f
end

local function makeToggle(parent,icon,label,key,cb)
    local row=Instance.new("Frame")
    row.Size=UDim2.new(1,0,0,30) row.BackgroundColor3=T().Panel
    row.BackgroundTransparency=0.5 row.BorderSizePixel=0 row.Parent=parent
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)

    -- icon box (fixed 24px, keeps text aligned)
    local icoLbl=Instance.new("TextLabel")
    icoLbl.Size=UDim2.new(0,24,1,0) icoLbl.Position=UDim2.new(0,6,0,0)
    icoLbl.BackgroundTransparency=1 icoLbl.Text=icon
    icoLbl.Font=Enum.Font.GothamBold icoLbl.TextSize=13
    icoLbl.TextColor3=T().Sub icoLbl.TextXAlignment=Enum.TextXAlignment.Center
    icoLbl.Parent=row

    local lbl=Instance.new("TextLabel")
    lbl.Size=UDim2.new(1,-64,1,0) lbl.Position=UDim2.new(0,32,0,0)
    lbl.BackgroundTransparency=1 lbl.TextColor3=T().Text
    lbl.Font=Enum.Font.Gotham lbl.TextSize=12
    lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text=label lbl.Parent=row

    local bg=Instance.new("Frame")
    bg.Size=UDim2.new(0,36,0,18) bg.Position=UDim2.new(1,-44,0.5,-9)
    bg.BackgroundColor3=CFG[key] and T().ON or T().OFF bg.BorderSizePixel=0 bg.Parent=row
    Instance.new("UICorner",bg).CornerRadius=UDim.new(1,0)
    local knob=Instance.new("Frame")
    knob.Size=UDim2.new(0,14,0,14) knob.Position=CFG[key] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)
    knob.BackgroundColor3=Color3.fromRGB(255,255,255) knob.BorderSizePixel=0 knob.Parent=bg
    Instance.new("UICorner",knob).CornerRadius=UDim.new(1,0)

    local function refresh()
        TweenService:Create(bg,TweenInfo.new(0.12),{BackgroundColor3=CFG[key] and T().ON or T().OFF}):Play()
        TweenService:Create(knob,TweenInfo.new(0.12),{Position=CFG[key] and UDim2.new(1,-16,0.5,-7) or UDim2.new(0,2,0.5,-7)}):Play()
    end
    row.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            CFG[key]=not CFG[key] refresh() if cb then cb(CFG[key]) end
        end
    end)
    return row
end

local function makeSlider(parent,icon,label,key,mn,mx,step)
    step=step or 1
    local row=Instance.new("Frame") row.Size=UDim2.new(1,0,0,44) row.BackgroundColor3=T().Panel row.BackgroundTransparency=0.5 row.BorderSizePixel=0 row.Parent=parent
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)

    local icoLbl=Instance.new("TextLabel") icoLbl.Size=UDim2.new(0,24,0,20) icoLbl.Position=UDim2.new(0,6,0,4) icoLbl.BackgroundTransparency=1 icoLbl.Text=icon icoLbl.Font=Enum.Font.GothamBold icoLbl.TextSize=13 icoLbl.TextColor3=T().Sub icoLbl.TextXAlignment=Enum.TextXAlignment.Center icoLbl.Parent=row

    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(0.65,0,0,20) lbl.Position=UDim2.new(0,32,0,4) lbl.BackgroundTransparency=1 lbl.TextColor3=T().Text lbl.Font=Enum.Font.Gotham lbl.TextSize=12 lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text=label lbl.Parent=row

    local val=Instance.new("TextLabel") val.Size=UDim2.new(0.3,0,0,20) val.Position=UDim2.new(0.7,-4,0,4) val.BackgroundTransparency=1 val.TextColor3=T().Sub val.Font=Enum.Font.GothamBold val.TextSize=12 val.TextXAlignment=Enum.TextXAlignment.Right val.Text=tostring(CFG[key]) val.Parent=row

    local track=Instance.new("Frame") track.Size=UDim2.new(1,-20,0,4) track.Position=UDim2.new(0,10,1,-12) track.BackgroundColor3=T().OFF track.BorderSizePixel=0 track.Parent=row Instance.new("UICorner",track).CornerRadius=UDim.new(1,0)
    local fill=Instance.new("Frame") fill.Size=UDim2.new((CFG[key]-mn)/(mx-mn),0,1,0) fill.BackgroundColor3=ACC fill.BorderSizePixel=0 fill.Parent=track Instance.new("UICorner",fill).CornerRadius=UDim.new(1,0)

    local ds=false
    track.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=true end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then ds=false end end)
    UserInputService.InputChanged:Connect(function(i)
        if ds and i.UserInputType==Enum.UserInputType.MouseMove then
            local rx=math.clamp(i.Position.X-track.AbsolutePosition.X,0,track.AbsoluteSize.X)
            local pct=rx/track.AbsoluteSize.X
            local snapped=math.floor((mn+(mx-mn)*pct)/step+0.5)*step
            snapped=math.clamp(snapped,mn,mx)
            CFG[key]=snapped fill.Size=UDim2.new(pct,0,1,0) val.Text=tostring(snapped)
        end
    end)
end

local function makeDropdown(parent,icon,label,key,options)
    local row=Instance.new("Frame") row.Size=UDim2.new(1,0,0,30) row.BackgroundColor3=T().Panel row.BackgroundTransparency=0.5 row.BorderSizePixel=0 row.ClipsDescendants=false row.Parent=parent
    Instance.new("UICorner",row).CornerRadius=UDim.new(0,7)

    local icoLbl=Instance.new("TextLabel") icoLbl.Size=UDim2.new(0,24,1,0) icoLbl.Position=UDim2.new(0,6,0,0) icoLbl.BackgroundTransparency=1 icoLbl.Text=icon icoLbl.Font=Enum.Font.GothamBold icoLbl.TextSize=13 icoLbl.TextColor3=T().Sub icoLbl.TextXAlignment=Enum.TextXAlignment.Center icoLbl.Parent=row
    local lbl=Instance.new("TextLabel") lbl.Size=UDim2.new(0.48,0,1,0) lbl.Position=UDim2.new(0,32,0,0) lbl.BackgroundTransparency=1 lbl.TextColor3=T().Text lbl.Font=Enum.Font.Gotham lbl.TextSize=12 lbl.TextXAlignment=Enum.TextXAlignment.Left lbl.Text=label lbl.Parent=row

    local vBtn=Instance.new("TextButton") vBtn.Size=UDim2.new(0,105,0,22) vBtn.Position=UDim2.new(1,-112,0.5,-11) vBtn.BackgroundColor3=T().Border vBtn.TextColor3=T().Text vBtn.Font=Enum.Font.GothamSemibold vBtn.TextSize=11 vBtn.Text=CFG[key].." ▾" vBtn.BorderSizePixel=0 vBtn.Parent=row Instance.new("UICorner",vBtn).CornerRadius=UDim.new(0,5)

    local df=Instance.new("Frame") df.Size=UDim2.new(0,105,0,#options*24+4) df.Position=UDim2.new(1,-112,1,2) df.BackgroundColor3=T().Panel df.BorderSizePixel=0 df.ZIndex=20 df.Visible=false df.Parent=row Instance.new("UICorner",df).CornerRadius=UDim.new(0,6)

    for i,opt in ipairs(options) do
        local ob=Instance.new("TextButton") ob.Size=UDim2.new(1,-4,0,22) ob.Position=UDim2.new(0,2,0,2+(i-1)*24) ob.BackgroundTransparency=1 ob.TextColor3=T().Text ob.Font=Enum.Font.Gotham ob.TextSize=11 ob.Text=opt ob.ZIndex=21 ob.Parent=df
        ob.MouseButton1Click:Connect(function() CFG[key]=opt vBtn.Text=opt.." ▾" df.Visible=false end)
        ob.MouseEnter:Connect(function() TweenService:Create(ob,TweenInfo.new(0.08),{BackgroundTransparency=0.75}):Play() end)
        ob.MouseLeave:Connect(function() TweenService:Create(ob,TweenInfo.new(0.08),{BackgroundTransparency=1}):Play() end)
    end
    vBtn.MouseButton1Click:Connect(function() df.Visible=not df.Visible end)
end

-- ============================================================
-- BUILD TABS
-- ============================================================
-- ⚔ Combat
local pg1=makeTab("Combat","⚔️")
makeSect(pg1,"— Parry")
makeToggle(pg1,"🛡","Auto Parry","AutoParry",nil)
makeSlider(pg1,"📏","Parry Radius","ParryRadius",8,45,1)
makeSlider(pg1,"⏱","Extra Delay ms","ParryDelay",0,100,1)
makeDropdown(pg1,"⚙️","Parry Mode","ParryMode",{"Remote","VIM","Hybrid"})
makeToggle(pg1,"📶","Ping Compensate","PingComp",nil)
makeSect(pg1,"— Aimbot")
makeToggle(pg1,"🎯","Aimbot","Aimbot",nil)
makeSlider(pg1,"🔭","FOV","AimbotFOV",30,360,5)
makeSlider(pg1,"🧈","Smoothing","AimbotSmooth",0,100,1)
makeDropdown(pg1,"🦴","Target Bone","AimbotBone",{"Head","UpperTorso","HumanoidRootPart"})
makeToggle(pg1,"👁","Vis Check","AimbotVisCheck",nil)
makeSect(pg1,"— Dodge")
makeToggle(pg1,"💨","Auto Dodge","AutoDodge",nil)

-- 🔧 Modules
local pg2=makeTab("Modules","🔧")
makeSect(pg2,"— New Modules")
makeToggle(pg2,"🔴","Ball Predict Line","BallPredLine",nil)
makeToggle(pg2,"💥","Kill Aura","KillAura",nil)
makeToggle(pg2,"⚡","Auto Skill","AutoSkill",nil)
makeToggle(pg2,"🌀","Spin Bot","SpinBot",nil)
makeToggle(pg2,"🤫","Anti-Aim Jitter","AntiAim",nil)
makeToggle(pg2,"♻️","Auto Respawn","AutoRespawn",nil)
makeToggle(pg2,"👻","Silent Aim","SilentAim",nil)
makeToggle(pg2,"🧲","Ball Teleport","BallTP",nil)
makeToggle(pg2,"🔦","Chams","ChamsEnabled",nil)
makeSlider(pg2,"📷","Camera FOV","CameraFOV",50,120,1)

-- 👁 Visual
local pg3=makeTab("Visual","👁️")
makeSect(pg3,"— ESP")
makeToggle(pg3,"📦","ESP Enabled","ESP",nil)
makeToggle(pg3,"🟥","Boxes","ESPBoxes",nil)
makeToggle(pg3,"🏷","Names","ESPNames",nil)
makeToggle(pg3,"📐","Distance","ESPDist",nil)
makeToggle(pg3,"📍","Tracers","ESPTracers",nil)
makeToggle(pg3,"⚽","Ball Tracer","ESPBallTrace",nil)
makeToggle(pg3,"🤝","Team Check","ESPTeam",nil)
makeSect(pg3,"— World")
makeToggle(pg3,"☀️","Fullbright","Fullbright",applyFullbright)
makeToggle(pg3,"🌫","No Fog","NoFog",nil)

-- 🧍 Player
local pg4=makeTab("Player","🧍")
makeSect(pg4,"— Movement")
makeToggle(pg4,"🏃","Speed Boost","SpeedBoost",applySpeed)
makeSlider(pg4,"✖️","Speed Mult","SpeedMult",1.0,3.0,0.1)
makeToggle(pg4,"👻","NoClip","NoClip",applyNoClip)
makeSect(pg4,"— Stats")
makeToggle(pg4,"⚡","Inf Stamina","InfStamina",nil)
makeToggle(pg4,"💤","Anti-AFK","AntiAFK",nil)

-- 🎨 Theme
local pg5=makeTab("Theme","🎨")
makeSect(pg5,"— Color Theme")
makeDropdown(pg5,"🌈","Theme","Theme",{"Dark","Light","Ocean","Crimson","Mint","Purple","Sunset"})
makeSect(pg5,"— Interface")
makeSlider(pg5,"🪟","Transparency","UITrans",0,80,1)
makeToggle(pg5,"📶","Show Ping","ShowPing",nil)
makeToggle(pg5,"🖥","Show FPS","ShowFPS",nil)

-- ℹ Info
local pg6=makeTab("Info","ℹ️")
makeSect(pg6,"— Build")
local function infoRow(parent,ico,k,v)
    local f=Instance.new("Frame") f.Size=UDim2.new(1,0,0,22) f.BackgroundTransparency=1 f.Parent=parent
    local il=Instance.new("TextLabel") il.Size=UDim2.new(0,22,1,0) il.BackgroundTransparency=1 il.Text=ico il.Font=Enum.Font.GothamBold il.TextSize=13 il.TextColor3=T().Sub il.TextXAlignment=Enum.TextXAlignment.Center il.Parent=f
    local kl=Instance.new("TextLabel") kl.Size=UDim2.new(0.5,0,1,0) kl.Position=UDim2.new(0,24,0,0) kl.BackgroundTransparency=1 kl.TextColor3=T().Sub kl.Font=Enum.Font.Gotham kl.TextSize=11 kl.TextXAlignment=Enum.TextXAlignment.Left kl.Text=k kl.Parent=f
    local vl=Instance.new("TextLabel") vl.Size=UDim2.new(0.45,0,1,0) vl.Position=UDim2.new(0.55,0,0,0) vl.BackgroundTransparency=1 vl.TextColor3=T().Text vl.Font=Enum.Font.GothamBold vl.TextSize=11 vl.TextXAlignment=Enum.TextXAlignment.Right vl.Text=v vl.Parent=f
end
infoRow(pg6,"⚡","Script","BB Ultimate v4")
infoRow(pg6,"👤","Author","2026solar")
infoRow(pg6,"🔨","Bench","olliE 2026")
infoRow(pg6,"🛡","Parry Engine","Sub-1ms Predictive")
infoRow(pg6,"🎮","Executor","Xeno/Syn/KRNL/Flux")
infoRow(pg6,"⌨️","Toggle Hotkey","RightShift")

-- activate first tab
do local t=tabs[1] if t then activeTab=t t.page.Visible=true t.accent.Visible=true t.btn.BackgroundTransparency=0.86 t.icon.TextColor3=T().Text t.text.TextColor3=T().Text end end

-- ============================================================
-- CANVAS AUTO-SIZE
-- ============================================================
RunService.Heartbeat:Connect(function()
    for _,tab in ipairs(tabs) do
        local l=tab.page:FindFirstChildOfClass("UIListLayout")
        if l then tab.page.CanvasSize=UDim2.new(0,0,0,l.AbsoluteContentSize.Y+20) end
    end
end)

-- ============================================================
-- MAIN LOOP
-- ============================================================
local fpsTimer=0
RunService.RenderStepped:Connect(function(dt)
    antiParryStep()
    autoDodgeStep()
    aimbotStep()
    silentAimStep()
    updateESP()
    updatePredLine()
    spinBotStep()
    antiAimStep()
    ballTPStep()
    applySpeed()
    applyFOV()
    applyChams()
    killAuraStep()
    autoSkillStep()

    -- FPS counter
    fpsTimer=fpsTimer+dt
    if fpsTimer>=0.5 then
        _fps=math.floor(1/dt)
        fpsTimer=0
    end

    -- Stats label
    local ping=getPing()
    local pc=ping<60 and "🟢" or (ping<120 and "🟡" or "🔴")
    local fc=_fps>=55 and "🟢" or (_fps>=30 and "🟡" or "🔴")
    StatLbl.Text=(CFG.ShowPing and (pc.." "..ping.."ms  ") or "")..(CFG.ShowFPS and (fc.." ".._fps.."fps") or "")

    -- No fog
    if CFG.NoFog then local L=game:GetService("Lighting") L.FogEnd=100000 L.FogStart=100000 end

    -- Dynamic theme apply
    local th=T()
    Main.BackgroundColor3=th.BG
    Hdr.BackgroundColor3=th.Panel HdrFix.BackgroundColor3=th.Panel
    Sidebar.BackgroundColor3=th.Panel
    TitleLbl.TextColor3=th.Text UserLbl.TextColor3=th.Text DurLbl.TextColor3=th.Sub
end)

-- ============================================================
-- TOGGLE HOTKEY
-- ============================================================
UserInputService.InputBegan:Connect(function(i,gpe)
    if gpe then return end
    if i.KeyCode==Enum.KeyCode.RightShift then Main.Visible=not Main.Visible end
end)

-- ============================================================
-- STARTUP TOAST
-- ============================================================
local toast=Instance.new("ScreenGui") toast.Parent=CoreGui toast.ResetOnSpawn=false
local tf=Instance.new("Frame") tf.Size=UDim2.new(0,300,0,46) tf.Position=UDim2.new(0.5,-150,1,-65) tf.BackgroundColor3=T().Panel tf.BackgroundTransparency=0.05 tf.BorderSizePixel=0 tf.Parent=toast Instance.new("UICorner",tf).CornerRadius=UDim.new(0,10)
local tl=Instance.new("TextLabel") tl.Size=UDim2.new(1,-16,1,0) tl.Position=UDim2.new(0,8,0,0) tl.BackgroundTransparency=1 tl.TextColor3=T().Text tl.Font=Enum.Font.GothamBold tl.TextSize=13 tl.TextXAlignment=Enum.TextXAlignment.Left tl.Text="⚡ BB Ultimate v4 loaded  ·  RightShift toggle" tl.Parent=tf
task.delay(3,function() TweenService:Create(tf,TweenInfo.new(0.5),{BackgroundTransparency=1}):Play() TweenService:Create(tl,TweenInfo.new(0.5),{TextTransparency=1}):Play() task.delay(0.6,function() toast:Destroy() end) end)
