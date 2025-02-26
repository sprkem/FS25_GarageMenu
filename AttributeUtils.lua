AttributeUtils = {}
AttributeUtils.DISPLAY_BUFFER = 0.0025

function AttributeUtils.createAttributeElements(cache, template, parent, vehicle, storeItem)
    -- local elements = {}

    local detailProfiles = {}
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconOperatingHours", resolver = AttributeUtils.resolveOperatingHours })
    table.insert(detailProfiles, { profile = "shopListAttributeIconPower", resolver = AttributeUtils.resolvePower })
    table.insert(detailProfiles, { profile = "shopListAttributeIconWeight", resolver = AttributeUtils.resolveWeight })
    table.insert(detailProfiles,
        { profile = "shopListAttributeIconLicensePlate", resolver = AttributeUtils.resolveLicensePlate })
    table.insert(detailProfiles, { profile = "shopListAttributeIconPowerReq", resolver = AttributeUtils.resolvePowerReq })
    table.insert(detailProfiles, { profile = "shopListAttributeIconLifeTime", resolver = AttributeUtils.resolveLifeTime })

    -- local profiles = {

    --     -- shopListAttributeIconWorkSpeed
    --     -- shopListAttributeIconWorkingWidth
    --     -- shopListAttributeIconWheels,
    --     -- shopListAttributeIconCondition,
    --     -- shopListAttributeIconBaleSizeRound
    --     -- shopListAttributeIconAdditionalWeight
    --     -- shopListAttributeIconBaleSizeSquare
    -- }

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

    for _, element in pairs(cache) do
        local iconElement = element:getDescendantByName("icon")
        local textElement = element:getDescendantByName("text")

        element:setSize(textElement.size[1] + iconElement.size[1] + AttributeUtils.DISPLAY_BUFFER, textElement.size[2])
    end
end

function AttributeUtils.resolveOperatingHours(element, vehicle, storeItem)
    local formatted = string.format(
        "%.2f h",
        vehicle.operatingTime / 1000 / 60 / 60
    )
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(formatted)
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

    -- local license = nil
    -- for k, v in g_inGameMenu.attributesLayout.elements do
    --     local icon = v.elements[1]
    --     if icon.profile == "shopListAttributeIconLicensePlate" then
    --         license = v
    --     end
    -- end
end

function AttributeUtils.resolvePowerReq(element, vehicle, storeItem)
    if storeItem.specs == nil or storeItem.specs.neededPower == nil then
        return
    end

    local powerConfig = 0
    local neededPower = 0

    if vehicle.configurations ~= nil and vehicle.configurations.powerConsumer ~= nil then
        powerConfig = vehicle.configurations.powerConsumer
    end

    if powerConfig == 0 and storeItem.specs.neededPower.base ~= nil then
        neededPower = storeItem.specs.neededPower.base
    else
        if storeItem.specs.neededPower.config[powerConfig] ~= nil then
            neededPower = storeItem.specs.neededPower.config[powerConfig]
        end
    end

    if neededPower > 0 then
        local result = string.format(g_i18n:getText("shop_maxPowerValueSingle"), math.floor(neededPower))
        element:setVisible(true)
        local textElement = element:getDescendantByName("text")
        textElement:setText(result)
    end
end

function AttributeUtils.resolveLifeTime(element, vehicle, storeItem)
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(string.format("%s %s", vehicle.age, g_i18n:getText("ui_months")))
end

function AttributeUtils.resolveWeight(element, vehicle, storeItem)
    if vehicle.getTotalMass == nil then
        return
    end

    local mass = vehicle:getTotalMass()

    local unit = "unit_kg"
    if mass > 1000 then
        mass = mass / 1000
        unit = "unit_tonsShort"
    end

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(string.format("%.2f %s", mass, g_i18n:getText(unit)))
end
