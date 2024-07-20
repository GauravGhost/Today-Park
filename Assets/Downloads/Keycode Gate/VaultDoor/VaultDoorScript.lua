local toggleGateRequest = Event.new("ToggleGateRequest")
local gateState = BoolValue.new("GateState", true)

local myUIScript = nil

function self:ClientAwake()

    myUIScript = self.gameObject:GetComponent(VaultDoorUi)

    function SetGate(state)
        local isActive = state
        self.gameObject:SetActive(isActive)
    end

    local TapHandler = self.gameObject:GetComponent(TapHandler)
    TapHandler.Tapped:Connect(function()
        myUIScript.SetVisible(true)
    end)

    if gateState.value then SetGate(gateState.value) end
    gateState.Changed:Connect(function(newVal, oldVale)
        -- Gate Changed
        SetGate(newVal)
    end)

    function SendGateRequest()
        toggleGateRequest:FireServer()
    end
end

function self:ServerAwake()
    toggleGateRequest:Connect(function()
        gateState.value = false
        Timer.After(2, function()gateState.value = true end)
    end)
end