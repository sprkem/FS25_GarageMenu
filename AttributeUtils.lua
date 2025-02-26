AttributeUtils = {}
AttributeUtils.DISPLAY_BUFFER = 0.0025

function AttributeUtils.createAttributeElements(cache, template, parent, vehicle, storeItem)
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
        -- if cache[profile] == nil then
        --     local itemElement = template:clone(parent)
        --     -- itemElement:setVisible(true)
        --     local iconElement = itemElement:getDescendantByName("icon")
        --     local textElement = itemElement:getDescendantByName("text")
        --     textElement.sizeStr = "100% 100%"
        --     iconElement:applyProfile(profile)
        --     cache[profile] = itemElement
        -- end

        -- resolver(cache[profile], vehicle, storeItem)
        local created = resolver(template, profile, vehicle, storeItem)
        if created ~= nil then
            parent:addElement(created)
            table.insert(elements, created)
        end
    end

    for _, element in pairs(elements) do
        local iconElement = element:getDescendantByName("icon")
        local textElement = element:getDescendantByName("text")

        element:setSize(textElement.size[1] + iconElement.size[1] + AttributeUtils.DISPLAY_BUFFER, textElement.size[2])
    end

    return elements
    -- local itemElement = template:clone(parent)
    -- local iconElement = itemElement:getDescendantByName("icon")
    -- local textElement = itemElement:getDescendantByName("text")
    -- textElement.sizeStr = "100% 100%"
    -- iconElement:applyProfile("shopListAttributeIconLicensePlate")
    -- textElement:setText("ABC 123 256")
end

function AttributeUtils.createElement(template, profile)
    local itemElement = template:clone()
    -- itemElement.sizeStr = "100% 100%"
    -- itemElement:resolveSizeString()
    -- itemElement:setVisible(true)
    local iconElement = itemElement:getDescendantByName("icon")
    local textElement = itemElement:getDescendantByName("text")
    -- textElement.sizeStr = "100% 100%"
    -- textElement:resolveSizeString()
    iconElement:applyProfile(profile)
    return itemElement
end

function AttributeUtils.resolveOperatingHours(template, profile, vehicle, storeItem)
    local element = AttributeUtils.createElement(template, profile)
    local formatted = string.format(
        "%.2f h",
        vehicle.operatingTime / 1000 / 60 / 60
    )
    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(formatted)
    return element
    --textElement:updateSize()
end

function AttributeUtils.resolvePower(template, profile, vehicle, storeItem)
    if vehicle.boughtConfigurations == nil or vehicle.boughtConfigurations.motor == nil then
        return nil
    end

    local element = AttributeUtils.createElement(template, profile)

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    textElement:setText(AttributeUtils.powerString(vehicle, storeItem))
    return element
    --textElement:updateSize()
end

function AttributeUtils.resolveLicensePlate(template, profile, vehicle, storeItem)
    if vehicle.spec_licensePlates == nil or vehicle.spec_licensePlates.licensePlateData == nil then
        return nil
    end

    local element = AttributeUtils.createElement(template, profile)

    element:setVisible(true)
    local textElement = element:getDescendantByName("text")
    print(textElement.size[1])
    print(textElement.size[2])
    textElement:setText(table.concat(vehicle.spec_licensePlates.licensePlateData.characters))
    print(textElement.size[1])
    print(textElement.size[2])
    textElement:updateSize()


    local license = nil
    for k, v in g_inGameMenu.attributesLayout.elements do
        local icon = v.elements[1]
        if icon.profile == "shopListAttributeIconLicensePlate" then
            license = v
        end
    end

    -- if license ~= nil then
    --     print('1')
    --     AttributeUtils.listDifference(license, element)
    --     print('2')
    --     AttributeUtils.listDifference(license.elements[1], element.elements[1])
    --     print('3')
    --     AttributeUtils.listDifference(license.elements[2], element.elements[2])
    -- end

    return element
end

-- function AttributeUtils.listDifference(a,b)
--     for k, v in pairs(a) do
--         if type(v) ~= "table" then
--             if b[k] == nil then
--                 print("Element B is Missing key: " .. k)
--             end

--             if b[k] ~= v then
--                 print("Element B has different value for key: " .. k .. " A: " .. v .. " B: " .. b[k])
--             end
--         end
--     end
-- end

function AttributeUtils.powerString(vehicle, storeItem)
    local boughtMotor = vehicle.configurations.motor
    local motorPower  = storeItem.configurations.motor[boughtMotor].power

    if motorPower == nil then return nil end

    local hp, _ = g_i18n:getPower(motorPower)
    return string.format(g_i18n:getText("shop_maxPowerValueSingle"), math.floor(hp))
end
