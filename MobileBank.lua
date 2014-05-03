--	MobileBank v0.36
----------------------------
--	Список команд:
-- /mb cls - очистить собраные данные
-- /mb hide/show - скрыть/показать главную панель
-- /mb p - Показать банк игрока
-- /mb g - Показать банки гильдий
-- /mb i - Показать инвентари персонажей
----------------------------

MB = {}

MB.version=0.36

MB.dataDefaultItems = {
	Guilds={},
	Chars={}
}

for i=1,GetNumGuilds() do
	MB.dataDefaultItems.Guilds[GetGuildName(i)]={}
end 

MB.dataDefaultParams = {
	MBUI_Menu = {10,10},
	MBUI_Container = {530,380}
}

MB.UI_Movable=false
MB.AddonReady=false
MB.TempData={}
MB.GCountOnUpdateTimer=0
MB.GuildBankIdToPrepare=1
MB.Debug=false
MB.PreviousButtonClicked=nil
MB.LastButtonClicked=nil
MB.CharsName=nil
MB.GuildsName=nil
MB.FilterChildrens=nil
MB.CurrentFilterType="All"

 local function debug(text)
	if MB.Debug then
		d(text)
	end
end

function MB.OnLoad(eventCode, addOnName)
	if (addOnName ~= "MobileBank" ) then return end

	--добавляем команду
	SLASH_COMMANDS["/mb"] = MB.commandHandler

	--Регистрация эвентов
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_OPEN_BANK, MB.PL_Opened)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_CLOSE_BANK, MB.PL_Closed)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_OPEN_GUILD_BANK, MB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_GUILD_BANK_ITEMS_READY, MB.GB_Ready)

	-- Сохранение лута
	EVENT_MANAGER:RegisterForEvent("MobileBank", EVENT_LOOT_RECEIVED, MB.SavePlayerInvent)

	--Загрузка сохраненных переменных
	MB.items= ZO_SavedVars:NewAccountWide( "MB_SavedVars" , 2, "Items" , MB.dataDefaultItems, nil )
	MB.params= ZO_SavedVars:New( "MB_SavedVars" , 2, "Params" , MB.dataDefaultParams, nil )

	thisCharName=GetUnitName("player")

	MB.items.Chars[thisCharName]={}

	MB.CharsName={}
	for k,v in pairs(MB.items.Chars) do
		MB.CharsName[#MB.CharsName+1]=k
	end

	MB.GuildsName={}
	for k,v in pairs(MB.items.Guilds) do
		MB.GuildsName[#MB.GuildsName+1]=k
	end

	-- Обновляем лут
	MB.SavePlayerInvent()

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
	MB_UI.Menu.Button.Bank = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Bank",MBUI_Menu,CT_BUTTON)
	MB_UI.Menu.Button.Invent = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Invent",MBUI_Menu,CT_BUTTON)
	-- MB_UI.Menu.Button.Move = WINDOW_MANAGER:CreateControl("MBUI_Menu_Button_Move",MBUI_Menu,CT_BUTTON)

	--Обработчики событий

    -- Клик по гильдии
    MB_UI.Menu.Button.Guild:SetHandler("OnClicked" , function(self)
    	local bool = not(MBUI_Container:IsHidden())
    	MB.PreviousButtonClicked=MB.LastButtonClicked
		MB.LastButtonClicked="Guild"

    	MB.CurrentLastValue=11

		MB.PrepareBankValues("Guild",1)
		-- MB.FillBank(MB.CurrentLastValue,MB.BankValueTable)
		MB.FilterBank(MB.CurrentLastValue,MB.CurrentFilterType)
    	MB.HideContainer(bool)
    end )

    -- Клик по банку
    MB_UI.Menu.Button.Bank:SetHandler( "OnClicked" , function(self)
    	local bool = not(MBUI_Container:IsHidden())
    	MB.PreviousButtonClicked=MB.LastButtonClicked
		MB.LastButtonClicked="Bank"

    	MB.CurrentLastValue=11

		MB.PrepareBankValues("Bank")
    	-- MB.FillBank(MB.CurrentLastValue,MB.BankValueTable)
    	MB.FilterBank(MB.CurrentLastValue,MB.CurrentFilterType)
    	MB.HideContainer(bool)
    end )

    -- Клик по инвентарю
    MB_UI.Menu.Button.Invent:SetHandler( "OnClicked" , function(self)
    	local bool = not(MBUI_Container:IsHidden())
    	MB.PreviousButtonClicked=MB.LastButtonClicked
		MB.LastButtonClicked="Invent"

    	MB.CurrentLastValue=11

		MB.PrepareBankValues("Invent",1)
    	-- MB.FillBank(MB.CurrentLastValue,MB.BankValueTable)
    	MB.FilterBank(MB.CurrentLastValue,MB.CurrentFilterType)
    	MB.HideContainer(bool)
    end )


    MBUI_Menu:SetHandler("OnMouseUp" , function(self) MB.MouseUp(self) end)
    MBUI_Container:SetHandler("OnMouseUp" , function(self) MB.MouseUp(self) end)

	--Настройки меню
	MB_UI.Menu:SetAnchor(TOPLEFT,MBUI,TOPLEFT,MB.params.MBUI_Menu[1],MB.params.MBUI_Menu[2])
	MB_UI.Menu:SetDimensions(200,45)
	MB_UI.Menu:SetMouseEnabled(true)
	MB_UI.Menu:SetMovable(true)

	--Фон
	MB_UI.Menu.BG:SetAnchor(CENTER,MBUI_Menu,CENTER,0,0)
	MB_UI.Menu.BG:SetDimensions(200,40)
	MB_UI.Menu.BG:SetCenterColor(0,0,0,1)
	MB_UI.Menu.BG:SetEdgeColor(0,0,0,0)
	MB_UI.Menu.BG:SetAlpha(0.5)

	--Заголовок
	MB_UI.Menu.Title:SetAnchor(CENTER,MBUI_Menu,TOP,0,13)
	MB_UI.Menu.Title:SetFont("ZoFontGame" )
	MB_UI.Menu.Title:SetColor(255,255,255,1.5)
	MB_UI.Menu.Title:SetText( "|cff8000Mobile Bank|" )

	-- Кнопка "Гильдия"
	MB_UI.Menu.Button.Guild:SetAnchor(BOTTOMLEFT,MBUI_Menu,BOTTOMLEFT,0,0)
	MB_UI.Menu.Button.Guild:SetText("[Guild]")
	MB_UI.Menu.Button.Guild:SetDimensions(70,25)
	MB_UI.Menu.Button.Guild:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Guild:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Guild:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "Банк"
	MB_UI.Menu.Button.Bank:SetAnchor(BOTTOM,MBUI_Menu,BOTTOM,0,0)
	MB_UI.Menu.Button.Bank:SetText("[Bank]")
	MB_UI.Menu.Button.Bank:SetDimensions(70,25)
	MB_UI.Menu.Button.Bank:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Bank:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Bank:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "Инвентарь"
	MB_UI.Menu.Button.Invent:SetAnchor(BOTTOMRIGHT,MBUI_Menu,BOTTOMRIGHT,0,0)
	MB_UI.Menu.Button.Invent:SetText("[Invent]")
	MB_UI.Menu.Button.Invent:SetDimensions(70,25)
	MB_UI.Menu.Button.Invent:SetFont("ZoFontGameBold")
	MB_UI.Menu.Button.Invent:SetNormalFontColor(0,255,255,.7)
	MB_UI.Menu.Button.Invent:SetMouseOverFontColor(0.8,0.4,0,1)
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
    for i=1,#MB.GuildsName do

    	local guildname=tostring(MB.GuildsName[i])
    	WINDOW_MANAGER:CreateControl("MBUI_ContainerTitleGuildButton"..i,MBUI_ContainerTitle,CT_BUTTON)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetParent(MBUI_ContainerTitleGuildButtons)
		_G["MBUI_ContainerTitleGuildButton"..i]:SetFont("ZoFontGame" )
		nextXstep=(MBUI_Container:GetWidth()/#MB.GuildsName*i)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetDimensions(MBUI_Container:GetWidth()/#MB.GuildsName,20)
    	-- Делаем поправку на ширину самой кнопки
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetAnchor(TOP,MBUI_Container,TOPLEFT,nextXstep-_G["MBUI_ContainerTitleGuildButton"..i]:GetWidth()/2,40)
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetText("["..guildname.."]")
    	_G["MBUI_ContainerTitleGuildButton"..i]:SetNormalFontColor(0,255,255,.7)
		_G["MBUI_ContainerTitleGuildButton"..i]:SetMouseOverFontColor(0.8,0.4,0,1)

		_G["MBUI_ContainerTitleGuildButton"..i]:SetHandler( "OnClicked" , function(self)
			MB.PrepareBankValues("Guild",i)
			MB.SortPreparedValues()
			-- MB.FillBank(11,MB.BankValueTable)
			MB.FilterBank(11,MB.CurrentFilterType)
		 end)
	end

    -- Создаем кнопки для переключения между Игроками
	local nextXstep=0
    for i=1,#MB.CharsName do

    	local charname=tostring(MB.CharsName[i])
    	WINDOW_MANAGER:CreateControl("MBUI_ContainerTitleInventButton"..i,MBUI_ContainerTitle,CT_BUTTON)
    	_G["MBUI_ContainerTitleInventButton"..i]:SetParent(MBUI_ContainerTitleInventButtons)
		_G["MBUI_ContainerTitleInventButton"..i]:SetFont("ZoFontGame" )
		nextXstep=(MBUI_Container:GetWidth()/#MB.CharsName*i)
    	_G["MBUI_ContainerTitleInventButton"..i]:SetDimensions(MBUI_Container:GetWidth()/#MB.CharsName,20)
    	-- Делаем поправку на ширину самой кнопки
    	_G["MBUI_ContainerTitleInventButton"..i]:SetAnchor(TOP,MBUI_Container,TOPLEFT,nextXstep-_G["MBUI_ContainerTitleInventButton"..i]:GetWidth()/2,40)
    	_G["MBUI_ContainerTitleInventButton"..i]:SetText("["..charname.."]")
    	_G["MBUI_ContainerTitleInventButton"..i]:SetNormalFontColor(0,255,255,.7)
		_G["MBUI_ContainerTitleInventButton"..i]:SetMouseOverFontColor(0.8,0.4,0,1)

		_G["MBUI_ContainerTitleInventButton"..i]:SetHandler( "OnClicked" , function(self)
			MB.PrepareBankValues("Invent",i)
			MB.SortPreparedValues()
			-- MB.FillBank(11,MB.BankValueTable)
			MB.FilterBank(11,MB.CurrentFilterType)	
		 end)
	end

    -- Правим строки (созданы из xml)
	for i = 1, 11 do
	    local dynamicControl = CreateControlFromVirtual("MBUI_Row", MBUI_Container, "TemplateRow",i)

	    -- Строка
	    local fromtop=150
	    _G["MBUI_Row"..i]:SetAnchor(TOP,MBUI_Container,TOP,0,fromtop+52*(i-1))
	    -- _G["MBUI_Row"..i]:SetDimensions (530,52)

	    -- Анимация
	    _G["MBUI_Row"..i.."IconTimeline"]=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_IconAnimation",_G["MBUI_Row"..i.."ButtonIcon"])
	    -- _G["MBUI_Row"..i.."CountTimeline"]=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_IconAnimation",_G["MBUI_Row"..i.."ButtonStackCount"])

	end
end

function MB.PrepareBankValues(PrepareType,IdToPrepare)
	MB.GuildBankIdToPrepare=GuildBankIdToPrepare
	MB.BankValueTable={}

	if PrepareType=="Bank" then
		debug("Preparing Player values")
		bagIcon, bagSlots=GetBagInfo(BAG_BANK)
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
					["ItemLink"]=tostring(clearlink),
					["icon"] = tostring(icon),
					["ItemName"]=tostring(name),
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
		MB.BankValueTable.CurSlots=#MB.BankValueTable
		MB.BankValueTable.MaxSlots=bagSlots

		MBUI_ContainerTitleInventButtons:SetHidden(true)
		MBUI_ContainerTitleGuildButtons:SetHidden(true)
	elseif PrepareType=="Invent" then
		debug("Preparing Inventory values")

		local LoadingCharName=MB.CharsName[IdToPrepare]

		MB.BankValueTable=MB.items.Chars[LoadingCharName]

		MBUI_ContainerTitleInventButtons:SetHidden(false)
		MBUI_ContainerTitleGuildButtons:SetHidden(true)
	elseif PrepareType=="Guild" then
		bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)
		debug("Preparing Guild values")

	    local guildname=tostring(MB.GuildsName[IdToPrepare])
		MB.BankValueTable=MB.items.Guilds[guildname]
		
		MBUI_ContainerTitleInventButtons:SetHidden(true)
		MBUI_ContainerTitleGuildButtons:SetHidden(false)
	else
		debug("Unknown prepare type: "..tostring(PrepareType))
	end

    MBUI_ContainerSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
		-- MB.FillBank(value,MB.BankValueTable)
		MB.FilterBank(value,MB.CurrentFilterType)
    end)

	MB.SortPreparedValues()
	return MB.BankValueTable
end

-- Инициализация фильтов
function MB.FilterInit(self)
	MB.FilterChildrens={}
		for i=1,self:GetNumChildren() do
			MB.FilterChildrens[i]=self:GetChild(i)
		end
	-- Анимация
	for k,v in pairs(MB.FilterChildrens) do
		v.NormalAnimation=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_FilterAnimation",_G[tostring(v:GetName().."TextureNormal")])
		v.HighlightAnimation=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_FilterAnimation",_G[tostring(v:GetName().."TextureHighlight")])
		v.PressedAnimation=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_FilterAnimation",_G[tostring(v:GetName().."TexturePressed")])
	end

	MBUI_ContainerTitleFilterAll.PressedAnimation:PlayInstantlyToEnd()
	MBUI_ContainerTitleFilterAllTexturePressed:SetAlpha(1)
end

function MB.FilterEnter(self)
	_G[tostring(self:GetName().."TextureHighlight")]:SetAlpha(0.75)
	self.NormalAnimation:PlayFromStart()
	self.HighlightAnimation:PlayFromStart()
end

function MB.FilterExit(self)
	_G[tostring(self:GetName().."TextureHighlight")]:SetAlpha(0)
	self.NormalAnimation:PlayFromEnd()
	self.HighlightAnimation:PlayFromEnd()
end

function MB.FilterClicked(self,filtertype)
	MB.FilterBank(11,filtertype)
	MBUI_ContainerSlider:SetValue(11)

	for k,v in pairs(MB.FilterChildrens) do
		_G[v:GetName().."TexturePressed"]:SetAlpha(0)
	end

	_G[self:GetName().."TexturePressed"]:SetAlpha(1)
	self.PressedAnimation:PlayInstantlyToEnd()
end

-- Типы фильтров:
-- All, Weapon, Apparel,Consumable, Materials,Miscellaceous,Junk

-- Не знаю что это за типы.
-- ["ITEMTYPE_NONE"] = 0
-- ["ITEMTYPE_PLUG"] = 3
-- ["ITEMTYPE_TABARD"] = 15
function MB.FilterBank(position,FilterType)
	local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
	if not position then position=11 end

	MB.BankValueTableFiltered={}

	Weapon={
		ITEMTYPE_WEAPON
	}
	Apparel={
		ITEMTYPE_ARMOR,ITEMTYPE_DISGUISE,ITEMTYPE_COSTUME
	}
	Consumable={
		ITEMTYPE_POTION,ITEMTYPE_RECIPE,ITEMTYPE_FOOD,ITEMTYPE_DRINK,ITEMTYPE_CONTAINER,ITEMTYPE_POISON
	}
	Materials={
		ITEMTYPE_ALCHEMY_BASE,ITEMTYPE_BLACKSMITHING_MATERIAL,ITEMTYPE_BLACKSMITHING_RAW_MATERIAL,ITEMTYPE_CLOTHIER_MATERIAL,
		ITEMTYPE_CLOTHIER_RAW_MATERIAL,ITEMTYPE_ENCHANTING_RUNE,ITEMTYPE_INGREDIENT,ITEMTYPE_RAW_MATERIAL,ITEMTYPE_REAGENT,
		ITEMTYPE_STYLE_MATERIAL,ITEMTYPE_WEAPON_TRAIT,ITEMTYPE_WOODWORKING_MATERIAL,ITEMTYPE_WOODWORKING_RAW_MATERIAL,ITEMTYPE_ARMOR_TRAIT,
		ITEMTYPE_SPICE,ITEMTYPE_FLAVORING,ITEMTYPE_ADDITIVE,ITEMTYPE_ARMOR_BOOSTER,ITEMTYPE_BLACKSMITHING_BOOSTER,ITEMTYPE_ENCHANTMENT_BOOSTER,
		ITEMTYPE_WEAPON_BOOSTER,ITEMTYPE_WOODWORKING_BOOSTER,ITEMTYPE_CLOTHIER_BOOSTER
	}
	Miscellaceous={
		ITEMTYPE_SCROLL,ITEMTYPE_TROPHY,ITEMTYPE_TOOL,ITEMTYPE_SOUL_GEM,ITEMTYPE_SIEGE,ITEMTYPE_LOCKPICK,ITEMTYPE_GLYPH_ARMOR,
		ITEMTYPE_GLYPH_JEWELRY,ITEMTYPE_GLYPH_WEAPON,ITEMTYPE_AVA_REPAIR,ITEMTYPE_COLLECTIBLE,ITEMTYPE_LURE
	}
	Junk={
		ITEMTYPE_TRASH,ITEMTYPE_NONE,ITEMTYPE_PLUG,ITEMTYPE_TABARD,
	}

	if FilterType=="Weapon" or FilterType=="Apparel" or FilterType=="Consumable" or FilterType=="Materials" or FilterType=="Miscellaceous" or FilterType=="Junk" then
		MB.CurrentFilterType=FilterType
		for k,v in pairs(MB.BankValueTable) do
			for k1,v1 in pairs(_G[FilterType]) do
				if type(v)=="table" then
					if v.ItemType==v1 then
						debug(v.ItemName.." is "..tostring(FilterType))
						MB.BankValueTableFiltered[#MB.BankValueTableFiltered+1]=v
					end
				end
			end
		end
		MB.FillBank(position,MB.BankValueTableFiltered)
		if #MB.BankValueTableFiltered>11 then
			MBUI_ContainerSlider:SetMinMax(11,#MB.BankValueTableFiltered)
			MBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#MB.BankValueTableFiltered*25000)/3, 0, 0, 1, 1)
			MBUI_ContainerSlider:SetHidden(false)
		else
			MBUI_ContainerSlider:SetHidden(true)
		end
	elseif FilterType=="All" then
		MB.CurrentFilterType=FilterType
		MB.FillBank(position,MB.BankValueTable)
		if #MB.BankValueTable>11 then
			MBUI_ContainerSlider:SetMinMax(11,#MB.BankValueTable)
			MBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#MB.BankValueTable*25000)/3, 0, 0, 1, 1)
			MBUI_ContainerSlider:SetHidden(false)
		else
			MBUI_ContainerSlider:SetHidden(true)
		end
	else
		d("No such FilterType: "..tostring(FilterType))
		MB.FillBank(position,MB.BankValueTable)
		if #MB.BankValueTable>11 then
			MBUI_ContainerSlider:SetMinMax(11,#MB.BankValueTable)
			MBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#MB.BankValueTable*25000)/3, 0, 0, 1, 1)
			MBUI_ContainerSlider:SetHidden(false)
		else
			MBUI_ContainerSlider:SetHidden(true)
		end
	end
end

-- сортировка таблицы
function MB.SortPreparedValues()
	function compare(a,b)
		return a["ItemName"]<b["ItemName"]	
	end

	table.sort(MB.BankValueTable,compare)
end

-- Заполнение банка
function MB.FillBank(last,TableToFillFrom)
-- Технические функции
-- Функции отображения и сокрытия тултипов при наведении мышки
	function MB.TooltipEnter(self)
		-- Тут может быть любой другой якорь. Нам важен его родитель
		ItemTooltip:ClearAnchors()
		ItemTooltip:ClearLines()

		if self:GetLeft()>=480 then
			ItemTooltip:SetAnchor(CENTER,self,CENTER,-480,0)
		else
			ItemTooltip:SetAnchor(CENTER,self,CENTER,500,0)
		end

		ItemTooltip:SetLink(TableToFillFrom[self.id].ItemLink)

		-- Сравнительный тултип
		if self.ItemType==ITEMTYPE_WEAPON or self.ItemType==ITEMTYPE_ARMOR then
			-- Броня в банке
			ItemTooltip:ClearAnchors()
			ComparativeTooltip1:ClearAnchors()

	    	if self:GetLeft()>=480 then
	    		ItemTooltip:SetAnchor(TOP,self,CENTER,-480,0)
	    		ComparativeTooltip1:SetAnchor(BOTTOM,self,CENTER,-480,0)
	    	else
	    		ItemTooltip:SetAnchor(TOP,self,CENTER,500,0)
	    		ComparativeTooltip1:SetAnchor(BOTTOM,self,CENTER,500,0)
	    	end	
	    	ComparativeTooltip1:SetAlpha(1)
	    	ComparativeTooltip1:SetHidden(false)
	    	ItemTooltip:ShowComparativeTooltips()
		end
		
		ItemTooltip:SetAlpha(1)
		ItemTooltip:SetHidden(false)
		_G[tostring(self:GetName().."Highlight")]:SetAlpha(1)  

		self.IconTimeline=ANIMATION_MANAGER:CreateTimelineFromVirtual("MBUI_IconAnimation",_G[tostring(self:GetName().."ButtonIcon")])
		self.IconTimeline:PlayFromStart()
	end

	function MB.TooltipExit(self)
		ItemTooltip:ClearAnchors()
		ItemTooltip:ClearLines()
		ItemTooltip:SetAlpha(0)
		ItemTooltip:SetHidden(true)
		_G[tostring(self:GetName().."Highlight")]:SetAlpha(0)

		self.IconTimeline:PlayFromEnd()

			-- Сравнительный тултип
			if self.ItemType==ITEMTYPE_WEAPON or self.ItemType==ITEMTYPE_ARMOR then
				ComparativeTooltip1:ClearAnchors()
		    	ItemTooltip:HideComparativeTooltips()
			end

	end

	-- Функция прокрутки колёсиком
	function MB.MoveScrollerWheel(self,delta)
		local calculatedvalue=MB.CurrentLastValue-delta
		if (calculatedvalue>=11) and (calculatedvalue<=#TableToFillFrom) then
			-- MB.FillBank(calculatedvalue,MB.BankValueTable)
			MB.FilterBank(calculatedvalue,MB.CurrentFilterType)
			MBUI_ContainerSlider:SetValue(calculatedvalue)
		end
	end


	if not TableToFillFrom then d("Wrong TableToFillFrom") return end

	if last<=1 then debug("last<=1") return end
    if (#TableToFillFrom==0) then 
    	d("No data avaliable.")
    	MBUI_ContainerItemCounter:SetHidden(true)
    	MBUI_ContainerSlider:SetHidden(true)
    	MB.HideContainer(true)
	    	for i=1,11 do
	    		_G["MBUI_Row"..i]:SetHidden(true)
	    	end
    	return 
	elseif last>1 and last<=11 then
    	for i=1,11 do
    		_G["MBUI_Row"..i]:SetHidden(false)
    	end
	else
    	for i=1,11 do
    		_G["MBUI_Row"..i]:SetHidden(false)
    	end
    end
    MB.CurrentLastValue=last

    if #TableToFillFrom<11 then
    	-- Прячем Слайдер
    	MBUI_ContainerSlider:SetHidden(true)
	    -- Заполнение идёт сверху
	    for i=1,#TableToFillFrom do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(TableToFillFrom[i].ItemLink)

			_G["MBUI_Row"..i].id=i
	    	_G["MBUI_Row"..i].ItemType=TableToFillFrom[i].ItemType

			_G["MBUI_Row"..i.."ButtonIcon"]:SetTexture(TableToFillFrom[i].icon)

		    if not TableToFillFrom[i].meetsUsageRequirement then
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,0,0,1)
			else
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,1,1,1)
			end

			_G["MBUI_Row"..i.."ButtonStackCount"]:SetText(TableToFillFrom[i].stackCount)
			_G["MBUI_Row"..i.."Name"]:SetText(TableToFillFrom[i].ItemLink)
		    if (TableToFillFrom[i].statValue~=0) then
				_G["MBUI_Row"..i.."StatValue"]:SetText(TableToFillFrom[i].statValue)
			else
				_G["MBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["MBUI_Row"..i.."SellPrice"]:SetText(TableToFillFrom[i].stackCount*sellPrice.."|t24:24:EsoUI/Art/currency/currency_gold.dds|t")

			_G["MBUI_Row"..i]:SetHandler("OnMouseUp", function(self,button) 
		    	if button~=2 then return end
		    	ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..TableToFillFrom[i].ItemLink.."]")
	    	end)
		end

		-- Прячем пустые строки
		for i=#TableToFillFrom+1,11 do
			_G["MBUI_Row"..i]:SetHidden(true)
		end
		-- Заполняем вместимость банка
		local CurBankCapacity = TableToFillFrom.CurSlots or #TableToFillFrom
		local BankMaxCapacity = TableToFillFrom.MaxSlots or bagSlots

		MBUI_ContainerItemCounter:SetText("Bank: "..CurBankCapacity.." / "..BankMaxCapacity)
		MBUI_ContainerItemCounter:SetHidden(false)
    else
    	-- Показываем слайдер
    	MBUI_ContainerSlider:SetHidden(false)
	    -- Заполнение идёт снизу
	    for i=11,1,-1 do
	    	debug("last: "..tostring(last))
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(TableToFillFrom[last].ItemLink)

	    	_G["MBUI_Row"..i].id=last
	    	_G["MBUI_Row"..i].ItemType=TableToFillFrom[last].ItemType

			_G["MBUI_Row"..i.."ButtonIcon"]:SetTexture(TableToFillFrom[last].icon)

		    if not TableToFillFrom[last].meetsUsageRequirement then
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,0,0,1)
			else
				_G["MBUI_Row"..i.."ButtonIcon"]:SetColor(1,1,1,1)
			end

			_G["MBUI_Row"..i.."ButtonStackCount"]:SetText(TableToFillFrom[last].stackCount)
			_G["MBUI_Row"..i.."Name"]:SetText(TableToFillFrom[last].ItemLink)
		    if (TableToFillFrom[last].statValue~=0) then
				_G["MBUI_Row"..i.."StatValue"]:SetText(TableToFillFrom[last].statValue)
			else
				_G["MBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["MBUI_Row"..i.."SellPrice"]:SetText(TableToFillFrom[last].stackCount*sellPrice.."|t20:20:EsoUI/Art/currency/currency_gold.dds|t")

			_G["MBUI_Row"..i]:SetHandler("OnMouseUp", function(self,button) 
		    	if button~=2 then return end
		    	ZO_ChatWindowTextEntryEditBox:SetText(tostring(ZO_ChatWindowTextEntryEditBox:GetText()).."["..TableToFillFrom[self.id].ItemLink.."]")
	    	end)

			if last<=#TableToFillFrom and last>1 then
	    		last=last-1
	    	else
	    		last=11
	    	end
		end
		-- Заполняем вместимость банка
		local CurBankCapacity = TableToFillFrom.CurSlots or #TableToFillFrom
		local BankMaxCapacity = TableToFillFrom.MaxSlots or bagSlots

		MBUI_ContainerItemCounter:SetText("Bank: "..CurBankCapacity.." / "..BankMaxCapacity)
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



function MB.commandHandler( text )
	if text=="cls" then
		MB.items.Guilds={}
		MB.items.Chars={}
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
		MB.PrepareBankValues("Bank")
		-- MB.FillBank(MB.CurrentLastValue,MB.BankValueTable)
		MB.FilterBank(MB.CurrentLastValue,MB.CurrentFilterType)
    	MBUI_Container:SetHidden(false)
    	MB.PreviousButtonClicked=nil
		MB.LastButtonClicked=nil
	elseif text=="i" then
    	MB.CurrentLastValue=11
		MB.PrepareBankValues("Invent",1)
		-- MB.FillBank(MB.CurrentLastValue,MB.BankValueTable)
		MB.FilterBank(MB.CurrentLastValue,MB.CurrentFilterType)
    	MBUI_Container:SetHidden(false)
    	MB.PreviousButtonClicked=nil
		MB.LastButtonClicked=nil
	elseif text=="g" then
    	MB.CurrentLastValue=11
		MB.PrepareBankValues("Guild",1)
		-- MB.FillBank(MB.CurrentLastValue,MB.BankValueTable)
		MB.FilterBank(MB.CurrentLastValue,MB.CurrentFilterType)
    	MBUI_Container:SetHidden(false)
		MB.PreviousButtonClicked=nil
		MB.LastButtonClicked=nil
	else
		d("/mb hide - hide main window")
		d("/mb show - show main window")
		d("/mb p - show player bank")
		d("/mb g - show guild bank")
		d("/mb i - show chars inventories")
		d("/mb cls - clear all data and reloadui")
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

function MB.SavePlayerInvent()
	bagIcon, bagSlots=GetBagInfo(BAG_BACKPACK)
	MB.ItemCounter=0
	debug("ThisCharName: "..tostring(thisCharName))
	debug("Items in Table Chars:"..tostring(#MB.items.Chars[thisCharName]))
	MB.items.Chars[thisCharName]={}
	debug("Items in Table Chars after clean:"..tostring(#MB.items.Chars[thisCharName]))

	while (MB.ItemCounter < bagSlots) do
		if GetItemName(BAG_BACKPACK,MB.ItemCounter)~="" then

			--Избавляемся от мусора при сохранении
			name = zo_strformat(SI_TOOLTIP_ITEM_NAME, GetItemName(BAG_BACKPACK, MB.ItemCounter))
			link = GetItemLink(BAG_BACKPACK,MB.ItemCounter)
			clearlink =string.gsub(link, "|h.+|h", "|h"..tostring(name).."|h")

			stackCount = GetSlotStackSize(BAG_BACKPACK,MB.ItemCounter)
			statValue = GetItemStatValue(BAG_BACKPACK,MB.ItemCounter)
			icon, stack, sellPrice, meetsUsageRequirement, locked, equipType, itemStyle, quality = GetItemInfo(BAG_BACKPACK,MB.ItemCounter)
			ItemType=GetItemType(BAG_BACKPACK,MB.ItemCounter)
			start,finish=string.find(link, "%d+")
			id=tonumber(string.sub(link,start,finish))

			MB.items.Chars[thisCharName][#MB.items.Chars[thisCharName]+1]={
				["ItemLink"]=tostring(clearlink),
				["icon"] = tostring(icon),
				["ItemName"]=tostring(name),
				["stackCount"]=stackCount,
				["StatValue"]=statValue,
				["sellPrice"] = sellPrice,
				["quality"] = quality,
				["meetsUsageRequirement"]=meetsUsageRequirement,
				["ItemType"]=ItemType,
				["Id"]=id
			}
		end
		MB.ItemCounter=MB.ItemCounter+1
	end
	local itemsToCheck=bagSlots
	while not CheckInventorySpaceSilently(itemsToCheck) do
		itemsToCheck=itemsToCheck-1
	end

	MB.items.Chars[thisCharName].CurSlots=bagSlots-itemsToCheck
	MB.items.Chars[thisCharName].MaxSlots=bagSlots
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
	    local guildbankid=GetSelectedGuildBankId() or 0
	    local guildname=tostring(GetGuildName(guildbankid)) or 0

	    if guildname=="" then d("Cannot save variables. Try again.") return end

	    MB.items.Guilds[guildname]={}
		d("Data saved for "..guildname)
	      	
		bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

		local sv = MB.items.Guilds[guildname]

		for i=1, #ZO_GuildBankBackpack.data do
			slotIndex=ZO_GuildBankBackpack.data[i].data.slotIndex

			link = GetItemLink(BAG_GUILDBANK,slotIndex)
			iconFile=ZO_GuildBankBackpack.data[i].data.iconFile
			name=ZO_GuildBankBackpack.data[i].data.name
			stackCount=ZO_GuildBankBackpack.data[i].data.stackCount
			statValue=ZO_GuildBankBackpack.data[i].data.statValue
			sellPrice=ZO_GuildBankBackpack.data[i].data.sellPrice
			quality=ZO_GuildBankBackpack.data[i].data.quality
			meetsUsageRequirement=ZO_GuildBankBackpack.data[i].data.meetsUsageRequirement
			ItemType=GetItemType(BAG_GUILDBANK,slotIndex)

			clearlink =string.gsub(link, "|h.+|h", "|h"..tostring(name).."|h")
			start,finish=string.find(link, "%d+")
			id=tonumber(string.sub(link,start,finish))

			sv[#sv+1] = 
			{
				["ItemLink"] = tostring(clearlink),
				["icon"] = tostring(iconFile),
				["ItemName"] = tostring(name),
				["stackCount"] = stackCount,
				["statValue"] = statValue,
				["sellPrice"] = sellPrice,
				["quality"] = quality,
				["meetsUsageRequirement"]=meetsUsageRequirement,
				["ItemType"]=ItemType,
				["Id"]=id

			}
			sv.CurSlots=#ZO_GuildBankBackpack.data
			sv.MaxSlots=bagSlots
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