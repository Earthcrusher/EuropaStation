var/list/human_icon_cache = list()
var/list/light_overlay_cache = list()

//Human Overlays Indexes/////////
#define BODY_LAYER				1
#define DAMAGE_LAYER			2
#define SURGERY_LEVEL			3		//bs12 specific.
#define UNIFORM_LAYER			4
#define ID_LAYER				5
#define SHOES_LAYER				6
#define GLOVES_LAYER			7
#define BELT_LAYER				8
#define SUIT_LAYER				9
#define TAIL_LAYER				10		//bs12 specific. this hack is probably gonna come back to haunt me
#define GLASSES_LAYER			11
#define BELT_LAYER_ALT			12
#define SUIT_STORE_LAYER		13
#define BACK_LAYER				14
#define HAIR_LAYER				15		//TODO: make part of head layer?
#define EARS_LAYER				16
#define FACEMASK_LAYER			17
#define HEAD_LAYER				18
#define COLLAR_LAYER			19
#define HANDCUFF_LAYER			20
#define LEGCUFF_LAYER			21
#define L_HAND_LAYER			22
#define R_HAND_LAYER			23
#define FIRE_LAYER				24		//If you're on fire
#define TARGETED_LAYER			25		//BS12: Layer for the target overlay from weapon targeting system
#define TOTAL_LAYERS			25
//////////////////////////////////

/mob/living/human
	var/list/overlays_standing[TOTAL_LAYERS]
	var/previous_damage_appearance // store what the body last looked like, so we only have to update it if something changed

//UPDATES OVERLAYS FROM OVERLAYS_LYING/OVERLAYS_STANDING
//this proc is messy as I was forced to include some old laggy cloaking code to it so that I don't break cloakers
//I'll work on removing that stuff by rewriting some of the cloaking stuff at a later date.
/mob/living/human/update_icons()
	lying_prev = lying	//so we don't update overlays for lying/standing unless our stance changes again
	update_hud()
	overlays.Cut()
	if(icon_update)
		for(var/image/I in overlays_standing)
			overlays += I
		if(species.has_floating_eyes)
			overlays |= species.get_eyes(src)
	if(lying)
		var/matrix/M = matrix()
		M.Turn(90)
		M.Scale(size_multiplier)
		M.Translate(1,-6)
		src.transform = M
	else
		var/matrix/M = matrix()
		M.Scale(size_multiplier)
		M.Translate(0, 16*(size_multiplier-1))
		src.transform = M

var/global/list/damage_icon_parts = list()

//DAMAGE OVERLAYS
//constructs damage icon for each organ from mask * damage field and saves it in our overlays_ lists
/mob/living/human/UpdateDamageIcon(var/update_icons=1)
	// first check whether something actually changed about damage appearance
	var/damage_appearance = ""

	for(var/obj/item/organ/external/O in organs)
		if(O.is_stump())
			continue
		damage_appearance += O.damage_state

	if(damage_appearance == previous_damage_appearance)
		// nothing to do here
		return

	previous_damage_appearance = damage_appearance

	var/icon/standing = new /icon(species.damage_overlays, "00")

	var/image/standing_image = new /image("icon" = standing)

	// blend the individual damage states with our icons
	for(var/obj/item/organ/external/O in organs)
		if(O.is_stump())
			continue
		O.update_icon()
		if(O.damage_state == "00") continue
		var/icon/DI
		var/use_colour = ((O.status & ORGAN_ROBOT) ? SYNTH_BLOOD_COLOUR : O.species.get_blood_colour(src))
		var/cache_index = "[O.damage_state]/[O.icon_name]/[use_colour]/[species.get_bodytype()]"
		if(damage_icon_parts[cache_index] == null)
			DI = new /icon(species.damage_overlays, O.damage_state)			// the damage icon for whole human
			DI.Blend(new /icon(species.damage_mask, O.icon_name), ICON_MULTIPLY)	// mask with this organ's pixels
			DI.Blend(use_colour, ICON_MULTIPLY)
			damage_icon_parts[cache_index] = DI
		else
			DI = damage_icon_parts[cache_index]

		standing_image.overlays += DI

	overlays_standing[DAMAGE_LAYER] = standing_image

	if(update_icons)   update_icons()

