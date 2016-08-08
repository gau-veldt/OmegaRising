
extends Control

onready var scroll=get_node("select")
onready var newAcct=get_node("newAccount")
onready var delAcct=get_node("delAccount")
onready var persist=get_node("/root/persist")
onready var view=get_node("acctView")
onready var edtUser=get_node("acctView/edit_user")
onready var edtHandle=get_node("acctView/edit_handle")
onready var edtPass1=get_node("acctView/edit_pass1")
onready var edtPass2=get_node("acctView/edit_pass2")
onready var passBtn=get_node("acctView/chgPass")
onready var userBtn=get_node("acctView/chgUser")
onready var acctID=get_node("acctView/txt_acctID")

var init_sel=false

func validatePassword(txt):
	var t1=edtPass1.get_text()
	var t2=edtPass2.get_text()
	if (t2==t1):
		if t1.length()>8:
			passBtn.set_text("Change Password")
			passBtn.set_disabled(false)
		else:
			passBtn.set_text("Too short.")
			passBtn.set_disabled(true)
	else:
		passBtn.set_text("Don't match.")
		passBtn.set_disabled(true)

func validateUser(edtText):
	var sel=int(scroll.get_value())
	var idx=persist.index_bytype['Account']
	var ob=idx.get_child(sel)
	var ok=true
	var usr=edtUser.get_text()
	for acct in idx.get_children():
		if acct!=ob and acct.read("username")==usr:
			ok=false
	if ok:
		userBtn.set_text("Change User/Handle")
		userBtn.set_disabled(false)
	else:
		userBtn.set_text("User exists.")
		userBtn.set_disabled(true)
		return
	var hdl=edtHandle.get_text()
	if hdl==usr:
		userBtn.set_text("Username == Handle")
		userBtn.set_disabled(true)
		return
	ok=true
	for acct in idx.get_children():
		if acct!=ob and acct.read("handle")==hdl:
			ok=false
	if ok:
		userBtn.set_text("Change User/Handle")
		userBtn.set_disabled(false)
	else:
		userBtn.set_text("Handle exists.")
		userBtn.set_disabled(true)

func onChangeName():
	var user=edtUser.get_text()
	var hndl=edtHandle.get_text()
	var sel=int(scroll.get_value())
	var idx=persist.index_bytype['Account']
	var ob=idx.get_child(sel)
	ob.write("username",user)
	ob.write("handle",hndl)

func onSelectAcct(sel):
	var index=persist.index_bytype['Account']
	var ob=index.get_child(sel)
	var uuid=ob.get_name()
	edtUser.set_text(ob.read("username"))
	edtHandle.set_text(ob.read("handle"))
	acctID.set_text(uuid)
	validatePassword("")
	validateUser("")

func onCreateAcct():
	var ob=persist.spawn("Account")
	var val=ob.get_index()

func onDeleteAcct():
	var index=persist.index_bytype['Account']
	var val=scroll.get_value()
	var ob=index.get_child(val)
	persist.nuke(ob)

func refresh(acctRoot):
	var total=acctRoot.get_children().size()
	if total>0:
		scroll.set_hidden(false)
		delAcct.set_hidden(false)
		view.set_hidden(false)
		scroll.set_min(0)
		scroll.set_max(total)
		scroll.set_step(1)
		scroll.set_page(1)
		scroll.set_value(max(0,min(scroll.get_value(),total-1)))
		if !init_sel:
			init_sel=true
			scroll.set_value(0)
		validateUser("")
	else:
		scroll.set_hidden(true)
		delAcct.set_hidden(true)
		view.set_hidden(true)

func _ready():
	pass
