local MOVEMENT = {
    { dict = "va_utillitruck", anim = "crane" },
    { dict = "v_boomtruck",    anim = "rotate_crane_base" },
}

local COLLISION = {

    {
        Model = `prop_crate_06a`,
        Bone = "bucket",
        Position = vec3(0.0, -0.36, -0.86),
        Rotation = vec3(0.0, 0.0, 90.0)
    },
    {
        Model = `prop_skate_rail`,
        Bone = "arm_1",
        Position = vec3(0.0, 3.0, 0.06)
    },
    {
        Model = `prop_skate_rail`,
        Bone = "arm_2",
        Position = vec3(0.0, -3.4, 0.1)
    }}

local PlayEntityAnim = PlayEntityAnim
local SetEntityAnimCurrentTime = SetEntityAnimCurrentTime
local IsEntityPlayingAnim = IsEntityPlayingAnim
local DisableControlAction = DisableControlAction
local IsDisabledControlPressed = IsDisabledControlPressed
local GetEntityAnimCurrentTime = GetEntityAnimCurrentTime

---@type integer
---@diagnostic disable-next-line: assign-type-mismatch
local craneVehicle = false
local craneState = false
local switchMode = 1
local dict = MOVEMENT[switchMode].dict
local anim = MOVEMENT[switchMode].anim
local animTime = { 0.0, 0.0 }

local function loadAnimationDicts()
    lib.array.forEach(MOVEMENT, function(type)
        lib.requestAnimDict(type.dict)
    end)
end

local function moveVertical(direction)
    if switchMode ~= 1 then
        anim = MOVEMENT[1].anim
        dict = MOVEMENT[1].dict
        switchMode = 1
        Entity(cache.ped).state:set('craneMode', switchMode, true)
    end

    if not IsEntityPlayingAnim(craneVehicle, dict, anim, 3) then
        PlayEntityAnim(craneVehicle, anim, dict, 8.0, false, true, false, 0.0, 0)
        Wait(0)
        SetEntityAnimCurrentTime(craneVehicle, dict, anim, animTime[switchMode])
    end

    SetEntityAnimSpeed(craneVehicle, dict, anim, 0.1 * direction)
end

local function moveHorizontal(direction)
    if switchMode ~= 2 then
        anim = MOVEMENT[2].anim
        dict = MOVEMENT[2].dict
        switchMode = 2
        Entity(cache.ped).state:set('craneMode', switchMode, true)
    end

    if not IsEntityPlayingAnim(craneVehicle, dict, anim, 3) then
        PlayEntityAnim(craneVehicle, anim, dict, 8.0, false, true, false, 0.0, 0)
        Wait(0)
        SetEntityAnimCurrentTime(craneVehicle, dict, anim, animTime[switchMode])
    end

    local animTime = animTime[2]

    if (direction == 1 and animTime >= 1) or (direction == -1 and animTime == 0) then
        local newTime = (direction == 1) and 0.0 or 1.0

        animTime = newTime
        SetEntityAnimCurrentTime(craneVehicle, dict, anim, newTime)
        Wait(0)
    end

    SetEntityAnimSpeed(craneVehicle, dict, anim, 0.1 * direction)
end

local function activateCrane()
    CreateThread(function()
        loadAnimationDicts()
        Entity(cache.ped).state:set('craneMode', switchMode, true)
        while craneState and craneVehicle do
            dict = MOVEMENT[switchMode].dict
            anim = MOVEMENT[switchMode].anim

            lib.showTextUI('Bucket Controls  \n ⬆ Up  \n ⬇ Down  \n⬅ Left  \n ➡ Right')

            SetEntityAnimSpeed(craneVehicle, dict, anim, 0.0)
            DisableControlAction(0, 172, true) -- Up
            DisableControlAction(0, 173, true) -- Down
            DisableControlAction(0, 174, true) -- Left
            DisableControlAction(0, 175, true) -- Right

            if IsDisabledControlPressed(0, 172) then
                moveVertical(1)    -- Up
            elseif IsDisabledControlPressed(0, 173) then
                moveVertical(-1)   -- Down
            elseif IsDisabledControlPressed(0, 174) then
                moveHorizontal(1)  -- Left
            elseif IsDisabledControlPressed(0, 175) then
                moveHorizontal(-1) -- Right
            end

            animTime[switchMode] = GetEntityAnimCurrentTime(craneVehicle, dict, anim)
            Entity(cache.ped).state:set('craneData', animTime, true)
            Wait(0)
        end

        lib.hideTextUI()
        craneState = false
    end)
