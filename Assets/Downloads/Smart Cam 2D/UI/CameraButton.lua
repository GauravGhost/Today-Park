--!Type(UI)

--!Bind
local _ResetButton : VisualElement = nil
--!Bind
local _Icon : UIImage = nil

--!SerializeField
local ButtonIcon : Texture = nil
--!SerializeField
local CameraObject : GameObject = nil

local cameraScript = nil

function PopulateUI()
  _Icon.image = ButtonIcon

  if cameraScript == nil then
    if CameraObject == nil then
      if self.gameObject == nil then
        print("CameraObject is nil")
        return
      else
        CameraObject = self.gameObject
      end
    end
    cameraScript = CameraObject:GetComponent(SmartCam2D)
  end
end

_ResetButton:RegisterPressCallback(function()
  cameraScript.ResetCamera()
end, true, true, true)

PopulateUI()