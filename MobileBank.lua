--	MobileBank v0.30
----------------------------
--	Список команд:
-- /mb cls - очистить собраные данные
-- /mb hide/show - скрыть/показать главную панель
-- /mb p - Показать банк игрока
-- /mb g - Показать банки гильдий
----------------------------



MB = {}

MB.version=0.30

MB.dataDefaultItems = {
	Guilds={}
}

for i=1,GetNumGuilds() do
	MB.dataDefaultItems.Guilds[i]=
		{
			[GetGuildName(i)]={

			}
		}
end 

MB.dataDefaultParams = {
	MBUI_Menu = {10,10},
	MBUI_Container = {530,380}
}

MB.GuildNames = {}

MB.UI_Movable=false
MB.AddonReady=false
MB.TempData={}
MB.GCountOnUpdateTimer=0
MB.GuildBankIdToPrepare=1
MB.Dedug=false
MB.PreviousButtonClicked=nil
MB.LastButtonClicked=nil

function debug(text)
	if MB.Debug then
		d(text)
	end
end

function MB.OnLoad(eventCode, addOnName)
	if (addOnName ~= "MobileBank" ) then return end

	--добавляем команду
	SLASH_COMMANDS["/mb"] = commandHandler

	--Регистрация эвентов
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_OPEN_BANK, MB.PL_Opened)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_CLOSE_BANK, MB.PL_Closed)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_OPEN_GUILD_BANK, MB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_GUILD_BANK_ITEMS_READY, MB.GB_Ready)

	--Загрузка сохраненных переменных
	MB.items= ZO_SavedVars:NewAccountWide( "MB_SavedVars" , 2, "Items" , MB.dataDefaultItems, nil )
	MB.params= ZO_SavedVars:New( "MB_SavedVars" , 2, "Params" , MB.dataDefaultParams, nil )

	--Инициализация графического интерфейся
	MB_UI = WINDOW_MANAGER:GetControlByName("MBUI")

	-- Создаем меню
	MB.CreateMenu()
	-- Создаем банк
	MB.CreateBank()

	MB.AddonReady=true
end


function MB.CreateMenu()
	MB_UI.Menu=WINDOW_MANAGER:CreateControl("MBUI_Menu",MBUI,CT_CONTROL)
	MB_UI.Menu.BG = WINDOW_MANAGER:CreateControl("MBUI_Menu_BG",MBUI_Menu,CT_BACKDROP)
	MB_UI.Menu.Title = WINDOW_MANAGER:CreateControl("MBUI_Menu_Title",MBUI_Menu,CT_LABEL)
	MB_UI.Menu.Button={}
	MB_UI.Menu.Button.Guild = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Guild",MBUI_Menu,CT_BUTTON)
	MB_UI.Menu.Button.Player = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Player",MBUI_Menu,CT_BUTTON)
	-- MB_UI.Menu.Button.Move = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Move",MBUI_Menu,CT_BUTTON)

	--Обработчики событий

    -- Клик по гильдии
    MB_UI.Menu.Button.Guild:SetHandler("OnClicked" , function(self)
    	local bool = not(MBUI_Container:IsHidden())
    	MB.PreviousButtonClicked=MB.LastButtonClicked
		MB.LastButtonClicked="Guild"

    	MB.CurrentLastValue=11

		MB.PrepareBankValues("Guild",1)
		MB.FillBank(MB.CurrentLastValue)
    	MB.HideContainer(bool)
    end )

    -- Клик по игроку
    MB_UI.Menu.Button.Player:SetHandler( "OnClicked" , function(self)
    	local bool = not(MBUI_Container:IsHidden())
    	MB.PreviousButtonClicked=MB.LastButtonClicked
		MB.LastButtonClicked="Player"

		if MB.PlayerShown then
			bool=false
		end

    	MB.CurrentLastValue=11

		MB.PrepareBankValues("Player")
    	MB.FillBank(MB.CurrentLastValue)
    	MB.HideContainer(bool)
    end )


    MBUI_Menu:SetHandler("OnMouseUp" , function(self) MB.MouseUp(self) end)
    MBUI_Container:SetHandler("OnMouseUp" , function(self) MB.MouseUp(self) end)

	--Настройки меню
	MB_UI.Menu:SetAnchor(TOPLEFT,MBUI,TOPLEFT,MB.params.MBUI_Menu[1],MB.params.MBUI_Menu[2])
	MB_UI.Menu:SetDimensions(130,45)
	MB_UI.Menu:SetMouseEnabled(true)
	MB_UI.Menu:SetMovable(true)

	--Фон
	MB_UI.Menu.BG:SetAnchor(CENTER,MBUI_Menu,CENTER,0,0)
	MB_UI.Menu.BG:SetDimensions(130,40)
	MB_UI.Menu.BG:SetCenterColor(0,0,0,1)
	MB_UI.Menu.BG:SetEdgeColor(0,0,0,0)
	MB_UI.Menu.BG:SetAlpha(0.5)

	--Заголовок
	MB_UI.Menu.Title:SetAnchor(CENTER,MBUI_Menu,TOP,0,13)
	MB_UI.Menu.Title:SetFont("ZoFontGame" )
	MB_UI.Menu.Title:SetColor(255,255,255,1.5)
	MB_UI.Menu.Title:SetText( "|cff8000Mobile Bank|" )

	-- Кнопка "Гильдия"
	MB_UI.Menu.Button.Guild:SetAnchor(BOTTOM,MBUI_Menu,BOTTOM,-30,0)
	MB_UI.Menu.Button.Guild:SetText("[Guild]")
	MB_UI.Menu.Button.Guild:SetDimensions(70,25)
	MB_UI.Menu.Button.Guild:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Guild:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Guild:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "Игрок"
	MB_UI.Menu.Button.Player:SetAnchor(BOTTOM,MBUI_Menu,BOTTOM,30,0)
	MB_UI.Menu.Button.Player:SetText("[Player]")
	MB_UI.Menu.Button.Player:SetDimensions(70,25)
	MB_UI.Menu.Button.Player:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Player:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Player:SetMouseOverFontColor(0.8,0.4,0,1)
