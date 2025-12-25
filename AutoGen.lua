--!optimize 2

local function fetchOffsets()
    local offsets = {}
    local response = game:HttpGet("https://offsets.ntgetwritewatch.workers.dev/offsets.json")
    for key, value in response:gmatch('"([^"]-)"%s*:%s*"([^"]-)"') do
        offsets[key] = tonumber(value) or value
    end
    return offsets
end

local Offsets = fetchOffsets()
local FrameRotation = tonumber(Offsets["FrameRotation"])

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:FindFirstChild("PlayerGui")

local function normalizeAngle(angle)
    angle = angle % 360
    if angle < 0 then
        angle = angle + 360
    end
    return angle
end

local function getAngleDifference(angle1, angle2)
    angle1 = normalizeAngle(angle1)
    angle2 = normalizeAngle(angle2)
    local diff = math.abs(angle1 - angle2)
    if diff > 180 then
        diff = 360 - diff
    end
    return diff
end

local function isRotationClose(rotation1, rotation2, threshold)
    threshold = threshold or 5
    local difference = getAngleDifference(rotation1, rotation2)
    return difference <= threshold
end

task.spawn(function()
    while true do
        local CheckPrompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
        if CheckPrompt then
            local Line = CheckPrompt.Check.Line
            local Goal = CheckPrompt.Check.Goal

            local Rotation = memory.readf32(Line, FrameRotation)
            local GoalRotation = memory.readf32(Goal, FrameRotation)

            Rotation = normalizeAngle(Rotation)
            GoalRotation = normalizeAngle(GoalRotation)

            local lowerSuccess = normalizeAngle(104 + GoalRotation)
            local upperSuccess = normalizeAngle(114 + GoalRotation)
            local upperNeutral = normalizeAngle(159 + GoalRotation)

            if lowerSuccess <= Rotation and Rotation <= upperSuccess then
                keypress(32)
                keyrelease(32)
            end
        end
        task.wait()
    end
end)
