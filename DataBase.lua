--	DataBase v0.01
----------------------------
--	Список команд:
-- /db bag - список сумок
-- /db ic - список инвентаря
-- /db bc - список банка
-- /db cls - очистить собраные данные
----------------------------
-- Сделать: тултипы, подсветку, занято/свободно

-- Пригодится: 
-- WINDOW_MANAGER:GetMouseOverControl()
-- ZO_FeedbackPanel - "loading...  - смотреть инвентарь когда она исчезла?



DB = { }

DB.version=0.16

DB.dataDefaultItems = {
    data = {}
}
DB.dataDefaultParams = {
	DBUI_Menu = {10,10},
	DBUI_Container = {530,380}
}

DB.UI_Movable=false
DB.BankCreated=false
DB.AddonReady=false

function DB.OnLoad(eventCode, addOnName)
	if (addOnName ~= "DataBase" ) then return end

	--добавляем команду
	SLASH_COMMANDS["/db"] = commandHandler

	--Регистрация эвентов
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_BANK, DB.PL_Opened)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_CLOSE_BANK, DB.PL_Closed)
	-- EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_SELECTED, DB.GB_Selected)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_GUILD_BANK, DB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_ITEMS_READY, DB.GB_Ready)

	--Загрузка сохраненных переменных
	DB.items= ZO_SavedVars:New( "DB_SavedVars" , 2, "items" , DB.dataDefaultItems, nil )
	DB.params= ZO_SavedVars:New( "DB_SavedVars" , 2, "params" , DB.dataDefaultParams, nil )

	--Инициализация графического интерфейся
	db_UI = WINDOW_MANAGER:CreateTopLevelWindow("DBUI")

	-- Создаем меню
	DB.CreateMenu()
	-- Создаем банк
	DB.CreateBank()

	DB.AddonReady=true
end


