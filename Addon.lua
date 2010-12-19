local _G = _G
local TL, TC, TR = 'TOPLEFT', 'TOP', 'TOPRIGHT'
local ML, MC, MR = 'LEFT', 'CENTER', 'RIGHT'
local BL, BC, BR = 'BOTTOMLEFT', 'BOTTOM', 'BOTTOMRIGHT'

local frame_name = 'oUF_Industrial_'

local padding = 0
local spacing = 0
local margin = 1
local translucency = 1

local offset_x = 0
local offset_y = -250

local buff_margin = margin / 2

local bar_width = 250 - padding * 2
local bar_texture = [[Interface\AddOns\oUF_Industrial\media\textures\statusbar]]

local health_width = bar_width
local health_height = 25
local health_texture = bar_texture
local health_color = {0.4, 0.4, 0.4, translucency}

local power_width = bar_width
local power_height = 25
local power_texture = bar_texture
local power_color = {0.5, 1, 0, translucency}

_G.oUF.colors.power.MANA = {0.2, 0.4, 0.6}
_G.oUF.colors.power.ENERGY = {0.6, 0.6, 0.2}
_G.oUF.colors.power.RAGE = {0.6, 0.2, 0.2}
_G.oUF.colors.power.FOCUS = {0.6, 0.4, 0.2}
_G.oUF.colors.power.RUNIC_POWER = {0.2, 0.6, 0.6}

local cast_color = {0.6, 0.6, 0.2, translucency}

local background_color = {0, 0, 0, translucency/2}

local text_offset_x = 6
local text_offset_y = 1
local text_font = [[Interface\AddOns\oUF_Industrial\media\fonts\Calibri.ttf]]
local text_color = {0.8, 0.8, 0.8}
local text_size = 14

local colors_raid = _G.RAID_CLASS_COLORS
local pethappiness = {':<',':|',':3'}
local shortclassnames = {
	DEATHKNIGHT = 'DK',
	DRUID = 'DR',
	HUNTER = 'HT',
	MAGE = 'MG',
	PALADIN = 'PL',
	PRIEST = 'PR',
	ROGUE = 'RG',
	SHAMAN = 'SH',
	WARLOCK = 'WL',
	WARRIOR = 'WR',
}

local format_value
local show_menu
local unit_class
local unit_level
local unit_name
local unit_tapped
local update_health
local update_power
local update_info
local create_unitframe
local create_player_unitframe
local create_target_unitframe
local create_targettarget_unitframe
local create_pet_unitframe
local create_pettarget_unitframe
local create_focus_unitframe
local create_focustarget_unitframe
local target_onupdate

function format_value (v)
	if type(v) == 'number' then
		if v > 1000 then
			return ('%.1f'):format(v / 1000)
		else
			return v
		end
	end
	return ''
end

function show_menu (frame)
	local unit = frame.unit:sub(1, -2)
	local cunit = frame.unit:gsub("(.)", string.upper, 1)

	if(unit == "party" or unit == "partypet") then
		ToggleDropDownMenu(1, nil, _G["PartyMemberFrame"..frame.id.."DropDown"], "cursor", 0, 0)
	elseif(_G[cunit.."FrameDropDown"]) then
		ToggleDropDownMenu(1, nil, _G[cunit.."FrameDropDown"], "cursor", 0, 0)
	end
end

function unit_class (unit)
	local class = select(2, UnitClass(unit))
	local color = RAID_CLASS_COLORS[class]

	return color and ('|cff%02X%02X%02X%s|r'):format(color.r*255, color.g*255, color.b*255, shortclassnames[class]) or ''
end

function unit_level (unit)
	--[[local color = GetDifficultyColor(UnitLevel(unit))
	return color and ('|cff%02X%02X%02X%s|r'):format(color.r*255, color.g*255, color.b*255, UnitLevel(unit))]]
	local level = UnitLevel(unit)
	return (level and (level >= 1 and level or '??'))
end

function unit_name (unit)
	name = UnitName(unit)
	class = select(2, UnitClass(unit))
	colors = _G.RAID_CLASS_COLORS[class]
	if colors then
		return ('|cff%02x%02x%02x%s|r'):format(colors.r * 255, colors.g * 255, colors.b * 255, name)
	else
		return name
	end
end

function unit_tapped (unit)
	if UnitIsTapped(unit) then
		if UnitIsTappedByPlayer(unit) then
			return '|cff00ff00*|r'
		end
		return '|cffff0000*|r'
	end
	return ''
