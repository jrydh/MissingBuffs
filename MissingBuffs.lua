--
-- MissingBuffs.lua
-- Copyright 2009 Johannes Rydh
--
-- MissingBuffs is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.
--

MissingBuffs = LibStub("AceAddon-3.0"):NewAddon( "MissingBuffs", "AceEvent-3.0" );

function MissingBuffs:OnInitialize()
	self:CreateFrame();
	self.needsUpdate = true;
end

function MissingBuffs:OnEnable()
	local f = function() self.needsUpdate = true; end
	self:RegisterEvent( "UNIT_AURA", f );
	self:RegisterEvent( "PLAYER_REGEN_ENABLED", f );
	self:RegisterEvent( "PARTY_MEMBERS_CHANGED", f );
end

function MissingBuffs:CreateFrame()
	local f = CreateFrame( "Frame", "MissingBuffsFrame",
	                    UIParent, "SecureFrameTemplate" );
	self.frame = f;

	f:SetWidth( 360 );
	f:SetHeight( 36 );
	f:SetMovable( true );
	if not f:GetLeft() then f:SetPoint( "CENTER" ); end

	self.icons = {};
	for i = 1,10 do
		local tf = CreateFrame( "Frame", nil, f );
		tf:SetPoint( "TOPLEFT", f, "TOPRIGHT", 3-36*i, -3 );
		tf:SetPoint( "BOTTOMRIGHT", f, "BOTTOMRIGHT", 33-36*i, 3 );
		tf:EnableMouse( true );
		tf:SetScript( "OnMouseDown",
			function() if IsAltKeyDown() then f:StartMoving(); end end );
		tf:SetScript( "OnMouseUp", function() f:StopMovingOrSizing(); end );
		self.icons[i] = tf;

		local t = tf:CreateTexture( nil, "OVERLAY" );
		t:SetAllPoints( tf );
		t:SetAlpha( 0.5 );
		self.icons[i].texture = t;
		
		local s = tf:CreateFontString( nil, "ARTWORK", "GameFontHighlight" );
		s:SetPoint( "BOTTOMRIGHT", tf, "BOTTOMRIGHT", -3, 3 );
		self.icons[i].number = s;
	end
	
	f:SetScript( "OnUpdate",
		function() if self.needsUpdate then self:UpdateFrame(); end end );
	RegisterStateDriver( f, "visibility", "[combat] hide; show" );
end

function MissingBuffs:UpdateFrame()
	self.needsUpdate = false;

	-- current buffs
	local hasBuff = {};
	for i = 1,40 do
		local buff = UnitBuff( "player", i );
		if not buff then break; end
		hasBuff[buff] = true;
	end

	-- party/raid members
	local _, myclass = UnitClass( "player" );
	local party = { ["DEATHKNIGHT"] = 0, ["DRUID"] = 0,
		["HUNTER"] = 0, ["MAGE"] = 0, ["PALADIN"] = 0,
		["PRIEST"] = 0, ["ROGUE"] = 0, ["SHAMAN"] = 0,
		["WARLOCK"] = 0, ["WARRIOR"] = 0 };
	local raid = { ["DEATHKNIGHT"] = 0, ["DRUID"] = 0,
		["HUNTER"] = 0, ["MAGE"] = 0, ["PALADIN"] = 0,
		["PRIEST"] = 0, ["ROGUE"] = 0, ["SHAMAN"] = 0,
		["WARLOCK"] = 0, ["WARRIOR"] = 0 };
	local n,m = GetNumRaidMembers(), GetNumPartyMembers();
	for i = 1,m do
		local _, class = UnitClass( "party"..i );
		if class then
			party[class] = party[class] + 1;
		end
	end
	party[myclass] = party[myclass] + 1;
	if n > 0 then
		for i = 1,n do
			local _, class = UnitClass( "raid"..i );
			if class then
				raid[class] = raid[class] + 1;
			end
		end
	else
		raid = party;
	end
	
	-- test helper routine
	local pos = 1;
	local testbuff = function( k, ... )
		for i = 1,select( "#", ... ) do
			local id = select( i, ... );
			name = GetSpellInfo( id );
			if hasBuff[name] then k = k - 1; end
		end
		if k > 0 and pos <= 10 then
			local id = select( 1, ... );
			local _, _, icon = GetSpellInfo( id );
			self.icons[pos].texture:SetTexture( icon );
			self.icons[pos].number:SetText( (k>1) and k or "" );
			self.icons[pos]:Show();
			pos = pos + 1;
		end
	end

	local casters = { ["DRUID"] = true, ["HUNTER"] = true,
		["MAGE"] = true, ["PALADIN"] = true, ["PRIEST"] = true,
		["SHAMAN"] = true, ["WARLOCK"] = true };
	local isCaster = casters[myclass];

	-- self buffs
	if myclass == "DEATHKNIGHT" then
		testbuff( 1, 48266, 48263, 48265 ); -- Presence
	elseif myclass == "DRUID" then
		testbuff( 1, 467 ); -- Thorns
	elseif myclass == "HUNTER" then
		testbuff( 1, 13165, 13164, 5118, 34074,
			     13161, 13159, 20043, 61846 ); -- Aspect
	elseif myclass == "MAGE" then
		testbuff( 1, 6117, 168, 7302, 30482 ); -- Armor
		testbuff( 1, 604, 1008 ); -- Amplify/Dampen Magic
	elseif myclass == "PALADIN" then
	elseif myclass == "PRIEST" then
		testbuff( 1, 588 ); -- Inner Fire
	elseif myclass == "ROGUE" then
	elseif myclass == "SHAMAN" then
	elseif myclass == "WARLOCK" then
		testbuff( 1, 696, 706, 28176 ); -- Armor
	elseif myclass == "WARRIOR" then
		testbuff( 1, 2457, 71, 2458 ); -- Stance
	end

	-- party/raid buffs
	if raid["DRUID"] > 0 then
		testbuff( 1, 1126, 21849 ); -- Mark of the Wild
	end
	if raid["MAGE"] > 0 and isCaster then
		testbuff( 1, 1459, 23028, 61024, 61316, 54424 ); -- Arcane Intellect
	end
	if raid["PALADIN"] > 0 then
		testbuff( raid["PALADIN"], 465, 7294, 19746,
		                 19876, 19888, 19891, 32223 ); -- Aura
		testbuff( raid["PALADIN"], 20217, 25898, 19740,
		             25782, 19742, 25894, 20911, 25899 ); -- Blessing
	end
	if raid["PRIEST"] > 0 then
		testbuff( 1, 1243, 21562 ); -- Power Word: Fortitude
		if isCaster then
			testbuff( 1, 14752, 27681 ); -- Divine Spirit
		end
	end
	
	local isArena = IsActiveBattlefieldArena();
	if n > 0 and not isArena and GetRealZoneText() ~= "Wintergrasp" then
		testbuff( 1, 57294 ); -- Well Fed
		testbuff( 1, 53760, 54212, 53758, 53755 ); -- Flask
	end
	
	-- hide unused textures
	for i = pos,10 do
		self.icons[i]:Hide();
	end
end
