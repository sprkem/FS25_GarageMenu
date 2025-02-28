AttributeUtils = {}
AttributeUtils.DISPLAY_BUFFER = 0.0025


function AttributeUtils.seedCache(cache, template, parent)
    for _, value in pairs(AttributeUtils.PROFILES) do
        local profile = value.profile
        if cache[profile] == nil then
            local itemElement = template:clone(parent)
            itemElement:setVisible(false)
            local iconElement = itemElement:getDescendantByName("icon")
            iconElement:applyProfile(profile)
            cache[profile] = itemElement
        end
    end
end

function AttributeUtils.createAttributeElements(cache, vehicle, storeItem)
    for _, value in pairs(AttributeUtils.PROFILES) do
        local profile = value.profile
        local resolver = value.resolver

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

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(hours)
    return element
end

function AttributeUtils.resolvePower(element, vehicle, storeItem)
    local power = Motorized.getSpecValuePower(storeItem, vehicle)
    if power == nil then
        return
    end
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(power)
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
    local power = PowerConsumer.getSpecValueNeededPower(storeItem, vehicle)
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
    local mass = Vehicle.getSpecValueWeight(storeItem, vehicle)
    if mass == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(mass)
end

function AttributeUtils.resolveWorkSpeed(element, vehicle, storeItem)
    local workSpeed = Vehicle.getSpecValueSpeedLimit(storeItem, vehicle)
    if workSpeed == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(workSpeed)
end

function AttributeUtils.resolveWorkWidth(element, vehicle, storeItem)
    local workingWidth = Vehicle.getSpecValueWorkingWidth(storeItem, vehicle)

    if workingWidth == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(workingWidth)
end

function AttributeUtils.resolveWheels(element, vehicle, storeItem)
    local name = Wheels.getSpecValueWheels(storeItem, vehicle)
    if name == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(name)
end

function AttributeUtils.resolveCondition(element, vehicle, storeItem)
    local condition = Wearable.getSpecValueCondition(storeItem, vehicle)
    if condition == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(condition)
end

function AttributeUtils.resolveTransmission(element, vehicle, storeItem)
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
end

function AttributeUtils.resolveCapacity(element, vehicle, storeItem)
    local capacity = FillUnit.getSpecValueCapacity(storeItem, vehicle)
    if capacity == nil then
        return
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(capacity)
end

function AttributeUtils.updateFillTypes(element, fruitTemplate, vehicle, storeItem)
    local fillTypes = FillUnit.getSpecValueFillTypes(storeItem, vehicle)
    if fillTypes == nil then
        element:setVisible(false)
        return
    end
    element:setVisible(true)
    element:getDescendantByName("icon"):setImageSlice(nil, "gui.storeAttribute_crops")
    local iconsLayoutBox = element.elements[3]
    local iconsLayout = iconsLayoutBox:getDescendantByName("iconsLayout")

    iconsLayout.elements = {}

    for _, fillTypeId in pairs(fillTypes) do
        local fillType = g_fillTypeManager.indexToFillType[fillTypeId]
        local image = fillType.hudOverlayFilename
        local fruitElement = fruitTemplate:clone(iconsLayout)
        fruitElement:setVisible(true)
        fruitElement:setImageFilename(image)
    end
    iconsLayoutBox.sizeStr = "100% 100%"
    iconsLayoutBox:resolveSizeString()
    iconsLayout:invalidateLayout()
end

function AttributeUtils.updateSeedingTypes(element, fruitTemplate, vehicle, storeItem)
    local fillTypes = SowingMachine.getSpecValueSeedFillTypes(storeItem, vehicle)
    if fillTypes == nil then
        element:setVisible(false)
        return
    end
    element:setVisible(true)
    element:getDescendantByName("icon"):setImageSlice(nil, "gui.storeAttribute_seeding")
    local iconsLayoutBox = element.elements[3]
    local iconsLayout = iconsLayoutBox:getDescendantByName("iconsLayout")

    iconsLayout.elements = {}

    for _, fillTypeId in pairs(fillTypes) do
        local fillType = g_fillTypeManager.indexToFillType[fillTypeId]
        local image = fillType.hudOverlayFilename
        local fruitElement = fruitTemplate:clone(iconsLayout)
        fruitElement:setVisible(true)
        fruitElement:setImageFilename(image)
    end
    iconsLayoutBox.sizeStr = "100% 100%"
    iconsLayoutBox:resolveSizeString()
    iconsLayout:invalidateLayout()
end

-- Keep this last
AttributeUtils.PROFILES = {
    { profile = "shopListAttributeIconOperatingHours", resolver = AttributeUtils.resolveOperatingHours },
    { profile = "shopListAttributeIconPower", resolver = AttributeUtils.resolvePower },
    { profile = "shopListAttributeIconCapacity", resolver = AttributeUtils.resolveCapacity },
    { profile = "shopListAttributeIconTransmission", resolver = AttributeUtils.resolveTransmission },
    { profile = "shopListAttributeIconFuel", resolver = AttributeUtils.resolveFuel },
    { profile = "shopListAttributeIconWorkSpeed", resolver = AttributeUtils.resolveWorkSpeed },
    { profile = "shopListAttributeIconWeight", resolver = AttributeUtils.resolveWeight },
    { profile = "shopListAttributeIconPowerReq", resolver = AttributeUtils.resolvePowerReq },
    { profile = "shopListAttributeIconWheels", resolver = AttributeUtils.resolveWheels },
    { profile = "shopListAttributeIconBaleSizeRound", resolver = AttributeUtils.resolveBaleSizeRound },
    { profile = "shopListAttributeIconBaleSizeSquare", resolver = AttributeUtils.resolveBaleSizeSquare },
    { profile = "shopListAttributeIconBaleWrapperBaleSizeRound", resolver = AttributeUtils.resolveBaleWrapRound },
    { profile = "shopListAttributeIconBaleWrapperBaleSizeSquare", resolver = AttributeUtils.resolveBaleWrapSquare },
    { profile = "shopListAttributeIconLicensePlate", resolver = AttributeUtils.resolveLicensePlate },
    { profile = "shopListAttributeIconLifeTime", resolver = AttributeUtils.resolveLifeTime },
    { profile = "shopListAttributeIconWorkingWidth", resolver = AttributeUtils.resolveWorkWidth },
    { profile = "shopListAttributeIconCondition", resolver = AttributeUtils.resolveCondition }
}
