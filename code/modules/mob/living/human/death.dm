/mob/living/human/gib()

	for(var/mob/M in src)
		if(M in src.stomach_contents)
			src.stomach_contents.Remove(M)
		M.forceMove(src.loc)
		M.visible_message("<span class='danger'>\The [M] bursts out of \the [src]!</span>")

	for(var/obj/item/organ/I in internal_organs)
		I.removed()
		if(istype(loc,/turf))
			I.throw_at(get_edge_target_turf(src,pick(alldirs)),rand(1,3),30)

	for(var/obj/item/organ/external/E in src.organs)
		E.droplimb(0,DROPLIMB_EDGE,1)

	sleep(1)

	for(var/obj/item/I in src)
		drop_from_inventory(I)
		I.throw_at(get_edge_target_turf(src,pick(alldirs)), rand(1,3), round(30/I.w_class))

	..(species.gibbed_anim)
	gibs(loc, null, species.get_flesh_colour(src), species.get_blood_colour(src))

/mob/living/human/dust()
	if(species)
		..(species.dusted_anim, species.remains_type)
	else
		..()

/mob/living/human/death(gibbed)

	if(stat == DEAD) return

	BITSET(hud_updateflag, HEALTH_HUD)
	BITSET(hud_updateflag, STATUS_HUD)
	BITSET(hud_updateflag, LIFE_HUD)

	//Handle species-specific deaths.
	species.handle_death(src)

	//Handle brain slugs.
	var/obj/item/organ/external/head = get_organ(BP_HEAD)
	var/mob/living/animal/borer/B

	for(var/I in head.implants)
		if(istype(I,/mob/living/animal/borer))
			B = I
	if(B)
		if(!B.ckey && ckey && B.controlling)
			B.ckey = ckey
			B.controlling = 0
		if(B.host_brain.ckey)
			ckey = B.host_brain.ckey
			B.host_brain.ckey = null
			B.host_brain.name = "host brain"
			B.host_brain.real_name = "host brain"

		verbs -= /mob/living/proc/release_control

	callHook("death", list(src, gibbed))

	if(!gibbed && species.death_sound)
		playsound(loc, species.death_sound, 80, 1, 1)

	if(ticker && ticker.mode)
		ticker.mode.check_win()

	if(wearing_rig)
		wearing_rig.notify_ai("<span class='danger'>Warning: user death event. Mobility control passed to integrated intelligence system.</span>")

	clear_fullscreens()

	return ..(gibbed,species.get_death_message(src))
	handle_hud_list()

/mob/living/human/proc/ChangeToHusk()
	if(disabilities & HUSK)
		return

	if(f_style)
		f_style = "Shaved"		//we only change the icon_state of the hair datum, so it doesn't mess up their UI/UE
	if(h_style)
		h_style = "Bald"
	update_hair(0)

	disabilities  |= HUSK
	status_flags |= DISFIGURED	//makes them unknown without fucking up other stuff like admintools
	update_body(1)
	return