end

local function createCollision()
    local objs = {}
    lib.array.forEach(COLLISION, function(col)
        local model = col.Model
        local bone = GetEntityBoneIndexByName(craneVehicle, col.Bone)
        local pos = col.Position
        local rot = col.Rotation or vec3(0.0, 0.0, 0.0)
        local coords = GetOffsetFromEntityInWorldCoords(craneVehicle, 0.0, 0.0, -20)

        lib.RequestModel(model)
        local obj = CreateObjectNoOffset(model, coords.x, coords.y, coords.z, true, false, false)
        SetModelAsNoLongerNeeded(model)
        SetEntityVisible(obj, false, false)
        AttachEntityToEntity(obj, craneVehicle, bone, pos.x, pos.y, pos.z, rot.x, rot.y, rot.z, true, true, true, true, 1,true)

        objs[#objs + 1] = NetworkGetNetworkIdFromEntity(obj)
    end)

    return objs
end

local function craneHandler()
    CreateThread(function()
        local previousLegsState = nil

        while craneVehicle do
            local currentLegsState = AreOutriggerLegsDeployed(craneVehicle)
            if currentLegsState ~= previousLegsState then
                if currentLegsState and not craneState then
                    craneState = true

                    local objects = not Entity(craneVehicle).state.hasCollision and createCollision() or false
                    TriggerServerEvent('utillitruck:deployLegs', VehToNet(craneVehicle), objects)
                    activateCrane()
                elseif not currentLegsState and craneState then
                    craneState = false
                    TriggerServerEvent('utillitruck:deployLegs', VehToNet(craneVehicle))
                end

                previousLegsState = currentLegsState
            end
            Wait(500)
        end
    end)
end

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler('crane', nil, function(bagName, _, value)
    if not value then return end

    local veh = GetEntityFromStateBagName(bagName)
    local ped = NetworkGetEntityFromNetworkId(value[2])

    if ped == cache.ped then return end

    CreateThread(function()
        loadAnimationDicts()

        local time = Entity(ped).state.craneData
        local newtime = time
        local mode = Entity(ped).state.craneMode
        local dict = MOVEMENT[mode].dict
        local anim = MOVEMENT[mode].anim

        while DoesEntityExist(veh) and DoesEntityExist(ped) and Entity(veh).state.crane do
            newtime = Entity(ped).state.craneData
            mode = Entity(ped).state.craneMode
            dict = MOVEMENT[mode].dict
            anim = MOVEMENT[mode].anim

            if not IsEntityPlayingAnim(veh, dict, anim, 3) then
                PlayEntityAnim(veh, anim, dict, 8.0, false, true, false, 0.0, 0)
                Wait(0)
                SetEntityAnimSpeed(veh, dict, anim, 0.0)
                Wait(0)
                SetEntityAnimCurrentTime(veh, dict, anim, newtime[mode])
            end

            if time[mode] ~= newtime[mode] then
                SetEntityAnimCurrentTime(veh, dict, anim, newtime[mode])
            end

            time = newtime
            Wait(0)
        end
    end)
end)

lib.onCache('vehicle', function(vehicle)
    if not vehicle or GetEntityModel(vehicle) ~= `utillitruck4` then
        ---@diagnostic disable-next-line: cast-local-type
        craneVehicle = false
        return
    end

    craneVehicle = vehicle
    craneHandler()
end)