function DB.CreateMenu()
	db_UI.Menu=WINDOW_MANAGER:CreateControl("DBUI_Menu",DBUI,CT_CONTROL)
	db_UI.Menu.BG = WINDOW_MANAGER:CreateControl("DBUI_Menu_BG",DBUI_Menu,CT_BACKDROP)
	db_UI.Menu.Title = WINDOW_MANAGER:CreateControl("DBUI_Menu_Title",DBUI_Menu,CT_LABEL)
	db_UI.Menu.Button={}
	db_UI.Menu.Button.Guild = WINDOW_MANAGER:CreateControl("DBUI_Menu_Button_Guild",DBUI_Menu,CT_BUTTON)
	db_UI.Menu.Button.Player = WINDOW_MANAGER:CreateControl("DBUI_Menu_Button_Player",DBUI_Menu,CT_BUTTON)
	db_UI.Menu.Button.Move = WINDOW_MANAGER:CreateControl("DBUI_Menu_Button_Move",DBUI_Menu,CT_BUTTON)

	--Обработчики событий

    -- Клик по гильдии
    db_UI.Menu.Button.Guild:SetHandler( "OnClicked" , function(self)
    	local bool = not(DBUI_Container:IsHidden())
    	DB.HideContainer(bool)
    	DB.CurrentLastValue=11

	    DBUI_ContainerSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
	    	DB.FillGuildBank(value)
	    end)

	    for i=1,11 do
	        _G["DBUI_Row"..i]:SetHandler("OnMouseWheel" , function(self, delta)
		    	local calculatedvalue=DB.CurrentLastValue-delta
		    	if (calculatedvalue>=11) and (calculatedvalue<=#DB.items.data) then
		    		DB.FillGuildBank(calculatedvalue)
		    		DBUI_ContainerSlider:SetValue(calculatedvalue)
		    	end
		    end )
	    end

    	DB.FillGuildBank(DB.CurrentLastValue)
    end )

    -- Клик по игроку
    db_UI.Menu.Button.Player:SetHandler( "OnClicked" , function(self)
    	local bool = not(DBUI_Container:IsHidden())
    	DB.HideContainer(bool)
    	DB.CurrentLastValue=11

	    DBUI_ContainerSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
	    	DB.FillPlayerBank(value)
	    end)

	    for i=1,11 do
	        _G["DBUI_Row"..i]:SetHandler("OnMouseWheel" , function(self, delta)
		    	local calculatedvalue=DB.CurrentLastValue-delta
		    	if (calculatedvalue>=11) and (calculatedvalue<=DB.ItemCounter) then
		    		DB.FillPlayerBank(calculatedvalue)
		    		DBUI_ContainerSlider:SetValue(calculatedvalue)
		    	end
		    end )
	    end

    	DB.FillPlayerBank(DB.CurrentLastValue)
    end )

    -- Клик по M
    db_UI.Menu.Button.Move:SetHandler( "OnClicked" , function(self)
    	if DB.UI_Movable then
    		db_UI.Menu:SetMovable(true)
    		DBUI_Container:SetMovable(true)
    		DB.UI_Movable=false
    	else
    		db_UI.Menu:SetMovable(false)
    		DBUI_Container:SetMovable(false)
    		DB.UI_Movable=true
    	end
    end )

    DBUI_Menu:SetHandler("OnMouseUp" , function(self) DB.MouseUp(self) end)
    DBUI_Container:SetHandler("OnMouseUp" , function(self) DB.MouseUp(self) end)

    function DB.MouseUp(self)
    	local name = self:GetName()
	    local left = self:GetLeft()
	    local top = self:GetTop()

	    if name=="DBUI_Menu" then
	    	d("Menu saved")
	    	DB.params.DBUI_Menu={left,top}
	    elseif name=="DBUI_Container" then
	    	d("Container saved")
	    	DB.params.DBUI_Container={left,top}
	    else
	    	d("Unknown window")
	    end

	end

	--Настройки меню
	db_UI.Menu:SetAnchor(TOPLEFT,DBUI,TOPLEFT,DB.params.DBUI_Menu[1],DB.params.DBUI_Menu[2])
	db_UI.Menu:SetDimensions(200,50)
	db_UI.Menu:SetMouseEnabled(true)

    if DB.UI_Movable then
		db_UI:SetMovable(true)
		DB.UI_Movable=false
	else
		db_UI:SetMovable(false)
		DB.UI_Movable=true
	end

	--Фон
	db_UI.Menu.BG:SetAnchor(BOTTOM,DBUI_Menu,BOTTOM,0,0)
	db_UI.Menu.BG:SetDimensions(200,50)
	db_UI.Menu.BG:SetCenterColor(0,0,0,1)
	db_UI.Menu.BG:SetEdgeColor(0,0,0,1)
	db_UI.Menu.BG:SetEdgeTexture("", 8, 1, 1)
	db_UI.Menu.BG:SetAlpha(0.5)

	--Заголовок
	db_UI.Menu.Title:SetAnchor(TOP,DBUI_Menu,TOP,0,0)
	db_UI.Menu.Title:SetFont("ZoFontGame" )
	db_UI.Menu.Title:SetColor(255,255,255,1.5)
	db_UI.Menu.Title:SetText( "|cff8000Bank Storage|" )

	-- Кнопка "Гильдия"
	db_UI.Menu.Button.Guild:SetAnchor(TOP,DBUI_Menu,TOPRIGHT,-150,20)
	db_UI.Menu.Button.Guild:SetText("[Guild]")
	db_UI.Menu.Button.Guild:SetDimensions(70,25)
	db_UI.Menu.Button.Guild:SetFont("ZoFontGameBold")
	db_UI.Menu.Button.Guild:SetNormalFontColor(0,255,255,.7)
	db_UI.Menu.Button.Guild:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "Игрок"
	db_UI.Menu.Button.Player:SetAnchor(TOP,DBUI_Menu,TOPRIGHT,-90,20)
	db_UI.Menu.Button.Player:SetText("[Player]")
	db_UI.Menu.Button.Player:SetDimensions(70,25)
	db_UI.Menu.Button.Player:SetFont("ZoFontGameBold")
	db_UI.Menu.Button.Player:SetNormalFontColor(0,255,255,.7)
	db_UI.Menu.Button.Player:SetMouseOverFontColor(0.8,0.4,0,1)

	-- Кнопка "M"
	db_UI.Menu.Button.Move:SetAnchor(TOP,DBUI_Menu,TOPRIGHT,-40,20)
	db_UI.Menu.Button.Move:SetText("[M]")
	db_UI.Menu.Button.Move:SetDimensions(40,25)
	db_UI.Menu.Button.Move:SetFont("ZoFontGameBold")
	db_UI.Menu.Button.Move:SetNormalFontColor(0,255,255,.7)
	db_UI.Menu.Button.Move:SetMouseOverFontColor(0.8,0.4,0,1)