end

function MB.CreateBank()
	local OldAnchor=false

	-- Настройки контейнера
	MBUI_Container:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,MB.params.MBUI_Container[1],MB.params.MBUI_Container[2])
	MBUI_Container:SetMovable(true)

	-- Правим Слайдер
    MBUI_ContainerSlider:SetValue(11)


    -- Создаем кнопки для переключения между гильдбанками
	local nextXstep=0
    for i=1,#MB.items.Guilds do

    	-- Сохраняем названия гильдий из Ключей
	    for k, v in pairs(MB.items.Guilds[i]) do
	        MB.GuildNames[#MB.GuildNames+1] = k
	    end

    	local guildname=tostring(MB.GuildNames[i])
    	WINDOW_MANAGER:CreateControl("MBUI_ContainerTitleGuildButton"..i,MBUI_ContainerTitle,CT_BUTTON)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetParent(MBUI_ContainerTitleGuildButtons)
		_G["MBUI_ContainerTitleGuildButton"..i]:SetFont("ZoFontGame" )
		nextXstep=(MBUI_Container:GetWidth()/#MB.items.Guilds*i)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetDimensions(MBUI_Container:GetWidth()/#MB.items.Guilds,20)
    	-- Делаем поправку на ширину самой кнопки
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetAnchor(TOP,MBUI_Container,TOPLEFT,nextXstep-_G["MBUI_ContainerTitleGuildButton"..i]:GetWidth()/2,40)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetText("["..guildname.."]")
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetNormalFontColor(0,255,255,.7)
		_G["MBUI_ContainerTitleGuildButton"..i]:SetMouseOverFontColor(0.8,0.4,0,1)

		_G["MBUI_ContainerTitleGuildButton"..i]:SetHandler( "OnClicked" , function(self)
			MB.PrepareBankValues("Guild",i)
			MB.SortPreparedValues()
			MB.FillBank(11)	
		 end)


	end

    -- Правим строки (созданы из xml)
	for i = 1, 11 do
	    local dynamicControl = CreateControlFromVirtual("MBUI_Row", MBUI_Container, "TemplateRow",i)

	    -- Строка
	    local fromtop=100
	    _G["MBUI_Row"..i]:SetAnchor(TOP,MBUI_Container,TOP,0,fromtop+52*(i-1))
	    -- _G["MBUI_Row"..i]:SetDimensions (530,52)

	    -- Анимация
	    _G["MBUI_Row"..i.."IconTimeline"]=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_IconAnimation",_G["MBUI_Row"..i.."ButtonIcon"])
	    -- _G["MBUI_Row"..i.."CountTimeline"]=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_IconAnimation",_G["MBUI_Row"..i.."ButtonStackCount"])

	end
end

function MB.PrepareBankValues(PrepareType,GuildBankIdToPrepare)
	MB.GuildBankIdToPrepare=GuildBankIdToPrepare
	MB.BankValueTable={}
	MB.BankMaxCapacity=0

	if PrepareType=="Player" then
		debug("Preparing Player values")
		bagIcon, bagSlots=GetBagInfo(BAG_BANK)
		MB.BankMaxCapacity=bagSlots
		MB.ItemCounter=0
		while (MB.ItemCounter < bagSlots) do
			if GetItemName(BAG_BANK,MB.ItemCounter)~="" then

				--Избавляемся от мусора при сохранении
				local name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(BAG_BANK, MB.ItemCounter))
				local link = GetItemLink(BAG_BANK,MB.ItemCounter)
				clearlink =string.gsub(link, "|h.+|h", "|h"..tostring(name).."|h")

				local stackCount = GetSlotStackSize(BAG_BANK,MB.ItemCounter)
				local statValue = GetItemStatValue(BAG_BANK,MB.ItemCounter)
				local icon, stack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(BAG_BANK,MB.ItemCounter)
				local ItemType=GetItemType(BAG_BANK,MB.ItemCounter)

				MB.BankValueTable[#MB.BankValueTable+1]={
					["link"]=tostring(clearlink),
					["icon"] = tostring(icon),
					["name"]=tostring(name),
					["stackCount"]=stackCount,
					["StatValue"]=statValue,
					["sellPrice"] = sellPrice,
					["quality"] = quality,
					["meetsUsageRequirement"]=meetsUsageRequirement,
					["ItemType"]=ItemType
				}
			end
			MB.ItemCounter=MB.ItemCounter+1
		end
		MBUI_ContainerTitleGuildButtons:SetHidden(true)
	elseif PrepareType=="Guild" then
		bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)
		MB.BankMaxCapacity=bagSlots
		debug("Preparing Guild values")

	    local guildname=tostring(GetGuildName(GuildBankIdToPrepare))
		MB.BankValueTable=MB.items.Guilds[GuildBankIdToPrepare][guildname]
		
		MBUI_ContainerTitleGuildButtons:SetHidden(false)
	else
		debug("Unknown prepare type: "..tostring(PrepareType))
	end

    MBUI_ContainerSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
		MB.FillBank(value)
    end)

    for i=1,11 do
        _G["MBUI_Row"..i]:SetHandler("OnMouseWheel" , function(self,delta)
	    	local calculatedvalue=MB.CurrentLastValue-delta
	    	if (calculatedvalue>=11) and (calculatedvalue<=#MB.BankValueTable) then
	    		MB.FillBank(calculatedvalue)
	    		MBUI_ContainerSlider:SetValue(calculatedvalue)
	    	end
	    end )
    end
MB.SortPreparedValues()
return MB.BankValueTable
end

function MB.SortPreparedValues()

	function compare(a,b)
		return a["name"]<b["name"]	
	end

	table.sort(MB.BankValueTable,compare)
end

function MB.FillBank(last)
	if last<=1 then debug("last<=1") return end
    if (#MB.BankValueTable==0) then 
    	d("No data avaliable. Open your bank first.")
    	MBUI_ContainerItemCounter:SetHidden(true)
    	MBUI_ContainerSlider:SetHidden(true)
    	MB.HideContainer(true)
	    	for i=1,11 do
	    		_G["MBUI_Row"..i]:SetHidden(true)
	    	end
    	return 
	else
		local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
		MBUI_ContainerSlider:SetHidden(false)
    	MBUI_ContainerSlider:SetMinMax(11,#MB.BankValueTable)
    	MBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#MB.BankValueTable*25000)/3, 0, 0, 1, 1)
    	for i=1,11 do
    		_G["MBUI_Row"..i]:SetHidden(false)
    	end
    end
    MB.CurrentLastValue=last

    if #MB.BankValueTable<11 then
    	-- Прячем Слайдер
    	MBUI_ContainerSlider:SetHidden(true)
	    -- Заполнение идёт сверху
	    for i=1,#MB.BankValueTable do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(MB.BankValueTable[i].link)

			_G["MBUI_Row"..i].id=i
	    	_G["MBUI_Row"..i].ItemType=MB.BankValueTable[i].ItemType

	    	-- Регистрируем отображение тултипов при наведении на строку
		    _G["MBUI_Row"..i]:SetHandler("OnMouseEnter", function(self)

		    	-- Тут может быть любой другой якорь. Нам важен его родитель
		    	OldAnchor=_G["MBUI_Row"..i.."ButtonIcon"]:GetParent()
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,-200,0)
		    	ItemTooltip:SetLink(_G["MBUI_Row"..i.."Name"]:GetText())
		    	ItemTooltip:SetAlpha(1)
		    	ItemTooltip:SetHidden(false)
		    	_G["MBUI_Row"..i.."Highlight"]:SetDimensions(GetDimensions(_G["MBUI_Row"..i]))

		    	
		    	end)

		    _G["MBUI_Row"..i]:SetHandler("OnMouseExit", function(self)
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAlpha(0)
		    	ItemTooltip:SetHidden(true)
		    	
		    	end)

			_G["MBUI_Row"..i.."ButtonIcon"]:SetTexture(MB.BankValueTable[i].icon)

		    if not MB.BankValueTable[i].meetsUsageRequirement then
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,0,0,1)
			else
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,1,1,1)
			end

			_G["MBUI_Row"..i.."ButtonStackCount"]:SetText(MB.BankValueTable[i].stackCount)
			_G["MBUI_Row"..i.."Name"]:SetText(MB.BankValueTable[i].link)
		    if (MB.BankValueTable[i].statValue~=0) then
				_G["MBUI_Row"..i.."StatValue"]:SetText(MB.BankValueTable[i].statValue)
			else
				_G["MBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["MBUI_Row"..i.."SellPrice"]:SetText(MB.BankValueTable[i].stackCount*sellPrice.."|t24:24:EsoUI/Art/currency/currency_gold.dds|t")

			_G["MBUI_Row"..i]:SetHandler("OnMouseUp", function(self,button) 
		    	if button~=2 then return end
		    	ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..MB.BankValueTable[i].link.."]")
	    	end)
		end
		-- Заполняем вместимость банка
		local CurBankCapacity = #MB.BankValueTable
		MBUI_ContainerItemCounter:SetText("Bank: "..CurBankCapacity.." / "..MB.BankMaxCapacity)
		-- Прячем пустые строки
		for i=#MB.BankValueTable+1,11 do
			_G["MBUI_Row"..i]:SetHidden(true)
		end
    else
    	-- Показываем слайдер
    	MBUI_ContainerSlider:SetHidden(false)
	    -- Заполнение идёт снизу
	    for i=11,1,-1 do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(MB.BankValueTable[last].link)

	    	_G["MBUI_Row"..i].id=last
	    	_G["MBUI_Row"..i].ItemType=MB.BankValueTable[last].ItemType

		    -- Регистрируем отображение тултипов при наведении на строку
		    _G["MBUI_Row"..i]:SetHandler("OnMouseEnter", function(self)

		    	-- Тут может быть любой другой якорь. Нам важен его родитель
		    	OldAnchor=_G["MBUI_Row"..i.."ButtonIcon"]:GetParent()
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()

		    	if _G["MBUI_Row"..i]:GetLeft()>=480 then
		    		ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,-480,0)
		    	else
		    		ItemTooltip:SetAnchor(CENTER,OldAnchor,CENTER,500,0)
		    	end

		    	ItemTooltip:SetLink(_G["MBUI_Row"..i.."Name"]:GetText())

		    	-- Сравнительный тултип
		    	if self.ItemType==ITEMTYPE_WEAPON or self.ItemType==ITEMTYPE_ARMOR then
		    		-- Броня в банке
		    		ItemTooltip:ClearAnchors()
		    		ComparativeTooltip1:ClearAnchors()

			    	if _G["MBUI_Row"..i]:GetLeft()>=480 then
			    		ItemTooltip:SetAnchor(TOP,OldAnchor,CENTER,-480,0)
			    		ComparativeTooltip1:SetAnchor(BOTTOM,OldAnchor,CENTER,-480,0)
			    	else
			    		ItemTooltip:SetAnchor(TOP,OldAnchor,CENTER,500,0)
			    		ComparativeTooltip1:SetAnchor(BOTTOM,OldAnchor,CENTER,500,0)
			    	end	
			    	ComparativeTooltip1:SetAlpha(1)
			    	ComparativeTooltip1:SetHidden(false)
			    	ItemTooltip:ShowComparativeTooltips()
		    	end
		    	
		    	ItemTooltip:SetAlpha(1)
		    	ItemTooltip:SetHidden(false)
		    	_G["MBUI_Row"..i.."Highlight"]:SetAlpha(1)  

		    	_G["MBUI_Row"..i.."IconTimeline"]:PlayFromStart()
		    	end)

		    _G["MBUI_Row"..i]:SetHandler("OnMouseExit", function(self)
		    	ItemTooltip:ClearAnchors()
		    	ItemTooltip:ClearLines()
		    	ItemTooltip:SetAlpha(0)
		    	ItemTooltip:SetHidden(true)
		    	_G["MBUI_Row"..i.."Highlight"]:SetAlpha(0) 

		    	_G["MBUI_Row"..i.."IconTimeline"]:PlayFromEnd()

			    	-- Сравнительный тултип
			    	if self.ItemType==ITEMTYPE_WEAPON or self.ItemType==ITEMTYPE_ARMOR then
			    		ComparativeTooltip1:ClearAnchors()
				    	ItemTooltip:HideComparativeTooltips()
			    	end

		    	end)

			_G["MBUI_Row"..i.."ButtonIcon"]:SetTexture(MB.BankValueTable[last].icon)

		    if not MB.BankValueTable[last].meetsUsageRequirement then
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,0,0,1)
			else
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,1,1,1)
			end

			_G["MBUI_Row"..i.."ButtonStackCount"]:SetText(MB.BankValueTable[last].stackCount)
			_G["MBUI_Row"..i.."Name"]:SetText(MB.BankValueTable[last].link)
		    if (MB.BankValueTable[last].statValue~=0) then
				_G["MBUI_Row"..i.."StatValue"]:SetText(MB.BankValueTable[last].statValue)
			else
				_G["MBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["MBUI_Row"..i.."SellPrice"]:SetText(MB.BankValueTable[last].stackCount*sellPrice.."|t20:20:EsoUI/Art/currency/currency_gold.dds|t")

			_G["MBUI_Row"..i]:SetHandler("OnMouseUp", function(self,button) 
		    	if button~=2 then return end
		    	ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..MB.BankValueTable[self.id].link.."]")
	    	end)

			if last<=#MB.BankValueTable and last>1 then
	    		last=last-1
	    	else
	    		last=11
	    	end
		end
		-- Заполняем вместимость банка
		local CurBankCapacity = #MB.BankValueTable
		MBUI_ContainerItemCounter:SetText("Bank: "..CurBankCapacity.." / "..MB.BankMaxCapacity)
		MBUI_ContainerItemCounter:SetHidden(false)
	end
