﻿if not MaxDps then
	return ;
end

--- @type MaxDps
local MaxDps = MaxDps;
local UnitPower = UnitPower;

local Paladin = MaxDps:NewModule('Paladin');

local RT = {
	Rebuke            = 96231,
	ShieldOfVengeance = 184662,
	AvengingWrath     = 31884,
	Inquisition       = 84963,
	Crusade           = 231895,
	ExecutionSentence = 267798,
	DivineStorm       = 53385,
	DivinePurpose     = 223817,
	TemplarsVerdict   = 85256,
	HammerOfWrath     = 24275,
	WakeOfAshes       = 255937,
	BladeOfJustice    = 184575,
	Judgment          = 20271,
	Consecration      = 205228,
	CrusaderStrike    = 35395,
	DivineRight       = 277678,
};

local PR = {
	AvengingWrath            = 31884,
	Seraphim                 = 152262,
	ShieldOfTheRighteous     = 53600,
	ShieldOfTheRighteousAura = 132403,
	Consecration             = 26573,
	Judgment                 = 275779,
	CrusadersJudgment        = 204023,
	AvengersShield           = 31935,
	AvengersValor            = 197561,
	BlessedHammer            = 204019,
	BastionOfLight           = 204035,
	HammerOfTheRighteous     = 53595,
};

local A = {
	DivineRight = 277678
}

local spellMeta = {
	__index = function(t, k)
		print('Spell Key ' .. k .. ' not found!');
	end
}

setmetatable(RT, spellMeta);
setmetatable(PR, spellMeta);
setmetatable(A, spellMeta);

-- General

function Paladin:Enable()
	MaxDps:Print(MaxDps.Colors.Info .. 'Paladin [Holy, Protection, Retribution]');

	if MaxDps.Spec == 1 then
		MaxDps.NextSpell = Paladin.Holy;
	elseif MaxDps.Spec == 2 then
		MaxDps.NextSpell = Paladin.Protection;
	elseif MaxDps.Spec == 3 then
		MaxDps.NextSpell = Paladin.Retribution;
	end ;

	return true;
end

function Paladin:Holy(timeShift, currentSpell, gcd, talents)

	--if MaxDps:SpellAvailable(_JudgementHoly, timeShift) then
	--	return _JudgementHoly;
	--end
	--
	--if MaxDps:SpellAvailable(_CrusaderStrike, timeShift) then
	--	return _CrusaderStrike;
	--end
	--
	--if MaxDps:SpellAvailable(_HolyShock, timeShift) then
	--	return _HolyShock;
	--end
	--
	--if MaxDps:SpellAvailable(_HolyConsecration, timeShift) and
	--	not MaxDps:TargetAura(_HolyConsecrationAura, timeShift + 3) then
	--	return _HolyConsecration;
	--end
end

function Paladin:Protection()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local gcd = fd.gcd;

	local consecrationUp = GetTotemInfo(1);
	-- call_action_list,name=cooldowns;

	Paladin:ProtectionCooldowns();

	-- consecration,if=!consecration.up;
	if cooldown[PR.Consecration].ready and (not consecrationUp) then
		return PR.Consecration;
	end

	-- judgment,if=(cooldown.judgment.remains<gcd&cooldown.judgment.charges_fractional>1&cooldown_react)|!talent.crusaders_judgment.enabled;
	if (cooldown[PR.Judgment].remains < gcd and cooldown[PR.Judgment].charges > 1) or
		not talents[PR.CrusadersJudgment] and cooldown[PR.Judgment].ready
	then
		return PR.Judgment;
	end

	-- avengers_shield,if=cooldown_react;
	if cooldown[PR.AvengersShield].ready then
		return PR.AvengersShield;
	end

	-- judgment,if=cooldown_react|!talent.crusaders_judgment.enabled;
	if not talents[PR.CrusadersJudgment] and cooldown[PR.Judgment].ready then
		return PR.Judgment;
	end

	-- blessed_hammer,strikes=2;
	if talents[PR.BlessedHammer] and cooldown[PR.BlessedHammer].ready then
		return PR.BlessedHammer;
	end

	-- hammer_of_the_righteous;
	if cooldown[PR.HammerOfTheRighteous].ready then
		return PR.HammerOfTheRighteous;
	end

	-- consecration;
	if cooldown[PR.Consecration].ready then
		return PR.Consecration;
	end
end