//BASE MOB SPRITE
/mob/living/human/proc/update_body(var/update_icons=1)
	var/image/compiled_image = image(null)
	var/list/overlays_to_add = list()
	for(var/obj/item/organ/external/part in organs)
		if(part) overlays_to_add += part.get_image()
	if(underwear && species.appearance_flags & HAS_UNDERWEAR)
		overlays_to_add += image('icons/mob/clothing/underwear.dmi', underwear)
	compiled_image.overlays = overlays_to_add
	overlays_standing[BODY_LAYER] = compiled_image
	if(update_icons)
		update_icons()

//HAIR OVERLAY
/mob/living/human/proc/update_hair(var/update_icons=1)
	overlays_standing[HAIR_LAYER] = null
	var/obj/item/organ/external/head/head_organ = get_organ(BP_HEAD)
	if(head_organ && !head_organ.is_stump())
		if(!((head && (head.flags_inv & BLOCKHAIR)) || (wear_mask && (wear_mask.flags_inv & BLOCKHAIR))))
			var/image/hairimage = image(null)
			hairimage.overlays += list(head_organ.get_facial_hair_image(),head_organ.get_head_hair_image())
			overlays_standing[HAIR_LAYER] = hairimage
	if(update_icons)
		update_icons()

/* --------------------------------------- */
//For legacy support.
/mob/living/human/regenerate_icons()
	..()
	if(transforming)		return

	update_body(0)
	update_hair(0)
	update_inv_w_uniform(0)
	update_inv_wear_id(0)
	update_inv_gloves(0)
	update_inv_glasses(0)
	update_inv_ears(0)
	update_inv_shoes(0)
	update_inv_s_store(0)
	update_inv_wear_mask(0)
	update_inv_head(0)
	update_inv_belt(0)
	update_inv_back(0)
	update_inv_wear_suit(0)
	update_inv_r_hand(0)
	update_inv_l_hand(0)
	update_inv_handcuffed(0)
	update_inv_legcuffed(0)
	update_inv_pockets(0)
	update_fire(0)
	update_surgery(0)
	UpdateDamageIcon()
	update_icons()
	//Hud Stuff
	update_hud()

/* --------------------------------------- */
//vvvvvv UPDATE_INV PROCS vvvvvv

/mob/living/human/update_inv_w_uniform(var/update_icons=1)
	if(w_uniform && istype(w_uniform, /obj/item/clothing/under) )
		w_uniform.screen_loc = ui_iclothing

		//determine the icon to use
		var/under_icon
		if(w_uniform.icon_override)
			under_icon = w_uniform.icon_override
		else if(w_uniform.sprite_sheets && w_uniform.sprite_sheets[species.get_bodytype()])
			under_icon = w_uniform.sprite_sheets[species.get_bodytype()]
		else if(w_uniform.item_icons && w_uniform.item_icons[slot_w_uniform_str])
			under_icon = w_uniform.item_icons[slot_w_uniform_str]
		else
			under_icon = INV_W_UNIFORM_DEF_ICON

		//determine state to use
		var/under_state
		if(w_uniform.item_state_slots && w_uniform.item_state_slots[slot_w_uniform_str])
			under_state = w_uniform.item_state_slots[slot_w_uniform_str]
		else if(w_uniform.item_state)
			under_state = w_uniform.item_state
		else
			under_state = w_uniform.icon_state

		//need to append _s to the icon state for legacy compatibility
		var/image/standing = image(icon = under_icon, icon_state = "[under_state]_s")
		standing.color = w_uniform.color

		//apply blood overlay
		if(w_uniform.blood_traces)
			var/image/bloodsies	= image(icon = species.blood_mask, icon_state = "uniformblood")
			bloodsies.color		= w_uniform.blood_color
			standing.overlays	+= bloodsies

		//accessories
		var/obj/item/clothing/under/under = w_uniform
		if(under.accessories.len)
			for(var/obj/item/clothing/accessory/A in under.accessories)
				standing.overlays |= A.get_mob_overlay()

		overlays_standing[UNIFORM_LAYER]	= standing
	else
		overlays_standing[UNIFORM_LAYER]	= null

	if(update_icons)
		update_icons()

