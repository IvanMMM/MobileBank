--	DataBase v0.01
----------------------------
--	Список команд:
-- /db bag - список сумок
-- /db ic - список инвентаря
-- /db bc - список банка
----------------------------
DB = { }

DB.version=0.02

DB.dataDefault = {
    data = {}
}


local ShowInfo = true
local startupTS		= GetGameTimeMilliseconds()
local EventItemreadyHack=0

function DB.OnLoad(eventCode, addOnName)
	if (addOnName ~= "DataBase" ) then return end

	--добавляем команду
	SLASH_COMMANDS["/db"] = commandHandler

	--Регистрация эвентов
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_BANK, DB.PL_Opened)
	-- EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_SELECTED, DB.GB_Selected)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_OPEN_GUILD_BANK, DB.GB_Opened)
	EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_GUILD_BANK_ITEMS_READY, DB.GB_Ready)

	--Загрузка сохраненных переменных
	DB.items= ZO_SavedVars:New( "DB_SavedVars" , 2, "items" , DB.dataDefault , nil )

	--Всё подгружается из базы, скроллится и перемещается. 
	--Минусы: некликабельные строки, нет картинок, неудобное восприятие информации

	-- Полезные функции: 
	--		Можно получить иконку и стоимость
	-- 		GetItemLinkInfo(string itemLink)
	--		
	--		Отображение тултипа из базы (/script d(db_UI.Tooltip:SetLink(DB.items.data[2].name)))
	--		SetLink(string aLink)

	--Инициализация графического интерфейся
	db_UI = WINDOW_MANAGER:CreateTopLevelWindow("DBUI")
	db_UI.BG = WINDOW_MANAGER:CreateControl("DBUI_BG",DBUI,CT_BACKDROP)
	db_UI.Title = WINDOW_MANAGER:CreateControl("DBUI_Title",DBUI,CT_LABEL)
	db_UI.Items = WINDOW_MANAGER:CreateControl("DBUI_Items",DBUI,CT_LABEL)
	db_UI.TB = WINDOW_MANAGER:CreateControl("DBUI_TB",DBUI,CT_TEXTBUFFER)
	db_UI.Slider = WINDOW_MANAGER:CreateControl("DBUI_Slider",DBUI_TB,CT_SLIDER)
	db_UI.Tooltip = WINDOW_MANAGER:CreateControl("DBUI_Tooltip",DBUI,CT_TOOLTIP)

	--Обработчики событий
	--Прокрутка слайдера и буфера колёсиком
	db_UI:SetHandler("OnMouseWheel", 
	function(self,delta)
		db_UI.TB:SetScrollPosition(DBUI_TB:GetScrollPosition() + delta)
		db_UI.Slider:SetValue(db_UI.Slider:GetValue()- delta)
	end)

	--Прокрутка буфера ползунком слайдера
	db_UI.Slider:SetHandler("OnValueChanged", 
	function(self, val, eventReason)
       db_UI.TB:SetScrollPosition(#DB.items.data-val)
    end)

	--Общие настройки интерфейса
	db_UI:SetAnchor(TOPLEFT,GuiRoot,TOPLEFT,10,10)
	db_UI:SetDimensions(300,245)
	db_UI:SetMouseEnabled(true)
	db_UI:SetMovable(true)

	--Фон
	db_UI.BG:SetDimensions(300,245)
	db_UI.BG:SetCenterColor(0,0,0,1)
	db_UI.BG:SetEdgeColor(0,0,0,1)
	db_UI.BG:SetEdgeTexture("", 8, 1, 1)
	db_UI.BG:SetAlpha(0.5)
	db_UI.BG:SetAnchor(BOTTOM,DBUI,BOTTOM,0,0)

	--Заголовок
	db_UI.Title:SetFont("ZoFontGame" )
	db_UI.Title:SetColor(255,255,255,1.5)
	db_UI.Title:SetText( "GuildBank Storage: " )
	db_UI.Title:SetAnchor(TOPLEFT,DBUI,TOPLEFT,10,0)

	--Выводим число вещей в инвентаре:
	db_UI.Items:SetFont("ZoFontGame" )
	db_UI.Items:SetColor(255,255,255,1.5)
	db_UI.Items:SetText("ItemsTotal: "..#DB.items.data)
	db_UI.Items:SetAnchor(TOPLEFT,DBUI,TOPLEFT,10,20)

	--Текстовый буфер
	db_UI.TB:SetDimensions(275,200)
	db_UI.TB:SetFont( "ZoFontGame" )
	db_UI.TB:SetAnchor(BOTTOM,DBUI,BOTTOM,0,-5)
	db_UI.TB:SetLinkEnabled(true)
	db_UI.TB:SetMaxHistoryLines(#DB.items.data)

	--Подсказка
	-- db_UI.Tooltip:SetDimensions(425,345)
	-- db_UI.Tooltip:SetFont( "ZoFontGame" )
	-- db_UI.Tooltip:SetAnchor(BOTTOM,DBUI,BOTTOM,50,50)

	--Слайдер
	-- /script db_UI.Slider:SetBackgroundBottomTexture("", 8, 1, 1)
	local tex = "/esoui/art/miscellaneous/scrollbox_elevator.dds"

	db_UI.Slider:SetMinMax(1,#DB.items.data)
    db_UI.Slider:SetWidth(22)
	db_UI.Slider:SetOrientation(ORIENTATION_VERTICAL)
	db_UI.Slider:SetThumbTexture(tex, tex, tex, 22, 100, 0, 0, 1, 1)
	db_UI.Slider:SetAnchor(BOTTOM,db_UI,BOTTOMRIGHT,-10,0)
	db_UI.Slider:SetMouseEnabled(true)
	db_UI.Slider:SetHeight(245)
    db_UI.Slider:SetValue(#DB.items.data)
	db_UI.Slider:SetValueStep(1)


	--Отображение
	db_UI.Items.Item={}
	db_UI.Items.Item.name ={}
	db_UI.Items.Item.count ={}

	if (#DB.items.data==0) then return end
	for i=1, #DB.items.data, 1 do

		db_UI.TB:AddMessage(i.."|| "..DB.items.data[i].count.." || "..DB.items.data[i].name)

		-- --Название
		-- db_UI.Items.Item.name[i] = WINDOW_MANAGER:CreateControl("DBUI_Item_name_"..i,DBUI,CT_LABEL)
		-- db_UI.Items.Item.name[i]:SetFont("ZoFontGame" )
		-- db_UI.Items.Item.name[i]:SetColor(255,255,255,1.5)
		-- db_UI.Items.Item.name[i]:SetText(DB.items.data[i].name)
		-- db_UI.Items.Item.name[i]:SetAnchor(TOPLEFT,DBUI,TOPLEFT,20,20+i*20)

		-- --Количество
		-- db_UI.Items.Item.name[i] = WINDOW_MANAGER:CreateControl("DBUI_Item_count_"..i,DBUI,CT_LABEL)
		-- db_UI.Items.Item.name[i]:SetFont("ZoFontGame" )
		-- db_UI.Items.Item.name[i]:SetColor(255,255,255,1.5)
		-- db_UI.Items.Item.name[i]:SetText(DB.items.data[i].count)
		-- db_UI.Items.Item.name[i]:SetAnchor(TOPLEFT,DBUI,TOPLEFT,300,20+i*20)

	end
end


function DB.Update(self)
-- Заготовка для обновления данных

end

function DB.PL_Opened()
	d("Player bank opened")
end

function DB.GB_Opened()
	d("Guild bank opened")
end

function DB.GB_Ready()
	--хак на срабатываение после второго события

	if EventItemreadyHack==1 then 

		DB.gcount()

		EventItemreadyHack=0
	else
		EventItemreadyHack=1
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
	else
		d("/db bag - bags list")
		d("/db ic - iventory list")
		d("/db bc - bank list")
		d("/db gc - guildbank list")
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
	
	-- что-то тут не так...
	while (ItemCounter < bagSlots) do
		if GetItemName(BAG_BACKPACK,ItemCounter)~="" then
			d(ItemCounter.." : "..GetItemName(BAG_BACKPACK,ItemCounter).." : "..GetItemTotalCount(BAG_BACKPACK,ItemCounter))
		end
		ItemCounter=ItemCounter+1
	end
	d("---------------------")
	d("Items total: "..(bagSlots-bagSpace))
	d("Slots counted: "..ItemCounter)
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
	d("---------------------")
	d("Slots counted: "..DB.ItemCounter)
end

function DB.gcount()

    local data = {}
    local dataStr = ""
    local founditems = false

	--Обнуление сохраненной базы
    DB.items.data={}
    
	local sv = DB.items.data
    	
	DB.ItemCounter=0
	bagIcon, bagSlots=GetBagInfo(BAG_GUILDBANK)

	while (DB.ItemCounter < bagSlots) do
		if GetItemName(BAG_GUILDBANK,DB.ItemCounter)~="" then
			d(DB.ItemCounter.." : "..GetItemLink(BAG_GUILDBANK,DB.ItemCounter).." : "..GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
			founditems=true
			
			--Избавляемся от мусора при сохранении
			local namefine=string.gsub(GetItemLink(BAG_GUILDBANK,DB.ItemCounter), "(^p)", "")
			namefine=string.gsub(namefine, "(^n)", "")

			sv[#sv+1] = 
					{
					 ["name"] = tostring(namefine),
					 ["count"] = tostring(GetSlotStackSize(BAG_GUILDBANK,DB.ItemCounter))
					}
		end
		DB.ItemCounter=DB.ItemCounter+1
	end
	d("---------------------")
	d("Slots counted: "..DB.ItemCounter)
	if DB.ItemCounter==bagSlots and founditems==false then
		d("Found nothing... try again")
	end
end


--Инициализация Аддона
EVENT_MANAGER:RegisterForEvent("DataBase", EVENT_ADD_ON_LOADED, DB.OnLoad)