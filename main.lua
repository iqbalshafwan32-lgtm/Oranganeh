--========================================================
-- 🌐 ALL MAP HUB V12
-- SMALL / MODERN / PC + MOBILE
-- SPEED / FLY / NOCLIP / INF JUMP / ESP
-- ANTI LAG / ANTI AFK / REJOIN / SERVER HOP
-- SAVE POSITION / TELEPORT / RESET
-- DRAG / MINIMIZE / CLOSE
--========================================================

--========================================================
-- SERVICES
--========================================================

local Players =
    game:GetService("Players")

local UIS =
    game:GetService("UserInputService")

local RunService =
    game:GetService("RunService")

local TeleportService =
    game:GetService("TeleportService")

local VirtualUser =
    game:GetService("VirtualUser")

local HttpService =
    game:GetService("HttpService")

local Player =
    Players.LocalPlayer

if not Player then
    return
end

local PlayerGui =
    Player:WaitForChild("PlayerGui")

--========================================================
-- REMOVE OLD GUI
--========================================================

local Old =
    PlayerGui:FindFirstChild(
        "AllMapHub"
    )

if Old then
    Old:Destroy()
end

--========================================================
-- VARIABLES
--========================================================

local SpeedEnabled = false
local SpeedValue = 100
local OldSpeed = 16

local FlyEnabled = false
local FlySpeed = 70

local NoclipEnabled = false
local InfJumpEnabled = false
local ESPEnabled = false

local AntiLagEnabled = false
local AntiAFKEnabled = false

local SavedPosition = nil

local Character
local Humanoid
local RootPart

local FlyVelocity = nil
local FlyConnection = nil
local NoclipConnection = nil
local ESPConnection = nil
local AntiAFKConnection = nil
local JumpConnection = nil
local CharacterConnection = nil

local NoclipSaved = {}
local AntiLagSaved = {}

local UpHeld = false
local DownHeld = false

local Closed = false
local Minimized = false

local Dragging = false
local DragInput = nil
local DragStart = nil
local StartPosition = nil

--========================================================
-- SIZE
--========================================================

local FullSize =
    UDim2.fromOffset(
        320,
        420
    )

local MiniSize =
    UDim2.fromOffset(
        320,
        58
    )

--========================================================
-- CHARACTER
--========================================================

local function UpdateCharacter()

    Character =
        Player.Character

    if not Character then

        Character =
            Player.CharacterAdded:Wait()

    end

    Humanoid =
        Character:WaitForChild(
            "Humanoid"
        )

    RootPart =
        Character:WaitForChild(
            "HumanoidRootPart"
        )

end

UpdateCharacter()

--========================================================
-- GUI
--========================================================

local Gui =
    Instance.new("ScreenGui")

Gui.Name =
    "AllMapHub"

Gui.ResetOnSpawn =
    false

Gui.IgnoreGuiInset =
    true

Gui.DisplayOrder =
    999

Gui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

Gui.Parent =
    PlayerGui

--========================================================
-- MAIN
--========================================================

local Main =
    Instance.new("Frame")

Main.Name =
    "Main"

Main.Size =
    FullSize

Main.Position =
    UDim2.new(
        0.5,
        -160,
        0.5,
        -210
    )

Main.BackgroundColor3 =
    Color3.fromRGB(
        12,
        16,
        26
    )

Main.BorderSizePixel =
    0

Main.ClipsDescendants =
    true

Main.Active =
    true

Main.Parent =
    Gui

Instance.new(
    "UICorner",
    Main
).CornerRadius =
    UDim.new(
        0,
        18
    )

local MainStroke =
    Instance.new("UIStroke")

MainStroke.Color =
    Color3.fromRGB(
        75,
        135,
        255
    )

MainStroke.Thickness =
    1.4

MainStroke.Transparency =
    0.1

MainStroke.Parent =
    Main

local MainGradient =
    Instance.new("UIGradient")

MainGradient.Rotation =
    135

MainGradient.Color =
    ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            Color3.fromRGB(
                19,
                28,
                47
            )
        ),

        ColorSequenceKeypoint.new(
            0.5,
            Color3.fromRGB(
                12,
                16,
                26
            )
        ),

        ColorSequenceKeypoint.new(
            1,
            Color3.fromRGB(
                30,
                18,
                43
            )
        )
    })

MainGradient.Parent =
    Main

--========================================================
-- TOP GLOW
--========================================================

local Glow =
    Instance.new("Frame")

Glow.Size =
    UDim2.new(
        1,
        0,
        0,
        3
    )

Glow.BackgroundColor3 =
    Color3.fromRGB(
        70,
        145,
        255
    )

Glow.BorderSizePixel =
    0

Glow.ZIndex =
    5

Glow.Parent =
    Main

local GlowGradient =
    Instance.new("UIGradient")

GlowGradient.Color =
    ColorSequence.new({
        ColorSequenceKeypoint.new(
            0,
            Color3.fromRGB(
                50,
                110,
                255
            )
        ),

        ColorSequenceKeypoint.new(
            0.5,
            Color3.fromRGB(
                170,
                75,
                255
            )
        ),

        ColorSequenceKeypoint.new(
            1,
            Color3.fromRGB(
                40,
                220,
                255
            )
        )
    })