/mob/living/human/update_inv_wear_id(var/update_icons=1)
	if(wear_id)
		wear_id.screen_loc = ui_id
		var/image/standing
		if(wear_id.icon_override)
			standing = image("icon" = wear_id.icon_override, "icon_state" = "[wear_id.icon_state]")
		else if(wear_id.sprite_sheets && wear_id.sprite_sheets[species.get_bodytype()])
			standing = image("icon" = wear_id.sprite_sheets[species.get_bodytype()], "icon_state" = "[wear_id.icon_state]")
		else
			if(wear_id.icon_state in icon_states('icons/mob/clothing/id_cards.dmi'))
				standing = image("icon" = 'icons/mob/clothing/id_cards.dmi', "icon_state" = wear_id.icon_state)
			else
				standing = image("icon" = 'icons/mob/clothing/id_cards.dmi', "icon_state" = "id")
		overlays_standing[ID_LAYER] = standing
	else
		overlays_standing[ID_LAYER] = null

	BITSET(hud_updateflag, ID_HUD)
	BITSET(hud_updateflag, WANTED_HUD)

	if(update_icons)
		update_icons()

/mob/living/human/update_inv_gloves(var/update_icons=1)
	if(gloves)
		var/t_state = gloves.item_state
		if(!t_state)	t_state = gloves.icon_state

		var/image/standing
		if(gloves.icon_override)
			standing = image("icon" = gloves.icon_override, "icon_state" = "[t_state]")
		else if(gloves.sprite_sheets && gloves.sprite_sheets[species.get_bodytype()])
			standing = image("icon" = gloves.sprite_sheets[species.get_bodytype()], "icon_state" = "[t_state]")
		else if(gloves.item_icons && gloves.item_icons[slot_gloves_str])
			standing = image("icon" = gloves.item_icons[slot_gloves_str], "icon_state" = "[t_state]")
		else
			standing = image("icon" = 'icons/mob/clothing/hands.dmi', "icon_state" = "[t_state]")

		if(gloves.blood_traces)
			var/image/bloodsies	= image("icon" = species.blood_mask, "icon_state" = "bloodyhands")
			bloodsies.color = gloves.blood_color
			standing.overlays	+= bloodsies
		gloves.screen_loc = ui_gloves
		standing.color = gloves.color
		overlays_standing[GLOVES_LAYER]	= standing
	else
		if(blood_traces)
			var/image/bloodsies	= image("icon" = species.blood_mask, "icon_state" = "bloodyhands")
			bloodsies.color = hand_blood_color
			overlays_standing[GLOVES_LAYER]	= bloodsies
		else
			overlays_standing[GLOVES_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/human/update_inv_glasses(var/update_icons=1)
	if(glasses)

		if(glasses.icon_override)
			overlays_standing[GLASSES_LAYER] = image("icon" = glasses.icon_override, "icon_state" = "[glasses.icon_state]")
		else if(glasses.sprite_sheets && glasses.sprite_sheets[species.get_bodytype()])
			overlays_standing[GLASSES_LAYER]= image("icon" = glasses.sprite_sheets[species.get_bodytype()], "icon_state" = "[glasses.icon_state]")
		else
			overlays_standing[GLASSES_LAYER]= image("icon" = 'icons/mob/clothing/eyes.dmi', "icon_state" = "[glasses.icon_state]")

	else
		overlays_standing[GLASSES_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/human/update_inv_ears(var/update_icons=1)
	overlays_standing[EARS_LAYER] = null
	if( (head && (head.flags_inv & (BLOCKHAIR | BLOCKHEADHAIR))) || (wear_mask && (wear_mask.flags_inv & (BLOCKHAIR | BLOCKHEADHAIR))))
		if(update_icons)   update_icons()
		return

	if(l_ear || r_ear)
		if(l_ear)

			var/t_type = l_ear.icon_state
			if(l_ear.icon_override)
				t_type = "[t_type]_l"
				overlays_standing[EARS_LAYER] = image("icon" = l_ear.icon_override, "icon_state" = "[t_type]")
			else if(l_ear.sprite_sheets && l_ear.sprite_sheets[species.get_bodytype()])
				t_type = "[t_type]_l"
				overlays_standing[EARS_LAYER] = image("icon" = l_ear.sprite_sheets[species.get_bodytype()], "icon_state" = "[t_type]")
			else
				overlays_standing[EARS_LAYER] = image("icon" = 'icons/mob/clothing/ears.dmi', "icon_state" = "[t_type]")

		if(r_ear)

			var/t_type = r_ear.icon_state
			if(r_ear.icon_override)
				t_type = "[t_type]_r"
				overlays_standing[EARS_LAYER] = image("icon" = r_ear.icon_override, "icon_state" = "[t_type]")
			else if(r_ear.sprite_sheets && r_ear.sprite_sheets[species.get_bodytype()])
				t_type = "[t_type]_r"
				overlays_standing[EARS_LAYER] = image("icon" = r_ear.sprite_sheets[species.get_bodytype()], "icon_state" = "[t_type]")
			else
				overlays_standing[EARS_LAYER] = image("icon" = 'icons/mob/clothing/ears.dmi', "icon_state" = "[t_type]")

	else
		overlays_standing[EARS_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/human/update_inv_shoes(var/update_icons=1)
	if(shoes && !(wear_suit && wear_suit.flags_inv & HIDESHOES))

		var/image/standing
		if(shoes.icon_override)
			standing = image("icon" = shoes.icon_override, "icon_state" = "[shoes.icon_state]")
		else if(shoes.sprite_sheets && shoes.sprite_sheets[species.get_bodytype()])
			standing = image("icon" = shoes.sprite_sheets[species.get_bodytype()], "icon_state" = "[shoes.icon_state]")
		else
			standing = image("icon" = 'icons/mob/clothing/feet.dmi', "icon_state" = "[shoes.icon_state]")

		if(shoes.blood_traces)
			var/image/bloodsies = image("icon" = species.blood_mask, "icon_state" = "shoeblood")
			bloodsies.color = shoes.blood_color
			standing.overlays += bloodsies
		standing.color = shoes.color
		overlays_standing[SHOES_LAYER] = standing
	else
		if(feet_blood_traces)
			var/image/bloodsies = image("icon" = species.blood_mask, "icon_state" = "shoeblood")
			bloodsies.color = feet_blood_color
			overlays_standing[SHOES_LAYER] = bloodsies
		else
			overlays_standing[SHOES_LAYER] = null
	if(update_icons)   update_icons()

/mob/living/human/update_inv_s_store(var/update_icons=1)
	if(s_store)
		var/t_state = s_store.item_state
		if(!t_state)	t_state = s_store.icon_state
		overlays_standing[SUIT_STORE_LAYER]	= image("icon" = 'icons/mob/clothing/belt.dmi', "icon_state" = "[t_state]")
		s_store.screen_loc = ui_sstore1		//TODO
	else
		overlays_standing[SUIT_STORE_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/human/update_inv_head(var/update_icons=1)
	if(head)
		head.screen_loc = ui_head		//TODO

		//Determine the icon to use
		var/t_icon
		if(head.icon_override)
			t_icon = head.icon_override
		else if(head.sprite_sheets && head.sprite_sheets[species.get_bodytype()])
			t_icon = head.sprite_sheets[species.get_bodytype()]

		else if(head.item_icons && (slot_head_str in head.item_icons))
			t_icon = head.item_icons[slot_head_str]
		else
			t_icon = INV_HEAD_DEF_ICON

		//Determine the state to use
		var/t_state
		if(istype(head, /obj/item/paper))
			/* I don't like this, but bandaid to fix half the hats in the game
			   being completely broken without re-breaking paper hats */
			t_state = "paper"
		else
			if(head.item_state_slots && head.item_state_slots[slot_head_str])
				t_state = head.item_state_slots[slot_head_str]
			else if(head.item_state)
				t_state = head.item_state
			else
				t_state = head.icon_state

		//Create the image
		var/image/standing = image(icon = t_icon, icon_state = t_state)

		if(head.blood_traces)
			var/image/bloodsies = image("icon" = species.blood_mask, "icon_state" = "helmetblood")
			bloodsies.color = head.blood_color
			standing.overlays	+= bloodsies

		if(istype(head,/obj/item/clothing/head))
			var/obj/item/clothing/head/hat = head
			var/cache_key = "[hat.light_overlay]_[species.get_bodytype()]"
			if(hat.on && light_overlay_cache[cache_key])
				standing.overlays |= light_overlay_cache[cache_key]

		standing.color = head.color
		overlays_standing[HEAD_LAYER] = standing

	else
		overlays_standing[HEAD_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/human/update_inv_belt(var/update_icons=1)
	if(belt)
		belt.screen_loc = ui_belt	//TODO
		var/t_state = belt.item_state
		if(!t_state)	t_state = belt.icon_state
		var/image/standing	= image("icon_state" = "[t_state]")

		if(belt.icon_override)
			standing.icon = belt.icon_override
		else if(belt.sprite_sheets && belt.sprite_sheets[species.get_bodytype()])
			standing.icon = belt.sprite_sheets[species.get_bodytype()]
		else if(belt.item_icons && belt.item_icons[slot_belt_str])
			standing.icon = belt.item_icons[slot_belt_str]
		else
			standing.icon = 'icons/mob/clothing/belt.dmi'

		var/belt_layer = BELT_LAYER
		if(istype(belt, /obj/item/storage/belt))
			var/obj/item/storage/belt/ubelt = belt
			if(ubelt.show_above_suit)
				overlays_standing[BELT_LAYER] = null
				belt_layer = BELT_LAYER_ALT
			else
				overlays_standing[BELT_LAYER_ALT] = null
			if(belt.contents.len)
				for(var/obj/item/i in belt.contents)
					var/i_state = i.item_state
					if(!i_state) i_state = i.icon_state
					standing.overlays	+= image("icon" = 'icons/mob/clothing/belt.dmi', "icon_state" = "[i_state]")

		standing.color = belt.color

		overlays_standing[belt_layer] = standing
	else
		overlays_standing[BELT_LAYER] = null
		overlays_standing[BELT_LAYER_ALT] = null
	if(update_icons)   update_icons()


/mob/living/human/update_inv_wear_suit(var/update_icons=1)

	if( wear_suit && istype(wear_suit, /obj/item/) )
		wear_suit.screen_loc = ui_oclothing

		var/image/standing

		var/t_icon = INV_SUIT_DEF_ICON
		if(wear_suit.icon_override)
			t_icon = wear_suit.icon_override
		else if(wear_suit.sprite_sheets && wear_suit.sprite_sheets[species.get_bodytype()])
			t_icon = wear_suit.sprite_sheets[species.name]
		else if(wear_suit.item_icons && wear_suit.item_icons[slot_wear_suit_str])
			t_icon = wear_suit.item_icons[slot_wear_suit_str]

		standing = image("icon" = t_icon, "icon_state" = "[wear_suit.icon_state]")
		standing.color = wear_suit.color

		if(wear_suit.blood_traces)
			var/obj/item/clothing/suit/S = wear_suit
			if(istype(S)) //You can put non-suits in your suit slot (diona nymphs etc).
				var/image/bloodsies = image("icon" = species.blood_mask, "icon_state" = "[S.blood_overlay_type]blood")
				bloodsies.color = wear_suit.blood_color
				standing.overlays	+= bloodsies

		// Accessories - copied from uniform, BOILERPLATE because fuck this system.
		var/obj/item/clothing/suit/suit = wear_suit
		if(istype(suit) && suit.accessories.len)
			for(var/obj/item/clothing/accessory/A in suit.accessories)
				standing.overlays |= A.get_mob_overlay()

		overlays_standing[SUIT_LAYER]	= standing
	else
		overlays_standing[SUIT_LAYER]	= null
		update_inv_shoes(0)

	if(update_icons)   update_icons()

/mob/living/human/update_inv_pockets(var/update_icons=1)
	if(l_store)			l_store.screen_loc = ui_storage1	//TODO
	if(r_store)			r_store.screen_loc = ui_storage2	//TODO
	if(update_icons)	update_icons()

/mob/living/human/update_inv_wear_mask(var/update_icons=1)
	if( wear_mask && (istype(wear_mask, /obj/item/clothing/mask) || istype(wear_mask, /obj/item/jewelry) || istype(wear_mask, /obj/item/clothing/accessory)) && !(head && head.flags_inv & HIDEMASK))
		wear_mask.screen_loc = ui_mask	//TODO

		var/image/standing
		if(wear_mask.icon_override)
			standing = image("icon" = wear_mask.icon_override, "icon_state" = "[wear_mask.icon_state]")
		else if(wear_mask.sprite_sheets && wear_mask.sprite_sheets[species.get_bodytype()])
			standing = image("icon" = wear_mask.sprite_sheets[species.get_bodytype()], "icon_state" = "[wear_mask.icon_state]")
		else if(wear_mask.item_icons && wear_mask.item_icons[slot_wear_mask_str])
			standing = image("icon" = wear_mask.item_icons[slot_wear_mask_str], "icon_state" = "[wear_mask.icon_state]")
		else
			standing = image("icon" = 'icons/mob/clothing/mask.dmi', "icon_state" = "[wear_mask.icon_state]")
		standing.color = wear_mask.color

		if(wear_mask.blood_traces)
			var/image/bloodsies = image("icon" = species.blood_mask, "icon_state" = "maskblood")
			bloodsies.color = wear_mask.blood_color
			standing.overlays	+= bloodsies
		overlays_standing[FACEMASK_LAYER]	= standing
	else
		overlays_standing[FACEMASK_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/human/update_inv_back(var/update_icons=1)
	if(back)
		back.screen_loc = ui_back	//TODO

		//determine the icon to use
		var/overlay_icon
		if(back.icon_override)
			overlay_icon = back.icon_override
		else if(istype(back, /obj/item/rig))
			//If this is a rig and a mob_icon is set, it will take species into account in the rig update_icon() proc.
			var/obj/item/rig/rig = back
			overlay_icon = rig.mob_icon
		else if(back.sprite_sheets && back.sprite_sheets[species.get_bodytype()])
			overlay_icon = back.sprite_sheets[species.get_bodytype()]
		else if(back.item_icons && (slot_back_str in back.item_icons))
			overlay_icon = back.item_icons[slot_back_str]
		else
			overlay_icon = INV_BACK_DEF_ICON

		//determine state to use
		var/overlay_state
		if(back.item_state_slots && back.item_state_slots[slot_back_str])
			overlay_state = back.item_state_slots[slot_back_str]
		else if(back.item_state)
			overlay_state = back.item_state
		else
			overlay_state = back.icon_state

		//apply color
		var/image/standing = image(icon = overlay_icon, icon_state = overlay_state)
		standing.color = back.color

		//create the image
		overlays_standing[BACK_LAYER] = standing
	else
		overlays_standing[BACK_LAYER] = null

	if(update_icons)
		update_icons()


/mob/living/human/update_hud()	//TODO: do away with this if possible
	if(client)
		client.screen |= contents
		if(hud_used)
			hud_used.hidden_inventory_update() 	//Updates the screenloc of the items on the 'other' inventory bar


/mob/living/human/update_inv_handcuffed(var/update_icons=1)
	if(handcuffed)
		drop_r_hand()
		drop_l_hand()
		stop_pulling()	//TODO: should be handled elsewhere

		var/image/standing
		if(handcuffed.icon_override)
			standing = image("icon" = handcuffed.icon_override, "icon_state" = "handcuff1")
		else if(handcuffed.sprite_sheets && handcuffed.sprite_sheets[species.get_bodytype()])
			standing = image("icon" = handcuffed.sprite_sheets[species.get_bodytype()], "icon_state" = "handcuff1")
		else
			standing = image("icon" = 'icons/mob/creatures/cuffed.dmi', "icon_state" = "handcuff1")
		overlays_standing[HANDCUFF_LAYER] = standing

	else
		overlays_standing[HANDCUFF_LAYER]	= null
	if(update_icons)   update_icons()

/mob/living/human/update_inv_legcuffed(var/update_icons=1)
	if(legcuffed)

		var/image/standing
		if(legcuffed.icon_override)
			standing = image("icon" = legcuffed.icon_override, "icon_state" = "legcuff1")
		else if(legcuffed.sprite_sheets && legcuffed.sprite_sheets[species.get_bodytype()])
			standing = image("icon" = legcuffed.sprite_sheets[species.get_bodytype()], "icon_state" = "legcuff1")
		else
			standing = image("icon" = 'icons/mob/creatures/cuffed.dmi', "icon_state" = "legcuff1")
		overlays_standing[LEGCUFF_LAYER] = standing

		if(src.m_intent != "walk")
			src.m_intent = "walk"
			if(src.hud_used && src.hud_used.move_intent)
				src.hud_used.move_intent.icon_state = "walking"

	else
		overlays_standing[LEGCUFF_LAYER]	= null
	if(update_icons)   update_icons()


/mob/living/human/update_inv_r_hand(var/update_icons=1)
	if(r_hand)
		r_hand.screen_loc = ui_rhand	//TODO

		//determine icon state to use
		var/t_state
		if(r_hand.item_state_slots && r_hand.item_state_slots[slot_r_hand_str])
			t_state = r_hand.item_state_slots[slot_r_hand_str]
		else if(r_hand.item_state)
			t_state = r_hand.item_state
		else
			t_state = r_hand.icon_state

		//determine icon to use
		var/t_icon
		if(r_hand.item_icons && (slot_r_hand_str in r_hand.item_icons))
			t_icon = r_hand.item_icons[slot_r_hand_str]
		else if(r_hand.icon_override)
			t_state += "_r"
			t_icon = r_hand.icon_override
		else
			t_icon = INV_R_HAND_DEF_ICON

		//apply color
		var/image/standing = image(icon = t_icon, icon_state = t_state)
		standing.color = r_hand.color

		overlays_standing[R_HAND_LAYER] = standing

		if (handcuffed) drop_r_hand() //this should be moved out of icon code
	else
		overlays_standing[R_HAND_LAYER] = null

	if(update_icons) update_icons()


/mob/living/human/update_inv_l_hand(var/update_icons=1)
	if(l_hand)
		l_hand.screen_loc = ui_lhand	//TODO

		//determine icon state to use
		var/t_state
		if(l_hand.item_state_slots && l_hand.item_state_slots[slot_l_hand_str])
			t_state = l_hand.item_state_slots[slot_l_hand_str]
		else if(l_hand.item_state)
			t_state = l_hand.item_state
		else
			t_state = l_hand.icon_state

		//determine icon to use
		var/t_icon
		if(l_hand.item_icons && (slot_l_hand_str in l_hand.item_icons))
			t_icon = l_hand.item_icons[slot_l_hand_str]
		else if(l_hand.icon_override)
			t_state += "_l"
			t_icon = l_hand.icon_override
		else
			t_icon = INV_L_HAND_DEF_ICON

		//apply color
		var/image/standing = image(icon = t_icon, icon_state = t_state)
		standing.color = l_hand.color

		overlays_standing[L_HAND_LAYER] = standing

		if (handcuffed) drop_l_hand() //This probably should not be here
	else
		overlays_standing[L_HAND_LAYER] = null

	if(update_icons) update_icons()

/mob/living/human/update_fire(var/update_icons=1)
	overlays_standing[FIRE_LAYER] = null
	if(on_fire)
		overlays_standing[FIRE_LAYER] = image("icon"='icons/mob/creatures/OnFire.dmi', "icon_state"="Standing", "layer"=FIRE_LAYER)

	if(update_icons)   update_icons()

/mob/living/human/proc/update_surgery(var/update_icons=1)
	overlays_standing[SURGERY_LEVEL] = null
	var/image/total = new
	for(var/obj/item/organ/external/E in organs)
		if(E.is_open())
			var/image/I = image("icon"='icons/mob/creatures/surgery.dmi', "icon_state"="[E.name][round(E.is_open())]", "layer"=-SURGERY_LEVEL)
			total.overlays += I
	overlays_standing[SURGERY_LEVEL] = total
	if(update_icons)   update_icons()

//Human Overlays Indexes/////////
#undef DAMAGE_LAYER
#undef SURGERY_LEVEL
#undef UNIFORM_LAYER
#undef ID_LAYER
#undef SHOES_LAYER
#undef GLOVES_LAYER
#undef EARS_LAYER
#undef SUIT_LAYER
#undef TAIL_LAYER
#undef GLASSES_LAYER
#undef FACEMASK_LAYER
#undef BELT_LAYER
#undef SUIT_STORE_LAYER
#undef BACK_LAYER
#undef HAIR_LAYER
#undef HEAD_LAYER
#undef COLLAR_LAYER
#undef HANDCUFF_LAYER
#undef LEGCUFF_LAYER
#undef L_HAND_LAYER
#undef R_HAND_LAYER
#undef TARGETED_LAYER
#undef FIRE_LAYER
#undef TOTAL_LAYERS
