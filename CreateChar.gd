extends Panel

onready var client=get_node("/root/Peer")
onready var userAcct=client.userAcct
onready var template=userAcct.template
onready var createList=get_node("scroll/list")
onready var modelCtl=get_node("model/frame")
onready var turnCW=modelCtl.get_node("cw")
onready var turnCCW=modelCtl.get_node("ccw")
onready var modelRoot=modelCtl.get_node("chroot")
onready var modelView=modelRoot.get_node("viewer")
onready var model=modelView.get_node("character")
onready var cam=modelView.get_node("Camera")

func onQuitting():
	hide()
	queue_free()

var chrControls={}
var btnCreateMe
var btnCancel
func _ready():
	client.connect("Quitting",self,"onQuitting")
	var ob
	var props
	var type
	var hint
	for name in template['Attributes']:
		props=template['Attributes'][name]
		type=props['type']
		hint=""
		if type=='ChooseOne': hint=" (One Only)"
		if type=='ChooseMulti': hint=" (Any Combination)"
		ob=Label.new()
		ob.set_text("\n%s%s" % [name,hint])
		createList.add_child(ob)
		if type=='String':
			ob=LineEdit.new()
			ob.set_custom_minimum_size(Vector2(500,24))
			ob.set_name(name)
			chrControls[name]=ob
			createList.add_child(ob)
		if type=='IntRange':
			ob=HSlider.new()
			ob.set_name(name)
			ob.set_custom_minimum_size(Vector2(500,24))
			ob.set_step(1.0)
			ob.set_min(float(props['min']))
			ob.set_max(float(props['max']))
			var mid=int((props['min']+props['max'])/2)
			ob.set_value(mid)
			chrControls[name]=ob
			createList.add_child(ob)
		if type=='FloatRange':
			ob=HSlider.new()
			ob.set_name(name)
			ob.set_custom_minimum_size(Vector2(500,24))
			ob.set_step(0.001)
			ob.set_min(float(props['min']))
			ob.set_max(float(props['max']))
			var mid=float((props['min']+props['max'])/2.0)
			ob.set_value(mid)
			chrControls[name]=ob
			createList.add_child(ob)
		if type in ['ChooseOne','ChooseMulti']:
			if type=='ChooseOne': ob=OptionButton.new()
			if type=='ChooseMulti':
				ob=ItemList.new()
				ob.set_max_columns(1)
				ob.set_select_mode(ItemList.SELECT_MULTI)
			ob.set_name(name)
			var txt
			var idx=0
			var size=24
			for opt in props['options']:
				if opt.has('always'):
					if type=='ChooseOne': ob.add_item(opt['always'],idx)
					else: ob.add_item(opt['always'])
					idx+=1
				if opt.has('Include'):
					for txt in opt['Include']:
						if type=='ChooseOne': ob.add_item(txt,idx)
						else: ob.add_item(txt)
						idx+=1
				if opt.has('Exclude'):
					for txt in opt['Exclude']:
						if type=='ChooseOne': ob.add_item(txt,idx)
						else: ob.add_item(txt)
						idx+=1
			if type=='ChooseMulti': size=max(24,24*ob.get_item_count())
			ob.set_custom_minimum_size(Vector2(500,size))
			chrControls[name]=ob
			createList.add_child(ob)
				
	ob=Label.new()
	ob.set_text("\n")
	createList.add_child(ob)
	btnCreateMe=Button.new()
	btnCreateMe.set_name("@DoCreate@")
	btnCreateMe.set_text("Create Character")
	createList.add_child(btnCreateMe)
	btnCancel=Button.new()
	btnCancel.set_name("@Cancel@")
	btnCancel.set_text("Cancel")
	createList.add_child(btnCancel)
	set_fixed_process(true)
	set_process(true)

func _process(delta):
	var props
	var type
	var opts
	var good=-1
	var bad=false
	for name in template['Attributes']:
		props=template['Attributes'][name]
		type=props['type']
		if type in ["ChooseOne","ChooseMulti"]:
			opts=props['options']
			var idx=0
			for opt in opts:
				if opt.has('always'):
					chrControls[name].set_item_disabled(idx,false)
					if good<0: good=idx
					idx+=1
				else:
					var ok=false
					if opt.has('Include'):
						ok=eval_tests(opt['when'])
					else:
						ok=!eval_tests(opt['when'])
					var choices
					if opt.has('Include'): choices=opt['Include']
					if opt.has('Exclude'): choices=opt['Exclude']
					for choice in choices:
						chrControls[name].set_item_disabled(idx,!ok)
						if ok:
							if good<0: good=idx
						else:
							bad=true
							if type=='ChooseMulti':
								chrControls[name].unselect(idx)
						idx+=1
			if bad:
				if type=='ChooseOne': chrControls[name].select(good)

func eval_tests(tests):
	var ok=true
	var prop
	var opt
	var testopt
	var neg
	var rslt
	for test in tests:
		neg=test['not']
		prop=test['attr']
		opt=test['option']
		testopt=chrControls[prop].get_text()
		if neg:
			rslt=(testopt!=opt)
		else:
			rslt=(testopt==opt)
		ok=ok and rslt
	return ok

var yrot=-45.0
var rot_spd=.5
func _fixed_process(delta):
	modelCtl.set_texture(modelRoot.get_render_target_texture())
	if client.test_cancel():
		client.ui_sound('error')
		hide()
		queue_free()
	if turnCW.is_pressed():
		yrot-=((360.0*rot_spd)*delta)
	if turnCCW.is_pressed():
		yrot+=((360.0*rot_spd)*delta)
	model.set_rotation_deg(Vector3(0,yrot,0))
	if chrControls.has('ModelHeightScale'):
		var v3=model.get_scale()
		v3.y=chrControls['ModelHeightScale'].get_value()
		model.set_scale(v3)
	if chrControls.has('ModelGirthScale'):
		var v3=model.get_scale()
		v3.x=chrControls['ModelGirthScale'].get_value()
		v3.z=chrControls['ModelGirthScale'].get_value()
		model.set_scale(v3)

