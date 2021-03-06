/turf/simulated/wall
	name = "wall"
	desc = "A huge chunk of metal used to seperate rooms."
	icon = 'icons/turf/wall_masks.dmi'
	icon_state = "generic"
	opacity = 1
	density = 1

	var/damage = 0
	var/damage_overlay = 0
	var/global/damage_overlays[16]
	var/active
	var/can_open = 0
	var/material/material
	var/material/reinf_material
	var/last_state
	var/construction_stage
	var/hitsound = 'sound/weapons/Genhit.ogg'
	var/list/wall_connections = list("0", "0", "0", "0")

// Walls always hide the stuff below them.
/turf/simulated/wall/levelupdate()
	for(var/obj/O in src)
		O.hide(1)

/turf/simulated/wall/New(var/newloc, var/materialtype, var/rmaterialtype)
	..(newloc)
	icon_state = "blank"
	if(!materialtype)
		materialtype = DEFAULT_WALL_MATERIAL
	material = get_material_by_name(materialtype)
	if(!isnull(rmaterialtype))
		reinf_material = get_material_by_name(rmaterialtype)
	update_material()
	hitsound = material.hitsound
	processing_turfs |= src

/turf/simulated/wall/Destroy()
	processing_turfs -= src
	dismantle_wall(null,null,1,0)
	return ..()

/turf/simulated/wall/process()
	// Calling parent will kill processing
	if(!radiate())
		return PROCESS_KILL

/turf/simulated/wall/bullet_act(var/obj/item/projectile/Proj)
	if(istype(Proj,/obj/item/projectile/beam))
		ignite()
	else if(istype(Proj,/obj/item/projectile/ion))
		ignite()

	var/proj_damage = Proj.get_structure_damage()

	//cap the amount of damage, so that things like emitters can't destroy walls in one hit.
	var/damage = min(proj_damage, 100)

	take_damage(damage)
	return

/turf/simulated/wall/hitby(AM as mob|obj, var/speed=THROWFORCE_SPEED_DIVISOR)
	..()
	if(ismob(AM))
		return

	var/tforce = AM:throwforce * (speed/THROWFORCE_SPEED_DIVISOR)
	if (tforce < 15)
		return

	take_damage(tforce)

/turf/simulated/wall/proc/clear_plants()
	for(var/obj/effect/plant/plant in range(src, 1))
		if(!plant.floor) //shrooms drop to the floor
			plant.floor = 1
			plant.update_icon()
			plant.pixel_x = 0
			plant.pixel_y = 0
		plant.update_neighbors()

/turf/simulated/wall/ChangeTurf(var/newtype)
	clear_plants()
	..(newtype)

//Appearance
/turf/simulated/wall/examine(mob/user)
	. = ..(user)

	if(!damage)
		user << "<span class='notice'>It looks fully intact.</span>"
	else
		var/dam = damage / material.integrity
		if(dam <= 0.3)
			user << "<span class='warning'>It looks slightly damaged.</span>"
		else if(dam <= 0.6)
			user << "<span class='warning'>It looks moderately damaged.</span>"
		else
			user << "<span class='danger'>It looks heavily damaged.</span>"

//Damage

/turf/simulated/wall/melt()

	if(!can_melt())
		return

	src.ChangeTurf(/turf/simulated/floor/plating)

	var/turf/simulated/floor/F = src
	if(!F)
		return
	F.burn_tile()
	F.icon_state = "wall_thermite"
	visible_message("<span class='danger'>\The [src] spontaneously combusts!.</span>") //!!OH SHIT!!
	return

/turf/simulated/wall/proc/take_damage(dam)
	if(dam)
		damage = max(0, damage + dam)
		update_damage()
	return

/turf/simulated/wall/proc/update_damage()
	var/cap = material.integrity
	if(reinf_material)
		cap += reinf_material.integrity

	if(damage >= cap)
		dismantle_wall()
	else
		update_icon()

	return

/turf/simulated/wall/proc/dismantle_wall(var/devastated, var/explode, var/no_product, var/change_turf=1, var/silent)

	if(!silent)
		playsound(src, 'sound/items/Welder.ogg', 100, 1)
	if(!no_product)
		if(reinf_material)
			reinf_material.place_dismantled_girder(src, reinf_material)
		else
			material.place_dismantled_girder(src)
		material.place_dismantled_product(src,devastated)

	clear_plants()
	material = get_material_by_path(/material/placeholder)
	reinf_material = null
	update_connections(1)

	if(change_turf)
		ChangeTurf(/turf/simulated/floor/plating)

/turf/simulated/wall/ex_act(severity)
	switch(severity)
		if(1.0)
			src.ChangeTurf(get_base_turf_by_area(src))
			return
		if(2.0)
			if(prob(75))
				take_damage(rand(100, 250))
			else
				dismantle_wall(1,1)
		if(3.0)
			take_damage(rand(0, 75))
		else
	return

/turf/simulated/wall/proc/can_melt()
	if(material.flags & MATERIAL_UNMELTABLE)
		return 0
	return 1

/turf/simulated/wall/proc/thermitemelt(mob/user as mob)
	if(!can_melt())
		return
	src.ChangeTurf(/turf/simulated/floor/plating)
	var/turf/simulated/floor/F = src
	F.burn_tile()
	F.icon_state = "wall_thermite"
	user << "<span class='warning'>The thermite starts melting through the wall.</span>"
	return

/turf/simulated/wall/proc/radiate()
	var/total_radiation = material.radioactivity + (reinf_material ? reinf_material.radioactivity / 2 : 0)
	if(!total_radiation)
		return

	for(var/mob/living/L in range(3,src))
		L.apply_effect(total_radiation, IRRADIATE,0)
	return total_radiation
