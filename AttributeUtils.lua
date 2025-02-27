AttributeUtils = {}
AttributeUtils.DISPLAY_BUFFER = 0.0025

function AttributeUtils.createAttributeElements(cache, template, parent, vehicle, storeItem)
    local detailProfiles = {}
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconOperatingHours", resolver = AttributeUtils.resolveOperatingHours })
    table.insert(detailProfiles, { profile = "shopListAttributeIconPower", resolver = AttributeUtils.resolvePower })

    table.insert(detailProfiles,
        { profile = "shopListAttributeIconCapacity", resolver = AttributeUtils.resolveCapacity })

    table.insert(detailProfiles,
        { profile = "shopListAttributeIconTransmission", resolver = AttributeUtils.resolveTransmission })
    table.insert(detailProfiles, { profile = "shopListAttributeIconFuel", resolver = AttributeUtils.resolveFuel })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconWorkSpeed", resolver = AttributeUtils.resolveWorkSpeed })
    table.insert(detailProfiles, { profile = "shopListAttributeIconWeight", resolver = AttributeUtils.resolveWeight })
    table.insert(detailProfiles, { profile = "shopListAttributeIconPowerReq", resolver = AttributeUtils.resolvePowerReq })
    table.insert(detailProfiles, { profile = "shopListAttributeIconWheels", resolver = AttributeUtils.resolveWheels })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconBaleSizeRound", resolver = AttributeUtils.resolveBaleSizeRound })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconBaleSizeSquare", resolver = AttributeUtils.resolveBaleSizeSquare })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconBaleWrapperBaleSizeRound", resolver = AttributeUtils.resolveBaleWrapRound })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconBaleWrapperBaleSizeSquare", resolver = AttributeUtils.resolveBaleWrapSquare })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconLicensePlate", resolver = AttributeUtils.resolveLicensePlate })
    table.insert(detailProfiles, { profile = "shopListAttributeIconLifeTime", resolver = AttributeUtils.resolveLifeTime })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconWorkingWidth", resolver = AttributeUtils.resolveWorkWidth })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconCondition", resolver = AttributeUtils.resolveCondition })

    for _, value in pairs(detailProfiles) do
        local profile = value.profile
        local resolver = value.resolver
        if cache[profile] == nil then
            local itemElement = template:clone(parent)
            itemElement:setVisible(false)
            local iconElement = itemElement:getDescendantByName("icon")
            iconElement:applyProfile(profile)
            cache[profile] = itemElement
        end

        resolver(cache[profile], vehicle, storeItem)
    end

    -- Too stupid to work out how to make the parent element resize to fit the children
    for _, element in pairs(cache) do
        local iconElement = element:getDescendantByName("icon")
        local textElement = element:getDescendantByName("text")

        element:setSize(textElement.size[1] + iconElement.size[1] + AttributeUtils.DISPLAY_BUFFER, textElement.size[2])
    end
end

function AttributeUtils.resolveOperatingHours(element, vehicle, storeItem)
    local hours = Vehicle.getSpecValueOperatingTime(storeItem, vehicle)

    if hours == nil then
        return
    end
    -- local formatted = string.format(
    --     "%.1f h",
    --     vehicle.operatingTime / 1000 / 60 / 60
    -- )

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(hours)
    return element
end

function AttributeUtils.resolvePower(element, vehicle, storeItem)
    if vehicle.boughtConfigurations == nil or vehicle.boughtConfigurations.motor == nil then
        return
    end

    local boughtMotor = vehicle.configurations.motor
    local motorPower  = storeItem.configurations.motor[boughtMotor].power
    if motorPower == nil then return end

    element:setVisible(true)

    local hp, _ = g_i18n:getPower(motorPower)

    local textElement = element:getDescendantByName("text")
    textElement:setText(string.format(g_i18n:getText("shop_maxPowerValueSingle"), math.floor(hp)))
end

function AttributeUtils.resolveLicensePlate(element, vehicle, storeItem)
    if vehicle.spec_licensePlates == nil or vehicle.spec_licensePlates.licensePlateData == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(table.concat(vehicle.spec_licensePlates.licensePlateData.characters))
end