end




function MB.PL_Opened()
	debug("Event PL_Opened fired")
end

function MB.PL_Closed()
	debug("Event PL_Closed fired")
end

function MB.GB_Opened()
	debug("Event GB_Opened fired")
end

function MB.GB_Ready()
	debug("Event GB_Ready fired")
	MB.gcount()
end



function commandHandler( text )
	if text=="cls" then
		MB.items.Guilds={}
		MB.params.MBUI_Menu=nil
		MB.params.MBUI_Container=nil
		ReloadUI()
	elseif text=="hide" then
		MB.params.hidden=true
		MBUI_Menu:SetHidden(true)
	elseif text=="show" then
		MB.params.hidden=false
		MBUI_Menu:SetHidden(false)
	elseif text=="p" then
    	MB.CurrentLastValue=11
		MB.PrepareBankValues("Player")
		MB.FillBank(MB.CurrentLastValue)
    	MBUI_Container:SetHidden(false)
    	MB.PreviousButtonClicked=nil
		MB.LastButtonClicked=nil
	elseif text=="g" then
    	MB.CurrentLastValue=11
		MB.PrepareBankValues("Guild",1)
		MB.FillBank(MB.CurrentLastValue)
    	MBUI_Container:SetHidden(false)
		MB.PreviousButtonClicked=nil
		MB.LastButtonClicked=nil
	else
		d("/mb hide - hide main window")
		d("/mb show - show main window")
		d("/mb p - show player bank")
		d("/mb g - show guild bank")
		d("/mb cls - clear all data and reloadui ")
	end
