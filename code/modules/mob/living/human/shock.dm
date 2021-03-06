/mob/living/human/var/shock_stage = 0

// proc to find out in how much pain the mob is at the moment
/mob/living/human/proc/updateshock()
	if (!can_feel_pain())
		src.traumatic_shock = 0
		return 0

	src.traumatic_shock = 			\
	1	* src.getOxyLoss() + 		\
	0.7	* src.getToxLoss() + 		\
	1.5	* src.getFireLoss() + 		\
	1.2	* src.getBruteLoss() + 		\
	2	* src.subdual + 			\
	-1	* src.analgesic

	if(src.slurring)
		src.traumatic_shock -= 20

	// broken or ripped off organs will add quite a bit of pain
	if(istype(src,/mob/living/human))
		var/mob/living/human/M = src
		for(var/obj/item/organ/external/organ in M.organs)
			if(organ && (organ.is_broken() || organ.is_open()))
				src.traumatic_shock += 30

	if(src.traumatic_shock < 0)
		src.traumatic_shock = 0

	return src.traumatic_shock

/mob/living/human/proc/handle_shock()
	updateshock()