end

function unit_threat (unit)
	if UnitIsEnemy('player', unit) then
		local threat_percent = select(3, UnitDetailedThreatSituation('player', 'target'))
		if threat_percent then
			return math.ceil(threat_percent) .. '%'
		else
			return ''
		end
	else
		return ''
	end
end

function process_icon (button)
	if button and button.icon then
		button.icon:SetTexCoord(.07, .93, .07, .93)
	end
end

function update_health (Health, unit, min, max)
	Health.value:SetText(format_value(min))
	update_info(Health:GetParent(), unit)
end

function update_power (Power, unit, min, max)
	Power.value:SetText(format_value(min > 0 and min or ''))
	update_info(Power:GetParent(), unit)
end

function update_info (frame, unit)
	local unit = frame.unit
	if not UnitExists(unit) then return end

	frame.Name:SetText(('%s%s'):format(unit_name(unit), unit_tapped(unit)))
	frame.Info:SetText(('%s %s'):format(unit_level(unit), unit_threat(unit)))
end

function update_pet_happiness(Happiness, unit, happinessLevel)
	if happinessLevel < 3 then
		Happiness:Show()
	else
		Happiness:Hide()
	end
	update_info(Happiness:GetParent(), unit)
end

function create_unitframe (frame, unit)
	local background = frame:CreateTexture(nil, 'BACKGROUND')
	local Health = CreateFrame('StatusBar', nil, frame)
	local Power = CreateFrame('StatusBar', nil, frame)
	local Buffs = CreateFrame('Frame', nil, frame)
	local Debuffs = CreateFrame('Frame', nil, frame)
	local Leader = Health:CreateTexture(nil, 'OVERLAY')
	local Raidicon = Health:CreateTexture(nil, 'OVERLAY')
	local Masterlooter = Health:CreateTexture(nil, 'OVERLAY')
	local Threat = Health:CreateTexture(nil, 'OVERLAY')
	local Castbar = CreateFrame('StatusBar', nil, Health)
	Health.info = Health:CreateFontString(nil, 'OVERLAY')
	Health.value = Health:CreateFontString(nil, 'OVERLAY')
	Power.info = Power:CreateFontString(nil, 'OVERLAY')
	Power.value = Power:CreateFontString(nil, 'OVERLAY')
	Castbar.Icon = Castbar:CreateTexture()
	Castbar.Text = Castbar:CreateFontString(nil, 'OVERLAY')
	Castbar.Time = Castbar:CreateFontString(nil, 'OVERLAY')
	Castbar.bg = Castbar:CreateTexture(nil, 'BACKGROUND')
	Castbar.SafeZone = Castbar:CreateTexture(nil, 'OVERLAY')

	-- Health
	Health:SetPoint(TL, frame, TL, padding, -padding)
	Health:SetWidth(health_width)
	Health:SetHeight(health_height)
	Health:SetStatusBarTexture(health_texture)
	Health:SetStatusBarColor(unpack(health_color))

	Health.frequentUpdates = true
	Health.PostUpdate = update_health

	Health.info:SetPoint(ML, Health, ML, text_offset_x, 1)
	Health.info:SetPoint(MR, Health.value, ML)
	Health.info:SetJustifyH('LEFT')
	Health.info:SetFont(text_font, text_size)
	Health.info:SetTextColor(unpack(text_color))
	Health.info:SetShadowColor(0, 0, 0)
	Health.info:SetShadowOffset(1, -1)

	Health.value:SetPoint(MR, Health, MR, -text_offset_x, 1)
	Health.value:SetJustifyH('RIGHT')
	Health.value:SetFont(text_font, text_size)
	Health.value:SetTextColor(unpack(text_color))
	Health.value:SetShadowColor(0, 0, 0)
	Health.value:SetShadowOffset(1, -1)

	-- Power
	Power:SetPoint(TL, Health, BL, 0, -spacing)
	Power:SetWidth(power_width)
	Power:SetHeight(power_height)
	Power:SetStatusBarTexture(power_texture)

	Power.frequentUpdates = true
	Power.colorPower = true
	Power.PostUpdate = update_power

	Power.info:SetPoint(ML, Power, ML, text_offset_x, text_offset_y)
	Power.info:SetPoint(MR, Power.value, ML)
	Power.info:SetJustifyH('LEFT')
	Power.info:SetFont(text_font, text_size)
	Power.info:SetTextColor(unpack(text_color))
	Power.info:SetShadowColor(0, 0, 0)
	Power.info:SetShadowOffset(1, -1)

	Power.value:SetPoint(MR, Power, MR, -text_offset_x, text_offset_y)
	Power.value:SetJustifyH('RIGHT')
	Power.value:SetFont(text_font, text_size)
	Power.value:SetTextColor(unpack(text_color))
	Power.value:SetShadowColor(0, 0, 0)
	Power.value:SetShadowOffset(1, -1)

	-- Castbar
	Castbar:SetPoint(ML, Castbar.Icon, MR)
	Castbar:SetPoint(TR, Power, BR, 0, -spacing - padding)
	Castbar:SetHeight(power_height)
	Castbar:SetToplevel(true)
	Castbar:SetStatusBarTexture(health_texture)
	Castbar:SetStatusBarColor(unpack(cast_color))

	Castbar.Icon:SetPoint(TL, Power, BL, 0, -spacing - padding)
	Castbar.Icon:SetWidth(power_height)
	Castbar.Icon:SetHeight(power_height)
	process_icon(Castbar.Icon)

	Castbar.Text:SetPoint(ML, Castbar, ML, text_offset_x, text_offset_y)
	Castbar.Text:SetJustifyH('LEFT')
	Castbar.Text:SetFont(text_font, text_size)
	Castbar.Text:SetTextColor(unpack(text_color))
	Castbar.Text:SetShadowColor(0, 0, 0)
	Castbar.Text:SetShadowOffset(1, -1)

	Castbar.Time:SetPoint(MR, Castbar, MR, -text_offset_x, text_offset_y)
	Castbar.Time:SetJustifyH('RIGHT')
	Castbar.Time:SetFont(text_font, text_size)
	Castbar.Time:SetTextColor(unpack(text_color))
	Castbar.Time:SetShadowColor(0, 0, 0)
	Castbar.Time:SetShadowOffset(1, -1)

	Castbar.bg:SetAllPoints(Castbar)
	Castbar.bg:SetTexture(0, 0, 0, translucency)

	-- Buffs
	local height = padding + health_height + spacing / 2
	local width = health_width
	local number = math.floor(width / height) * 2
	Buffs:SetPoint(BL, frame, TL, 0, buff_margin)
	Buffs:SetWidth(width)
	Buffs:SetHeight(height)
	Buffs.size = height
	Buffs.num = number
	Buffs.initialAnchor = BL
	Buffs['growth-x'] = 'RIGHT'
	Buffs['growth-y'] = 'UP'
	Buffs.PostCreateIcon = process_icon

	-- Debuffs
	Debuffs:SetPoint(TL, frame, BL, 0, -buff_margin)
	Debuffs:SetWidth(width)
	Debuffs:SetHeight(height)
	Debuffs.size = height
	Debuffs.num = number
	Debuffs.initialAnchor = TL
	Debuffs['growth-x'] = 'RIGHT'
	Debuffs['growth-y'] = 'DOWN'
	Debuffs.PostCreateIcon = process_icon

	-- Leader icon
	Leader:SetPoint(MC, frame, TL)
	Leader:SetWidth(16)
	Leader:SetHeight(16)

	-- raid icon
	Raidicon:SetPoint(MC, frame, TC)
	Raidicon:SetWidth(16)
	Raidicon:SetHeight(16)

	-- master looter icon
	Masterlooter:SetPoint(ML, Leader, MR)
	Masterlooter:SetWidth(16)
	Masterlooter:SetHeight(16)

	-- Threat
	Threat:SetPoint(MC, frame, TR)
	Threat:SetWidth(16)
	Threat:SetHeight(16)

	-- Background
	background:SetAllPoints(frame)
	background:SetTexture(unpack(background_color))

	-- Frame
	frame:RegisterForClicks('anyup')
	frame:SetAttribute('type2', 'menu')
	frame:SetAttribute('initial-width', Health:GetWidth() + padding * 2)
	frame:SetAttribute('initial-height', Health:GetHeight() + Power:GetHeight() + padding * 2 + spacing)
	frame.menu = show_menu
	frame.Buffs = Buffs
	frame.Castbar = Castbar
	frame.Debuffs = Debuffs
	frame.Health = Health
	frame.Info = Power.info
	frame.Leader = Leader
	frame.MasterLooter = Masterlooter
	frame.Name = Health.info
	frame.PostCreateAuraIcon = process_icon
	frame.Power = Power
	frame.RaidIcon = Raidicon
	frame.Threat = Threat
