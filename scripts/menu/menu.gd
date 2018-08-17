extends Node

const VERSION = "v0.3"

# balanced deck
const DEFAULT = {
	"fire_elemental":3,"greater_fire_elemental":2,"burning_wisp":1,
	"lava_elemental":2,"fire_avatar":2,
	"fire_blade":2,"blaze":1,"fire_ball":2,"explosion":2,
	"water_elemental":3,"greater_water_elemental":2,"freezing_wisp":1,
	"ice_elemental":2,"ice_avatar":2,
	"chill":2,"equalize":2,"hailstorm":1,"flash_flood":2,
	"wind_elemental":1,"lightning_elemental":1,
	"draw":2,"inversion":2
}
# focus on strong fire creatures, temperature inversion and damage cards
const FIRE = {
	"fire_elemental":3,"greater_fire_elemental":2,
	"burning_wisp":2,"explosive_wisp":1,
	"lava_elemental":2,"lava_golem":2,"fire_avatar":2,
	"blaze":2,"spectral_blade":3,
	"explosion":2,"vulcano":1,
	"freezing_wisp":1,"ice_avatar":2,"giant_ice_golem":2,
	"equalize":2,"flash_flood":2,
	"lightning_elemental":2,
	"draw":2,"inversion":3,
	"mass_inversion":2
}
# focus on ice creatures, defense and direct player damage
const ICE = {
	"fire_elemental":2,"greater_fire_elemental":1,"lava_golem":2,
	"explosion":2,
	"water_elemental":2,"greater_water_elemental":2,"freezing_wisp":2,
	"ice_avatar":2,"ice_shard_defender":2,"giant_ice_golem":2,
	"chill":1,"ice_armor":2,"equalize":2,"flash_flood":2,
	"ice_wall":1,"freeze":2,"snow_storm":1,
	"wind_elemental":1,"lightning_elemental":1,"shadow_elemental":1,
	"draw":1,"inversion":2,"cleanse":1,
	"hurricane":1,"mass_inversion":1,"thermal_shield":1
}
const INVENTORY_DEFAULT = {
	"fire_elemental":3,"greater_fire_elemental":2,"burning_wisp":2,
	"lava_elemental":2,"fire_avatar":2,
	"fire_blade":3,"blaze":1,"fire_ball":2,"explosion":2,
	"water_elemental":3,"greater_water_elemental":2,"freezing_wisp":2,
	"ice_elemental":2,"ice_avatar":2,
	"chill":3,"equalize":2,"hailstorm":2,"flash_flood":2,
	"wind_elemental":2,"lightning_elemental":1,
	"draw":2,"inversion":2
}
const MAX_MULT = 3
const MAX_CARDS = 40
const CARD_PACK_SIZE = 3
const LOCALES = ["en"]

var deck = DEFAULT.duplicate()
var _deck
var deck_name = tr("DEFAULT")
var gold = 100
var inventory = {}
var active = false
var status_text = ""
var waiting = false
var dots = 0
var player_deck = {}
var player_name = {}
var player_self
var reward = 0

var _name = tr("PLAYER")
var fullscreen
var maximized
var screen_size
var music
var music_volume
var sound
var sound_volume
var locale
var animations

var tut_scene = preload("res://scenes/main/tutorial.tscn")


func _skirmish():
	# Start a match vs the AI.
	var rnd = randf()
	Main.reset()
	Main.deck[0] = get_deck()
	if (rnd<0.25):
		Main.deck[1] = get_deck(FIRE)
	elif (rnd<0.5):
		Main.deck[1] = get_deck(ICE)
	else:
		Main.deck[1] = get_deck(DEFAULT)
	Main.player_name[0] = _name
	Main.player_name[1] = tr("AI_SKIRMISH")
	Main.ai = true
	UI.show()
	Main.start()
	reward = 100
	hide()
	active = true
	get_node("Panel/VBoxContainer/Button5").show()
	if (has_node("/root/Tutorial")):
		get_node("/root/Tutorial").queue_free()

func _local():
	# Start a match without AI.
	Main.reset()
	Main.deck[0] = get_deck()
	Main.deck[1] = get_deck()
	Main.player_name[0] = _name
	Main.player_name[1] = _name
	UI.show()
	Main.start()
	reward = 0
	hide()
	active = true
	get_node("Panel/VBoxContainer/Button5").show()
	if (has_node("/root/Tutorial")):
		get_node("/root/Tutorial").queue_free()

func _tutorial():
	# Start a match vs the AI and show the tutorial.
	var ti = tut_scene.instance()
	Main.reset()
	Main.deck[0] = get_deck(DEFAULT)
	Main.deck[1] = get_deck(DEFAULT)
	Main.player_name[0] = _name
	Main.player_name[1] = tr("AI_SKIRMISH")
	Main.ai = true
	reward = 100
	UI.get_node("Player1/VBoxContainer/Name").set_text(_name)
	UI.get_node("Player2/VBoxContainer/Name").set_text(tr("AI_SKIRMISH"))
	UI.show()
	hide()
	active = true
	get_node("Panel/VBoxContainer/Button5").show()
	if (has_node("/root/Tutorial")):
		get_node("/root/Tutorial").queue_free()
		get_node("/root/Tutorial").set_name("deleted")
	ti.set_name("Tutorial")
	get_tree().get_root().add_child(ti)