GlowGradient.Parent =
    Glow

--========================================================
-- HEADER
--========================================================

local Header =
    Instance.new("Frame")

Header.Name =
    "Header"

Header.Size =
    UDim2.new(
        1,
        0,
        0,
        61
    )

Header.BackgroundTransparency =
    1

Header.ZIndex =
    10

Header.Parent =
    Main

--========================================================
-- DRAG AREA
--========================================================

local DragArea =
    Instance.new("Frame")

DragArea.Name =
    "DragArea"

DragArea.Size =
    UDim2.new(
        1,
        -110,
        1,
        0
    )

DragArea.Position =
    UDim2.fromOffset(
        0,
        0
    )

DragArea.BackgroundTransparency =
    1

DragArea.Active =
    true

DragArea.ZIndex =
    20

DragArea.Parent =
    Header

--========================================================
-- BUBBLES
--========================================================

local Bubble1 =
    Instance.new("Frame")

Bubble1.Size =
    UDim2.fromOffset(
        75,
        75
    )

Bubble1.Position =
    UDim2.new(
        1,
        -75,
        0,
        -35
    )

Bubble1.BackgroundColor3 =
    Color3.fromRGB(
        65,
        125,
        255
    )

Bubble1.BackgroundTransparency =
    0.9

Bubble1.BorderSizePixel =
    0

Bubble1.ZIndex =
    2

Bubble1.Parent =
    Header

Instance.new(
    "UICorner",
    Bubble1
).CornerRadius =
    UDim.new(
        1,
        0
    )

local Bubble2 =
    Instance.new("Frame")

Bubble2.Size =
    UDim2.fromOffset(
        30,
        30
    )

Bubble2.Position =
    UDim2.new(
        1,
        -105,
        0,
        35
    )

Bubble2.BackgroundColor3 =
    Color3.fromRGB(
        180,
        75,
        255
    )

Bubble2.BackgroundTransparency =
    0.82

Bubble2.BorderSizePixel =
    0

Bubble2.ZIndex =
    2

Bubble2.Parent =
    Header

Instance.new(
    "UICorner",
    Bubble2
).CornerRadius =
    UDim.new(
        1,
        0
    )

--========================================================
-- TITLE
--========================================================

local Title =
    Instance.new("TextLabel")

Title.Size =
    UDim2.new(
        1,
        0,
        0,
        25
    )

Title.Position =
    UDim2.fromOffset(
        14,
        5
    )

Title.BackgroundTransparency =
    1

Title.Text =
    "🌐  ALL MAP HUB"

Title.TextColor3 =
    Color3.fromRGB(
        245,
        248,
        255
    )

Title.TextSize =
    17

Title.Font =
    Enum.Font.GothamBold

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.ZIndex =
    25

Title.Parent =
    DragArea

local Subtitle =
    Instance.new("TextLabel")

Subtitle.Size =
    UDim2.new(
        1,
        0,
        0,
        16
    )

Subtitle.Position =
    UDim2.fromOffset(
        15,
        30
    )

Subtitle.BackgroundTransparency =
    1

Subtitle.Text =
    "Universal Player Hub"

Subtitle.TextColor3 =
    Color3.fromRGB(
        125,
        140,
        165
    )

Subtitle.TextSize =
    9

Subtitle.Font =
    Enum.Font.Gotham

Subtitle.TextXAlignment =
    Enum.TextXAlignment.Left

Subtitle.ZIndex =
    25

Subtitle.Parent =
    DragArea

local Status =
    Instance.new("TextLabel")

Status.Size =
    UDim2.fromOffset(
        80,
        14
    )

Status.Position =
    UDim2.fromOffset(
        15,
        46
    )

Status.BackgroundTransparency =
    1

Status.Text =
    "● ONLINE"

Status.TextColor3 =
    Color3.fromRGB(
        70,
        220,
        135
    )

Status.TextSize =
    8

Status.Font =
    Enum.Font.GothamBold

Status.TextXAlignment =
    Enum.TextXAlignment.Left

Status.ZIndex =
    25

Status.Parent =
    DragArea

--========================================================
-- MINIMIZE
--========================================================

local MinButton =
    Instance.new("TextButton")

MinButton.Name =
    "Minimize"

MinButton.Size =
    UDim2.fromOffset(
        30,
        27
    )

MinButton.Position =
    UDim2.new(
        1,
        -68,
        0,
        9
    )

MinButton.BackgroundColor3 =
    Color3.fromRGB(
        29,
        38,
        56
    )

MinButton.Text =
    "−"

MinButton.TextColor3 =
    Color3.fromRGB(
        230,
        238,
        250
    )

MinButton.TextSize =
    18

MinButton.Font =
    Enum.Font.GothamBold

MinButton.BorderSizePixel =
    0

MinButton.AutoButtonColor =
    false

MinButton.Active =
    true

MinButton.ZIndex =
    100

MinButton.Parent =
    Header

Instance.new(
    "UICorner",
    MinButton
).CornerRadius =
    UDim.new(
        0,
        8
    )

--========================================================
-- CLOSE
--========================================================

local CloseButton =
    Instance.new("TextButton")

CloseButton.Name =
    "Close"

