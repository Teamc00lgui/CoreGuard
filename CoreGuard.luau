local CoreGui = game:GetService("CoreGui")

local CoreGuard = {}

CoreGuard.Name = "CoreGuard"
CoreGuard.Container = nil
CoreGuard.UsingCoreGui = false
CoreGuard.Initialized = false
CoreGuard.Recovering = false
CoreGuard.MonitorConnection = nil
CoreGuard.LastWarning = nil
CoreGuard.ScreenGui = nil
CoreGuard.PlayerGui = nil
CoreGuard.GuiName = nil

function CoreGuard:Log(Message)
    warn("[CoreGuard]: " .. Message)
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

function CoreGuard:RemoveExisting(Container, ProtectedGui)
    local Existing = self:FindExisting(Container)

    if not Existing or Existing == ProtectedGui then
        return true
    end

    local Success = pcall(function()
        Existing:Destroy()
    end)

    if not Success then
        self:Log("Failed to remove an existing GUI instance.")
    end

    return Success
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

    return true
end

function CoreGuard:MountToPlayerGui(ScreenGui)
    if not self:IsAccessible(self.PlayerGui) then
        return false
    end

    if not self:PrepareContainer(self.PlayerGui, ScreenGui) then
        return false
    end

    local Success = pcall(function()
        ScreenGui.Parent = self.PlayerGui
    end)

    if not Success then
        return false
    end

    local ParentSuccess, Parent = pcall(function()
        return ScreenGui.Parent
    end)

    if not ParentSuccess or Parent ~= self.PlayerGui then
        return false
    end

    self.Container = self.PlayerGui
    self.UsingCoreGui = false

    return true
end

function CoreGuard:Mount(ScreenGui, PlayerGui)
    if self.Initialized then
        self:Log("Mount request ignored because CoreGuard is already initialized.")
        return self:IsMounted(ScreenGui)
    end

    if not ScreenGui then
        self:Log("Mount failed: ScreenGui is required.")
        return false
    end

    if not PlayerGui then
        self:Log("Mount failed: PlayerGui is required.")
        return false
    end

    self.ScreenGui = ScreenGui
    self.PlayerGui = PlayerGui
    self.GuiName = ScreenGui.Name
    self.Initialized = true

    if self:MountToCoreGui(ScreenGui) then
        self:Log("CoreGui mounted successfully.")
        return true
    end

    self.LastWarning = "CoreGui unavailable."

    self:Log("Error using CoreGui, switching to PlayerGui...")

    if self:MountToPlayerGui(ScreenGui) then
        self:Log("PlayerGui fallback mounted successfully.")
        return true
    end

    self:Log("Critical error: failed to mount GUI.")

    return false
end

function CoreGuard:Recover(ScreenGui)
    ScreenGui = ScreenGui or self.ScreenGui

    if not ScreenGui or self.Recovering then
        return false
    end

    self.Recovering = true

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
        self:Log("GUI recovery completed.")
    else
        self:Log("GUI recovery failed.")
    end

    self.Recovering = false

    return Recovered
end

function CoreGuard:Monitor(ScreenGui)
    ScreenGui = ScreenGui or self.ScreenGui

    if not ScreenGui then
        self:Log("Monitor failed: ScreenGui is required.")
        return false
    end

    if self.MonitorConnection then
        self.MonitorConnection:Disconnect()
        self.MonitorConnection = nil
    end

    self.MonitorConnection = ScreenGui.AncestryChanged:Connect(function()
        if self.Recovering then
            return
        end

        task.defer(function()
            if not self:IsMounted(ScreenGui) then
                self:Log("GUI mount changed unexpectedly.")
                self:Recover(ScreenGui)
            end
        end)
    end)

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
    return self.MonitorConnection ~= nil
end

function CoreGuard:GetStatus()
    if not self.Container then
        return "Uninitialized"
    end

    if self.UsingCoreGui then
        return "CoreGui"
    end

    return "PlayerGui"
end

function CoreGuard:Shutdown()
    if self.MonitorConnection then
        self.MonitorConnection:Disconnect()
        self.MonitorConnection = nil
    end

    self.Container = nil
    self.UsingCoreGui = false
    self.Initialized = false
    self.Recovering = false
    self.LastWarning = nil
    self.ScreenGui = nil
    self.PlayerGui = nil
    self.GuiName = nil
end