end

function DB.CreateBank()
	local OldAnchor=false

	--Настройки контейнера
	DBUI_Container:SetParent(DBUI)
	DBUI_Container:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,DB.params.DBUI_Container[1],DB.params.DBUI_Container[2])
	DBUI_Container:SetDimensions(560,640)
	DBUI_Container:SetMouseEnabled(true)
	DBUI_Container:SetHidden(true)

    -- Фон
    DBUI_ContainerBg:SetAnchor(TOPLEFT,DBUI_Container,TOPLEFT,10,0)
    DBUI_ContainerBg:SetCenterColor(0,0,0,0.5)
    DBUI_ContainerBg:SetEdgeColor(0,0,0,0.5)
    DBUI_ContainerBg:SetDimensions(DBUI_Container:GetDimensions())

	-- + Правим заголовок 
	DBUI_ContainerTitle:SetAnchor(TOP,DBUI_Container,TOP,0,15)
	DBUI_ContainerTitle:SetFont("ZoFontGame")
	DBUI_ContainerTitle:SetText( "|cff8000Offline Bank Storage|" )
	DBUI_ContainerTitle:SetHeight(150)

	-- + Правим Слайдер
    DBUI_ContainerSlider:SetAnchor(BOTTOM,DBUI_Container,BOTTOMRIGHT,0,-15)
    DBUI_ContainerSlider:SetValue(11)
    DBUI_ContainerSlider:SetWidth(ZO_PlayerBankBackpackScrollBar:GetWidth())
    DBUI_ContainerSlider:SetHeight(550)
    DBUI_ContainerSlider:SetAllowDraggingFromThumb(true)

	for i = 1, 11 do
	    local dynamicControl = CreateControlFromVirtual("DBUI_Row", DBUI_Container, "TemplateRow",i)
	    -- _G[] - позволяет подставлять динамические имена переменных

	    -- Строка
	    local fromtop=60
	    _G["DBUI_Row"..i]:ClearAnchors()
	    _G["DBUI_Row"..i]:SetAnchor(TOP,DBUI_Container,TOP,0,fromtop+52*(i-1))
	    _G["DBUI_Row"..i]:SetDimensions (530,52)


	    -- Фон
	    _G["DBUI_Row"..i.."Bg"]:SetColor(1,1,1,1)
	    --На самом деле это хак ('notexture'). Не могу найти нормальную текстуру
	    _G["DBUI_Row"..i.."Bg"]:SetTexture('notexture')
	    _G["DBUI_Row"..i.."Bg"]:SetDimensions (549,59)
	    _G["DBUI_Row"..i.."Bg"]:GetTextureFileDimensions(512,64)

	    -- Кнопка
		OldAnchor=_G["DBUI_Row"..i.."Button"]:GetParent()

			--Иконка
			OldAnchor=_G["DBUI_Row"..i.."ButtonIcon"]:GetParent()
			-- Это не ошибки. Привязки ниже идут к другому якорю.
			_G["DBUI_Row"..i.."ButtonIcon"]:ClearAnchors()
		    _G["DBUI_Row"..i.."ButtonIcon"]:SetAnchor(TOPLEFT,OldAnchor,TOPLEFT,0,0)
		    _G["DBUI_Row"..i.."ButtonIcon"]:SetColor(1,1,1,1)
		    _G["DBUI_Row"..i.."ButtonIcon"]:SetDimensions (40,40)
		    _G["DBUI_Row"..i.."ButtonIcon"]:GetTextureFileDimensions(64,64)

		    --Количество
			_G["DBUI_Row"..i.."ButtonStackCount"]:ClearAnchors()
		    _G["DBUI_Row"..i.."ButtonStackCount"]:SetAnchor(TOPLEFT,OldAnchor,TOPLEFT,20,20)
		    _G["DBUI_Row"..i.."ButtonStackCount"]:SetDimensions (38,35)

	    -- Наименование
		_G["DBUI_Row"..i.."Name"]:ClearAnchors()
	    _G["DBUI_Row"..i.."Name"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,50,15)


		-- Отображение статов
		_G["DBUI_Row"..i.."StatValue"]:ClearAnchors()
	    _G["DBUI_Row"..i.."StatValue"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,380,15)

	    -- Цена
		_G["DBUI_Row"..i.."SellPrice"]:ClearAnchors()
	    _G["DBUI_Row"..i.."SellPrice"]:SetAnchor(CENTERLEFT,OldAnchor,CENTERLEFT,480,15)

	    _G["DBUI_Row"..i.."Highlight"]:SetHidden(true)
	end
	DB.BankCreated=true