function AttributeUtils.resolvePowerReq(element, vehicle, storeItem)
    -- if storeItem.specs == nil or storeItem.specs.neededPower == nil then
    --     return
    -- end

    -- local powerConfig = 0
    -- local neededPower = 0

    -- if vehicle.configurations ~= nil and vehicle.configurations.powerConsumer ~= nil then
    --     powerConfig = vehicle.configurations.powerConsumer
    -- end

    -- if powerConfig == 0 and storeItem.specs.neededPower.base ~= nil then
    --     neededPower = storeItem.specs.neededPower.base
    -- else
    --     if storeItem.specs.neededPower.config[powerConfig] ~= nil then
    --         neededPower = storeItem.specs.neededPower.config[powerConfig]
    --     end
    -- end

    -- if neededPower > 0 then
    --     local result = string.format(g_i18n:getText("shop_maxPowerValueSingle"), math.floor(neededPower))
    --     element:setVisible(true)
    --     local textElement = element:getDescendantByName("text")
    --     textElement:setText(result)
    -- end
    local power = Motorized.getSpecValuePower(storeItem, vehicle)
    if power == nil then
        return
    end
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(power)
end

function AttributeUtils.resolveLifeTime(element, vehicle, storeItem)
    local age = Vehicle.getSpecValueAge(storeItem, vehicle)
    if age == nil then
        return
    end
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(age)
end

function AttributeUtils.resolveWeight(element, vehicle, storeItem)
    -- if vehicle.getTotalMass == nil then
    --     return
    -- end
    local mass = Vehicle.getSpecValueWeight(storeItem, vehicle)

    if mass == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(mass)
end

function AttributeUtils.resolveWorkSpeed(element, vehicle, storeItem)
    -- if storeItem.specs.speedLimit == nil then
    --     return
    -- end
    -- local speedLimit = math.floor(storeItem.specs.speedLimit)
    local workSpeed = Vehicle.getSpecValueSpeedLimit(storeItem, vehicle)

    if workSpeed == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    -- textElement:setText(string.format("%.1f %s", g_i18n:getSpeed(speedLimit), g_i18n:getSpeedMeasuringUnit()))
    textElement:setText(workSpeed)
end

function AttributeUtils.resolveWorkWidth(element, vehicle, storeItem)
    -- if storeItem.specs == nil then
    --     return
    -- end

    local workingWidth = Vehicle.getSpecValueWorkingWidth(storeItem, vehicle)

    if workingWidth == nil then
        return
    end

    -- local workingWidth = nil
    -- if storeItem.specs.workingWidth ~= nil then
    --     workingWidth = storeItem.specs.workingWidth
    -- elseif storeItem.specs.workingWidthConfig ~= nil and vehicle.configurations.powerConsumer ~= nil then
    --     local powerConfig = vehicle.configurations.powerConsumer
    --     workingWidth = storeItem.specs.workingWidthConfig.powerConsumer[powerConfig]
    -- end

    -- if workingWidth == nil then
    --     return
    -- end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    -- textElement:setText(string.format("%.1f %s", workingWidth, g_i18n:getText("unit_mShort")))
    textElement:setText(workingWidth)
end

function AttributeUtils.resolveWheels(element, vehicle, storeItem)
    -- if vehicle.spec_wheels == nil or vehicle.spec_wheels.wheels == nil or vehicle.spec_wheels.wheels[1] == nil then
    --     return
    -- end

    -- local name = vehicle.spec_wheels.wheels[1].name
    -- if name == nil then
    --     return
    -- end
    local name = Wheels.getSpecValueWheels(storeItem, vehicle)

    if name == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(name)
end

function AttributeUtils.resolveCondition(element, vehicle, storeItem)
    -- local damage = vehicle:getDamageAmount()
    local condition = Wearable.getSpecValueCondition(storeItem, vehicle)
    if condition == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(condition)
    -- textElement:setText(math.floor((damage) * 100) .. " %")
end

function AttributeUtils.resolveTransmission(element, vehicle, storeItem)
    -- if storeItem.specs == nil or storeItem.specs.transmission == nil then
    --     return
    -- end

    -- local transmission = storeItem.specs.transmission[1]

    -- if transmission == nil then
    --     return
    -- end

    local transmission = Motorized.getSpecValueTransmission(storeItem, vehicle)

    if transmission == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(transmission)
end

function AttributeUtils.resolveFuel(element, vehicle, storeItem)
    if vehicle.getConsumerFillUnitIndex == nil then
        return
    end
    local fuelTypeList = {
        FillType.DIESEL,
        FillType.ELECTRICCHARGE,
        FillType.METHANE,
    }
    for _, fuelType in pairs(fuelTypeList) do
        local fillUnitIndex = vehicle:getConsumerFillUnitIndex(fuelType)
        if fillUnitIndex ~= nil then
            local fuelLevel = vehicle:getFillUnitFillLevel(fillUnitIndex)
            element:setVisible(true)
            local textElement = element:getDescendantByName("text")
            textElement:setText(string.format("%s %s", math.ceil(fuelLevel), g_i18n:getText("unit_literShort")))
            return
        end
    end