sync func _multiplayer():
	# Start a multiplayer match.
	if (player_name.size()<2):
		return
	var other = player_name.keys()[0]
	if (other==1):
		other = player_name.keys()[1]
	Main.reset()
	Main.deck[0] = player_deck[1]
	Main.deck[1] = player_deck[other]
	Main.player_name[0] = player_name[1]
	Main.player_name[1] = player_name[other]
	Main.multiplayer = true
	Main.server = player_self==0
	if (player_self!=0):
		Main.turn = 0
		Main.mana = [3,2]
		Main.mana_max = [3,2]
	UI.show()
	Main.start()
	reward = 250
	hide()
	active = true
	get_node("Panel/VBoxContainer/Button5").show()
	if (has_node("/root/Tutorial")):
		get_node("/root/Tutorial").queue_free()
	get_node("Lobby/VBoxContainer/Buttons/ButtonJ").set_disabled(false)
	get_node("Lobby/VBoxContainer/Buttons/ButtonH").set_disabled(false)
	get_node("Lobby/VBoxContainer/Status/ButtonC").hide()
	set_status("CONNECTED",false,false)


func game_over(victory,error=""):
	# Show victory/game over message.
	get_node("Panel/VBoxContainer/Button5").hide()
	active = false
	if (error=="player_dc"):
		get_node("GameOver").set_title(tr("DISCONNECTED"))
		get_node("GameOver/Text").set_text(tr("PLAYER_DISCONNECTED"))
	elif (error=="server_dc"):
		get_node("GameOver").set_title(tr("DISCONNECTED"))
		get_node("GameOver/Text").set_text(tr("SERVER_DISCONNECTED"))
	elif (victory):
		get_node("GameOver").set_title(tr("VICTORY"))
		get_node("GameOver/Text").set_text(tr("YOU_WIN")+"\n"+tr("REWARD_GAINED")%reward)
		gold += reward
	else:
		reward = int(reward/2)
		get_node("GameOver").set_title(tr("GAME_OVER"))
		get_node("GameOver/Text").set_text(tr("YOU_LOST")+"\n"+tr("REWARD_GAINED")%reward)
		gold += reward
	get_node("GameOver").popup_centered()
	save_inventory()
	UI.hide()
	Main.hide()
	show()
	Music.temperature = 0
	if (has_node("/root/Tutorial")):
		get_node("/root/Tutorial").queue_free()


func hide():
	for c in get_children():
		if (c.has_method("hide")):
			c.hide()

func show():
	get_node("Panel").show()

func quit():
	if (get_node("Quit").is_visible()):
		save_config()
		get_tree().quit()
	elif (get_node("Deck/Decks").is_visible()):
		get_node("Deck/Decks").hide()
	elif (get_node("Deck").is_visible()):
		get_node("Deck").hide()
	elif (get_node("Shop").is_visible()):
		get_node("Shop").hide()
	elif (get_node("Acquired").is_visible()):
		get_node("Acquired").hide()
	elif (get_node("Options").is_visible()):
		get_node("Options").hide()
	elif (get_node("Lobby").is_visible()):
		get_node("Lobby").hide()
	elif (get_node("Info").is_visible()):
		get_node("Info").hide()
	elif (get_node("Credits").is_visible()):
		get_node("Credits").hide()
	elif (get_node("GameOver").is_visible()):
		get_node("GameOver").hide()
	else:
		yield(get_tree(),"idle_frame")
		get_node("Quit").popup_centered()

func _show_deck(t=false):
	var num_cards
	var show_all = get_node("Deck/Header/CheckBox").is_pressed() || true
	if (_deck==null):
		_deck = deck.duplicate()
	num_cards = get_num_cards(_deck)
	for i in range(Cards.data.size()):
		if (typeof(Cards.data.values()[i]["rarity"])==TYPE_BOOL && !Cards.data.values()[i]["rarity"]):
			continue
		var bi
		var type = Cards.data.keys()[i]
		var ammount = 0
		var max_ammount = 0
		if (inventory.has(type)):
			max_ammount = min(MAX_MULT,inventory[type])
		if (!has_node("Deck/ScrollContainer/GridContainer/Card"+str(i))):
			var ni = Cards.create_card(type)
			bi = get_node("Deck/Card").duplicate()
			bi.set_name("Card"+str(i))
			bi.get_node("ButtonAdd").connect("pressed",self,"add_card",[i])
			bi.get_node("ButtonSub").connect("pressed",self,"rm_card",[i])
			ni.type = "preview"
			ni.set_position(Vector2(105,150))
			bi.get_node("Preview").add_child(ni)
			get_node("Deck/ScrollContainer/GridContainer").add_child(bi)
		else:
			bi = get_node("Deck/ScrollContainer/GridContainer/Card"+str(i))
		if (_deck.has(type)):
			ammount = _deck[type]
			bi.get_node("ButtonAdd").set_disabled(ammount>=max_ammount || num_cards>=MAX_CARDS)
			bi.get_node("ButtonSub").set_disabled(false)
		else:
			bi.get_node("ButtonAdd").set_disabled(max_ammount==0 || num_cards>=MAX_CARDS)
			bi.get_node("ButtonSub").set_disabled(true)
		if (inventory.has(type)):
			bi.get_node("Label").set_text(str(ammount)+" / "+str(max_ammount)+" ("+str(inventory[type])+")")
		else:
			bi.get_node("Label").set_text(str(ammount)+" / "+str(max_ammount))
		if (show_all || max_ammount>0):
			bi.show()
		else:
			bi.hide()
	
	get_node("Deck/Header/Label").set_text(tr("CARDS")+": "+str(get_num_cards(_deck))+" / "+str(MAX_CARDS))
	get_node("Deck/Header/Name").set_text(deck_name)
	get_node("Deck").popup_centered()
	get_node("Deck/Decks").hide()
	get_node("Singleplayer").hide()

