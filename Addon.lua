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
local offset_y = -350

local buff_margin = margin / 2

local bar_width = 200 - padding * 2
local bar_texture = [[Interface\AddOns\oUF_Industrial\media\textures\statusbar]]

local health_width = bar_width
local health_height = 20
local health_texture = bar_texture
local health_color = {0.5, 0.5, 0.5, translucency + translucency / 2}

local power_width = bar_width
local power_height = 20
local power_texture = bar_texture
local power_color = {0.5, 1, 0, translucency + translucency / 2}

local cast_color = {1, 1, 0, translucency + translucency / 2}

local text_offset_x = 3
local text_offset_y = 1
local text_font = _G.GameFontNormal:GetFont()
local text_color = {1, 1, 1}

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
	return UnitLevel(unit)
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

function process_icon (frame, button)
	if button and button.icon then
		button.icon:SetTexCoord(.07, .93, .07, .93)
	end
end

function update_health (frame, event, unit, bar, min, max)
	bar.value:SetText(format_value(min))
	update_info(frame)
end

function update_power (frame, event, unit, bar, min, max)
	bar.value:SetText(format_value(min > 0 and min or ''))
	update_info(frame)
end

function update_info (frame)
	local unit = frame.unit
	if not UnitExists(unit) then return end

	frame.Name:SetText(('%s%s'):format(unit_name(unit), unit_tapped(unit)))
	frame.Info:SetText(('%s %s'):format(unit_level(unit), unit_threat(unit)))
end

