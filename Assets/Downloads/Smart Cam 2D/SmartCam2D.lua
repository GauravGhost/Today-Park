--!Header("Zoom Settings")
--!SerializeField
local zoom : number = 10.0
--!SerializeField
local zoomMin : number = 5.0
--!SerializeField
local zoomMax : number = 15.0

--!SerializeField
local camerFollowPlayer : boolean = true  -- Whether the camera should follow the player
--!SerializeField
local cameraFollowSpeed : number = 3.0  -- The speed at which the camera follows the player

--!SerializeField
local xOffset : number = 0.0  -- The offset in the x-axis
--!SerializeField
local yOffset : number = 5.0  -- The offset in the y-axis

--!SerializeField
local panSensitivity : number = 100 -- The sensitivity of the camera pan
--!SerializeField
local mobileZoomSensitivity : number = 50 -- The sensitivity of the zoom on mobile devices

-- boundaries
--!SerializeField
local boundary : boolean = true  -- Whether the camera should have boundaries
--!SerializeField
local minBoundaryX : number = 4.0 -- Minimum x boundary
--!SerializeField
local maxBoundaryX : number = 10.0 -- Maximum x boundary
--!SerializeField
local minBoundaryY : number = -10.0 -- Minimum y boundary
--!SerializeField
local maxBoundaryY : number = 10.0 -- Maximum y boundary

--!SerializeField
local deadzone : boolean = true  -- Whether the camera should have a deadzone
--!SerializeField
local deadzoneWidth : number = 3.0  -- Width of the deadzone
--!SerializeField
local deadzoneHeight : number = 3.0  -- Height of the deadzone

local camera = self.gameObject:GetComponent(Camera)
if camera == nil then
    print("SmartCam2D requires a Camera component on the GameObject its attached to.")
    return
end

-- Ensure the camera is orthographic
camera.orthographic = true

local target = Vector3.zero                      -- the point the camera is looking at
local camerPanSmoothingFactor : number = 0.1    -- the smoothing factor for the camera pan

local isPinching : boolean = false             -- whether the player is pinching the screen
local lastPosition : Vector2 = Vector2.zero   -- the last position of the pinch gesture (todo)

local myChar = nil
local cameraOverridden = false                   -- whether the camera has been overridden by a pan

client.localPlayer.CharacterChanged:Connect(function(player, character)
    if character then
        myChar = character
    end
end)

function ClampPosition(position)
  if not boundary then return position end

  position.x = Mathf.Clamp(position.x, minBoundaryX, maxBoundaryX)
  position.y = Mathf.Clamp(position.y, minBoundaryY, maxBoundaryY)
  return position
end

function UpdateZoom()
  camera.orthographicSize = zoom
end

function ZoomIn()
  zoom = Mathf.Clamp(zoom - 1, zoomMin, zoomMax)

  UpdateZoom()
end

function ZoomOut()
  zoom = Mathf.Clamp(zoom + 1, zoomMin, zoomMax)

  UpdateZoom()
end

function CenterOn(newTarget)
  target = newTarget
  camera.transform.position = Vector3.new(target.x, target.y, camera.transform.position.z)
end

function ConvertSensitivity(userInput, isMobile)
  if userInput > 100 or userInput < 0 or userInput == nil then
    userInput = 100
  end

  userInput = math.max(0, math.min(100, userInput))

  local decimal = 0.001
  if isMobile then
    decimal = 0.01 -- returns 0.01 for mobile 50 = 0.5
  end

  local newPanSens = userInput * decimal
  return newPanSens
end

function PanCamera(evt)
  local zoomAdjustedSensitivity = panSensitivity * (zoom / zoomMax)

  local newPanSens = ConvertSensitivity(zoomAdjustedSensitivity)

  local pan = Vector3.new(-evt.deltaPosition.x * newPanSens, -evt.deltaPosition.y * newPanSens, 0)
  local newPosition = camera.transform.position + pan

  newPosition = ClampPosition(newPosition) -- Boundaries

  camera.transform.position = Vector3.Lerp(camera.transform.position, newPosition, camerPanSmoothingFactor)
  target = Vector3.Lerp(target, target + pan, camerPanSmoothingFactor)
end

function IsOutsideDeadzone(playerPosition, cameraPosition)
  if not deadzone then return true end -- Deadzone is disabled

  local deadzoneHalfWidth = deadzoneWidth / 2
  local deadzoneHalfHeight = deadzoneHeight / 2

  local deltaX = math.abs(playerPosition.x - cameraPosition.x)
  local deltaY = math.abs(playerPosition.y - cameraPosition.y)

  return deltaX > deadzoneHalfWidth or deltaY > deadzoneHalfHeight
end

Input.MouseWheel:Connect(function(evt)
    if evt.delta.y < 0.0 then
        ZoomIn()
    else
        ZoomOut()
    end
end)

Input.PinchOrDragBegan:Connect(function(evt)
  if evt.isPinching then
      isPinching = true
  else
      lastPosition = evt.position
  end
end)

Input.PinchOrDragChanged:Connect(function(evt)
  if isPinching then
    local scaleChange = evt.scale - 1
    -- Inverted for pinch gesture
    local adjustedScaleChange = -scaleChange * ConvertSensitivity(mobileZoomSensitivity)

    local newZoom = zoom + (zoom * adjustedScaleChange)
    zoom = Mathf.Clamp(newZoom, zoomMin, zoomMax)

    UpdateZoom()
  else
    PanCamera(evt)
  end

  cameraOverridden = true
end)

Input.PinchOrDragEnded:Connect(function(evt)
  isPinching = false
end)

function UpdatePosition()
  if myChar then
    -- Initialize targetPosition at the start to ensure it's never nil
    local playerPosition = myChar.transform.position + Vector3.new(xOffset, yOffset, 0)
    targetPosition = targetPosition or playerPosition -- Initialize targetPosition if not already set

    if myChar.isMoving then 
      cameraOverridden = false
    else
      if cameraOverridden then
          return
      end
    end

    local originalCameraZ = camera.transform.position.z -- Store the original z value of the camera

    if IsOutsideDeadzone(playerPosition, camera.transform.position) then
        -- Update the target position to be the player position when outside deadzone
        targetPosition = playerPosition
        cameraOverridden = false
    end

    -- Calculate dynamic lerp factor based on distance to target
    local distance = (camera.transform.position - targetPosition).magnitude
    local dynamicLerpFactor = Mathf.Clamp(Time.deltaTime * cameraFollowSpeed * (distance / 10), 0.01, 1)
    local newPosition = Vector3.Lerp(camera.transform.position, targetPosition, dynamicLerpFactor)
    
    newPosition.z = originalCameraZ -- Set the z value of the newPosition to the original z value of the camera
    camera.transform.position = newPosition
    target = newPosition

  else
      print("SmartCam2D: No character found to follow.")
  end
end

function ResetCamera()
  if myChar then
    -- Set the target position for the camera to smoothly move towards
    targetPosition = myChar.transform.position + Vector3.new(xOffset, yOffset, 0)
    -- Ensure the camera starts moving towards the target position
    cameraOverridden = false
  else
    print("SmartCam2D: No character found to follow.")
  end
end

function self:Start()
    local startPos = self.transform.position
    target = startPos
    CenterOn(startPos)
end

function self:Update()
    if camera == nil then
        return
    end

    if camerFollowPlayer then    
        UpdatePosition()
    end
end