end

function DB.FillPlayerBank(last)

	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_BANK)

	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_BANK,DB.ItemCounter)~="" then
			DB.ItemCounter=DB.ItemCounter+1
		end
	end
	-- Отсчет начинается с "0"
	DB.ItemCounter=DB.ItemCounter-1

	if last<=1 then d("last<=1") return end
    if (DB.ItemCounter==0) then 
    	d("No items in bank")
    	DB.HideContainer(true)
	    	for i=1,11 do
	    		_G["DBUI_Row"..i]:SetHidden(true)
	    	end
    	return 
	else
		local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
    	DBUI_ContainerSlider:SetMinMax(11,DB.ItemCounter)
    	DBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/DB.ItemCounter+DB.ItemCounter)/3, 0, 0, 1, 1)
    	for i=1,11 do
    		_G["DBUI_Row"..i]:SetHidden(false)
    	end
    end
    DB.CurrentLastValue=last

    if DB.ItemCounter<11 then
    	-- Прячем Слайдер
    	DBUI_ContainerSlider:SetHidden(true)
	    -- Заполнение идёт сверху
	    for i=1,DB.ItemCounter do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(GetItemLink(BAG_BANK,i))
			_G["DBUI_Row"..i.."ButtonIcon"]:SetTexture(icon)
			_G["DBUI_Row"..i.."ButtonStackCount"]:SetText(GetSlotStackSize(BAG_BANK,i))
			_G["DBUI_Row"..i.."Name"]:SetText(GetItemLink(BAG_BANK,i))
		    if (GetItemStatValue(BAG_BANK,i)~="0") then
				_G["DBUI_Row"..i.."StatValue"]:SetText(GetItemStatValue(BAG_BANK,i))
			else
				_G["DBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["DBUI_Row"..i.."SellPrice"]:SetText(GetSlotStackSize(BAG_GUILDBANK,i)*sellPrice)
		end
		-- Прячем пустые строки
		for i=DB.ItemCounter+1,11 do
			_G["DBUI_Row"..i]:SetHidden(true)
		end
    else
    	-- Показываем слайдер
    	DBUI_ContainerSlider:SetHidden(false)

    	-- Поправка на начало отсчета с 0
    	last=last-1
	    -- Заполнение идёт снизу
	    for i=11,1,-1 do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle=GetItemLinkInfo(GetItemLink(BAG_BANK,last))
			_G["DBUI_Row"..i.."ButtonIcon"]:SetTexture(icon)
			_G["DBUI_Row"..i.."ButtonStackCount"]:SetText(GetSlotStackSize(BAG_BANK,last))
			_G["DBUI_Row"..i.."Name"]:SetText(GetItemLink(BAG_BANK,last))
		    if (GetItemStatValue(BAG_BANK,last)~=0) then
				_G["DBUI_Row"..i.."StatValue"]:SetText(GetItemStatValue(BAG_BANK,last))
			else
				_G["DBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["DBUI_Row"..i.."SellPrice"]:SetText(GetSlotStackSize(BAG_BANK,last)*sellPrice)
			d()
			if last<=DB.ItemCounter and last>0 then
	    		last=last-1
	    	else
	    		last=last
	    	end
		end
	end

end

function DB.FillGuildBank(last)
	if last<=1 then d("last<=1") return end
    if (#DB.items.data==0) then 
    	d("No data avaliable. Open your bank first.")
    	DB.HideContainer(true)
	    	for i=1,11 do
	    		_G["DBUI_Row"..i]:SetHidden(true)
	    	end
    	return 
	else
		local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
    	DBUI_ContainerSlider:SetMinMax(11,#DB.items.data)
    	DBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#DB.items.data+#DB.items.data)/3, 0, 0, 1, 1)
    	for i=1,11 do
    		_G["DBUI_Row"..i]:SetHidden(false)
    	end
    end
    DB.CurrentLastValue=last

    if #DB.items.data<11 then
    	-- Прячем Слайдер
    	DBUI_ContainerSlider:SetHidden(true)
	    -- Заполнение идёт сверху
	    for i=1,#DB.items.data do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(DB.items.data[i].name)
			_G["DBUI_Row"..i.."ButtonIcon"]:SetTexture(icon)
			_G["DBUI_Row"..i.."ButtonStackCount"]:SetText(DB.items.data[i].count)
			_G["DBUI_Row"..i.."Name"]:SetText(DB.items.data[i].name)
		    if (DB.items.data[i].statvalue~="0") then
				_G["DBUI_Row"..i.."StatValue"]:SetText(DB.items.data[i].statvalue)
			else
				_G["DBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["DBUI_Row"..i.."SellPrice"]:SetText(DB.items.data[i].count*sellPrice)
		end
		-- Прячем пустые строки
		for i=#DB.items.data+1,11 do
			_G["DBUI_Row"..i]:SetHidden(true)
		end
    else
    	-- Показываем слайдер
    	DBUI_ContainerSlider:SetHidden(false)
	    -- Заполнение идёт снизу
	    for i=11,1,-1 do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(DB.items.data[last].name)
			_G["DBUI_Row"..i.."ButtonIcon"]:SetTexture(icon)
			_G["DBUI_Row"..i.."ButtonStackCount"]:SetText(DB.items.data[last].count)
			_G["DBUI_Row"..i.."Name"]:SetText(DB.items.data[last].name)
		    if (DB.items.data[last].statvalue~="0") then
				_G["DBUI_Row"..i.."StatValue"]:SetText(DB.items.data[last].statvalue)
			else
				_G["DBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["DBUI_Row"..i.."SellPrice"]:SetText(DB.items.data[last].count*sellPrice)
			if last<=#DB.items.data and last>1 then
	    		last=last-1
	    	else
	    		last=11
	    	end
		end
	end
end




function DB.PL_Opened()
end

function DB.PL_Closed()

end

function DB.GB_Opened()
	DB.EventHacked=false
end

function DB.GB_Ready()
	--хак на срабатывание только 1 события

	if  (not DB.EventHacked) then 
		DB.gcount()
		DB.EventHacked=true
	end
end

function DB.GB_Selected(guildid)
	d("Bank owned by "..guildid.." selected")
	DB.GuildBankId=GetSelectedGuildBankId()
	d("GuildBank id: "..DB.GuildBankId)
end


function commandHandler( text )
	if text=="ic" then
		DB.icount()
	elseif text=="bc" then
		DB.bcount()
	elseif text=="gc" then
		DB.gcount()
	elseif text=="cls" then
		DB.items.data={}
		DB.params.DBUI_Menu=nil
		DB.params.DBUI_Container=nil
		d("All data cleared")
	else
		d("/db bag - bags list")
		d("/db ic - iventory list")
		d("/db bc - bank list")
		d("/db gc - guildbank list")
		d("/db cls - clear all data ")
	end
end

function DB.icount()
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_BACKPACK)

	for i = bagSlots, 0, -1 do
		bagSpace = i
		if CheckInventorySpaceSilently(bagSpace) then break end
	end

	d("BagSpaceTotal: "..bagSlots)
	d("BagSpaceFree: "..bagSpace)
	d("BagSpaceOccupied: "..(bagSlots-bagSpace))
	d("slot:name:count")
	
	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_BACKPACK,DB.ItemCounter)~="" then
			d(DB.ItemCounter.." : "..GetItemName(BAG_BACKPACK,DB.ItemCounter).." : "..GetItemTotalCount(BAG_BACKPACK,DB.ItemCounter))
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	-- d("---------------------")
	-- d("Items total: "..(bagSlots-bagSpace))
	-- d("Slots counted: "..DB.ItemCounter)
end

function DB.bcount()
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_BANK)

	d("BagSpaceTotal: "..bagSlots)

	d("slot:name:count")
	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_BANK,DB.ItemCounter)~="" then
			d(DB.ItemCounter.." : "..GetItemName(BAG_BANK,DB.ItemCounter).." : "..GetSlotStackSize(BAG_BANK,DB.ItemCounter))
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	-- d("---------------------")
	-- d("Slots counted: "..DB.ItemCounter)
end

function DB.gcount()

    local data = {}
    local dataStr = ""
    local sv=false
    -- 0-не найдено, 1-найдено, 2-обновлено
    local founditems = 0
      	
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_GUILDBANK,DB.ItemCounter)~="" then
			-- d(DB.ItemCounter.." : "..GetItemLink(BAG_GUILDBANK,DB.ItemCounter).." : "..GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))

			if founditems==0 then
				founditems=1
			end

			--Обнуление сохраненной базы
			if  (founditems==1) then 
				DB.items.data={}
				sv = DB.items.data 
				founditems=2
				d("Data saved!")
			end
	
			--Избавляемся от мусора при сохранении
			local namefine=string.gsub(GetItemLink(BAG_GUILDBANK,DB.ItemCounter), "(^p)", "")
			namefine=string.gsub(namefine, "(^n)", "")

			-- Разбираем строку и вытаскиваем из неё id
			local start,finish=string.find(namefine,'item:%d+')
			local id=string.sub(namefine,start+5,finish)

			sv[#sv+1] = 
					{
					 ["name"] = tostring(namefine),
					 ["count"] = tostring(GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter)),
					 ["statvalue"]=tostring(GetItemStatValue(BAG_GUILDBANK,DB.ItemCounter)),
					 ["id"]=tostring(id)
					}
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	-- d("---------------------")
	-- d("Slots counted: "..DB.ItemCounter)
	if DB.ItemCounter==bagSlots and founditems==0 then
		d("No data found. Try again.")
	end
end

function DB.Update(self)
if (not DB.AddonReady) then return end

	local EscMenuHidden = ZO_GameMenu_InGame:IsHidden()
	local interactHidden = ZO_InteractWindow:IsHidden()

	if (EscMenuHidden == false) then
		DBUI_Container:SetHidden(true)
		DBUI_Menu:SetHidden(true)
	elseif (interactHidden == false) then
		DBUI_Container:SetHidden(true)
		DBUI_Menu:SetHidden(true)
	else
		DBUI_Menu:SetHidden(false)
	end

end

function DB.HideContainer(value)
	DBUI_Container:SetHidden(value)
	-- d("GuildBankHideValue: "..tostring(value))
end

--Инициализация Аддона
EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_ADD_ON_LOADED, DB.OnLoad)