func _show_decks():
	var file = File.new()
	var dir = Directory.new()
	var error = dir.open("user://decks")
	var decks = {tr("DEFAULT"):DEFAULT}
	if (error==OK):
		var filename
		dir.list_dir_begin(true)
		filename = dir.get_next()
		while (filename!=""):
			if (!dir.current_is_dir()):
				var nm = filename.split(".")[0]
				var err = file.open("user://decks/"+filename,File.READ)
				if (err!=OK):
					continue
				var currentline = JSON.parse(file.get_line()).result
				if (currentline!=null):
					decks[nm] = currentline
				file.close()
			filename = dir.get_next()
		dir.list_dir_end()
	
	for c in get_node("Deck/Decks/ScrollContainer/VBoxContainer").get_children():
		c.hide()
	for i in range(decks.size()):
		var bi
		if (!has_node("Deck/Decks/ScrollContainer/VBoxContainer/Button"+str(i))):
			bi = get_node("Deck/Decks/Button").duplicate()
			bi.set_name("Button"+str(i))
			get_node("Deck/Decks/ScrollContainer/VBoxContainer").add_child(bi)
		else:
			bi = get_node("Deck/Decks/ScrollContainer/VBoxContainer/Button"+str(i))
		bi.get_node("Label").set_text(decks.keys()[i])
		if (bi.is_connected("pressed",self,"_load_deck")):
			bi.disconnect("pressed",self,"_load_deck")
		bi.connect("pressed",self,"_load_deck",[decks.values()[i],decks.keys()[i]])
		bi.show()
	
	get_node("Deck/Decks").popup_centered()

func _show_shop():
	get_node("Shop/VBoxContainer/Gold/Label").set_text(tr("GOLD")+": "+str(gold))
	get_node("Acquired").hide()
	get_node("Shop").popup_centered()
	get_node("Singleplayer").hide()

func _show_options():
	var idx = 0
	fullscreen = OS.is_window_fullscreen()
	maximized = OS.is_window_maximized()
	screen_size = OS.get_window_size()
	music = !AudioServer.is_bus_mute(1)
	music_volume = 100*db2linear(AudioServer.get_bus_volume_db(1))
	sound = !AudioServer.is_bus_mute(2)
	sound_volume = 100*db2linear(AudioServer.get_bus_volume_db(2))
	locale = TranslationServer.get_locale()
	for i in range(get_node("Options/ScrollContainer/VBoxContainer/Locale/OptionButton").get_item_count()):
		if (get_node("Options/ScrollContainer/VBoxContainer/Locale/OptionButton").get_item_text(i)==locale):
			idx = i
			break
	
	get_node("Options/ScrollContainer/VBoxContainer/Animations").set_pressed(animations)
	if (OS.has_feature("mobile")):
		get_node("Options/ScrollContainer/VBoxContainer/Fullscreen").hide()
		get_node("Options/ScrollContainer/VBoxContainer/WindowSize").hide()
	else:
		get_node("Options/ScrollContainer/VBoxContainer/Fullscreen").set_pressed(fullscreen)
		get_node("Options/ScrollContainer/VBoxContainer/WindowSize/SpinBoxX").set_value(screen_size.x)
		get_node("Options/ScrollContainer/VBoxContainer/WindowSize/SpinBoxY").set_value(screen_size.y)
	get_node("Options/ScrollContainer/VBoxContainer/Audio/Music").set_pressed(music)
	get_node("Options/ScrollContainer/VBoxContainer/Volume/SpinBoxM").set_value(music_volume)
	get_node("Options/ScrollContainer/VBoxContainer/Audio/Sound").set_pressed(sound)
	get_node("Options/ScrollContainer/VBoxContainer/Volume/SpinBoxS").set_value(sound_volume)
	get_node("Options/ScrollContainer/VBoxContainer/Locale/OptionButton").select(idx)
	if (_name!="" && _name!=tr("PLAYER")):
		get_node("Options/ScrollContainer/VBoxContainer/Name/Name").set_text(_name)
	get_node("Options").popup_centered()
	get_node("Singleplayer").hide()

