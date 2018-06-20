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

var deck = DEFAULT.duplicate()
var _deck
var active = false


func _skirmish():
	# Start a match vs the AI.
	Main.reset()
	Main.deck[0] = get_deck()
	Main.deck[1] = get_deck(DEFAULT)
	Main.ai = true
	Main.start()
	UI._show()
	_hide()
	active = true
	get_node("Panel/VBoxContainer/Button5").show()

func _local():
	# Start a match without AI.
	Main.reset()
	Main.deck[0] = get_deck()
	Main.deck[1] = get_deck()
	Main.ai = false
	Main.start()
	UI._show()
	_hide()
	active = true
	get_node("Panel/VBoxContainer/Button5").show()


func game_over(victory):
	# Show victory/game over message.
	get_node("Panel/VBoxContainer/Button5").hide()
	active = false
	if (victory):
		get_node("GameOver").set_title(tr("VICTORY"))
		get_node("GameOver/Text").set_text(tr("YOU_WIN"))
	else:
		get_node("GameOver").set_title(tr("GAME_OVER"))
		get_node("GameOver/Text").set_text(tr("YOU_LOST"))
	get_node("GameOver").popup_centered()
	Music.temperature = 0


func _hide():
	for c in get_children():
		c.hide()

func _show():
	get_node("Panel").show()

func quit():
	if (get_node("Quit").is_visible()):
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


func _resize():
	get_node("Deck").show()
	yield(get_tree(),"idle_frame")
	get_node("Deck/ScrollContainer/GridContainer").set_columns(floor(get_node("Deck/ScrollContainer/GridContainer").get_size().x/212))
	get_node("Deck").hide()

func _input(event):
	if (event.is_action_pressed("ui_cancel")):
		if (get_node("Panel").is_visible()):
			if (active):
				_hide()
			else:
				quit()
		else:
			_show()

func _ready():
	randomize()
	get_tree().connect("screen_resized",self,"_resize")
	set_process_input(true)
	OS.set_window_maximized(true)
	load_deck()
	
	# connect buttons
	get_node("Panel/VBoxContainer/Button1").connect("pressed",self,"_skirmish")
	get_node("Panel/VBoxContainer/Button7").connect("pressed",self,"_local")
	get_node("Panel/VBoxContainer/Button2").connect("pressed",self,"_show_deck")
	get_node("Panel/VBoxContainer/Button5").connect("pressed",self,"_hide")
	get_node("Panel/VBoxContainer/Button6").connect("pressed",get_node("Info"),"popup_centered")
	get_node("Panel/VBoxContainer/Button4").connect("pressed",self,"quit")
	get_node("Quit").connect("confirmed",get_tree(),"quit")
	get_node("Deck/HBoxContainer/ButtonA").connect("pressed",self,"_change_deck")
	get_node("Deck/HBoxContainer/ButtonR").connect("pressed",self,"_reset_deck")
	get_node("Deck/HBoxContainer/ButtonC").connect("pressed",get_node("Deck"),"hide")
	
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