CloseButton.Size =
    UDim2.fromOffset(
        30,
        27
    )

CloseButton.Position =
    UDim2.new(
        1,
        -34,
        0,
        9
    )

CloseButton.BackgroundColor3 =
    Color3.fromRGB(
        55,
        27,
        40
    )

CloseButton.Text =
    "×"

CloseButton.TextColor3 =
    Color3.fromRGB(
        255,
        110,
        135
    )

CloseButton.TextSize =
    19

CloseButton.Font =
    Enum.Font.GothamBold

CloseButton.BorderSizePixel =
    0

CloseButton.AutoButtonColor =
    false

CloseButton.Active =
    true

CloseButton.ZIndex =
    100

CloseButton.Parent =
    Header

Instance.new(
    "UICorner",
    CloseButton
).CornerRadius =
    UDim.new(
        0,
        8
    )

--========================================================
-- CONTENT
--========================================================

local Content =
    Instance.new("Frame")

Content.Name =
    "Content"

Content.Size =
    UDim2.new(
        1,
        0,
        1,
        -61
    )

Content.Position =
    UDim2.fromOffset(
        0,
        61
    )

Content.BackgroundTransparency =
    1

Content.Parent =
    Main

--========================================================
-- TAB BAR
--========================================================

local TabBar =
    Instance.new("Frame")

TabBar.Size =
    UDim2.new(
        1,
        -18,
        0,
        39
    )

TabBar.Position =
    UDim2.fromOffset(
        9,
        4
    )

TabBar.BackgroundColor3 =
    Color3.fromRGB(
        19,
        24,
        36
    )

TabBar.BorderSizePixel =
    0

TabBar.Parent =
    Content

Instance.new(
    "UICorner",
    TabBar
).CornerRadius =
    UDim.new(
        0,
        11
    )

local function CreateTab(
    Text,
    X
)

    local B =
        Instance.new("TextButton")

    B.Size =
        UDim2.fromOffset(
            94,
            31
        )

    B.Position =
        UDim2.fromOffset(
            X,
            4
        )

    B.BackgroundColor3 =
        Color3.fromRGB(
            28,
            34,
            48
        )

    B.Text =
        Text

    B.TextColor3 =
        Color3.fromRGB(
            170,
            185,
            210
        )

    B.TextSize =
        10

    B.Font =
        Enum.Font.GothamBold

    B.BorderSizePixel =
        0

    B.AutoButtonColor =
        false

    B.Active =
        true

    B.Parent =
        TabBar

    Instance.new(
        "UICorner",
        B
    ).CornerRadius =
        UDim.new(
            0,
            9
        )

    return B
end

local FarmTab =
    CreateTab(
        "🌾 FARM",
        4
    )

local ServerTab =
    CreateTab(
        "🖥️ SERVER",
        101
    )

local PlayerTab =
    CreateTab(
        "👤 PLAYER",
        198
    )

--========================================================
-- PAGES
--========================================================

local Pages =
    Instance.new("Frame")

Pages.Size =
    UDim2.new(
        1,
        -18,
        1,
        -51
    )

Pages.Position =
    UDim2.fromOffset(
        9,
        49
    )

Pages.BackgroundTransparency =
    1

Pages.Parent =
    Content

local function CreatePage()

    local P =
        Instance.new("ScrollingFrame")

    P.Size =
        UDim2.new(
            1,
            0,
            1,
            0
        )

    P.BackgroundTransparency =
        1

    P.BorderSizePixel =
        0

    P.ScrollBarThickness =
        2

    P.ScrollBarImageColor3 =
        Color3.fromRGB(
            75,
            135,
            255
        )

    P.AutomaticCanvasSize =
        Enum.AutomaticSize.Y

    P.CanvasSize =
        UDim2.new(
            0,
            0,
            0,
            0
        )

    P.Visible =
        false

    P.Active =
        true

    P.Parent =
        Pages

    local Layout =
        Instance.new("UIListLayout")

    Layout.Padding =
        UDim.new(
            0,
            6
        )

    Layout.SortOrder =
        Enum.SortOrder.LayoutOrder

    Layout.Parent =
        P

    local Padding =
        Instance.new("UIPadding")

    Padding.PaddingTop =
        UDim.new(
            0,
            3
        )

    Padding.PaddingBottom =
        UDim.new(
            0,
            8
        )

    Padding.PaddingLeft =
        UDim.new(
            0,
            1
        )

    Padding.PaddingRight =
        UDim.new(
            0,
            3
        )

    Padding.Parent =
        P

    return P
end

local FarmPage =
    CreatePage()

local ServerPage =
    CreatePage()

local PlayerPage =
    CreatePage()

--========================================================
-- UI HELPERS
--========================================================

local function Label(
    Parent,
    Text
)

    local L =
        Instance.new("TextLabel")

    L.Size =
        UDim2.new(
            1,
            -6,
            0,
            22
        )

    L.BackgroundTransparency =
        1

    L.Text =
        Text

    L.TextColor3 =
        Color3.fromRGB(
            210,
            220,
            238
        )

    L.TextSize =
        11

    L.Font =
        Enum.Font.GothamBold

    L.TextXAlignment =
        Enum.TextXAlignment.Left

    L.Parent =
        Parent

    return L
