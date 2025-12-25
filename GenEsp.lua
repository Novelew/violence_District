--!optimize 2

local CurrentCamera = workspace.CurrentCamera
local Map = workspace:FindFirstChild("Map")

local function RenderGenerator(generator)
    local HitBox = generator:FindFirstChild("HitBox")
    if not HitBox then return end
    
    local Screen, Visible = CurrentCamera:WorldToScreenPoint(HitBox.Position)
    if Visible then
        local Progress = generator:GetAttribute("RepairProgress") or 0
        DrawingImmediate.OutlinedText(Screen, 14, Color3.fromRGB(125, 165, 255), 1, string.format("Generator %d%%", math.floor(Progress)), true, "Tamzen")
    end
end

RunService.Render:Connect(function()
    if not Map then return end
    
    for _, Child in Map:GetChildren() do
        if Child.ClassName == "Model" and Child.Name == "Generator" then
            RenderGenerator(Child)
        elseif Child.ClassName == "Folder" or Child.ClassName == "Model" then
            for _, SubChild in Child:GetChildren() do
                if SubChild.ClassName == "Model" and SubChild.Name == "Generator" then
                    RenderGenerator(SubChild)
                end
            end
        end
    end
    task.wait()
end)
