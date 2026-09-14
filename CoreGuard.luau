local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")

local CoreGuard = {}

CoreGuard.Name = "CoreGuard"
CoreGuard.Version = "0.1.0"

CoreGuard.Container = nil
CoreGuard.UsingCoreGui = false
CoreGuard.Initialized = false
CoreGuard.Recovering = false
CoreGuard.Monitoring = false

CoreGuard.MonitorConnection = nil
CoreGuard.HeartbeatConnection = nil

CoreGuard.LastWarning = nil
CoreGuard.LastError = nil
CoreGuard.LastRecovery = nil

CoreGuard.ScreenGui = nil
CoreGuard.PlayerGui = nil
CoreGuard.GuiName = nil

CoreGuard.State = "Uninitialized"
CoreGuard.Logging = true
CoreGuard.MonitorInterval = 2
CoreGuard.LastMonitorCheck = 0

function CoreGuard:Log(Message)
    if not self.Logging then
        return
    end

    warn("[CoreGuard]: " .. Message)
end

function CoreGuard:SetLogging(Enabled)
    self.Logging = Enabled == true
end

function CoreGuard:IsAccessible(Object)
    if not Object then
        return false
    end

    local Success = pcall(function()
        Object:GetChildren()
    end)

    return Success
end

function CoreGuard:ResolvePlayerGui()
    if self:IsAccessible(self.PlayerGui) then
        return self.PlayerGui
    end

    local Player = Players.LocalPlayer

    if not Player then
        return nil
    end

    local Success, PlayerGui = pcall(function()
        return Player:FindFirstChildOfClass("PlayerGui")
    end)

    if not Success or not PlayerGui then
        Success, PlayerGui = pcall(function()
            return Player:WaitForChild("PlayerGui", 5)
        end)
    end

    if Success and PlayerGui then
        self.PlayerGui = PlayerGui
        return PlayerGui
    end

    return nil
end

function CoreGuard:IsMounted(ScreenGui)
    ScreenGui = ScreenGui or self.ScreenGui

    if not ScreenGui or not self.Container then
        return false
    end

    local Success, Parent = pcall(function()
        return ScreenGui.Parent
    end)

    if not Success then
        return false
    end

    return Parent == self.Container
end

function CoreGuard:CanUseCoreGui()
    return self:IsAccessible(CoreGui)
end

function CoreGuard:FindExisting(Container)
    if not self:IsAccessible(Container) or not self.GuiName then
        return nil
    end

    local Success, Existing = pcall(function()
        return Container:FindFirstChild(self.GuiName)
    end)

    if not Success then
        return nil
    end

    return Existing
end

function CoreGuard:FindDuplicates(Container, ProtectedGui)
    if not self:IsAccessible(Container) or not self.GuiName then
        return {}
    end

    local Duplicates = {}

    local Success, Children = pcall(function()
        return Container:GetChildren()
    end)

    if not Success then
        return Duplicates
    end

    for _, Child in ipairs(Children) do
        if Child ~= ProtectedGui and Child.Name == self.GuiName then
            table.insert(Duplicates, Child)
        end
    end

    return Duplicates
end

function CoreGuard:RemoveDuplicates(Container, ProtectedGui)
    local Duplicates = self:FindDuplicates(Container, ProtectedGui)

    for _, Duplicate in ipairs(Duplicates) do
        pcall(function()
            Duplicate:Destroy()
        end)
    end

    return #Duplicates
end

function CoreGuard:RemoveExisting(Container, ProtectedGui)
    if not self:IsAccessible(Container) then
        return false
    end

    self:RemoveDuplicates(Container, ProtectedGui)

    return true
end

function CoreGuard:PrepareContainer(Container, ScreenGui)
    if not self:IsAccessible(Container) then
        return false
    end

    self:RemoveExisting(Container, ScreenGui)

    return true
end

function CoreGuard:MountToCoreGui(ScreenGui)
    if not self:CanUseCoreGui() then
        return false
    end

    if not self:PrepareContainer(CoreGui, ScreenGui) then
        return false
    end

    local Success = pcall(function()
        ScreenGui.Parent = CoreGui
    end)

    if not Success then
        return false
    end

    local ParentSuccess, Parent = pcall(function()
        return ScreenGui.Parent
    end)

    if not ParentSuccess or Parent ~= CoreGui then
        return false
    end

    self.Container = CoreGui
    self.UsingCoreGui = true
    self.State = "CoreGui"

    return true
end

function CoreGuard:MountToPlayerGui(ScreenGui)
    local PlayerGui = self:ResolvePlayerGui()

    if not self:IsAccessible(PlayerGui) then
        return false
    end

    if not self:PrepareContainer(PlayerGui, ScreenGui) then
        return false
    end

    local Success = pcall(function()
        ScreenGui.Parent = PlayerGui
    end)

    if not Success then
        return false
    end

    local ParentSuccess, Parent = pcall(function()
        return ScreenGui.Parent
    end)

    if not ParentSuccess or Parent ~= PlayerGui then
        return false
    end

    self.Container = PlayerGui
    self.UsingCoreGui = false
    self.State = "PlayerGui"

    return true
end

