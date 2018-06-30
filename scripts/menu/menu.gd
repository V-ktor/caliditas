extends Node

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
const MAX_MULT = 3
const MAX_CARDS = 40
const locales = ["en"]

var deck = DEFAULT.duplicate()
var _deck
var gold = 100
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

var tut_scene = preload("res://scenes/main/tutorial.tscn")


func _skirmish():
	# Start a match vs the AI.
	Main.reset()
	Main.deck[0] = get_deck()
	Main.deck[1] = get_deck(DEFAULT)
	Main.player_name[0] = _name
	Main.player_name[1] = tr("AI_SKIRMISH")
	Main.ai = true
	Main.start()
	reward = 100
	UI.show()
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
	Main.start()
	reward = 0
	UI.show()
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
	reward = 50
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
	Main.start()
	reward = 250
	UI.show()
	hide()
	active = true
	get_node("Panel/VBoxContainer/Button5").show()
	if (has_node("/root/Tutorial")):
		get_node("/root/Tutorial").queue_free()
	get_node("Lobby/VBoxContainer/Buttons/ButtonJ").set_disabled(false)
	get_node("Lobby/VBoxContainer/Buttons/ButtonH").set_disabled(false)
	get_node("Lobby/VBoxContainer/Status/ButtonC").hide()
	set_status("CONNECTED",false,false)
#	get_node("Lobby/VBoxContainer/Status").hide()


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
	else:
		yield(get_tree(),"idle_frame")
		get_node("Quit").popup_centered()

func _show_deck():
	var num_cards
	if (_deck==null):
		_deck = deck.duplicate()
	num_cards = get_num_cards(_deck)
	for i in range(Cards.data.size()):
		var bi
		var type = Cards.data.keys()[i]
		var ammount = 0
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
		if (deck.has(type)):
			ammount = _deck[type]
			bi.get_node("ButtonAdd").set_disabled(ammount>=MAX_MULT || num_cards>=MAX_CARDS)
			bi.get_node("ButtonSub").set_disabled(false)
		else:
			bi.get_node("ButtonAdd").set_disabled(num_cards>=MAX_CARDS)
			bi.get_node("ButtonSub").set_disabled(true)
		bi.get_node("Label").set_text(str(ammount)+" / "+str(MAX_MULT))
		bi.show()
	
	get_node("Deck/Label").set_text(str(get_num_cards(_deck))+" / "+str(MAX_CARDS))
	get_node("Deck").show()

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
	get_node("Options").show()

func add_card(ID):
	var type = Cards.data.keys()[ID]
	if (get_num_cards(_deck)>=MAX_CARDS || (_deck.has(type) && _deck[type]>=MAX_MULT)):
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


func _change_deck():
	deck = _deck
	_deck = null
	save_deck()
	get_node("Deck").hide()

func _reset_deck():
	deck = DEFAULT
	_deck = null
	save_deck()
	_show_deck()

func load_deck():
	var file = File.new()
	var currentline
	file.open("user://deck.cfg",File.READ)
	currentline = JSON.parse(file.get_line()).get_result()
	file.close()
	if (currentline==null):
		return
	
	deck = currentline

func save_deck():
	var file = File.new()
	var dir = Directory.new()
	if (!dir.dir_exists("user://")):
		dir.make_dir_recursive("user://")
	
	file.open("user://deck.cfg",File.WRITE)
	file.store_line(JSON.print(deck))
	file.close()


# config stuff

func save_config():
	var file = ConfigFile.new()
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
	file.save("user://config.cfg")

func load_config():
	var file = ConfigFile.new()
	var default_locale = OS.get_locale()
	if !(default_locale in locales):
		default_locale = default_locale.split("_")[0]
		if !(default_locale in locales):
			default_locale = "en"
	file.load("user://config.cfg")
	fullscreen = file.get_value("video","fullscreen",false)
	maximized = file.get_value("video","maximized",true)
	screen_size = Vector2(file.get_value("video","screenw",1024),file.get_value("video","screenh",768))
	music = file.get_value("audio","music",true)
	music_volume = file.get_value("audio","music_volume",100)
	sound = file.get_value("audio","sound",true)
	sound_volume = file.get_value("audio","sound_volume",100)
	locale = file.get_value("locale","locale",default_locale)
	_name = file.get_value("player","name",tr("PLAYER"))
	if (_name!="" && _name!=tr("PLAYER")):
		get_node("Options/ScrollContainer/VBoxContainer/Name/Name").set_text(_name)
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


func _resize():
	get_node("Deck").show()
	yield(get_tree(),"idle_frame")
	get_node("Deck/ScrollContainer/GridContainer").set_columns(floor(get_node("Deck/ScrollContainer/GridContainer").get_size().x/212))
	get_node("Deck").hide()

func _input(event):
	if (event.is_action_pressed("ui_cancel")):
		if (get_node("Panel").is_visible()):
			if (active):
				hide()
			else:
				quit()
		else:
			show()