end

function AttributeUtils.resolveBaleSizeRound(element, vehicle, storeItem)
    if storeItem.specs == nil or storeItem.specs.balerBaleSizeRound == nil then
        return
    end
    local spec = storeItem.specs.balerBaleSizeRound
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")

    if spec.minDiameter == spec.maxDiameter then
        textElement:setText(string.format("%s%s", math.floor(spec.minDiameter * 100), g_i18n:getText("unit_cmShort")))
    else
        textElement:setText(string.format("%s%s-%s%s", math.floor(spec.minDiameter * 100), g_i18n:getText("unit_cmShort"),
            math.floor(spec.maxDiameter * 100), g_i18n:getText("unit_cmShort")))
    end
    -- local size = BaleLoader.loadSpecValueBaleSizeRound(storeItem, vehicle)
    -- if size == nil then
    --     return
    -- end
    -- element:setVisible(true)
    -- local textElement = element:getDescendantByName("text")
    -- textElement:setText(size)
end

function AttributeUtils.resolveBaleSizeSquare(element, vehicle, storeItem)
    if storeItem.specs == nil or storeItem.specs.baleLoaderBaleSizeSquare == nil then
        return
    end
    local spec = storeItem.specs.baleLoaderBaleSizeSquare
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")

    if spec.minLength == spec.maxLength then
        textElement:setText(string.format("%s%s", math.floor(spec.minLength * 100), g_i18n:getText("unit_cmShort")))
    else
        textElement:setText(string.format("%s%s-%s%s", math.floor(spec.minLength * 100), g_i18n:getText("unit_cmShort"),
            math.floor(spec.maxLength * 100), g_i18n:getText("unit_cmShort")))
    end
    -- local size = BaleLoader.loadSpecValueBaleSizeSquare(storeItem, vehicle)
    -- if size == nil then
    --     return
    -- end
    -- element:setVisible(true)
    -- local textElement = element:getDescendantByName("text")
    -- textElement:setText(size)
end

function AttributeUtils.resolveBaleWrapRound(element, vehicle, storeItem)
    if storeItem.specs == nil or storeItem.specs.baleWrapperBaleSizeRound == nil then
        return
    end

    local spec = storeItem.specs.baleWrapperBaleSizeRound
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")

    if spec.minDiameter == spec.maxDiameter then
        textElement:setText(string.format("%s%s", math.floor(spec.minDiameter * 100), g_i18n:getText("unit_cmShort")))
    else
        textElement:setText(string.format("%s%s-%s%s", math.floor(spec.minDiameter * 100), g_i18n:getText("unit_cmShort"),
            math.floor(spec.maxDiameter * 100), g_i18n:getText("unit_cmShort")))
    end
    -- local size = BaleWrapper.loadSpecValueBaleSizeRound(storeItem, vehicle)
    -- if size == nil then
    --     return
    -- end
    -- element:setVisible(true)
    -- local textElement = element:getDescendantByName("text")
    -- textElement:setText(size)
end

function AttributeUtils.resolveBaleWrapSquare(element, vehicle, storeItem)
    if storeItem.specs == nil or storeItem.specs.baleWrapperBaleSizeSquare == nil then
        return
    end

    local spec = storeItem.specs.baleWrapperBaleSizeSquare
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")

    if spec.minLength == spec.maxLength then
        textElement:setText(string.format("%s%s", math.floor(spec.minLength * 100), g_i18n:getText("unit_cmShort")))
    else
        textElement:setText(string.format("%s%s-%s%s", math.floor(spec.minLength * 100), g_i18n:getText("unit_cmShort"),
            math.floor(spec.maxLength * 100), g_i18n:getText("unit_cmShort")))
    end
    -- local size = BaleWrapper.loadSpecValueBaleSizeSquare(storeItem, vehicle)
    -- if size == nil then
    --     -- size = InlineWrapper.getSpecValueBaleSizeSquare(storeItem, vehicle)
    --     -- if size == nil then
    --     --     return
    --     -- end
    --     return
    -- end
    -- element:setVisible(true)
    -- local textElement = element:getDescendantByName("text")
    -- textElement:setText(size)
end

function AttributeUtils.resolveCapacity(element, vehicle, storeItem)
    -- if storeItem.specs == nil or storeItem.specs.capacity == nil then
    --     return
    -- end
    local capacity = FillUnit.getSpecValueCapacity(storeItem, vehicle)
    if capacity == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(capacity)
end
