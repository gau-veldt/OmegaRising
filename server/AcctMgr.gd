
extends Control

onready var server=get_node("/root/Server")
onready var persist=get_node("/root/persist")

onready var scroll=get_node("select")
onready var newAcct=get_node("newAccount")
onready var delAcct=get_node("delAccount")
onready var view=get_node("acctView")
onready var edtUser=get_node("acctView/edit_user")
onready var edtHandle=get_node("acctView/edit_handle")
onready var edtEmail=get_node("acctView/edit_email")
onready var edtPass1=get_node("acctView/edit_pass1")
onready var edtPass2=get_node("acctView/edit_pass2")
onready var edtIP=get_node("acctView/edit_IP")
onready var passBtn=get_node("acctView/chgPass")
onready var userBtn=get_node("acctView/chgUser")
onready var emailBtn=get_node("acctView/chgEmail")
onready var emailVfyBtn=get_node("acctView/chgEmailVfy")
onready var acctID=get_node("acctView/txt_acctID")
onready var ipWList=get_node("acctView/ip_wlist_area/ip_wlist")
onready var ipWLadd=get_node("acctView/wlistAdd")

var init_sel=false

func validateEmail(eml):
	pass

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

func onChangePass():
	var p1=edtPass1.get_text()
	var p2=edtPass2.get_text()
	var sel=int(scroll.get_value())
	var idx=persist.index_bytype['Account']
	var ob=idx.get_child(sel)
	if p1==p2:
		var pw_hash=(server.serverSalt+p1).sha256_text()
		ob.write("password",pw_hash)
		edtPass1.set_text("")
		edtPass2.set_text("")
		validatePassword("")

func onChangeEmail():
	var sel=int(scroll.get_value())
	var idx=persist.index_bytype['Account']
	var ob=idx.get_child(sel)
	ob.write("email",edtEmail.get_text())

func onChangeEmailVfy(vfy):
	var sel=int(scroll.get_value())
	var idx=persist.index_bytype['Account']
	var ob=idx.get_child(sel)
	if vfy:
		emailVfyBtn.set_text("Unverified")
		emailVfyBtn.set("custom_colors/font_color",Color("ff8080"))
		emailVfyBtn.set("custom_colors/font_color_pressed",Color("ff8080"))
		emailVfyBtn.set("custom_colors/font_color_hover",Color("ff8080"))
		ob.write("email_vfy",false)
	else:
		emailVfyBtn.set_text("Verified")
		emailVfyBtn.set("custom_colors/font_color",Color("80ff80"))
		emailVfyBtn.set("custom_colors/font_color_pressed",Color("80ff80"))
		emailVfyBtn.set("custom_colors/font_color_hover",Color("80ff80"))
		ob.write("email_vfy",true)

func onWLDelete():
	var index=persist.index_bytype['Account']
	var count=index.get_children().size()
	var val=scroll.get_value()
	var ob=index.get_child(val)
	var allowed=ob.read("allowed_ip")
	var ip=""
	var gone=ipWList.get_selected_items()
	if gone.size()>0:
		ip=ipWList.get_item_text(gone[0])
		allowed.erase(ip)
		ob.write("allowed_ip",allowed)
	ipWList.remove_item(gone[0])
	validateWLIP(edtIP.get_text())

func onWLAdd():
	var index=persist.index_bytype['Account']
	var count=index.get_children().size()
	var val=scroll.get_value()
	var ob=index.get_child(val)
	var allowed=ob.read("allowed_ip")
	var ip=edtIP.get_text()
	allowed.append(ip)
	ob.write("allowed_ip",allowed)
	ipWList.add_item(ip,null,true)
	validateWLIP(ip)

func validateWLIP(txt):
	var ts=txt.split(".")
	var bad=true
	if ts.size()==4:
		var num
		bad=false
		for each in ts:
			if !each.is_valid_integer():
				bad=true
			else:
				num=int(each)
				if num<0 or num>255:
					bad=true
	ipWLadd.set_text("Add")
	if (!bad):
		var fixup="%s.%s.%s.%s" % [int(ts[0]),int(ts[1]),int(ts[2]),int(ts[3])]
		if fixup!=txt:
			txt=fixup
			edtIP.set_text(txt)
		for idx in range(ipWList.get_item_count()):
			if ipWList.get_item_text(idx)==txt:
				# don't allow duplicates
				bad=true
				ipWList.select(idx)
				ipWList.ensure_current_is_visible()
				ipWLadd.set_text("Dup")
	ipWLadd.set_disabled(bad)

func onSelectAcct(sel):
	var index=persist.index_bytype['Account']
	var ob=index.get_child(sel)
	var uuid=ob.get_name()
	var email_vfy=ob.read("email_vfy")
	edtUser.set_text(ob.read("username"))
	edtHandle.set_text(ob.read("handle"))
	edtEmail.set_text(ob.read("email"))
	acctID.set_text(uuid)
	var allowed=ob.read("allowed_ip")
	ipWList.clear()
	ipWList.set_max_columns(1)
	ipWList.set_size(ipWList.get_parent().get_size())
	for each in allowed:
		ipWList.add_item(each,null,true)
	if email_vfy==true:
		emailVfyBtn.set_pressed(true)
		emailVfyBtn.set_text("Verified")
		emailVfyBtn.set("custom_colors/font_color",Color("80ff80"))
		emailVfyBtn.set("custom_colors/font_color_pressed",Color("80ff80"))
		emailVfyBtn.set("custom_colors/font_color_hover",Color("80ff80"))
	else:
		emailVfyBtn.set_pressed(false)
		emailVfyBtn.set_text("Unverified")
		emailVfyBtn.set("custom_colors/font_color",Color("ff8080"))
		emailVfyBtn.set("custom_colors/font_color_pressed",Color("ff8080"))
		emailVfyBtn.set("custom_colors/font_color_hover",Color("ff8080"))
	validatePassword("")
	validateUser("")
	validateWLIP(edtIP.get_text())

func onCreateAcct():
	var index=persist.index_bytype['Account']
	var ob=persist.spawn("Account")
	var val=ob.get_index()
	refresh(index)
	scroll.set_value(val)
	onSelectAcct(val)

func onDeleteAcct():
	var index=persist.index_bytype['Account']
	var count=index.get_children().size()
	var val=scroll.get_value()
	var ob=index.get_child(val)
	if (1+val)<scroll.get_max():
		val+=1
		scroll.set_value(val)
		onSelectAcct(val)
	else:
		if (val>0):
			val-=1
			scroll.set_value(val)
			onSelectAcct(val)
	if count==1:
		# flag need to reset selection on next create
		# when deleting the last account in the system
		init_sel=false
	persist.nuke(ob)
	call_deferred("refresh",index)

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
			onSelectAcct(0)
		validateUser("")
	else:
		scroll.set_hidden(true)
		delAcct.set_hidden(true)
		view.set_hidden(true)

func _ready():
	pass