function Paladin:ProtectionCooldowns()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;

	-- avenging_wrath;
	MaxDps:GlowCooldown(PR.AvengingWrath, cooldown[PR.AvengingWrath].ready);
	MaxDps:GlowCooldown(PR.ShieldOfTheRighteous, cooldown[PR.ShieldOfTheRighteous].ready and not buff[PR.ShieldOfTheRighteousAura].up);

	-- seraphim;
	if talents[PR.Seraphim] then
		MaxDps:GlowCooldown(PR.Seraphim, cooldown[PR.Seraphim].ready);
	end

	if talents[PR.BastionOfLight] then
		MaxDps:GlowCooldown(PR.BastionOfLight, cooldown[PR.BastionOfLight].ready and (cooldown[PR.ShieldOfTheRighteous].charges <= 0.5));
	end
end

function Paladin:Retribution()
	local fd = MaxDps.FrameData;
	fd.targets = MaxDps:SmartAoe();

	-- call_action_list,name=cooldowns;
	Paladin:RetributionCooldowns();

	-- call_action_list,name=generators;
	return Paladin:RetributionGenerators();
end

function Paladin:RetributionCooldowns()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local holyPower = UnitPower('player', Enum.PowerType.HolyPower);

	MaxDps:GlowCooldown(RT.ShieldOfVengeance, cooldown[RT.ShieldOfVengeance].ready);

	if talents[RT.Crusade] then
		-- crusade,if=holy_power>=4;
		MaxDps:GlowCooldown(
			RT.Crusade,
			cooldown[RT.Crusade].ready and holyPower >= 4
		);
	else
		-- avenging_wrath,if=buff.inquisition.up|!talent.inquisition.enabled;
		MaxDps:GlowCooldown(
			RT.AvengingWrath,
			cooldown[RT.AvengingWrath].ready and (buff[RT.Inquisition].up or not talents[RT.Inquisition])
		);
	end
end

function Paladin:RetributionFinishers()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local azerite = fd.azerite;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local holyPower = UnitPower('player', Enum.PowerType.HolyPower);
	local targetHp = MaxDps:TargetPercentHealth() * 100;

	-- variable,name=ds_castable,value=spell_targets.divine_storm>=2|azerite.divine_right.enabled&target.health.pct<=20&buff.divine_right.down;
	local dsCastable = targets >= 2 or azerite[A.DivineRight] > 0 and targetHp <= 20 and not buff[RT.DivineRight].up;

	-- inquisition,if=buff.inquisition.down|buff.inquisition.remains<5&holy_power>=3|talent.execution_sentence.enabled&cooldown.execution_sentence.remains<10&buff.inquisition.remains<15|cooldown.avenging_wrath.remains<15&buff.inquisition.remains<20&holy_power>=3;
	if talents[RT.Inquisition] and holyPower >= 1 and (
		not buff[RT.Inquisition].up or buff[RT.Inquisition].remains < 5 and
			holyPower >= 3 or talents[RT.ExecutionSentence] and
			cooldown[RT.ExecutionSentence].remains < 10 and
			buff[RT.Inquisition].remains < 15 or cooldown[RT.AvengingWrath].remains < 15 and
			buff[RT.Inquisition].remains < 20 and holyPower >= 3
	) then
		return RT.Inquisition;
	end

	-- execution_sentence,if=spell_targets.divine_storm<=2&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2);
	if talents[RT.ExecutionSentence] and cooldown[RT.ExecutionSentence].ready and holyPower >= 3 and (
		targets <= 2 and (not talents[RT.Crusade] or cooldown[RT.Crusade].remains > gcd * 2)
	) then
		return RT.ExecutionSentence;
	end

	-- divine_storm,if=variable.ds_castable&buff.divine_purpose.react;
	if holyPower >= 3 and (dsCastable and buff[RT.DivinePurpose].count) then
		return RT.DivineStorm;
	end

	-- divine_storm,if=variable.ds_castable&(!talent.crusade.enabled|cooldown.crusade.remains>gcd*2);
	if holyPower >= 3 and (dsCastable and (not talents[RT.Crusade] or cooldown[RT.Crusade].remains > gcd * 2)) then
		return RT.DivineStorm;
	end

	-- templars_verdict,if=buff.divine_purpose.react;
	if holyPower >= 3 and (buff[RT.DivinePurpose].count) then
		return RT.TemplarsVerdict;
	end

	-- templars_verdict,if=(!talent.crusade.enabled|cooldown.crusade.remains>gcd*3)&(!talent.execution_sentence.enabled|buff.crusade.up&buff.crusade.stack<10|cooldown.execution_sentence.remains>gcd*2);
	if holyPower >= 3 and ((not talents[RT.Crusade] or cooldown[RT.Crusade].remains > gcd * 3) and (not talents[RT.ExecutionSentence] or buff[RT.Crusade].up and buff[RT.Crusade].count < 10 or cooldown[RT.ExecutionSentence].remains > gcd * 2)) then
		return RT.TemplarsVerdict;
	end