func add_card(ID):
	var type = Cards.data.keys()[ID]
	if (!inventory.has(type) || get_num_cards(_deck)>=MAX_CARDS || (_deck.has(type) && _deck[type]>=min(MAX_MULT,inventory[type]))):
		return
	
	if (_deck.has(type)):
		_deck[type] += 1
	else:
		_deck[type] = 1
	
	_show_deck()

func rm_card(ID):
	var type = Cards.data.keys()[ID]
	if (!_deck.has(type)):
		return
	
	if (_deck[type]==1):
		_deck.erase(type)
	else:
		_deck[type] -= 1
	
	_show_deck()

func add_inventory(ID):
	if (inventory.has(ID)):
		inventory[ID] += 1
	else:
		inventory[ID] = 1

func get_pack_card(grade,type):
	if (!Cards.grade_cards[grade].has(type)):
		return
	var cards = Cards.grade_cards[grade][type]
	if (cards.size()==0):
		return
	return cards[randi()%cards.size()]

func _buy_pack(grade,type):
	var price = Cards.CARD_PACK_PRICE[grade][type]
	if (gold<price):
		print("Not enough gold!")
		return
	
	var cards = []
	gold -= price
	for i in range(CARD_PACK_SIZE):
		var t = type
		var card
		if (t=="random"):
			t = ["fire","ice","neutral"][randi()%3]
		card = get_pack_card(grade,t)
		if (card!=null):
			add_inventory(card)
			cards.push_back(card)
	
	show_new_cards(cards)
	save_inventory()
	get_node("Shop").hide()

func show_new_cards(cards):
	var timer = Timer.new()
	var offset = (get_node("Acquired/Cards").get_size().x-150)/cards.size()
	for c in get_node("Acquired/Cards").get_children():
		c.queue_free()
	
	for i in range(cards.size()):
		var ni = Cards.create_card(cards[i])
		ni.type = "preview"
		ni.set_position(get_node("Acquired").get_size()/2.0+Vector2(-95,45))
		get_node("Acquired/Cards").add_child(ni)
		ni.get_node("Tween").interpolate_property(ni,"position",ni.get_position(),Vector2(105+i*offset,150),0.5,Tween.TRANS_LINEAR,Tween.EASE_IN_OUT,0.5+0.25*i)
		ni.get_node("Tween").start()
	get_node("Acquired/Stack/AnimationPlayer").play("fade_out")
	get_node("Acquired").popup_centered()
	get_node("SoundShuffle").play()
	timer.set_one_shot(true)
	timer.set_wait_time(0.5)
	add_child(timer)
	timer.start()
	yield(timer,"timeout")
	timer.set_wait_time(0.25)
	for i in range(cards.size()):
		get_node("SoundCard").play()
		timer.start()
		yield(timer,"timeout")
	timer.queue_free()


func get_deck(d=deck):
	# Convert deck dictionary to array.
	var array = []
	for k in d.keys():
		for i in range(d[k]):
			array.push_back(k)
	
	return array

func get_num_cards(d=deck):
	var num = 0
	for n in d.values():
		num += n
	return num


func _new_deck():
	deck.clear()
	deck_name = tr("NEW_DECK")
	_deck = null
	_show_deck()

func _change_deck():
	if (_deck!=null):
		deck = _deck
		if (deck_name!=tr("DEFAULT")):
			save_deck()
		_deck = null
	get_node("Deck").hide()
	save_config()

func _set_deck_name(dname):
	deck_name = dname

func _load_deck(d,n):
	deck = d.duplicate()
	_deck = null
	deck_name = n
	_show_deck()

func load_deck(dname):
	deck_name = dname
	if (dname==tr("DEFAULT")):
		deck = DEFAULT.duplicate()
	else:
		var currentline
		var file = File.new()
		var error = file.open("user://decks/"+dname+".cfg",File.READ)
		if (error!=OK):
			return
		currentline = JSON.parse(file.get_line()).get_result()
		file.close()
		if (currentline==null):
			return
		
		deck = currentline
	_show_deck()

func save_deck():
	var file = File.new()
	var dir = Directory.new()
	if (!dir.dir_exists("user://decks")):
		dir.make_dir_recursive("user://decks")
	deck = _deck
	if (deck_name==tr("DEFAULT")):
		# Change deck name to an unused name.
		var ID = 1
		while (file.file_exists("user://decks/"+tr("NEW_DECK")+" "+str(ID)+".cfg")):
			ID += 1
		deck_name = tr("NEW_DECK")+" "+str(ID)
		get_node("Deck/Header/Name").set_text(deck_name)
	
	file.open("user://decks/"+deck_name+".cfg",File.WRITE)
	file.store_line(JSON.print(deck))
	file.close()