end

local function Button(
    Parent,
    Text
)

    local B =
        Instance.new("TextButton")

    B.Size =
        UDim2.new(
            1,
            -6,
            0,
            37
        )

    B.BackgroundColor3 =
        Color3.fromRGB(
            25,
            32,
            47
        )

    B.Text =
        Text

    B.TextColor3 =
        Color3.fromRGB(
            235,
            242,
            255
        )

    B.TextSize =
        11

    B.Font =
        Enum.Font.GothamBold

    B.BorderSizePixel =
        0

    B.AutoButtonColor =
        false

    B.Active =
        true

    B.Parent =
        Parent

    Instance.new(
        "UICorner",
        B
    ).CornerRadius =
        UDim.new(
            0,
            10
        )

    local Stroke =
        Instance.new("UIStroke")

    Stroke.Color =
        Color3.fromRGB(
            55,
            75,
            110
        )

    Stroke.Thickness =
        1

    Stroke.Transparency =
        0.55

    Stroke.Parent =
        B

    return B
end

local function InputBox(
    Parent,
    Default,
    Placeholder
)

    local Box =
        Instance.new("TextBox")

    Box.Size =
        UDim2.new(
            1,
            -6,
            0,
            37
        )

    Box.BackgroundColor3 =
        Color3.fromRGB(
            20,
            26,
            39
        )

    Box.Text =
        tostring(Default)

    Box.PlaceholderText =
        Placeholder

    Box.TextColor3 =
        Color3.fromRGB(
            245,
            248,
            255
        )

    Box.PlaceholderColor3 =
        Color3.fromRGB(
            105,
            120,
            145
        )

    Box.TextSize =
        12

    Box.Font =
        Enum.Font.GothamBold

    Box.ClearTextOnFocus =
        false

    Box.BorderSizePixel =
        0

    Box.Parent =
        Parent

    Instance.new(
        "UICorner",
        Box
    ).CornerRadius =
        UDim.new(
            0,
            10
        )

    local Stroke =
        Instance.new("UIStroke")

    Stroke.Color =
        Color3.fromRGB(
            55,
            75,
            110
        )

    Stroke.Thickness =
        1

    Stroke.Transparency =
        0.55

    Stroke.Parent =
        Box

    return Box
end

local function SetToggle(
    ButtonObject,
    Name,
    State
)

    ButtonObject:SetAttribute(
        "Enabled",
        State
    )

    if State then

        ButtonObject.Text =
            Name.."  •  ON"

        ButtonObject.BackgroundColor3 =
            Color3.fromRGB(
                30,
                100,
                72
            )

    else

        ButtonObject.Text =
            Name.."  •  OFF"

        ButtonObject.BackgroundColor3 =
            Color3.fromRGB(
                25,
                32,
                47
            )

    end

end

--========================================================
-- 🌾 FARM PAGE
--========================================================

Label(
    FarmPage,
    "🌾  FARM / MOVEMENT"
)

Label(
    FarmPage,
    "🏃  SPEED"
)

local SpeedBox =
    InputBox(
        FarmPage,
        100,
        "Speed 1 - 5000"
    )

local SpeedButton =
    Button(
        FarmPage,
        "🏃 SPEED  •  OFF"
    )

SpeedBox.FocusLost:Connect(
    function()

        local Number =
            tonumber(
                SpeedBox.Text
            )

        if Number then

            SpeedValue =
                math.clamp(
                    Number,
                    1,
                    5000
                )

            SpeedBox.Text =
                tostring(
                    SpeedValue
                )

            if SpeedEnabled
            and Humanoid then

                Humanoid.WalkSpeed =
                    SpeedValue

            end

        else

            SpeedBox.Text =
                tostring(
                    SpeedValue
                )

        end

    end
)

SpeedButton.Activated:Connect(
    function()

        SpeedEnabled =
            not SpeedEnabled

        if SpeedEnabled then

            if Humanoid             then

                OldSpeed =
                    Humanoid.WalkSpeed

                Humanoid.WalkSpeed =
                    SpeedValue

            end

        else

            if Humanoid then

                Humanoid.WalkSpeed =
                    OldSpeed

            end

        end

        SetToggle(
            SpeedButton,
            "🏃 SPEED",
            SpeedEnabled
        )

    end
)


--========================================================
-- ✈️ FLY
--========================================================

Label(
    FarmPage,
    "✈️  FLY"
)

local FlyBox =
    InputBox(
        FarmPage,
        70,
        "Fly Speed 1 - 5000"
    )

local FlyButton =
    Button(
        FarmPage,
        "✈️ FLY  •  OFF"
    )

FlyBox.FocusLost:Connect(
    function()

        local Number =
            tonumber(
                FlyBox.Text
            )

        if Number then

            FlySpeed =
                math.clamp(
                    Number,
                    1,
                    5000
                )

            FlyBox.Text =
                tostring(
                    FlySpeed
                )

        else

            FlyBox.Text =
                tostring(
                    FlySpeed
                )

        end

    end
)


--========================================================
-- 📱 MOBILE FLY CONTROLS
--========================================================

local FlyControls =
    Instance.new("Frame")