end

function Paladin:RetributionGenerators()
	local fd = MaxDps.FrameData;
	local cooldown = fd.cooldown;
	local buff = fd.buff;
	local talents = fd.talents;
	local targets = fd.targets;
	local gcd = fd.gcd;
	local holyPower = UnitPower('player', Enum.PowerType.HolyPower);
	local targetHp = MaxDps:TargetPercentHealth() * 100;
	local result;

	-- variable,name=HoW,value=(!talent.hammer_of_wrath.enabled|target.health.pct>=20&(buff.avenging_wrath.down|buff.crusade.down));
	local hoW = (
		not talents[RT.HammerOfWrath] or targetHp >= 20 and
		(not buff[RT.AvengingWrath].up or not buff[RT.Crusade].up)
	);

	-- call_action_list,name=finishers,if=holy_power>=5;
	if holyPower >= 5 then
		result = Paladin:RetributionFinishers();
		if result then return result; end
	end

	-- wake_of_ashes,if=(!raid_event.adds.exists|raid_event.adds.in>15|spell_targets.wake_of_ashes>=2)&(holy_power<=0|holy_power=1&cooldown.blade_of_justice.remains>gcd);
	if cooldown[RT.WakeOfAshes].ready and (
		holyPower <= 0 or holyPower == 1 and
		cooldown[RT.BladeOfJustice].remains > gcd
	) then
		return RT.WakeOfAshes;
	end

	-- blade_of_justice,if=holy_power<=2|(holy_power=3&(cooldown.hammer_of_wrath.remains>gcd*2|variable.HoW));
	if cooldown[RT.BladeOfJustice].ready and (holyPower <= 2 or (holyPower == 3 and (cooldown[RT.HammerOfWrath].remains > gcd * 2 or hoW))) then
		return RT.BladeOfJustice;
	end

	-- judgment,if=holy_power<=2|(holy_power<=4&(cooldown.blade_of_justice.remains>gcd*2|variable.HoW));
	if cooldown[RT.Judgment].ready and (
		holyPower <= 2 or (holyPower <= 4 and (cooldown[RT.BladeOfJustice].remains > gcd * 2 or hoW))
	) then
		return RT.Judgment;
	end

	-- hammer_of_wrath,if=holy_power<=4;
	if talents[RT.HammerOfWrath] and cooldown[RT.HammerOfWrath].ready and (holyPower <= 4) then
		return RT.HammerOfWrath;
	end

	-- consecration,if=holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2;
	if talents[RT.Consecration] and cooldown[RT.Consecration].ready and (
		holyPower <= 2 or holyPower <= 3 and
		cooldown[RT.BladeOfJustice].remains > gcd * 2 or holyPower == 4 and
		cooldown[RT.BladeOfJustice].remains > gcd * 2 and
		cooldown[RT.Judgment].remains > gcd * 2
	) then
		return RT.Consecration;
	end

	-- call_action_list,name=finishers,if=talent.hammer_of_wrath.enabled&(target.health.pct<=20|buff.avenging_wrath.up|buff.crusade.up)&(buff.divine_purpose.up|buff.crusade.stack<10);
	if talents[RT.HammerOfWrath] and
		(targetHp <= 20 or buff[RT.AvengingWrath].up or buff[RT.Crusade].up) and
		(buff[RT.DivinePurpose].up or buff[RT.Crusade].count < 10)
	then
		result = Paladin:RetributionFinishers();
		if result then return result; end
	end

	-- crusader_strike,if=cooldown.crusader_strike.charges_fractional>=1.75&(holy_power<=2|holy_power<=3&cooldown.blade_of_justice.remains>gcd*2|holy_power=4&cooldown.blade_of_justice.remains>gcd*2&cooldown.judgment.remains>gcd*2&cooldown.consecration.remains>gcd*2);
	if cooldown[RT.CrusaderStrike].charges >= 1.75 and (
		holyPower <= 2 or holyPower <= 3 and
		cooldown[RT.BladeOfJustice].remains > gcd * 2 or holyPower == 4 and
		cooldown[RT.BladeOfJustice].remains > gcd * 2 and
		cooldown[RT.Judgment].remains > gcd * 2 and
		cooldown[RT.Consecration].remains > gcd * 2
	) then
		return RT.CrusaderStrike;
	end

	-- call_action_list,name=finishers;
	result = Paladin:RetributionFinishers();
	if result then return result; end

	-- crusader_strike,if=holy_power<=4;
	if holyPower <= 4 then
		return RT.CrusaderStrike;
	end
end