func load_inventory():
	var currentline
	var file = File.new()
	var error = file.open("user://inventory.cfg",File.READ)
	if (error!=OK):
		inventory = INVENTORY_DEFAULT.duplicate()
		return
	currentline = JSON.parse(file.get_line()).get_result()
	if (currentline!=null):
		gold = int(currentline)
	currentline = JSON.parse(file.get_line()).get_result()
	if (currentline!=null):
		inventory = currentline
	file.close()

func save_inventory():
	var file = File.new()
	var dir = Directory.new()
	if (!dir.dir_exists("user://")):
		dir.make_dir_recursive("user://")
	
	file.open("user://inventory.cfg",File.WRITE)
	file.store_line(str(gold))
	file.store_line(JSON.print(inventory))
	file.close()


# config stuff

func save_config():
	var file = ConfigFile.new()
	file.set_value("video","animations",animations)
	file.set_value("video","fullscreen",fullscreen)
	file.set_value("video","maximized",OS.is_window_maximized())
	file.set_value("video","screenw",screen_size.x)
	file.set_value("video","screenh",screen_size.y)
	file.set_value("audio","music",music)
	file.set_value("audio","music_volume",int(music_volume))
	file.set_value("audio","sound",music)
	file.set_value("audio","sound_volume",int(sound_volume))
	file.set_value("locale","locale",locale)
	file.set_value("player","name",_name)
	file.set_value("player","deck",deck_name)
	file.save("user://config.cfg")

func load_config():
	var file = ConfigFile.new()
	var default_locale = OS.get_locale()
	if !(default_locale in LOCALES):
		default_locale = default_locale.split("_")[0]
		if !(default_locale in LOCALES):
			default_locale = "en"
	file.load("user://config.cfg")
	animations = file.get_value("video","animations",true)
	fullscreen = file.get_value("video","fullscreen",false)
	maximized = file.get_value("video","maximized",true)
	screen_size = Vector2(file.get_value("video","screenw",OS.get_screen_size().x),file.get_value("video","screenh",OS.get_screen_size().y))
	music = file.get_value("audio","music",true)
	music_volume = file.get_value("audio","music_volume",100)
	sound = file.get_value("audio","sound",true)
	sound_volume = file.get_value("audio","sound_volume",100)
	locale = file.get_value("locale","locale",default_locale)
	_name = file.get_value("player","name",tr("PLAYER"))
	if (_name!="" && _name!=tr("PLAYER")):
		get_node("Options/ScrollContainer/VBoxContainer/Name/Name").set_text(_name)
	deck_name = file.get_value("player","deck",tr("DEFAULT"))
	load_deck(deck_name)
	_options_apply()

func _options_accept():
	_options_apply()
	get_node("Options").hide()

func _options_apply():
	OS.set_window_size(screen_size)
	OS.set_window_maximized(maximized)
	OS.set_window_fullscreen(fullscreen)
	AudioServer.set_bus_mute(1,!music)
	AudioServer.set_bus_volume_db(1,linear2db(music_volume/100.0))
	AudioServer.set_bus_mute(2,!sound)
	AudioServer.set_bus_volume_db(2,linear2db(sound_volume/100.0))
	TranslationServer.set_locale(locale)
	_name = get_node("Options/ScrollContainer/VBoxContainer/Name/Name").get_text()
	if (_name==""):
		_name = tr("PLAYER")
	save_config()

func _set_animations(enabled):
	animations = enabled

func _set_fullscreen(enabled):
	fullscreen = enabled

func _set_screenw(value):
	screen_size.x = value

func _set_screenh(value):
	screen_size.y = value

func _set_music(enabled):
	music = enabled

func _set_music_volume(value):
	music_volume = value

func _set_sound(enabled):
	sound = enabled

func _set_sound_volume(value):
	sound_volume = value

func _set_locale(idx):
	locale = get_node("Options/ScrollContainer/VBoxContainer/Language/OptionButton").get_item_text(idx)


# network callbacks #

func _player_disconnected(id):
	# Someone disconnected, stop the game.
	game_over(false,"player_dc")
	cancel_mp()

func _server_disconnected():
	# Server disconnected, stop the game.
	game_over(false,"player_dc")
	cancel_mp()

func _connected_ok():
	# Only called on clients, not server. Send my ID and info to all other peers.
	var _deck = get_deck(deck)
	player_name[get_tree().get_network_unique_id()] = _name
	player_deck[get_tree().get_network_unique_id()] = _deck
	rpc("register_player",get_tree().get_network_unique_id(),_name,_deck)

func _connected_fail():
	cancel_mp()

remote func register_player(ID,nm,_deck):
	player_name[ID] = nm
	player_deck[ID] = _deck
	rpc_id(ID,"register_player",1,_name,get_deck(deck)) # Send myself to the other dude.
	
	if (player_name.size()>1):
		if (player_self==0):
			rpc("_multiplayer")

# game creation #

