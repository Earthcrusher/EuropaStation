/datum/job/head
	title = "Colony Liaison"
	job_category = IS_HEAD
	total_positions = 1
	spawn_positions = 1
	supervisors = "Jovian authorities"
	req_admin_notify = 1
	minimal_access = list()
	selection_color = "#dddddd"
	access = list(access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels,
            access_teleporter, access_external_airlocks, access_atmospherics, access_emergency_storage, access_eva,
            access_heads, access_construction, access_sec_doors, access_medical, access_medical_equip, access_morgue,
			access_genetics, access_chemistry, access_virology, access_cmo, access_surgery, access_RC_announce,
			access_keycard_auth, access_psychiatrist)
	minimal_access = list(access_engine, access_engine_equip, access_tech_storage, access_maint_tunnels,
            access_teleporter, access_external_airlocks, access_atmospherics, access_emergency_storage, access_eva,
            access_heads, access_construction, access_sec_doors, access_medical, access_medical_equip, access_morgue,
			access_genetics, access_chemistry, access_virology, access_cmo, access_surgery, access_RC_announce,
			access_keycard_auth, access_psychiatrist)

/datum/job/head/equip(var/mob/living/human/H, skip_suit = 0, skip_hat = 0, skip_shoes = 0, var/alt_rank)
	if(!H)	return 0
	..(H) // Same as all the nobodies.
	//TODO: Access cards, documentation, any other specialist gear.

/datum/job/head/marshal
	title = "Marshal"
	idtype = /obj/item/card/id
	access = list(access_security, access_eva, access_sec_doors, access_brig, access_armory, access_forensics_lockers,
			access_morgue, access_maint_tunnels, access_all_personal_lockers, access_research, access_engine,
			access_mining, access_medical, access_construction, access_mailsorting, access_heads, access_hos,
			access_RC_announce, access_keycard_auth, access_gateway, access_external_airlocks)
	minimal_access = list(access_security, access_eva, access_sec_doors, access_brig, access_armory, access_forensics_lockers,
			access_morgue, access_maint_tunnels, access_all_personal_lockers, access_research, access_engine,
			access_mining, access_medical, access_construction, access_mailsorting, access_heads, access_hos,
			access_RC_announce, access_keycard_auth, access_gateway, access_external_airlocks)

/datum/job/head/coordinator
	title = "Corporate Contact Officer"
	selection_color = "#ffeeff"
	idtype = /obj/item/card/id
	access = list(access_rd, access_heads, access_tox, access_genetics, access_morgue,
			            access_tox_storage, access_teleporter, access_sec_doors, access_mining, access_mining_station,
			            access_research, access_robotics, access_xenobiology, access_ai_upload, access_tech_storage,
			            access_RC_announce, access_keycard_auth, access_tcomsat, access_gateway, access_xenoarch,
						access_maint_tunnels, access_mailsorting, access_cargo, access_cargo_bot, access_qm)
	minimal_access = list(access_rd, access_heads, access_tox, access_genetics, access_morgue,
			            access_tox_storage, access_teleporter, access_sec_doors, access_mining, access_mining_station,
			            access_research, access_robotics, access_xenobiology, access_ai_upload, access_tech_storage,
			            access_RC_announce, access_keycard_auth, access_tcomsat, access_gateway, access_xenoarch,
						access_maint_tunnels, access_mailsorting, access_cargo, access_cargo_bot, access_qm)
