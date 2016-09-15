
extends Panel

signal DoLogin(username,password)

onready var client=get_node("/root/Peer")
onready var edtUser=get_node("./user")
onready var edtPass=get_node("./pass")
onready var btnLogin=get_node("./login")
onready var txtVer=get_node("./txt_ver")

var pass_ok=false
var user_ok=false
var nologin=false

func nologin(st):
	nologin=st

func defaultUser(user):
	edtUser.set_text(user)
	edtPass.grab_focus()
	validateUser(user)

func validatePassword(txt):
	pass_ok=false
	if txt.length()>8:
		pass_ok=true

func validateUser(txt):
	user_ok=false
	if txt.length()>=1:
		user_ok=true

func _process(delta):
	btnLogin.set_disabled(!pass_ok or !user_ok or nologin)

func onEnter(txt):
	if !btnLogin.is_disabled():
		doLogin()

func doLogin():
	emit_signal("DoLogin",edtUser.get_text(),edtPass.get_text())

func _ready():
	var ver=client.client_version()['string']
	txtVer.set_text("Omega Rising client (Version %s)" % ver)
	edtUser.grab_focus()
	validatePassword("")
	validateUser("")
	set_process(true)