func _host():
	var host = NetworkedMultiplayerENet.new()
	var port = int(get_node("Lobby/VBoxContainer/Adress/Port").get_text())
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	var err = host.create_server(port,1) # Max 1 peer, since it's a 2 players game.
	if (err!=OK):
		# Is another server running?
		set_status("ADRESS_IN_USE",true,false)
		return
	
	player_name.clear()
	player_deck.clear()
	player_self = 0
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer",host)
	get_node("Lobby/VBoxContainer/Buttons/ButtonJ").set_disabled(true)
	get_node("Lobby/VBoxContainer/Buttons/ButtonH").set_disabled(true)
	get_node("Lobby/VBoxContainer/Status/ButtonC").show()
	set_status("WAITING_FOR_PLAYER",false,true)

func _join():
	var ip = get_node("Lobby/VBoxContainer/Adress/Adress").get_text()
	var port = int(get_node("Lobby/VBoxContainer/Adress/Port").get_text())
	if (!ip.is_valid_ip_address()):
		set_status("IP_INVALID",true,false)
		return
	
	var host = NetworkedMultiplayerENet.new()
	player_name.clear()
	player_deck.clear()
	player_self = 1
	host.set_compression_mode(NetworkedMultiplayerENet.COMPRESS_RANGE_CODER)
	host.create_client(ip,port)
	get_tree().set_network_peer(host)
	get_tree().set_meta("network_peer",host)
	get_node("Lobby/VBoxContainer/Buttons/ButtonJ").set_disabled(true)
	get_node("Lobby/VBoxContainer/Buttons/ButtonH").set_disabled(true)
	get_node("Lobby/VBoxContainer/Status/ButtonC").show()
	set_status("CONNECTING",false,true)

func cancel_mp():
	get_tree().set_network_peer(null) # remove peer
	get_tree().set_meta("network_peer",null)
	get_node("Lobby/VBoxContainer/Buttons/ButtonJ").set_disabled(false)
	get_node("Lobby/VBoxContainer/Buttons/ButtonH").set_disabled(false)
	get_node("Lobby/VBoxContainer/Status/ButtonC").hide()
	get_node("Lobby/VBoxContainer/Status").hide()

# display multiplayer stuff #

func set_status(text,error,wt):
	status_text = tr(text)
	waiting = wt
	dots = 0
	get_node("Lobby/VBoxContainer/Status/Label").set_text(status_text)
	if (error):
		get_node("Lobby/VBoxContainer/Status/Label").add_color_override("font_color",Color(1.0,0.1,0.1))
	else:
		get_node("Lobby/VBoxContainer/Status/Label").add_color_override("font_color",Color(0.1,1.0,0.1))
	get_node("Lobby/VBoxContainer/Status").show()

func _display_status():
	var text = ""+status_text
	if (waiting):
		for i in range(dots):
			text += "."
	get_node("Lobby/VBoxContainer/Status/Label").set_text(text)
	dots = (dots+1)%4


func go_back():
	if (get_node("Info").is_visible()):
		get_node("Info").hide()
	elif (get_node("Singleplayer").is_visible()):
		get_node("Singleplayer").hide()
	elif (get_node("Panel").is_visible()):
		if (active):
			hide()
		else:
			quit()
	else:
		show()

func _resize():
	get_node("Deck").popup_centered(OS.get_window_size()-Vector2(50,90))
	yield(get_tree(),"idle_frame")
	get_node("Deck/ScrollContainer/GridContainer").set_columns(floor(get_node("Deck/ScrollContainer/GridContainer").get_size().x/212))
	get_node("Deck").hide()

func _input(event):
	if (event.is_action_pressed("ui_cancel")):
		go_back()
	if (event is InputEventMouseButton):
		if (event.button_index==1 && !event.pressed):
			Main.get_node("Arrow").hide()

func _notification(what):
	match what:
		MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
			quit()
		MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST:
			go_back()

