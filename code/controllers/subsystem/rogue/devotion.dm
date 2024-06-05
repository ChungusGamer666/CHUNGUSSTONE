/// DEFINITIONS ///
#define CLERIC_T0 0
#define CLERIC_T1 1
#define CLERIC_T2 2
#define CLERIC_T3 3

#define CLERIC_REQ_0 0
#define CLERIC_REQ_1 100
#define CLERIC_REQ_2 250
#define CLERIC_REQ_3 500

// Cleric Holder Datums

/datum/devotion
	var/holder_mob = null
	var/patron = null
	var/devotion = 0
	var/max_devotion = CLERIC_REQ_3 * 2
	var/progression = 0
	var/max_progression = CLERIC_REQ_3
	var/level = CLERIC_T0

/datum/devotion/New(mob/living/carbon/human/holder, god)
	holder_mob = holder
	holder.devotion = src
	patron = god

/datum/devotion/proc/check_devotion(obj/effect/proc_holder/spell/spell)
	if(devotion - spell.devotion_cost < 0)
		return FALSE
	return TRUE

/datum/devotion/proc/update_devotion(dev_amt, prog_amt)
	var/datum/patron/P = patron
	devotion = clamp(devotion + dev_amt, 0, max_devotion)
	//Max devotion limit
	if(devotion >= max_devotion)
		to_chat(holder_mob, "<span class='warning'>I have reached the limit of my devotion...</span>")
	if(!prog_amt) // no point in the rest if it's just an expenditure
		return TRUE
	progression = clamp(progression + prog_amt, 0, max_progression)
	var/obj/effect/spell_unlocked
	switch(level)
		if(CLERIC_T0)
			if(progression >= CLERIC_REQ_1)
				spell_unlocked = P.t1
				level = CLERIC_T1
		if(CLERIC_T1)
			if(progression >= CLERIC_REQ_2)
				spell_unlocked = P.t2
				level = CLERIC_T2
		if(CLERIC_T2)
			if(progression >= CLERIC_REQ_3)
				spell_unlocked = P.t3
				level = CLERIC_T3
	if(!spell_unlocked || !holder_mob?.mind || holder_mob.mind.has_spell(spell_unlocked, specific = FALSE))
		return TRUE
	spell_unlocked = new spell_unlocked
	to_chat(holder_mob, "<span class='boldnotice'>I have unlocked a new spell: [spell_unlocked]</span>")
	usr.mind.AddSpell(spell_unlocked)
	return TRUE

// Cleric Spell Spawner
/datum/devotion/proc/grant_spells_priest(mob/living/carbon/human/H)
	if(!H || !H.mind)
		return

	var/datum/patron/A = H.patron
	var/list/spelllist = list(A.t0, A.t1, A.t2, A.t3)
	for(var/spell_type in spelllist)
		if(!spell_type || H.mind.has_spell(spell_type))
			continue
		H.mind.AddSpell(new spell_type)
	level = CLERIC_T3
	update_devotion(300, 900)

/datum/devotion/proc/grant_spells(mob/living/carbon/human/H)
	if(!H || !H.mind)
		return

	var/datum/patron/A = H.patron
	var/list/spelllist = list(A.t0, A.t1)
	for(var/spell_type in spelllist)
		if(!spell_type || H.mind.has_spell(spell_type))
			continue
		H.mind.AddSpell(new spell_type)
	level = CLERIC_T1

/datum/devotion/proc/grant_spells_templar(mob/living/carbon/human/H)
	if(!H || !H.mind)
		return

	var/datum/patron/A = H.patron
	var/list/spelllist = list(/obj/effect/proc_holder/spell/targeted/churn, A.t0)
	for(var/spell_type in spelllist)
		if(!spell_type || H.mind.has_spell(spell_type))
			continue
		H.mind.AddSpell(new spell_type)
	level = CLERIC_T0

/mob/living/carbon/human/proc/devotionreport()
	set name = "Check Devotion"
	set category = "Cleric"

	var/datum/devotion/C = src.devotion
	to_chat(src,"My devotion is [C.devotion].")

// Debug verb
/mob/living/carbon/human/proc/devotionchange()
	set name = "(DEBUG)Change Devotion"
	set category = "Special Verbs"

	var/datum/devotion/C = src.devotion
	var/changeamt = input(src, "My devotion is [C.devotion]. How much to change?", "How much to change?") as null|num
	if(!changeamt)
		return
	C.devotion += changeamt

// Generation Procs

/mob/living/carbon/human/proc/clericpray()
	set name = "Give Prayer"
	set category = "Cleric"
	
	var/datum/devotion/C = src.devotion
	var/prayersesh = 0

	visible_message("[src] kneels their head in prayer to the Gods.", "I kneel my head in prayer to [patron.name].")
	for(var/i in 1 to 20)
		if(do_after(src, 30))
			if(C.devotion >= C.max_devotion)
				to_chat(src, "<font color='red'>I have reached the limit of my devotion...</font>")
				break
			C.update_devotion(2, 2)
			prayersesh += 2
		else
			visible_message("[src] concludes their prayer.", "I conclude my prayer.")
			to_chat(src, "<font color='purple'>I gained [prayersesh] devotion!</font>")
			return
	to_chat(src, "<font color='purple'>I gained [prayersesh] devotion!</font>")
