extends Panel

onready var client=get_node("/root/Peer")
onready var userAcct=client.userAcct
onready var menus=get_node("menu")
onready var btnPlay=menus.get_node("Play")
onready var selChar=menus.get_node("CharacterSelect")
onready var btnCreate=menus.get_node("Create")
onready var btnAccount=menus.get_node("Account")
onready var btnClient=menus.get_node("Client")
onready var btnQuit=menus.get_node("Quit")

var dlgCreate=load("CreateChar.tscn")
var dlgAccount=load("AccountOpts.tscn")
var dlgClient=load("ClientOpts.tscn")

var useChar=""

func _process(delta):
	useChar=selChar.get_text()
	btnPlay.set_disabled(useChar=="")

func onQuit():
	client.ui_sound('choice')
	client.emit_quit()
func onQuitting():
	hide()
	queue_free()

func _ready():
	client.connect("Quitting",self,"onQuitting")
	btnQuit.connect("pressed",self,"onQuit")
	btnCreate.connect("pressed",self,"onCreateCharacter")
	btnAccount.connect("pressed",self,"onAccountSettings")
	btnClient.connect("pressed",self,"onClientSettings")
	btnPlay.connect("pressed",self,"onEnterGame")
	userAcct.connect("CharacterListChanged",self,"onUpdateCharList")
	userAcct.get_character_list()
	set_process(true)

var selList=[]
func onUpdateCharList(chars):
	print("available characters: ",chars)
	selChar.clear()
	selList.clear()
	var id=0
	for char in chars:
		selChar.add_item(char,id)
		selList.append(char)
		id+=1

func onCreateCharacter():
	client.ui_sound('choice')
	var dlg=dlgCreate.instance()
	get_parent().add_child(dlg)

func onAccountSettings():
	client.ui_sound('choice')
	var dlg=dlgAccount.instance()
	get_parent().add_child(dlg)

func onClientSettings():
	client.ui_sound('choice')
	var dlg=dlgClient.instance()
	get_parent().add_child(dlg)


var gwFactory=load("GameWorld.tscn")
func onEnterGame():
	var charName=selChar.get_text()
	if charName!="":
		client.candy.hide()
		hide()
		var gw=gwFactory.instance()
		gw.set_name("session: %s" % charName)
		gw.main_menu=self
		gw.who=charName
		client.add_child(gw)
		var tgt=userAcct.joinCharacter(charName)
		gw.call_deferred("changeTarget",tgt)