func _ready():
	randomize()
	get_tree().connect("screen_resized",self,"_resize")
	set_process_input(true)
	load_config()
	load_inventory()
	get_node("Version").set_text(VERSION)
	
	# Connect buttons.
	get_node("Panel/VBoxContainer/Button5").connect("pressed",self,"hide")
	get_node("Panel/VBoxContainer/Button1").connect("pressed",self,"_skirmish")
	get_node("Panel/VBoxContainer/Button7").connect("pressed",self,"_local")
	get_node("Panel/VBoxContainer/Button9").connect("pressed",self,"_tutorial")
	get_node("Panel/VBoxContainer/Button12").connect("pressed",get_node("Singleplayer"),"show")
	get_node("Panel/VBoxContainer/Button10").connect("pressed",get_node("Lobby"),"popup_centered")
	get_node("Panel/VBoxContainer/Button2").connect("pressed",self,"_show_deck")
	get_node("Panel/VBoxContainer/Button11").connect("pressed",self,"_show_shop")
	get_node("Panel/VBoxContainer/Button3").connect("pressed",self,"_show_options")
	get_node("Panel/VBoxContainer/Button6").connect("pressed",get_node("Info"),"show")
	get_node("Panel/VBoxContainer/Button8").connect("pressed",get_node("Credits"),"popup_centered")
	get_node("Panel/VBoxContainer/Button4").connect("pressed",self,"quit")
	get_node("Quit").connect("confirmed",get_tree(),"quit")
	get_node("Deck/HBoxContainer/ButtonA").connect("pressed",self,"_change_deck")
	get_node("Deck/HBoxContainer/ButtonC").connect("pressed",get_node("Deck"),"hide")
	get_node("Deck/HBoxContainer/ButtonL").connect("pressed",self,"_show_decks")
	get_node("Deck/HBoxContainer/ButtonS").connect("pressed",self,"save_deck")
	get_node("Deck/HBoxContainer/ButtonN").connect("pressed",self,"_new_deck")
	get_node("Deck/Header/CheckBox").connect("toggled",self,"_show_deck")
	get_node("Deck/Header/Name").connect("text_changed",self,"_set_deck_name")
	get_node("Options/HBoxContainer/Button1").connect("pressed",self,"_options_accept")
	get_node("Options/HBoxContainer/Button2").connect("pressed",self,"_options_apply")
	get_node("Options/HBoxContainer/Button3").connect("pressed",get_node("Options"),"hide")
	get_node("Options/ScrollContainer/VBoxContainer/Animations").connect("toggled",self,"_set_animations")
	get_node("Options/ScrollContainer/VBoxContainer/Fullscreen").connect("toggled",self,"_set_fullscreen")
	get_node("Options/ScrollContainer/VBoxContainer/WindowSize/SpinBoxX").connect("value_changed",self,"_set_screenw")
	get_node("Options/ScrollContainer/VBoxContainer/WindowSize/SpinBoxY").connect("value_changed",self,"_set_screenh")
	get_node("Options/ScrollContainer/VBoxContainer/Audio/Music").connect("toggled",self,"_set_music")
	get_node("Options/ScrollContainer/VBoxContainer/Volume/SpinBoxM").connect("value_changed",self,"_set_music_volume")
	get_node("Options/ScrollContainer/VBoxContainer/Audio/Sound").connect("toggled",self,"_set_sound")
	get_node("Options/ScrollContainer/VBoxContainer/Volume/SpinBoxS").connect("value_changed",self,"_set_sound_volume")
	get_node("Options/ScrollContainer/VBoxContainer/Locale/OptionButton").connect("item_selected",self,"_set_locale")
	get_node("Lobby/VBoxContainer/Buttons/ButtonH").connect("pressed",self,"_host")
	get_node("Lobby/VBoxContainer/Buttons/ButtonJ").connect("pressed",self,"_join")
	get_node("Lobby/VBoxContainer/Status/ButtonC").connect("pressed",self,"cancel_mp")
	get_node("Acquired/HBoxContainer/Button1").connect("pressed",self,"_show_shop")
	get_node("Acquired/HBoxContainer/Button2").connect("pressed",get_node("Acquired"),"hide")
	get_node("Deck/ButtonClose").connect("pressed",get_node("Deck"),"hide")
	get_node("Deck/Decks/ButtonClose").connect("pressed",get_node("Deck/Decks"),"hide")
	get_node("Shop/ButtonClose").connect("pressed",get_node("Shop"),"hide")
	get_node("Acquired/ButtonClose").connect("pressed",get_node("Acquired"),"hide")
	get_node("Options/ButtonClose").connect("pressed",get_node("Options"),"hide")
	get_node("Lobby/ButtonClose").connect("pressed",get_node("Lobby"),"hide")
	get_node("Info/ButtonClose").connect("pressed",get_node("Info"),"hide")
	get_node("Credits/ButtonClose").connect("pressed",get_node("Credits"),"hide")
	get_node("GameOver/ButtonClose").connect("pressed",get_node("GameOver"),"hide")
	get_node("Quit/ButtonClose").connect("pressed",get_node("Quit"),"hide")
	get_node("Quit/ButtonClose").set_position(Vector2(28,-48))
	get_node("Quit/ButtonClose").set_size(Vector2(48,48))
	get_node("GameOver/ButtonClose").set_position(Vector2(28,-48))
	get_node("GameOver/ButtonClose").set_size(Vector2(48,48))
	get_node("Singleplayer/VBoxContainer/Button1").connect("pressed",self,"_tutorial")
	get_node("Singleplayer/VBoxContainer/Button2").connect("pressed",self,"_skirmish")
	get_node("Singleplayer/VBoxContainer/Button3").connect("pressed",self,"_local")
	get_node("Singleplayer/VBoxContainer/Button4").connect("pressed",get_node("Singleplayer"),"hide")
	
	# Set up card pack buttons.
	for grade in range(3):
		for type in range(4):
			get_node("Shop/VBoxContainer/Grade"+str(grade+1)+"/Button"+str(type+1)).connect("pressed",self,"_buy_pack",[grade,Cards.CARD_PACK_PRICE[grade].keys()[type]])
			get_node("Shop/VBoxContainer/Grade"+str(grade+1)+"/Button"+str(type+1)+"/Cost").set_text(tr("PRICE")+": "+str(Cards.CARD_PACK_PRICE[grade].values()[type])+" "+tr("GOLD"))
	
	# Add available options to the language option button.
	for i in range(LOCALES.size()):
		get_node("Options/ScrollContainer/VBoxContainer/Locale/OptionButton").add_item(LOCALES[i],i)
	
	# Add tooltips.
	get_node("Panel/VBoxContainer/Button1").set_tooltip(tr("SKIRMISH_DESC"))
	get_node("Panel/VBoxContainer/Button7").set_tooltip(tr("LOCAL_DESC"))
	get_node("Panel/VBoxContainer/Button9").set_tooltip(tr("TUTORIAL_DESC"))
	get_node("Panel/VBoxContainer/Button10").set_tooltip(tr("MULTIPLAYER_DESC"))
	get_node("Panel/VBoxContainer/Button2").set_tooltip(tr("DECK_DESC"))
	get_node("Panel/VBoxContainer/Button11").set_tooltip(tr("SHOP_DESC"))
	
	# Connect the callbacks related to networking.
	get_tree().connect("network_peer_disconnected",self,"_player_disconnected")
	get_tree().connect("server_disconnected",self,"_server_disconnected")
	get_tree().connect("connected_to_server",self,"_connected_ok")
	get_tree().connect("connection_failed",self,"_connected_fail")
	
	var timer = Timer.new()
	timer.set_wait_time(0.5)
	add_child(timer)
	timer.connect("timeout",self,"_display_status")
	timer.start()
	if (OS.has_feature("web")):
		get_node("Panel/VBoxContainer/Button4").hide()
	
	# Set up info text.