function create_unitframe (frame, unit)
	local background = frame:CreateTexture(nil, 'BACKGROUND')
	local health = CreateFrame('StatusBar', nil, frame)
	local power = CreateFrame('StatusBar', nil, frame)
	local buffs = CreateFrame('Frame', nil, frame)
	local debuffs = CreateFrame('Frame', nil, frame)
	local rlicon = health:CreateTexture(nil, 'OVERLAY')
	local ricon = health:CreateTexture(nil, 'OVERLAY')
	local mlicon = health:CreateTexture(nil, 'OVERLAY')
	local threat = health:CreateTexture(nil, 'OVERLAY')
	local castbar = CreateFrame('StatusBar', nil, health)
	health.info = health:CreateFontString(nil, 'OVERLAY')
	health.value = health:CreateFontString(nil, 'OVERLAY')
	power.info = power:CreateFontString(nil, 'OVERLAY')
	power.value = power:CreateFontString(nil, 'OVERLAY')
	frame.menu = show_menu
	castbar.Icon = castbar:CreateTexture()
	castbar.Text = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.Time = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.background = castbar:CreateTexture(nil, 'BACKGROUND')

	-- healthbar
	health:SetPoint(TL, frame, TL, padding, -padding)
	health:SetWidth(health_width)
	health:SetHeight(health_height)
	health:SetStatusBarTexture(health_texture)
	health:SetStatusBarColor(unpack(health_color))

	health.info:SetPoint(ML, health, ML, text_offset_x, 1)
	health.info:SetPoint(MR, health.value, ML)
	health.info:SetJustifyH('LEFT')
	health.info:SetFont(text_font, 10)
	health.info:SetTextColor(unpack(text_color))
	health.info:SetShadowColor(0, 0, 0)
	health.info:SetShadowOffset(1, -1)

	health.value:SetPoint(MR, health, MR, -text_offset_x, 1)
	health.value:SetJustifyH('RIGHT')
	health.value:SetFont(text_font, 10)
	health.value:SetTextColor(unpack(text_color))
	health.value:SetShadowColor(0, 0, 0)
	health.value:SetShadowOffset(1, -1)

	-- powerbar
	power:SetPoint(TL, health, BL, 0, -spacing)
	power:SetWidth(power_width)
	power:SetHeight(power_height)
	power:SetStatusBarTexture(power_texture)
	oUF.colors.power.MANA = {0/255, 153/255, 204/255}
	power.colorPower = true

	power.info:SetPoint(ML, power, ML, text_offset_x, text_offset_y)
	power.info:SetPoint(MR, power.value, ML)
	power.info:SetJustifyH('LEFT')
	power.info:SetFont(text_font, 10)
	power.info:SetTextColor(unpack(text_color))
	power.info:SetShadowColor(0, 0, 0)
	power.info:SetShadowOffset(1, -1)

	power.value:SetPoint(MR, power, MR, -text_offset_x, text_offset_y)
	power.value:SetJustifyH('RIGHT')
	power.value:SetFont(text_font, 10)
	power.value:SetTextColor(unpack(text_color))
	power.value:SetShadowColor(0, 0, 0)
	power.value:SetShadowOffset(1, -1)

	-- castbar
	castbar:SetPoint(ML, castbar.Icon, MR)
	castbar:SetPoint(MR, power, MR)
	castbar:SetHeight(power_height)
	castbar:SetToplevel(true)
	castbar:SetStatusBarTexture(health_texture)
	castbar:SetStatusBarColor(unpack(cast_color))

	castbar.Icon:SetPoint(ML, power, ML)
	castbar.Icon:SetWidth(power_height)
	castbar.Icon:SetHeight(power_height)
	process_icon(castbar.Icon)

	castbar.Text:SetPoint(ML, castbar, ML, text_offset_x, text_offset_y)
	castbar.Text:SetJustifyH('LEFT')
	castbar.Text:SetFont(text_font, 10)
	castbar.Text:SetTextColor(unpack(text_color))
	castbar.Text:SetShadowColor(0, 0, 0)
	castbar.Text:SetShadowOffset(1, -1)

	castbar.Time:SetPoint(MR, castbar, MR, -text_offset_x, text_offset_y)
	castbar.Time:SetJustifyH('RIGHT')
	castbar.Time:SetFont(text_font, 10)
	castbar.Time:SetTextColor(unpack(text_color))
	castbar.Time:SetShadowColor(0, 0, 0)
	castbar.Time:SetShadowOffset(1, -1)

	castbar.background:SetAllPoints(castbar)
	castbar.background:SetTexture(0, 0, 0, translucency)

	-- buffs
	local height = padding + health_height + spacing / 2
	local width = health_width
	local number = math.floor(width / height) * 2
	buffs:SetPoint(BL, frame, TL, 0, buff_margin)
	buffs:SetWidth(width)
	buffs:SetHeight(height)
	buffs.size = height
	buffs.num = number
	buffs.initialAnchor = BL
	buffs['growth-x'] = 'RIGHT'
	buffs['growth-y'] = 'UP'

	debuffs:SetPoint(TL, frame, BL, 0, -buff_margin)
	debuffs:SetWidth(width)
	debuffs:SetHeight(height)
	debuffs.size = height
	debuffs.num = number
	debuffs.initialAnchor = TL
	debuffs['growth-x'] = 'RIGHT'
	debuffs['growth-y'] = 'DOWN'

	-- rlicon icon
	rlicon:SetPoint(MC, frame, TL)
	rlicon:SetWidth(16)
	rlicon:SetHeight(16)

	-- raid icon
	ricon:SetPoint(MC, frame, TC)
	ricon:SetWidth(16)
	ricon:SetHeight(16)

	-- master looter icon
	mlicon:SetPoint(ML, rlicon, MR)
	mlicon:SetWidth(16)
	mlicon:SetHeight(16)

	-- threat
	threat:SetPoint(MC, frame, TR)
	threat:SetWidth(16)
	threat:SetHeight(16)

	-- frame
	frame:RegisterForClicks('anyup')
	frame:SetAttribute('type2', 'menu')
	frame:SetAttribute('initial-width', health:GetWidth() + padding * 2)
	frame:SetAttribute('initial-height', health:GetHeight() + power:GetHeight() + padding * 2 + spacing)

	background:SetAllPoints(frame)
	background:SetTexture(0, 0, 0, translucency)

	frame.Buffs = buffs
	frame.Castbar = castbar
	frame.Debuffs = debuffs
	frame.Health = health
	frame.Info = power.info
	frame.Leader = rlicon
	frame.MasterLooter = mlicon
	frame.Name = health.info
	frame.PostCreateAuraIcon = process_icon
	frame.PostUpdateHealth = update_health
	frame.PostUpdatePower = update_power
	frame.Power = power
	frame.RaidIcon = ricon
	frame.Threat = threat
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

	local happiness = frame.Health:CreateTexture(nil, 'OVERLAY')
	happiness:SetPoint(MC, frame, TL)
	happiness:SetWidth(16)
	happiness:SetHeight(16)

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