end

function create_player_unitframe (frame, unit)
	create_unitframe(frame, unit)

	frame.Buffs:ClearAllPoints()
	frame.Buffs:SetPoint(TR, frame, TL, -buff_margin, 0)
	frame.Buffs.initialAnchor = TR
	frame.Buffs['growth-x'] = 'LEFT'
	frame.Buffs['growth-y'] = 'DOWN'
end

function create_target_unitframe (frame, unit)
	create_unitframe(frame, unit)

	frame.Buffs:ClearAllPoints()
	frame.Buffs:SetPoint(TL, frame, TR, buff_margin, 0)
	frame.Buffs.initialAnchor = TL
	frame.Buffs['growth-x'] = 'RIGHT'
	frame.Buffs['growth-y'] = 'DOWN'

	frame.Debuffs:ClearAllPoints()
	frame.Debuffs:SetPoint(TL, frame, BL, 0, -buff_margin)
	frame.Debuffs.initialAnchor = TL
	frame.Debuffs['growth-x'] = 'RIGHT'
	frame.Debuffs['growth-y'] = 'DOWN'
end

function create_targettarget_unitframe (frame, unit)
	create_unitframe(frame, unit)

	frame.Power:SetHeight(0)

	frame:SetAttribute('initial-height', frame.Health:GetHeight() + padding * 2)

	frame.Power = nil
	frame.PostUpdatePower = nil
	frame.Buffs = nil
	frame.Debuffs = nil