#	get_node("Info/Text").push_align(RichTextLabel.ALIGN_FILL)		# extreme stretching with half-filled lines
	get_node("Info/Text").push_color(Color(0.0,0.0,0.0))
	for s in ["HELP_INTRO","HELP_1","HELP_2","HELP_3","HELP_4","HELP_5"]:
		var array = tr(s).split("_")
		for st in array:
			if (st=="creature" || st=="creatures"):
				get_node("Info/Text").push_color(Cards.COLOR_CREATURE)
			elif (st=="spell"):
				get_node("Info/Text").push_color(Cards.COLOR_SPELL)
			elif (st=="health"):
				get_node("Info/Text").push_color(Cards.COLOR_HEALTH)
			elif (st=="mana"):
				get_node("Info/Text").push_color(Cards.COLOR_MANA)
			elif (st=="temperature"):
				get_node("Info/Text").push_color(Cards.COLOR_COLD.linear_interpolate(Cards.COLOR_HOT,0.5))
			get_node("Info/Text").add_text(st)
			get_node("Info/Text").push_color(Color(0.0,0.0,0.0))
		get_node("Info/Text").add_text("\n\n")
	get_node("Info/Text").add_text(tr("CONTROLS")+":\n"+tr("HELP_6"))
	
	# Set up credit text.
	get_node("Credits/Text").push_color(Color(0.0,0.0,0.0))
	get_node("Credits/Text").add_text(tr("ENGINE")+":\n Godot (")
	get_node("Credits/Text").append_bbcode("[url=https://godotengine.org/]godotengine.org/[/url]")
	get_node("Credits/Text").add_text(")\n\n"+tr("PROGRAMMING")+":\n - Viktor Hahn\n\n")
	get_node("Credits/Text").add_text(tr("GRAPHICS")+":\n - Justin Nichol\n - Katarzyna Zalecka (")
	get_node("Credits/Text").append_bbcode("[url=http://kasia88.deviantart.com]kasia88.deviantart.com[/url]")
	get_node("Credits/Text").add_text("), Gabriel Verdon (")
	get_node("Credits/Text").append_bbcode("[url=http://www.gabrielverdon.com]www.gabrielverdon.com[/url]")
	get_node("Credits/Text").add_text(") ")
	get_node("Credits/Text").append_bbcode("[url=http://www.AncientBeast.com]www.AncientBeast.com[/url]\n")
	get_node("Credits/Text").add_text(" - p0ss\n")
	get_node("Credits/Text").add_text(" - Viktor Hahn\n\n")
	get_node("Credits/Text").add_text(tr("MUSIC")+":\n - Viktor Hahn\n\n")
	get_node("Credits/Text").add_text(tr("SOUNDS")+":\n - Iwan 'qubodup' Gabovitch (")
	get_node("Credits/Text").append_bbcode("[url=http://qubodup.net]qubodup.net[/url])\n")
	get_node("Credits/Text").add_text(" - ViRiX Dreamcore (David Mckee) (")
	get_node("Credits/Text").append_bbcode("[url=http://www.soundcloud.com/virix]www.soundcloud.com[/url])\n")
	get_node("Credits/Text").add_text(" - p0ss\n - Bart K.\n - artisticdude\n - Blender Foundation\n - artisticdude\n - HaelDB\n - Ylmir\n - Aleks41\n\n")
	get_node("Credits/Text").add_text(tr("FONT")+":\n - Jonas Hecksher")
	get_node("Credits/Text").connect("meta_clicked",OS,"shell_open")
	
	yield(get_tree(),"idle_frame")
	get_node("Deck").hide()