function CoreGuard:Mount(ScreenGui)
    if self.Initialized then
        self:Log("Mount request ignored because CoreGuard is already initialized.")
        return self:IsMounted(ScreenGui)
    end

    if not ScreenGui then
        self.LastError = "ScreenGui is required."
        self.State = "Failed"
        self:Log("Mount failed: ScreenGui is required.")
        return false
    end

    self.ScreenGui = ScreenGui
    self.PlayerGui = self:ResolvePlayerGui()
    self.GuiName = ScreenGui.Name
    self.Initialized = true
    self.State = "Mounting"

    if self:MountToCoreGui(ScreenGui) then
        self.LastWarning = nil
        self.LastError = nil
        self:Log("CoreGui mounted successfully.")
        return true
    end

    self.LastWarning = "CoreGui unavailable."
    self:Log("Error using CoreGui, switching to PlayerGui...")

    if self:MountToPlayerGui(ScreenGui) then
        self.LastError = nil
        self:Log("PlayerGui fallback mounted successfully.")
        return true
    end

    self.LastError = "Failed to mount GUI."
    self.State = "Failed"

    self:Log("Critical error: failed to mount GUI.")

    return false
end

function CoreGuard:Recover(ScreenGui)
    ScreenGui = ScreenGui or self.ScreenGui

    if not ScreenGui or self.Recovering then
        return false
    end

    self.Recovering = true
    self.State = "Recovering"

    local Recovered = false

    if self.UsingCoreGui then
        Recovered = self:MountToCoreGui(ScreenGui)

        if not Recovered then
            self:Log("CoreGui recovery failed, switching to PlayerGui...")
            Recovered = self:MountToPlayerGui(ScreenGui)
        end
    else
        Recovered = self:MountToCoreGui(ScreenGui)

        if Recovered then
            self:Log("CoreGui became available again.")
        else
            Recovered = self:MountToPlayerGui(ScreenGui)
        end
    end

    if Recovered then
        self.LastError = nil
        self.LastRecovery = os.clock()
        self:Log("GUI recovery completed.")
    else
        self.LastError = "GUI recovery failed."
        self.State = "Failed"
        self:Log("GUI recovery failed.")
    end

    self.Recovering = false

    return Recovered
end

function CoreGuard:CheckIntegrity()
    if not self.Initialized then
        return false
    end

    if not self.ScreenGui then
        self.LastError = "Protected ScreenGui reference is missing."
        return false
    end

    if not self:IsMounted(self.ScreenGui) then
        return false
    end

    if not self:IsAccessible(self.Container) then
        return false
    end

    return true
end

function CoreGuard:CheckDuplicates()
    if not self.Initialized or not self.GuiName then
        return 0
    end

    local Removed = 0

    if self:IsAccessible(CoreGui) then
        Removed += self:RemoveDuplicates(CoreGui, self.ScreenGui)
    end

    local PlayerGui = self:ResolvePlayerGui()

    if PlayerGui and PlayerGui ~= CoreGui then
        Removed += self:RemoveDuplicates(PlayerGui, self.ScreenGui)
    end

    return Removed
end

function CoreGuard:Monitor(ScreenGui)
    ScreenGui = ScreenGui or self.ScreenGui

    if not ScreenGui then
        self.LastError = "ScreenGui is required."
        self:Log("Monitor failed: ScreenGui is required.")
        return false
    end

    if self.MonitorConnection then
        self.MonitorConnection:Disconnect()
        self.MonitorConnection = nil
    end

    self.MonitorConnection = ScreenGui.AncestryChanged:Connect(function()
        if self.Recovering or not self.Initialized then
            return
        end

        task.defer(function()
            if not self:IsMounted(ScreenGui) then
                self:Log("GUI mount changed unexpectedly.")
                self:Recover(ScreenGui)
            end
        end)
    end)

    self.Monitoring = true

    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end

    self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
        if self.Recovering or not self.Initialized then
            return
        end

        local Now = os.clock()

        if Now - self.LastMonitorCheck < self.MonitorInterval then
            return
        end

        self.LastMonitorCheck = Now

        if not self:CheckIntegrity() then
            self:Log("GUI integrity check failed.")
            self:Recover(ScreenGui)
            return
        end

        self:CheckDuplicates()
    end)

    self:Log("GUI monitoring started.")

    return true
end

function CoreGuard:GetContainer()
    return self.Container
end

function CoreGuard:IsUsingCoreGui()
    return self.UsingCoreGui
end

function CoreGuard:IsEnabled()
    return self.Initialized and self:IsMounted()
end

function CoreGuard:IsMonitoring()
    return self.Monitoring and self.MonitorConnection ~= nil
end

function CoreGuard:GetStatus()
    if self.State == "Uninitialized" then
        return "Uninitialized"
    end

    if self.State == "Failed" then
        return "Failed"
    end

    if self.Recovering then
        return "Recovering"
    end

    if self.UsingCoreGui then
        return "CoreGui"
    end

    if self.Container then
        return "PlayerGui"
    end

    return self.State
end

function CoreGuard:GetDiagnostics()
    return {
        Name = self.Name,
        Version = self.Version,
        State = self.State,
        Initialized = self.Initialized,
        Enabled = self:IsEnabled(),
        Monitoring = self:IsMonitoring(),
        Recovering = self.Recovering,
        UsingCoreGui = self.UsingCoreGui,
        Container = self.Container,
        ScreenGui = self.ScreenGui,
        GuiName = self.GuiName,
        PlayerGui = self.PlayerGui,
        LastWarning = self.LastWarning,
        LastError = self.LastError,
        LastRecovery = self.LastRecovery
    }
end

function CoreGuard:Shutdown()
    if self.MonitorConnection then
        self.MonitorConnection:Disconnect()
        self.MonitorConnection = nil
    end

    if self.HeartbeatConnection then
        self.HeartbeatConnection:Disconnect()
        self.HeartbeatConnection = nil
    end

    self.Container = nil
    self.UsingCoreGui = false
    self.Initialized = false
    self.Recovering = false
    self.Monitoring = false

    self.LastWarning = nil
    self.LastError = nil
    self.LastRecovery = nil

    self.ScreenGui = nil
    self.PlayerGui = nil
    self.GuiName = nil

    self.State = "Uninitialized"
end