FlyControls.Name =
    "FlyControls"

FlyControls.Size =
    UDim2.fromOffset(
        48,
        104
    )

FlyControls.Position =
    UDim2.new(
        1,
        -60,
        0.5,
        -52
    )

FlyControls.BackgroundTransparency =
    1

FlyControls.Visible =
    false

FlyControls.ZIndex =
    200

FlyControls.Parent =
    Gui


local UpButton =
    Instance.new("TextButton")

UpButton.Size =
    UDim2.fromOffset(
        44,
        44
    )

UpButton.Position =
    UDim2.fromOffset(
        2,
        0
    )

UpButton.BackgroundColor3 =
    Color3.fromRGB(
        35,
        105,
        180
    )

UpButton.Text =
    "▲"

UpButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

UpButton.TextSize =
    18

UpButton.Font =
    Enum.Font.GothamBold

UpButton.BorderSizePixel =
    0

UpButton.ZIndex =
    201

UpButton.Parent =
    FlyControls

Instance.new(
    "UICorner",
    UpButton
).CornerRadius =
    UDim.new(
        0,
        12
    )


local DownButton =
    Instance.new("TextButton")

DownButton.Size =
    UDim2.fromOffset(
        44,
        44
    )

DownButton.Position =
    UDim2.fromOffset(
        2,
        52
    )

DownButton.BackgroundColor3 =
    Color3.fromRGB(
        75,
        65,
        155
    )

DownButton.Text =
    "▼"

DownButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

DownButton.TextSize =
    18

DownButton.Font =
    Enum.Font.GothamBold

DownButton.BorderSizePixel =
    0

DownButton.ZIndex =
    201

DownButton.Parent =
    FlyControls

Instance.new(
    "UICorner",
    DownButton
).CornerRadius =
    UDim.new(
        0,
        12
    )


local function UpdateFlyControls()

    if Closed then

        FlyControls.Visible =
            false

    else

        FlyControls.Visible =
            UIS.TouchEnabled
            and FlyEnabled

    end

end


UpButton.InputBegan:Connect(
    function(Input)

        if Input.UserInputType ==
            Enum.UserInputType.Touch
            or Input.UserInputType ==
            Enum.UserInputType.MouseButton1
        then

            UpHeld = true

        end

    end
)

UpButton.InputEnded:Connect(
    function(Input)

        if Input.UserInputType ==
            Enum.UserInputType.Touch
            or Input.UserInputType ==
            Enum.UserInputType.MouseButton1
        then

            UpHeld = false

        end

    end
)


DownButton.InputBegan:Connect(
    function(Input)

        if Input.UserInputType ==
            Enum.UserInputType.Touch
            or Input.UserInputType ==
            Enum.UserInputType.MouseButton1
        then

            DownHeld = true

        end

    end
)

DownButton.InputEnded:Connect(
    function(Input)

        if Input.UserInputType ==
            Enum.UserInputType.Touch
            or Input.UserInputType ==
            Enum.UserInputType.MouseButton1
        then

            DownHeld = false

        end

    end
)


--========================================================
-- ✈️ FLY FUNCTION
--========================================================

local function StopFly()

    if FlyConnection then

        FlyConnection:Disconnect()
        FlyConnection = nil

    end

    if FlyVelocity then

        FlyVelocity:Destroy()
        FlyVelocity = nil

    end

    UpHeld = false
    DownHeld = false

    UpdateFlyControls()

end


local function StartFly()

    StopFly()

    if not RootPart then
        return
    end

    FlyVelocity =
        Instance.new("BodyVelocity")

    FlyVelocity.MaxForce =
        Vector3.new(
            math.huge,
            math.huge,
            math.huge
        )

    FlyVelocity.Velocity =
        Vector3.zero

    FlyVelocity.Parent =
        RootPart


    FlyConnection =
        RunService.RenderStepped:Connect(
            function()

                if not FlyEnabled
                or Closed
                or not RootPart
                or not RootPart.Parent
                then

                    StopFly()
                    return

                end

                local Camera =
                    workspace.CurrentCamera

                if not Camera then
                    return
                end

                local MoveDirection =
                    Vector3.zero

                if Humanoid then

                    MoveDirection =
                        Humanoid.MoveDirection

                end

                local Vertical =
                    0

                if UIS:IsKeyDown(
                    Enum.KeyCode.Space
                ) then

                    Vertical =
                        Vertical + 1

                end

                if UIS:IsKeyDown(
                    Enum.KeyCode.LeftControl
                )
                or UIS:IsKeyDown(
                    Enum.KeyCode.RightControl
                ) then

                    Vertical =
                        Vertical - 1

                end

                if UpHeld then
                    Vertical = 1
                end

                if DownHeld then
                    Vertical = -1
                end

                local Velocity =
                    MoveDirection *
                    FlySpeed

                Velocity =
                    Velocity +
                    Vector3.new(
                        0,
                        Vertical * FlySpeed,
                        0
                    )

                FlyVelocity.Velocity =
                    Velocity

            end
        )

    UpdateFlyControls()

end


FlyButton.Activated:Connect(
    function()

        FlyEnabled =
            not FlyEnabled

        if FlyEnabled then

            StartFly()

        else

            StopFly()

        end

        SetToggle(
            FlyButton,
            "✈️ FLY",
            FlyEnabled
        )

        UpdateFlyControls()

    end
)


