/*
 * Defines the helmets, gloves and shoes for rigs.
 */

/obj/item/clothing/head/voidsuit/rig
	name = "helmet"
	item_flags = THICKMATERIAL
	flags_inv = 		 HIDEEARS|HIDEEYES|HIDEFACE|BLOCKHAIR
	body_parts_covered = HEAD|FACE|EYES
	heat_protection =    HEAD|FACE|EYES
	cold_protection =    HEAD|FACE|EYES
	light_power = 4
	species_restricted = null

/obj/item/clothing/head/voidsuit/rig/proc/prevent_track()
	return 0

/obj/item/clothing/gloves/rig
	name = "gauntlets"
	item_flags = THICKMATERIAL
	body_parts_covered = HANDS
	heat_protection =    HANDS
	cold_protection =    HANDS
	species_restricted = null
	gender = PLURAL

/obj/item/clothing/gloves/rig/do_touch(var/atom/A, var/proximity)
	if(!A || !proximity)
		return 0
	var/mob/living/human/H = loc
	if(!istype(H) || !H.back)
		return 0
	var/obj/item/rig/suit = H.back
	if(!suit || !istype(suit) || !suit.installed_modules.len)
		return 0
	for(var/obj/item/rig_module/module in suit.installed_modules)
		if(module.active && module.activates_on_touch)
			if(module.engage(A))
				return 1
	return 0

/obj/item/clothing/shoes/rig
	name = "boots"
	body_parts_covered = FEET
	cold_protection = FEET
	heat_protection = FEET
	species_restricted = null
	gender = PLURAL

/obj/item/clothing/suit/voidsuit/rig
	name = "chestpiece"
	allowed = list(/obj/item/flashlight,/obj/item/tank)
	body_parts_covered = UPPER_TORSO|LOWER_TORSO|LEGS|ARMS
	heat_protection =    UPPER_TORSO|LOWER_TORSO|LEGS|ARMS
	cold_protection =    UPPER_TORSO|LOWER_TORSO|LEGS|ARMS
	flags_inv =          HIDEJUMPSUIT|HIDETAIL
	item_flags =              STOPPRESSUREDAMAGE | THICKMATERIAL | AIRTIGHT
	slowdown = 0
	//will reach 10 breach damage after 25 laser carbine blasts, 3 revolver hits, or ~1 PTR hit. Completely immune to smg or sts hits.
	breach_threshold = 38
	resilience = 0.2
	can_breach = 1
	supporting_limbs = list()
