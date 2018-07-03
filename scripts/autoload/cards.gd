extends Node


const data = {
	# fire creatures
	"fire_elemental":{
		"type":"creature",
		"temperature":2,
		"level":2,
		"rarity":0,
		"rules":[],
		"tags":["fire","elemental"],
		"animation":"fire_blast",
		"image":preload("res://images/cards/fire_creature.jpg")
	},
	"burning_wisp":{
		"type":"creature",
		"temperature":1,
		"level":2,
		"rarity":1,
		"rules":["inc_player_temp-2"],
		"on_play":"inc_player_temp-2",
		"on_removed":"dec_player_temp-2",
		"tags":["fire","elemental","support"],
		"animation":"fire_blast",
		"image":preload("res://images/cards/wisp_fire.jpg")
	},
	"greater_fire_elemental":{
		"type":"creature",
		"temperature":3,
		"level":3,
		"rarity":0,
		"rules":[],
		"tags":["fire","elemental"],
		"animation":"fire_blast",
		"image":preload("res://images/cards/fire_creature.jpg")
	},
	"explosive_wisp":{
		"type":"creature",
		"temperature":1,
		"level":4,
		"rarity":2,
		"rules":["dead_kill_all_cold-2"],
		"on_dead":"kill_all_cold-2",
		"tags":["fire","elemental","area","trap"],
		"animation":"fire_blast",
		"image":preload("res://images/cards/wisp_fire.jpg")
	},
	"lava_elemental":{
		"type":"creature",
		"temperature":4,
		"level":5,
		"rarity":0,
		"rules":[],
		"tags":["fire","elemental"],
		"animation":"fire_blast",
		"image":preload("res://images/cards/Magma_Spawn_by_Katarzyna_Zalecka_and_Gabriel_Verdon.jpg")
	},
	"lava_golem":{
		"type":"creature",
		"temperature":3,
		"level":5,
		"rarity":2,
		"rules":["spawn_dead-2-fire_elemental"],
		"on_dead":"spawn-2-fire_elemental",
		"tags":["fire","golem","trap"],
		"animation":"fire_blast",
		"image":preload("res://images/cards/Magma_Spawn_by_Katarzyna_Zalecka_and_Gabriel_Verdon.jpg")
	},
	"fire_avatar":{
		"type":"creature",
		"temperature":4,
		"level":6,
		"rarity":2,
		"rules":["heat_aura-1"],
		"on_play":"inc_ally_temp-1",
		"on_ally_creature_spawn":"inc_temp-1",
		"on_removed":"dec_ally_temp-1",
		"tags":["fire","elemental","area","support"],
		"animation":"fire_strike",
		"image":preload("res://images/cards/DivineGuardian.jpg")
	},
	
	# fire spells
	"fire_blade":{
		"type":"spell",
		"temperature":1,
		"level":2,
		"rarity":0,
		"rules":["inc_ally_temp-1"],
		"on_play":"inc_temp-1",
		"target":"creature-ally",
		"tags":["fire","equipment"],
		"animation":"fire_blade",
		"image":preload("res://images/cards/fire_blade.jpg")
	},
	"fire_ball":{
		"type":"spell",
		"temperature":3,
		"level":3,
		"rarity":0,
		"rules":["kill_cold-3"],
		"on_play":"kill_cold-3",
		"target":"creature",
		"tags":["fire","attack"],
		"animation":"fire_ball",
		"image":preload("res://images/cards/fire_ball.jpg")
	},
	"blaze":{
		"type":"spell",
		"temperature":2,
		"level":3,
		"rarity":1,
		"rules":["inc_temp-2"],
		"on_play":"inc_temp-2",
		"target":"creature",
		"tags":["fire"],
		"animation":"fire_circle",
		"image":preload("res://images/cards/blaze.jpg")
	},
	"explosion":{
		"type":"spell",
		"temperature":0,
		"level":4,
		"rarity":2,
		"rules":["explosion"],
		"on_play":"explosion",
		"target":"creature-ally",
		"tags":["fire","area","attack"],
		"animation":"explosion",
		"image":preload("res://images/cards/explosion.jpg")
	},
	
	# ice creatures
	"water_elemental":{
		"type":"creature",
		"temperature":-2,
		"level":2,
		"rarity":0,
		"rules":[],
		"tags":["ice","elemental"],
		"animation":"water_blast",
		"image":preload("res://images/cards/welcome_to_air_OMGWTF_by_shiroikuro.jpg")
	},
	"freezing_wisp":{
		"type":"creature",
		"temperature":-1,
		"level":2,
		"rarity":1,
		"rules":["dec_attacker_temp-1"],
		"on_attacked":"dec_temp-1",
		"tags":["ice","elemental","trap"],
		"animation":"ice_blast",
		"image":preload("res://images/cards/wisp_ice.jpg")
	},
	"greater_water_elemental":{
		"type":"creature",
		"temperature":-3,
		"level":3,
		"rarity":0,
		"rules":[],
		"tags":["ice","elemental"],
		"animation":"water_blast",
		"image":preload("res://images/cards/welcome_to_air_OMGWTF_by_shiroikuro.jpg")
	},
	"ice_elemental":{
		"type":"creature",
		"temperature":-4,
		"level":4,
		"rarity":0,
		"rules":["fire_armor-2"],
		"on_new_turn":"fire_armor-2",
		"tags":["ice","elemental"],
		"animation":"ice_blast",
		"image":preload("res://images/cards/ice_creature.jpg")
	},
	"ice_avatar":{
		"type":"creature",
		"temperature":-4,
		"level":6,
		"rarity":2,
		"rules":["ice_armor-2"],
		"on_new_turn":"ice_armor-2",
		"tags":["ice","elemental"],
		"animation":"spike_blast",
		"image":preload("res://images/cards/ice_creature.jpg")
	},
	
	# ice spells
	"chill":{
		"type":"spell",
		"temperature":-1,
		"level":2,
		"rarity":0,
		"rules":["dec_temp-1"],
		"on_play":"dec_temp-1",
		"target":"creature",
		"tags":["ice"],
		"animation":"ice_circle",
		"image":preload("res://images/cards/ice_spell.jpg")
	},
	"hailstorm":{
		"type":"spell",
		"temperature":0,
		"level":4,
		"rarity":2,
		"rules":["kill_all_hot-2"],
		"on_play":"kill_all_hot-2",
		"tags":["ice","area","attack"],
		"animation":"hailstorm",
		"image":preload("res://images/cards/hailstorm.jpg")
	},
	"flash_flood":{
		"type":"spell",
		"temperature":0,
		"level":5,
		"rarity":1,
		"rules":["move_to_hand"],
		"on_play":"move_to_hand",
		"target":"creature",
		"tags":["attack"],
		"animation":"flash_flood",
		"image":preload("res://images/cards/flash_flood.jpg")
	},
	"equalize":{
		"type":"spell",
		"temperature":0,
		"level":3,
		"rarity":1,
		"rules":["neutralize_temp-2"],
		"on_play":"neutralize_temp-2",
		"target":"creature",
		"tags":["ice"],
		"animation":"neutralize",
		"image":preload("res://images/cards/spell_neutral.jpg")
	},
	"ice_armor":{
		"type":"spell",
		"temperature":-2,
		"level":2,
		"rarity":2,
		"rules":["ice_armor-2"],
		"on_play":"",
		"on_new_turn":"ice_armor-2",
		"target":"creature-ally",
		"tags":["ice","equipment"],
		"animation":"ice_shield",
		"image":preload("res://images/cards/ice_shield.jpg")
	},
	
	# neutral creatures
	"wind_elemental":{
		"type":"creature",
		"temperature":0,
		"level":2,
		"rarity":1,
		"rules":["kill_attacker_level-3"],
		"on_attacked":"kill_level-3",
		"tags":["neutral","elemental"],
		"animation":"wind_blast",
		"image":preload("res://images/cards/back.png")
	},
	"lightning_elemental":{
		"type":"creature",
		"temperature":0,
		"level":4,
		"rarity":1,
		"rules":["kill_attacker_level-5"],
		"on_attacked":"kill_level-5",
		"tags":["neutral","elemental"],
		"animation":"wind_blast",
		"image":preload("res://images/cards/back.png")
	},
	"assembled_golem":{
		"type":"creature",
		"temperature":0,
		"level":5,
		"rarity":1,
		"rules":["assemble"],
		"on_play":"assemble",
		"tags":["neutral","golem"],
		"animation":"wind_blast",
		"image":preload("res://images/cards/back.png")
	},
	
	# neutral spells
	"draw":{
		"type":"spell",
		"temperature":0,
		"level":3,
		"rarity":0,
		"rules":["draw-3"],
		"on_play":"draw-3",
		"tags":[],
		"animation":"sparks",
		"image":preload("res://images/cards/spell_neutral.jpg")
	},
	"inversion":{
		"type":"spell",
		"temperature":0,
		"level":3,
		"rarity":2,
		"rules":["invert_temp"],
		"on_play":"invert_temp",
		"target":"creature",
		"tags":[],
		"animation":"neutralize",
		"image":preload("res://images/cards/spell_neutral.jpg")
	},
	"cleanse":{
		"type":"spell",
		"temperature":0,
		"level":4,
		"rarity":1,
		"rules":["cleanse"],
		"on_play":"cleanse",
		"target":"creature",
		"tags":[],
		"animation":"sparks",
		"image":preload("res://images/cards/spell_neutral.jpg")
	},
	"mass_calibration":{
		"type":"spell",
		"temperature":0,
		"level":5,
		"rarity":2,
		"rules":["global_diffusion_all-1"],
		"on_play":"global_diffusion_all-1",
		"tags":["area"],
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
const CARD_PACK_PRICE = [
	{"fire":110,"ice":110,"neutral":120,"random":100},
	{"fire":220,"ice":220,"neutral":240,"random":200},
	{"fire":440,"ice":440,"neutral":480,"random":400}
]

var grade_cards = [{"fire":[],"ice":[],"neutral":[]},{"fire":[],"ice":[],"neutral":[]},{"fire":[],"ice":[],"neutral":[]}]

var base = preload("res://scenes/main/card_base.tscn")


func create_card(type):
	var ci = base.instance()
	var text = ""
	var tag_text = tr(data[type]["type"].to_upper())+" - "
	ci.get_node("Image").set_texture(data[type]["image"])
	ci.get_node("Name").set_text(tr(type.to_upper()))
	for t in data[type]["tags"]:
		tag_text += tr(t.to_upper())+" "
	ci.get_node("Tags").set_text(tag_text)
	for s in data[type]["rules"]:
		var array = s.split("-")
		var line = tr(array[0].to_upper()+"_DESC")+"\n"
		for i in range(1,array.size()):
			line = line.replace("%"+str(i),tr(array[i].to_upper()))
		text += line
	ci.get_node("Desc").set_text(text)
	ci.get_node("Level").set_text(str(data[type]["level"]))
	ci.get_node("Temp").set_text(str(data[type]["temperature"]))
	ci.get_node("OverlayLevel/Grade"+str(min(data[type]["rarity"],3))).show()
	if (data[type]["temperature"]>0):
		ci.get_node("OverlayTemp").set_self_modulate(COLOR_HOT)
		ci.get_node("OverlayTemp/Fire").show()
	elif (data[type]["temperature"]<0):
		ci.get_node("OverlayTemp").set_self_modulate(COLOR_COLD)
		ci.get_node("OverlayTemp/Frost").show()
	else:
		ci.get_node("OverlayTemp").set_self_modulate(Color(0.5,0.5,0.5))
	if (data[type]["type"]=="creature"):
		ci.get_node("Overlay").set_modulate(COLOR_CREATURE)
	elif (data[type]["type"]=="spell"):
		ci.get_node("Overlay").set_modulate(COLOR_SPELL)
	
	return ci


func _ready():
	for card in data.keys():
		var grade = clamp(data[card]["level"]/2+data[card]["rarity"]-1.5,0,2)
		var g1 = int(grade)
		var g2 = int(round(grade))
		var type = "neutral"
		if ("fire" in data[card]["tags"]):
			grade_cards[g1]["fire"].push_back(card)
			if (g2!=g1):
				grade_cards[g2]["fire"].push_back(card)
			type = "fire"
		if ("ice" in data[card]["tags"]):
			grade_cards[g1]["ice"].push_back(card)
			if (g2!=g1):
				grade_cards[g2]["ice"].push_back(card)
			type = "ice"
		if (type=="neutral" || ("neutral" in data[card]["tags"])):
			grade_cards[g1]["neutral"].push_back(card)
			if (g2!=g1):
				grade_cards[g2]["neutral"].push_back(card)
			type = "neutral"