--========================================================
-- 🚫 NOCLIP
--========================================================

local NoclipButton =
    Button(
        FarmPage,
        "🚫 NOCLIP  •  OFF"
    )


local function RestoreNoclip()

    for Part,OldState in pairs(
        NoclipSaved
    ) do

        if Part and Part.Parent then

            Part.CanCollide =
                OldState

        end

    end

    table.clear(
        NoclipSaved
    )

end


local function ApplyNoclip()

    if not Character then
        return
    end

    for _,Part in ipairs(
        Character:GetDescendants()
    ) do

        if Part:IsA("BasePart") then

            if NoclipSaved[Part] ==
                nil
            then

                NoclipSaved[Part] =
                    Part.CanCollide

            end

            Part.CanCollide =
                false

        end

    end

end


NoclipButton.Activated:Connect(
    function()

        NoclipEnabled =
            not NoclipEnabled

        if NoclipEnabled then

            if NoclipConnection then
                NoclipConnection:Disconnect()
            end

            NoclipConnection =
                RunService.Stepped:Connect(
                    function()

                        if NoclipEnabled then
                            ApplyNoclip()
                        end

                    end
                )

            ApplyNoclip()

        else

            if NoclipConnection then

                NoclipConnection:Disconnect()
                NoclipConnection = nil

            end

            RestoreNoclip()

        end

        SetToggle(
            NoclipButton,
            "🚫 NOCLIP",
            NoclipEnabled
        )

    end
)


--========================================================
-- 🦘 INF JUMP
--========================================================

local JumpButton =
    Button(
        FarmPage,
        "🦘 INF JUMP  •  OFF"
    )


JumpButton.Activated:Connect(
    function()

        InfJumpEnabled =
            not InfJumpEnabled

        if InfJumpEnabled then

            if JumpConnection then
                JumpConnection:Disconnect()
            end

            JumpConnection =
                UIS.JumpRequest:Connect(
                    function()

                        if InfJumpEnabled
                        and Humanoid
                        then

                            Humanoid:
                                ChangeState(
                                    Enum.HumanoidStateType.Jumping
                                )

                        end

                    end
                )

        else

            if JumpConnection then

                JumpConnection:Disconnect()
                JumpConnection = nil

            end

        end

        SetToggle(
            JumpButton,
            "🦘 INF JUMP",
            InfJumpEnabled
        )

    end
)


--========================================================
-- 👁️ ESP
--========================================================

local ESPButton =
    Button(
        FarmPage,
        "👁️ ESP  •  OFF"
    )


local function AddESP(Target)

    if Target == Player then
        return
    end

    local TargetCharacter =
        Target.Character

    if not TargetCharacter then
        return
    end

    if TargetCharacter:
        FindFirstChild(
            "AllMapESP"
        )
    then

        return

    end

    local Highlight =
        Instance.new("Highlight")

    Highlight.Name =
        "AllMapESP"

    Highlight.FillColor =
        Color3.fromRGB(
            70,
            145,
            255
        )

    Highlight.OutlineColor =
        Color3.fromRGB(
            255,
            255,
            255
        )

    Highlight.FillTransparency =
        0.65

    Highlight.OutlineTransparency =
        0

    Highlight.DepthMode =
        Enum.HighlightDepthMode.AlwaysOnTop

    Highlight.Adornee =
        TargetCharacter

    Highlight.Parent =
        TargetCharacter

end


local function RemoveESP()

    for _,Target in ipairs(
        Players:GetPlayers()
    ) do

        if Target ~= Player then

            local TargetCharacter =
                Target.Character

            if TargetCharacter then

                local Highlight =
                    TargetCharacter:
                    FindFirstChild(
                        "AllMapESP"
                    )

                if Highlight then
                    Highlight:Destroy()
                end

            end

        end

    end

end


ESPButton.Activated:Connect(
    function()

        ESPEnabled =
            not ESPEnabled

        if ESPEnabled then

            if ESPConnection then
                ESPConnection:Disconnect()
            end

            ESPConnection =
                RunService.Heartbeat:Connect(
                    function()

                        for _,Target in ipairs(
                            Players:GetPlayers()
                        ) do

                            if Target ~= Player then
                                AddESP(Target)
                            end

                        end

                    end
                )

        else

            if ESPConnection then

                ESPConnection:Disconnect()
                ESPConnection = nil

            end

            RemoveESP()

        end

        SetToggle(
            ESPButton,
            "👁️ ESP",
            ESPEnabled
        )

    end
)


--========================================================
-- 🖥️ SERVER PAGE
--========================================================

Label(
    ServerPage,
    "🖥️  SERVER TOOLS"
)


--========================================================
-- ⚡ ANTI LAG
--========================================================

local AntiLagButton =
    Button(
        ServerPage,
        "⚡ ANTI LAG  •  OFF"
    )


