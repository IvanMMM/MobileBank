--	DataBase v0.01
----------------------------
--	Список команд:
-- /db cls - очистить собраные данные
----------------------------
-- Сделать: тултипы, подсветку, занято/свободно

-- Пригодится: 
-- WINDOW_MANAGER:GetMouseOverControl()
-- ZO_FeedbackPanel - "loading...  - смотреть инвентарь когда она исчезла?



DB = { }

DB.version=0.18

DB.dataDefaultItems = {
    data = {}
}
DB.dataDefaultParams = {
	DBUI_Menu = {10,10},
	DBUI_Container = {530,380}
}

DB.UI_Movable=false
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
    	DB.CurrentLastValue=11

    	if DBUI_Container:IsHidden() then
    		DB.PrepareBankValues("Guild")
    		DB.FillBank(DB.CurrentLastValue)
    	end
    	DB.HideContainer(bool)
    end )

    -- Клик по игроку
    db_UI.Menu.Button.Player:SetHandler( "OnClicked" , function(self)
    	local bool = not(DBUI_Container:IsHidden())
    	DB.CurrentLastValue=11

    	if DBUI_Container:IsHidden() then
			DB.PrepareBankValues("Player")
	    	DB.FillBank(DB.CurrentLastValue)
    	end
    	DB.HideContainer(bool)
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
end

function DB.PrepareBankValues(PrepareType)
	DB.BankValueTable={}

	if PrepareType=="Player" then
		d("Preparing Player values")
		bagIcon, bagSlots=GetBagInfo(BAG_BANK)
		DB.ItemCounter=0
		while (DB.ItemCounter < bagSlots) do
			if GetItemName(BAG_BANK,DB.ItemCounter)~="" then

				--Избавляемся от мусора при сохранении
				local namefine=string.gsub(GetItemLink(BAG_BANK,DB.ItemCounter), "(^p)", "")
				namefine=string.gsub(namefine, "(^n)", "")

				local start,finish=string.find(namefine,'|h.+|h')
				local nameClear=string.sub(namefine,start+2,finish-2)


				DB.BankValueTable[#DB.BankValueTable+1]={
					["name"]=tostring(namefine),
					["nameClear"]=tostring(nameClear),
					["count"]=tostring(GetSlotStackSize(BAG_BANK,DB.ItemCounter)),
					["statvalue"]=tostring(GetItemStatValue(BAG_BANK,DB.ItemCounter))
			}
			end
			DB.ItemCounter=DB.ItemCounter+1
		end
	elseif PrepareType=="Guild" then
		d("Preparing Guild values")
		DB.BankValueTable=DB.items.data
	else
		d("Unknown prepare type: "..tostring(PrepareType))
	end

    DBUI_ContainerSlider:SetHandler("OnValueChanged",function(self, value, eventReason)
		DB.FillBank(value)
    end)

    for i=1,11 do
        _G["DBUI_Row"..i]:SetHandler("OnMouseWheel" , function(self, delta)
	    	local calculatedvalue=DB.CurrentLastValue-delta
	    	if (calculatedvalue>=11) and (calculatedvalue<=#DB.BankValueTable) then
	    		DB.FillBank(calculatedvalue)
	    		DBUI_ContainerSlider:SetValue(calculatedvalue)
	    	end
	    end )
    end

    DB.SortPreparedValues()
	return DB.BankValueTable

end

function DB.SortPreparedValues()

	function compare(a,b)
		-- d("a: "..tostring(a["nameClear"])..", b: "..tostring(b["nameClear"]))
		return a["nameClear"]<b["nameClear"]	
	end

	table.sort(DB.BankValueTable,compare)
end

function DB.FillBank(last)
	if last<=1 then d("last<=1") return end
    if (#DB.BankValueTable==0) then 
    	d("No data avaliable. Open your bank first.")
    	DB.HideContainer(true)
	    	for i=1,11 do
	    		_G["DBUI_Row"..i]:SetHidden(true)
	    	end
    	return 
	else
		local texture='/esoui/art/miscellaneous/scrollbox_elevator.dds'
    	DBUI_ContainerSlider:SetMinMax(11,#DB.BankValueTable)
    	DBUI_ContainerSlider:SetThumbTexture(texture, texture, texture, 18, (1/#DB.BankValueTable*25000)/3, 0, 0, 1, 1)
    	for i=1,11 do
    		_G["DBUI_Row"..i]:SetHidden(false)
    	end
    end
    DB.CurrentLastValue=last

    if #DB.BankValueTable<11 then
    	-- Прячем Слайдер
    	DBUI_ContainerSlider:SetHidden(true)
	    -- Заполнение идёт сверху
	    for i=1,#DB.BankValueTable do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(DB.BankValueTable[i].name)
			_G["DBUI_Row"..i.."ButtonIcon"]:SetTexture(icon)
			_G["DBUI_Row"..i.."ButtonStackCount"]:SetText(DB.BankValueTable[i].count)
			_G["DBUI_Row"..i.."Name"]:SetText(DB.BankValueTable[i].name)
		    if (DB.BankValueTable[i].statvalue~="0") then
				_G["DBUI_Row"..i.."StatValue"]:SetText(DB.BankValueTable[i].statvalue)
			else
				_G["DBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["DBUI_Row"..i.."SellPrice"]:SetText(DB.BankValueTable[i].count*sellPrice)
		end
		-- Прячем пустые строки
		for i=#DB.BankValueTable+1,11 do
			_G["DBUI_Row"..i]:SetHidden(true)
		end
    else
    	-- Показываем слайдер
    	DBUI_ContainerSlider:SetHidden(false)
	    -- Заполнение идёт снизу
	    for i=11,1,-1 do
	    	local icon,sellPrice,meetsUsageRequirement,equipType,itemStyle = GetItemLinkInfo(DB.BankValueTable[last].name)
			_G["DBUI_Row"..i.."ButtonIcon"]:SetTexture(icon)
			_G["DBUI_Row"..i.."ButtonStackCount"]:SetText(DB.BankValueTable[last].count)
			_G["DBUI_Row"..i.."Name"]:SetText(DB.BankValueTable[last].name)
		    if (DB.BankValueTable[last].statvalue~="0") then
				_G["DBUI_Row"..i.."StatValue"]:SetText(DB.BankValueTable[last].statvalue)
			else
				_G["DBUI_Row"..i.."StatValue"]:SetText("-")
			end
			_G["DBUI_Row"..i.."SellPrice"]:SetText(DB.BankValueTable[last].count*sellPrice)
			if last<=#DB.BankValueTable and last>1 then
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



function commandHandler( text )
	if text=="cls" then
		DB.items.data={}
		DB.params.DBUI_Menu=nil
		DB.params.DBUI_Container=nil
		d("All data cleared")
	else
		d("/db cls - clear all data ")
	end
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

			start,finish=string.find(namefine,'|h.+|h')
			local nameClear=string.sub(namefine,start+2,finish-2)

			sv[#sv+1] = 
					{
					 ["name"] = tostring(namefine),
					 ["nameClear"]=tostring(nameClear),
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