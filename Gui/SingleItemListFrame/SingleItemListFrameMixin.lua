local _, addon = ...;

KrowiV_SingleItemListFrameMixin = {};

function KrowiV_SingleItemListFrameMixin:OnLoad()
    ButtonFrameTemplate_HidePortrait(self);
    ButtonFrameTemplate_ShowButtonBar(self);
end

function KrowiV_SingleItemListFrameMixin:SetIcon(icon)
    ButtonFrameTemplate_ShowPortrait(self);
    SetPortraitToTexture(self.PortraitContainer.portrait, icon);
end

function KrowiV_SingleItemListFrameMixin:AppendListItem(link, icon, color, name, onClick, ...)
    self.EmbeddedItemList:AppendListItem(link, icon, color, name, onClick, ...);
end

function KrowiV_SingleItemListFrameMixin:RemoveListItem(elementData)
    self.EmbeddedItemList:RemoveListItem(elementData);
end

function KrowiV_SingleItemListFrameMixin:SetListItemsOnClick(func)
    self.EmbeddedItemList:SetListItemsOnClick(func);
end

function KrowiV_SingleItemListFrameMixin:RegisterListItemsForClicks(...)
    self.EmbeddedItemList:RegisterListItemsForClicks(...);
end

function KrowiV_SingleItemListFrameMixin:ClearListItems()
    self.EmbeddedItemList:ClearListItems();
end

function KrowiV_SingleItemListFrameMixin:GetItems()
    return self.EmbeddedItemList:GetItems();
end

function KrowiV_SingleItemListFrameMixin:SetListInfo(text)
    self.ItemListInfo:SetText(text);
end