local function SetAntiLag(State)

    if State then

        for _,Object in ipairs(
            workspace:GetDescendants()
        ) do

            if Object:IsA(
                "ParticleEmitter"
            )
            or Object:IsA(
                "Trail"
            )
            or Object:IsA(
                "Smoke"
            )
            or Object:IsA(
                "Fire"
            )
            then

                if AntiLagSaved[Object] ==
                    nil
                then

                    AntiLagSaved[Object] =
                        Object.Enabled

                end

                Object.Enabled =
                    false

            end

        end

    else

        for Object,OldState in pairs(
            AntiLagSaved
        ) do

            if Object and Object.Parent then

                Object.Enabled =
                    OldState

            end

        end

        table.clear(
            AntiLagSaved
        )

    end

end


AntiLagButton.Activated:Connect(
    function()

        AntiLagEnabled =
            not AntiLagEnabled

        SetAntiLag(
            AntiLagEnabled
        )

        SetToggle(
            AntiLagButton,
            "⚡ ANTI LAG",
            AntiLagEnabled
        )

    end
)


--========================================================
-- 💤 ANTI AFK
--========================================================

local AntiAFKButton =
    Button(
        ServerPage,
        "💤 ANTI AFK  •  OFF"
    )


AntiAFKButton.Activated:Connect(
    function()

        AntiAFKEnabled =
            not AntiAFKEnabled

        if AntiAFKEnabled then

            if AntiAFKConnection then
                AntiAFKConnection:Disconnect()
            end

            AntiAFKConnection =
                Player.Idled:Connect(
                    function()

                        if AntiAFKEnabled then

                            VirtualUser:
                                CaptureController()

                            VirtualUser:
                                ClickButton2(
                                    Vector2.new(
                                        0,
                                        0
                                    )
                                )

                        end

                    end
                )

        else

            if AntiAFKConnection then

                AntiAFKConnection:Disconnect()
                AntiAFKConnection = nil

            end

        end

        SetToggle(
            AntiAFKButton,
            "💤 ANTI AFK",
            AntiAFKEnabled
        )

    end
)


--========================================================
-- 🔄 REJOIN
--========================================================

local RejoinButton =
    Button(
        ServerPage,
        "🔄 REJOIN SERVER"
    )


RejoinButton.Activated:Connect(
    function()

        TeleportService:
            Teleport(
                game.PlaceId,
                Player
            )

    end
)


--========================================================
-- 🌐 SERVER HOP
--========================================================

local ServerHopButton =
    Button(
        ServerPage,
        "🌐 SERVER HOP"
    )


ServerHopButton.Activated:Connect(
    function()

        local Success,Result =
            pcall(
                function()

                    local Data =
                        HttpService:
                        JSONDecode(
                            game:HttpGet(
                                "https://games.roblox.com/v1/games/"
                                ..game.PlaceId
                                .."/servers/Public?sortOrder=Asc&limit=100"
                            )
                        )

                    for _,Server in ipairs(
                        Data.data
                    ) do

                        if Server.id ~=
                            game.JobId
                        and Server.playing <
                            Server.maxPlayers
                        then

                            TeleportService:
                                TeleportToPlaceInstance(
                                    game.PlaceId,
                                    Server.id,
                                    Player
                                )

                            return true

                        end

                    end

                    return false

                end
            )

        if not Success then

            warn(
                "[ALL MAP HUB] Server Hop Error:",
                Result
            )

        end

    end
)


--========================================================
-- 👤 PLAYER PAGE
--========================================================

Label(
    PlayerPage,
    "👤  PLAYER TOOLS"
)


--========================================================
-- 💾 SAVE POSITION
--========================================================

local SaveButton =
    Button(
        PlayerPage,
        "💾 SAVE POSITION"
    )


SaveButton.Activated:Connect(
    function()

        if RootPart then

            SavedPosition =
                RootPart.CFrame

            SaveButton.Text =
                "💾 POSITION SAVED"

            task.delay(
                1.5,
                function()

                    if SaveButton
                    and SaveButton.Parent
                    then

                        SaveButton.Text =
                            "💾 SAVE POSITION"

                    end

                end
            )

        end

    end
)


--========================================================
-- 📍 TELEPORT SAVED
--========================================================

local TeleportSavedButton =
    Button(
        PlayerPage,
        "📍 TELEPORT SAVED"
    )


TeleportSavedButton.Activated:Connect(
    function()

        if RootPart
        and SavedPosition
        then

            RootPart.CFrame =
                SavedPosition
                + Vector3.new(
                    0,
                    3,
                    0
                )

        end

    end
)


--========================================================
-- 💀 RESET
--========================================================

local ResetButton =
    Button(
        PlayerPage,
        "💀 RESET CHARACTER"
    )


ResetButton.Activated:Connect(
    function()

        if Humanoid then

            Humanoid.Health =
                0

              end

    end
)


--========================================================
-- 📑 TAB SYSTEM
--========================================================

local function ShowPage(
    Page,
    ActiveButton
)

    FarmPage.Visible =
        false

    ServerPage.Visible =
        false

    PlayerPage.Visible =
        false

    FarmTab.BackgroundColor3 =
        Color3.fromRGB(
            28,
            34,
            48
        )

    ServerTab.BackgroundColor3 =
        Color3.fromRGB(
            28,
            34,
            48
        )

    PlayerTab.BackgroundColor3 =
        Color3.fromRGB(
            28,
            34,
            48
        )

    Page.Visible =
        true

    ActiveButton.BackgroundColor3 =
        Color3.fromRGB(
            55,
            100,
            175
        )

