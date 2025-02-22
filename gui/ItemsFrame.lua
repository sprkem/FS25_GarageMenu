ItemsFrame = {}
ItemsFrame._mt = Class(ItemsFrame, TabbedMenuFrameElement)

function ItemsFrame.new(i18n, messageCenter)
    local self = ItemsFrame:superClass().new(nil, ItemsFrame._mt)
    self.name = "itemsFrame"
    self.i18n = i18n
    self.messageCenter = messageCenter

    self.dataBindings = {}
    self.items = nil

    return self
end

function ItemsFrame:delete()
    ItemsFrame:superClass().delete(self)
end

function ItemsFrame:copyAttributes(src)
    ItemsFrame:superClass().copyAttributes(self, src)
    self.i18n = src.i18n
end

function ItemsFrame:onGuiSetupFinished()
    ItemsFrame:superClass().onGuiSetupFinished(self)
    self.itemsList:setDataSource(self)
    self.itemsList:setDelegate(self)
end

function ItemsFrame:initialize()
end

function ItemsFrame:onFrameOpen()
    ItemsFrame:superClass().onFrameOpen(self)
    self:updateContent()
end

function ItemsFrame:onFrameClose()
    ItemsFrame:superClass().onFrameClose(self)
end

function ItemsFrame:updateContent()
    if self.items == nil then
        return
    end
end