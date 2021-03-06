
////////////////////////////////////////////////////////////////////////////////
/// (Mixing)Glass.
////////////////////////////////////////////////////////////////////////////////
/obj/item/reagent_containers/glass
	name = " "
	var/base_name = " "
	desc = " "
	icon = 'icons/obj/chemical.dmi'
	icon_state = "null"
	item_state = "null"
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,25,30,60)
	volume = 60
	w_class = 2
	flags = OPENCONTAINER
	unacidable = 1 //glass doesn't dissolve in acid

	var/label_text = ""

	var/list/can_be_placed_into = list(
		/obj/machinery/reagentgrinder,
		/obj/structure/table,
		/obj/structure/crate,
		/obj/item/storage,
		/obj/machinery/constructable_frame
		)

	initialize()
		..()
		base_name = name

	examine(var/mob/user)
		if(!..(user, 2))
			return
		if(reagents && reagents.reagent_list.len)
			user << "<span class='notice'>It contains [reagents.total_volume] units of liquid.</span>"
		else
			user << "<span class='notice'>It is empty.</span>"
		if(!is_open_container())
			user << "<span class='notice'>Airtight lid seals it completely.</span>"

	attack_self()
		..()
		if(is_open_container())
			usr << "<span class = 'notice'>You put the lid on \the [src].</span>"
			flags ^= OPENCONTAINER
		else
			usr << "<span class = 'notice'>You take the lid off \the [src].</span>"
			flags |= OPENCONTAINER
		update_icon()

	afterattack(var/obj/target, var/mob/user, var/flag)

		if(!is_open_container() || !flag)
			return

		for(var/type in can_be_placed_into)
			if(istype(target, type))
				return

		if(standard_splash_mob(user, target))
			return
		if(standard_dispenser_refill(user, target))
			return
		if(standard_pour_into(user, target))
			return

		if(reagents.total_volume)
			user << "<span class='notice'>You splash the solution onto [target].</span>"
			reagents.splash(target, reagents.total_volume)
			return

	attackby(obj/item/W as obj, mob/user as mob)
		if(istype(W, /obj/item/pen))
			var/tmp_label = sanitizeSafe(input(user, "Enter a label for [name]", "Label", label_text), MAX_NAME_LEN)
			if(length(tmp_label) > 10)
				user << "<span class='notice'>The label can be at most 10 characters long.</span>"
			else
				user << "<span class='notice'>You set the label to \"[tmp_label]\".</span>"
				label_text = tmp_label
				update_name_label()

	proc/update_name_label()
		if(label_text == "")
			name = base_name
		else
			name = "[base_name] ([label_text])"

/obj/item/reagent_containers/glass/beaker
	name = "beaker"
	desc = "A beaker."
	icon = 'icons/obj/chemical.dmi'
	icon_state = "beaker"
	item_state = "beaker"
	matter = list("glass" = 500)

	initialize()
		..()
		desc += " Can hold up to [volume] units."

	on_reagent_change()
		update_icon()

	pickup(mob/user)
		..()
		update_icon()

	dropped(mob/user)
		..()
		update_icon()

	attack_hand()
		..()
		update_icon()

	update_icon()
		overlays.Cut()

		if(reagents.total_volume)
			var/image/filling = image('icons/obj/reagentfillings.dmi', src, "[icon_state]10")

			var/percent = round((reagents.total_volume / volume) * 100)
			switch(percent)
				if(0 to 9)		filling.icon_state = "[icon_state]-10"
				if(10 to 24) 	filling.icon_state = "[icon_state]10"
				if(25 to 49)	filling.icon_state = "[icon_state]25"
				if(50 to 74)	filling.icon_state = "[icon_state]50"
				if(75 to 79)	filling.icon_state = "[icon_state]75"
				if(80 to 90)	filling.icon_state = "[icon_state]80"
				if(91 to INFINITY)	filling.icon_state = "[icon_state]100"

			filling.color = reagents.get_color()
			overlays += filling

		if (!is_open_container())
			var/image/lid = image(icon, src, "lid_[initial(icon_state)]")
			overlays += lid

/obj/item/reagent_containers/glass/beaker/vial
	name = "vial"
	desc = "A small glass vial."
	icon_state = "vial"
	matter = list("glass" = 250)
	volume = 30
	amount_per_transfer_from_this = 10
	possible_transfer_amounts = list(5,10,15,25)
	flags = OPENCONTAINER

/obj/item/reagent_containers/glass/bucket
	desc = "It's a bucket."
	name = "bucket"
	icon = 'icons/obj/janitor.dmi'
	icon_state = "bucket"
	item_state = "bucket"
	matter = list(DEFAULT_WALL_MATERIAL = 200)
	w_class = 3.0
	amount_per_transfer_from_this = 20
	possible_transfer_amounts = list(10,20,30,60,120)
	volume = 120
	flags = OPENCONTAINER
	unacidable = 0

/obj/item/reagent_containers/glass/bucket/update_icon()
	overlays.Cut()
	if (!is_open_container())
		var/image/lid = image(icon, src, "lid_[initial(icon_state)]")
		overlays += lid