end


FarmTab.Activated:Connect(
    function()

        ShowPage(
            FarmPage,
            FarmTab
        )

    end
)


ServerTab.Activated:Connect(
    function()

        ShowPage(
            ServerPage,
            ServerTab
        )

    end
)


PlayerTab.Activated:Connect(
    function()

        ShowPage(
            PlayerPage,
            PlayerTab
        )

    end
)


--========================================================
-- 🖐️ DRAG PC + MOBILE
--========================================================

DragArea.InputBegan:Connect(
    function(Input)

        if Input.UserInputType ==
            Enum.UserInputType.MouseButton1
            or Input.UserInputType ==
            Enum.UserInputType.Touch
        then

            Dragging =
                true

            DragStart =
                Input.Position

            StartPosition =
                Main.Position

            Input.Changed:Connect(
                function()

                    if Input.UserInputState ==
                        Enum.UserInputState.End
                    then

                        Dragging =
                            false

                    end

                end
            )

        end

    end
)


DragArea.InputChanged:Connect(
    function(Input)

        if Input.UserInputType ==
            Enum.UserInputType.MouseMovement
            or Input.UserInputType ==
            Enum.UserInputType.Touch
        then

            DragInput =
                Input

        end

    end
)


UIS.InputChanged:Connect(
    function(Input)

        if Input ==
            DragInput
            and Dragging
        then

            local Delta =
                Input.Position -
                DragStart

            Main.Position =
                UDim2.new(
                    StartPosition.X.Scale,
                    StartPosition.X.Offset
                        + Delta.X,

                    StartPosition.Y.Scale,
                    StartPosition.Y.Offset
                        + Delta.Y
                )

        end

    end
)


--========================================================
-- 📌 MINIMIZE / RESTORE
--========================================================

MinButton.Activated:Connect(
    function()

        Minimized =
            not Minimized

        if Minimized then

            Content.Visible =
                false

            Main.Size =
                MiniSize

            MinButton.Text =
                "+"

        else

            Content.Visible =
                true

            Main.Size =
                FullSize

            MinButton.Text =
                "−"

        end

    end
)


--========================================================
-- ❌ CLOSE
--========================================================

CloseButton.Activated:Connect(
    function()

        Closed =
            true

        FlyEnabled =
            false

        NoclipEnabled =
            false

        ESPEnabled =
            false

        SpeedEnabled =
            false


        if FlyConnection then

            FlyConnection:Disconnect()
            FlyConnection = nil

        end


        if NoclipConnection then

            NoclipConnection:Disconnect()
            NoclipConnection = nil

        end


        if ESPConnection then

            ESPConnection:Disconnect()
            ESPConnection = nil

        end


        if AntiAFKConnection then

            AntiAFKConnection:Disconnect()
            AntiAFKConnection = nil

        end


        if JumpConnection then

            JumpConnection:Disconnect()
            JumpConnection = nil

        end


        if CharacterConnection then

            CharacterConnection:Disconnect()
            CharacterConnection = nil

        end


        RemoveESP()


        for Part,OldState in pairs(
            NoclipSaved
        ) do

            if Part
            and Part.Parent
            then

                Part.CanCollide =
                    OldState

            end

        end


        table.clear(
            NoclipSaved
        )


        FlyControls.Visible =
            false


        Gui:Destroy()

    end
)


--========================================================
-- 👤 CHARACTER UPDATE
--========================================================

local function UpdateCharacterAfterRespawn(
    NewCharacter
)

    if not NewCharacter then
        return
    end

    Character =
        NewCharacter

    Humanoid =
        NewCharacter:WaitForChild(
            "Humanoid",
            10
        )

    RootPart =
        NewCharacter:WaitForChild(
            "HumanoidRootPart",
            10
        )


    if Humanoid
    and SpeedEnabled
    then

        Humanoid.WalkSpeed =
            SpeedValue

    end

end


CharacterConnection =
    Player.CharacterAdded:Connect(
        function(
            NewCharacter
        )

            task.wait(
                0.5
            )

            UpdateCharacterAfterRespawn(
                NewCharacter
            )


            if NoclipEnabled then

                task.wait(
                    0.2
                )

                ApplyNoclip()

            end

        end
    )


--========================================================
-- 🔄 INITIAL STATE
--========================================================

if Player.Character then

    UpdateCharacterAfterRespawn(
        Player.Character
    )

end


FarmPage.Visible =
    true

ServerPage.Visible =
    false

PlayerPage.Visible =
    false


FarmTab.BackgroundColor3 =
    Color3.fromRGB(
        55,
        100,
        175
    )

ServerTab.BackgroundColor3 =
    Color3.fromRGB(
        28,
        34,
        48
    )

PlayerTab.BackgroundColor3 =
    Color3.fromRGB(
        28,
        34,
        48
    )


FlyControls.Visible =
    UIS.TouchEnabled
    and FlyEnabled


Gui.Enabled =
    true


--========================================================
-- ✅ LOADED
--========================================================

print(
    "[ALL MAP HUB V12] Loaded"
)