func _ready():
	randomize()
	get_tree().connect("screen_resized",self,"_resize")
	set_process_input(true)
	load_config()
	load_deck()
	
	# connect buttons
	get_node("Panel/VBoxContainer/Button1").connect("pressed",self,"_skirmish")
	get_node("Panel/VBoxContainer/Button7").connect("pressed",self,"_local")
	get_node("Panel/VBoxContainer/Button9").connect("pressed",self,"_tutorial")
	get_node("Panel/VBoxContainer/Button10").connect("pressed",get_node("Lobby"),"popup_centered")
	get_node("Panel/VBoxContainer/Button2").connect("pressed",self,"_show_deck")
	get_node("Panel/VBoxContainer/Button5").connect("pressed",self,"hide")
	get_node("Panel/VBoxContainer/Button3").connect("pressed",self,"_show_options")
	get_node("Panel/VBoxContainer/Button6").connect("pressed",get_node("Info"),"popup_centered")
	get_node("Panel/VBoxContainer/Button8").connect("pressed",get_node("Credits"),"popup_centered")
	get_node("Panel/VBoxContainer/Button4").connect("pressed",self,"quit")
	get_node("Quit").connect("confirmed",get_tree(),"quit")
	get_node("Deck/HBoxContainer/ButtonA").connect("pressed",self,"_change_deck")
	get_node("Deck/HBoxContainer/ButtonR").connect("pressed",self,"_reset_deck")
	get_node("Deck/HBoxContainer/ButtonC").connect("pressed",get_node("Deck"),"hide")
	get_node("Options/HBoxContainer/Button1").connect("pressed",self,"_options_accept")
	get_node("Options/HBoxContainer/Button2").connect("pressed",self,"_options_apply")
	get_node("Options/HBoxContainer/Button3").connect("pressed",get_node("Options"),"hide")
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
	
	for i in range(locales.size()):
		get_node("Options/ScrollContainer/VBoxContainer/Locale/OptionButton").add_item(locales[i],i)
	get_node("Panel/VBoxContainer/Button1").set_tooltip(tr("SKIRMISH_DESC"))
	get_node("Panel/VBoxContainer/Button2").set_tooltip(tr("DECK_DESC"))
	get_node("Panel/VBoxContainer/Button7").set_tooltip(tr("LOCAL_DESC"))
	get_node("Panel/VBoxContainer/Button9").set_tooltip(tr("TUTORIAL_DESC"))
	get_node("Panel/VBoxContainer/Button10").set_tooltip(tr("MULTIPLAYER_DESC"))
	
	# connect the callbacks related to networking
	get_tree().connect("network_peer_disconnected",self,"_player_disconnected")
	get_tree().connect("server_disconnected",self,"_server_disconnected")
	get_tree().connect("connected_to_server",self,"_connected_ok")
	get_tree().connect("connection_failed",self,"_connected_fail")
	
	var timer = Timer.new()
	timer.set_wait_time(0.5)
	add_child(timer)
	timer.connect("timeout",self,"_display_status")
	timer.start()
	
	# set up info text
#	get_node("Info/Text").push_align(RichTextLabel.ALIGN_FILL)		# extreme stretching with half-filled lines
	for s in ["HELP_INTRO","HELP_1","HELP_2","HELP_3","HELP_4","HELP_5"]:
		var array = tr(s).split("_")
		for st in array:
			if (st=="creature"):
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
			get_node("Info/Text").push_color(Color(1.0,1.0,1.0))
		get_node("Info/Text").add_text("\n\n")
	get_node("Info/Text").add_text(tr("CONTROLS")+":\n"+tr("HELP_6"))
	
	get_node("Credits/Text").add_text(tr("ENGINE")+":\n Godot (")
	get_node("Credits/Text").append_bbcode("[url=https://godotengine.org/]godotengine.org/[/url]")
	get_node("Credits/Text").add_text(")\n\n"+tr("PROGRAMMING")+":\n - Viktor Hahn\n\n")
	get_node("Credits/Text").add_text(tr("GRAPHICS")+":\n - Justin Nichol\n - Katarzyna Zalecka (")
	get_node("Credits/Text").append_bbcode("[url=http://kasia88.deviantart.com]kasia88.deviantart.com[/url]")
	get_node("Credits/Text").add_text("), Gabriel Verdon (")
	get_node("Credits/Text").append_bbcode("[url=http://www.gabrielverdon.com]www.gabrielverdon.com[/url]")
	get_node("Credits/Text").add_text(") ")
	get_node("Credits/Text").append_bbcode("[url=http://www.AncientBeast.com]www.AncientBeast.com[/url]\n")
	get_node("Credits/Text").add_text(" - Viktor Hahn\n\n")
	get_node("Credits/Text").add_text(tr("MUSIC")+":\n - Viktor Hahn\n\n")
	get_node("Credits/Text").add_text(tr("SOUNDS")+":\n - Iwan 'qubodup' Gabovitch (")
	get_node("Credits/Text").append_bbcode("[url=http://qubodup.net]qubodup.net[/url])\n")
	get_node("Credits/Text").add_text(" - Michel Baradari (")
	get_node("Credits/Text").append_bbcode("[url=http://apollo-music.de]apollo-music.de[/url])\n")
	get_node("Credits/Text").add_text(" - p0ss\n - Bart K.\n - artisticdude\n - Blender Foundation\n - artisticdude\n - HaelDB\n - Ylmir\n")
	get_node("Credits/Text").connect("meta_clicked",OS,"shell_open")