end

function create_pet_unitframe(frame, unit)
	create_focus_unitframe(frame, unit)

	local happiness = frame:CreateTexture(nil, 'OVERLAY')
	happiness:SetPoint(MC, frame, TL)
	happiness:SetWidth(16)
	happiness:SetHeight(16)

	happiness.PostUpdate = update_pet_happiness

	frame.Happiness = happiness
end

function create_pettarget_unitframe (frame, unit)
	create_focus_unitframe(frame, unit)
end

function create_focus_unitframe (frame, unit)
	create_targettarget_unitframe(frame, unit)

	frame.Health:SetWidth(health_width / 2 - padding - margin / 2)
	frame:SetAttribute('initial-width', frame.Health:GetWidth() + padding * 2)
end

function create_focustarget_unitframe (frame, unit)
	create_focus_unitframe(frame, unit)
end

oUF:RegisterStyle('Industrial-player', create_player_unitframe)
oUF:RegisterStyle('Industrial-target', create_target_unitframe)
oUF:RegisterStyle('Industrial-targettarget', create_targettarget_unitframe)
oUF:RegisterStyle('Industrial-pet', create_pet_unitframe)
oUF:RegisterStyle('Industrial-pettarget', create_pettarget_unitframe)
oUF:RegisterStyle('Industrial-focus', create_focus_unitframe)
oUF:RegisterStyle('Industrial-focustarget', create_focustarget_unitframe)

oUF:SetActiveStyle('Industrial-player')
local player       = oUF:Spawn('player', frame_name..'player')

oUF:SetActiveStyle('Industrial-target')
local target       = oUF:Spawn('target', frame_name..'target')

oUF:SetActiveStyle('Industrial-targettarget')
local targettarget = oUF:Spawn('targettarget', frame_name..'targettarget')

oUF:SetActiveStyle('Industrial-pet')
local pet          = oUF:Spawn('pet', frame_name..'pet')

oUF:SetActiveStyle('Industrial-pettarget')
local pettarget    = oUF:Spawn('pettarget', frame_name..'pettarget')

oUF:SetActiveStyle('Industrial-focus')
local focus        = oUF:Spawn('focus', frame_name..'focus')

oUF:SetActiveStyle('Industrial-focustarget')
local focustarget  = oUF:Spawn('focustarget', frame_name..'focustarget')

targettarget:SetScript('OnUpdate', targettarget.PLAYER_ENTERING_WORLD)

player:SetPoint(MR, UIParent, MC, -offset_x - margin / 2, offset_y)
target:SetPoint(ML, UIParent, MC, offset_x + margin / 2, offset_y)
targettarget:SetPoint(BL, target, TL, 0, margin)
pet:SetPoint(BL, player, TL, 0, margin)
pettarget:SetPoint(BL, pet, TL, 0, margin)
focus:SetPoint(BR, player, TR, 0, margin)
focustarget:SetPoint(BR, focus, TR, 0, margin)

RuneFrame:Hide()