end

function MB.gcount()
	MB.GCountOnUpdateTimer=GetGameTimeMilliseconds()
	MB.GCountOnUpdateReady=true
end

function MB.MouseUp(self)
	local name = self:GetName()
    local left = self:GetLeft()
    local top = self:GetTop()

    if name=="MBUI_Menu" then
    	debug("Menu saved")
    	MB.params.MBUI_Menu={left,top}
    elseif name=="MBUI_Container" then
    	debug("Container saved")
    	MB.params.MBUI_Container={left,top}
    else
    	debug("Unknown window")
    end
end

function MB.Update(self)
if (not MB.AddonReady) then return end

	local EscMenuHidden = ZO_GameMenu_InGame:IsHidden()
	local interactHidden = ZO_InteractWindow:IsHidden()

	if (EscMenuHidden == false) then
		MBUI_Container:SetHidden(true)
		MBUI_Menu:SetHidden(true)
	elseif (interactHidden == false) then
		MBUI_Container:SetHidden(true)
		MBUI_Menu:SetHidden(true)
	elseif (MB.params.hidden==false) then
		MBUI_Menu:SetHidden(false)
	elseif (MB.params.hidden==true) then
		MBUI_Menu:SetHidden(true)
	end

	--Хак на проверку инвентаря спустя Х сек после первого срабатывания эвента
	if MB.GCountOnUpdateReady and (GetGameTimeMilliseconds()-MB.GCountOnUpdateTimer>=1000) then
		MB.GCountOnUpdateReady=false
	    local guildbankid=GetSelectedGuildBankId()
	    local guildname=tostring(GetGuildName(guildbankid))
	    MB.items.Guilds[guildbankid][guildname]={}
		d("Data saved for "..guildname)
	    local sv=false
	      	
		bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

		sv = MB.items.Guilds[guildbankid][guildname]

		for i=1, #ZO_GuildBankBackpack.data do
			slotIndex=ZO_GuildBankBackpack.data[i].data.slotIndex

			link = GetItemLink(BAG_GUILDBANK,slotIndex)
			iconFile=ZO_GuildBankBackpack.data[i].data.iconFile
			name=ZO_GuildBankBackpack.data[i].data.name
			stackCount=ZO_GuildBankBackpack.data[i].data.stackCount
			statValue=ZO_GuildBankBackpack.data[i].data.statValue
			sellPrice=ZO_GuildBankBackpack.data[i].data.sellPrice
			quality=ZO_GuildBankBackpack.data[i].data.quality
			age=ZO_GuildBankBackpack.data[i].data.age
			bagId=ZO_GuildBankBackpack.data[i].data.bagId
			equipType=ZO_GuildBankBackpack.data[i].data.equipType
			isJunk=ZO_GuildBankBackpack.data[i].data.isJunk
			itemInstanceId=ZO_GuildBankBackpack.data[i].data.itemInstanceId
			locked=ZO_GuildBankBackpack.data[i].data.locked
			meetsUsageRequirement=ZO_GuildBankBackpack.data[i].data.meetsUsageRequirement
			slotType=ZO_GuildBankBackpack.data[i].data.slotType
			searchData=ZO_GuildBankBackpack.data[i].data.searchData
			filterData=ZO_GuildBankBackpack.data[i].data.filterData
			ItemType=GetItemType(BAG_GUILDBANK,slotIndex)


			clearlink =string.gsub(link, "|h.+|h", "|h"..tostring(name).."|h")

			sv[#sv+1] = 
			{
				["link"] = tostring(clearlink),
				["icon"] = tostring(iconFile),
				["name"] = tostring(name),
				["stackCount"] = stackCount,
				["statValue"] = statValue,
				["sellPrice"] = sellPrice,
				["quality"] = quality,
				["age"]=quality,
				["bagId"]=bagId,
				["equipType"]=equipType,
				["isJunk"]=isJunk,
				["itemInstanceId"]=tostring(itemInstanceId),
				["locked"]=locked,
				["meetsUsageRequirement"]=meetsUsageRequirement,
				["slotType"]=slotType,
				["searchData"]=searchData,
				["filterData"]=filterData,
				["ItemType"]=ItemType

			}
		end
	end
end

function MB.HideContainer(value)
	debug("StartPrevious:"..tostring(MB.PreviousButtonClicked))
	debug("StartLast:"..tostring(MB.LastButtonClicked))
	if MB.PreviousButtonClicked==MB.LastButtonClicked then
		MBUI_Container:SetHidden(true)
		MB.PreviousButtonClicked=nil
		MB.LastButtonClicked=nil
	else
		MBUI_Container:SetHidden(false)
	end
	debug("FinishPrevious:"..tostring(MB.PreviousButtonClicked))
	debug("FinishLast:"..tostring(MB.LastButtonClicked))
end

--Инициализация Аддона
EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_ADD_ON_LOADED, MB.OnLoad)