AttributeUtils = {}

function AttributeUtils.createAttributeElements(template, parent, vehicle, storeItem)
    local elements = {}

    local profiles = {
        shopListAttributeIconOperatingHours = AttributeUtils.resolveOperatingHours,
        shopListAttributeIconPower = AttributeUtils.resolvePower,
        shopListAttributeIconLicensePlate = AttributeUtils.resolveLicensePlate,
        -- shopListAttributeIconPowerReq
        -- shopListAttributeIconWeight
        -- shopListAttributeIconWorkSpeed
        -- shopListAttributeIconWorkingWidth
        -- shopListAttributeIconLifeTime,
        -- shopListAttributeIconWheels,
        -- shopListAttributeIconCondition,
        -- shopListAttributeIconBaleSizeRound
        -- shopListAttributeIconAdditionalWeight
        -- shopListAttributeIconBaleSizeSquare
    }

    for profile, resolver in pairs(profiles) do
        local element = resolver(template, parent, vehicle, storeItem, profile)
        if element ~= nil then
            table.insert(elements, element)
        end
    end

    return elements
end

function AttributeUtils.resolveOperatingHours(template, parent, vehicle, storeItem, profile)
    return nil
end

function AttributeUtils.resolvePower(template, parent, vehicle, storeItem, profile)
    local itemElement = template:clone(parent)
    itemElement:setVisible(true)
    local iconElement = itemElement:getDescendantByName("icon")
    local textElement = itemElement:getDescendantByName("text")
    iconElement:applyProfile(profile)
    textElement:setText(AttributeUtils.powerString(vehicle, storeItem))
    return itemElement
end

function AttributeUtils.resolveLicensePlate(template, parent, vehicle, storeItem, profile)
    return nil
end

function AttributeUtils.powerString(vehicle, storeItem)
    if vehicle.boughtConfigurations == nil or vehicle.boughtConfigurations.motor == nil then
        return nil
    end

    local boughtMotor = vehicle.configurations.motor
    local motorPower  = storeItem.configurations.motor[boughtMotor].power

    if motorPower == nil then return nil end

    local hp, _ = g_i18n:getPower(motorPower)
    return string.format(g_i18n:getText("shop_maxPowerValueSingle"), math.floor(hp))
end
