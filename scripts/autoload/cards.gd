extends Node


const data = {
	# fire creatures
	"fire_elemental":{
		"type":"creature",
		"temperature":2,
		"level":2,
		"rules":[],
		"animation":"fire_blast",
		"image":preload("res://images/cards/fire_creature.jpg")
	},
	"greater_fire_elemental":{
		"type":"creature",
		"temperature":3,
		"level":3,
		"rules":[],
		"animation":"fire_blast",
		"image":preload("res://images/cards/fire_creature.jpg")
	},
	"lava_elemental":{
		"type":"creature",
		"temperature":4,
		"level":5,
		"rules":[],
		"animation":"fire_blast",
		"image":preload("res://images/cards/Magma_Spawn_by_Katarzyna_Zalecka_and_Gabriel_Verdon.jpg")
	},
	"fire_avatar":{
		"type":"creature",
		"temperature":4,
		"level":6,
		"rules":["heat_aura-1"],
		"on_play":"inc_ally_temp-1",
		"on_ally_creature_spawn":"inc_temp-1",
		"on_removed":"dec_ally_temp-1",
		"animation":"fire_blast",
		"image":preload("res://images/cards/DivineGuardian.jpg")
	},
	
	# fire spells
	"fire_blade":{
		"type":"spell",
		"temperature":1,
		"level":2,
		"rules":["inc_ally_temp-1"],
		"on_play":"inc_temp-1",
		"target":"creature-ally",
		"animation":"fire_circle",
		"image":preload("res://images/cards/fire_blade.jpg")
	},
	"fire_ball":{
		"type":"spell",
		"temperature":3,
		"level":3,
		"rules":["kill_cold-3"],
		"on_play":"kill_cold-3",
		"target":"creature",
		"animation":"fire_ball",
		"image":preload("res://images/cards/fire_blade.jpg")
	},
	"blaze":{
		"type":"spell",
		"temperature":2,
		"level":3,
		"rules":["inc_temp-2"],
		"on_play":"inc_temp-2",
		"target":"creature",
		"animation":"fire_circle",
		"image":preload("res://images/cards/fire_blade.jpg")
	},
	"explosion":{
		"type":"spell",
		"temperature":0,
		"level":4,
		"rules":["explosion"],
		"on_play":"explosion",
		"target":"creature-ally",
		"animation":"explosion",
		"image":preload("res://images/cards/fire_blade.jpg")
	},
	
	# ice creatures
	"water_elemental":{
		"type":"creature",
		"temperature":-2,
		"level":2,
		"rules":[],
		"animation":"ice_blast",
		"image":preload("res://images/cards/welcome_to_air_OMGWTF_by_shiroikuro.jpg")
	},
	"greater_water_elemental":{
		"type":"creature",
		"temperature":-3,
		"level":3,
		"rules":[],
		"animation":"ice_blast",
		"image":preload("res://images/cards/ice_creature.jpg")
	},
	"ice_elemental":{
		"type":"creature",
		"temperature":-4,
		"level":4,
		"rules":["fire_armor-2"],
		"on_new_turn":"fire_armor-2",
		"animation":"ice_blast",
		"image":preload("res://images/cards/ice_creature.jpg")
	},
	"ice_avatar":{
		"type":"creature",
		"temperature":-4,
		"level":6,
		"rules":["ice_armor-2"],
		"on_new_turn":"ice_armor-2",
		"animation":"ice_blast",
		"image":preload("res://images/cards/ice_creature.jpg")
	},
	
	# ice spells
	"chill":{
		"type":"spell",
		"temperature":-1,
		"level":2,
		"rules":["dec_temp-1"],
		"on_play":"dec_temp-1",
		"target":"creature",
		"animation":"ice_circle",
		"image":preload("res://images/cards/ice_spell.jpg")
	},
	"hailstorm":{
		"type":"spell",
		"temperature":-2,
		"level":4,
		"rules":["kill_all_hot-2"],
		"on_play":"kill_all_hot-2",
		"animation":"hailstorm",
		"image":preload("res://images/cards/ice_spell.jpg")
	},
	"flash_flood":{
		"type":"spell",
		"temperature":0,
		"level":5,
		"rules":["move_to_hand"],
		"on_play":"move_to_hand",
		"target":"creature",
		"animation":"ice_circle",
		"image":preload("res://images/cards/ice_spell.jpg")
	},
	"equalize":{
		"type":"spell",
		"temperature":0,
		"level":3,
		"rules":["neutralize_temp-2"],
		"on_play":"neutralize_temp-2",
		"target":"creature",
		"animation":"neutralize",
		"image":preload("res://images/cards/spell_neutral.jpg")
	},
	
	# neutral spells
	"draw":{
		"type":"spell",
		"temperature":0,
		"level":3,
		"rules":["draw-3"],
		"on_play":"draw-3",
		"animation":"ice_circle",
		"image":preload("res://images/cards/spell_neutral.jpg")
	},
	"inversion":{
		"type":"spell",
		"temperature":0,
		"level":3,
		"rules":["invert_temp"],
		"on_play":"invert_temp",
		"target":"creature",
		"animation":"neutralize",
		"image":preload("res://images/cards/spell_neutral.jpg")
	}
}
const COLOR_COLD = Color(0.25,0.5,1.0)
const COLOR_HOT = Color(1.0,0.4,0.2)
const COLOR_CREATURE = Color(0.3,0.8,0.2)
const COLOR_SPELL = Color(0.8,0.7,0.1)
const COLOR_HEALTH = Color(1.0,0.25,0.225)
const COLOR_MANA = Color(0.9,0.7,0.2)

var base = preload("res://scenes/main/card_base.tscn")


func create_card(type):
	var ci = base.instance()
	var text = ""
	ci.get_node("Image").set_texture(data[type]["image"])
	ci.get_node("Name").set_text(tr(type.to_upper()))
	ci.get_node("Tags").set_text(tr(data[type]["type"].to_upper()))
	for s in data[type]["rules"]:
		text += tr(s.to_upper()+"_DESC")+"\n"
	ci.get_node("Desc").set_text(text)
	ci.get_node("Level").set_text(str(data[type]["level"]))
	ci.get_node("Temp").set_text(str(data[type]["temperature"]))
	if (data[type]["temperature"]>0):
		ci.get_node("OverlayTemp").set_modulate(COLOR_HOT)
	elif (data[type]["temperature"]<0):
		ci.get_node("OverlayTemp").set_modulate(COLOR_COLD)
	else:
		ci.get_node("OverlayTemp").set_modulate(Color(0.5,0.5,0.5))
	if (data[type]["type"]=="creature"):
		ci.get_node("Overlay").set_modulate(COLOR_CREATURE)
	elif (data[type]["type"]=="spell"):
		ci.get_node("Overlay").set_modulate(COLOR_SPELL)
	
	return ci


