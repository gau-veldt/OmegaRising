
extends Node

signal MOTD(msg)
signal LoginOK(acctID)
signal LoginFail(code,reason)

onready var login_timer=get_node("/root/Peer/LoginTimer")

remote func hello(id):
	if id==1:
		print("Got server hello.")
	else:
		print("Invalid hello from peer %d." % id)

remote func motd(id,msg):
	if id==1:
		emit_signal("MOTD",msg)
	else:
		print("Invalid MOTD from peer %d." % id)

const LOGIN_TIMEOUT		=-1
const LOGIN_OK			=0
const LOGIN_INVALID		=1
const LOGIN_BADACCT		=2
const LOGIN_REFUSED		=3
const LOGIN_SERVERR		=4
const LOGIN_ERR={
	LOGIN_INVALID	:	"Bad username or password.",
	LOGIN_BADACCT	:	"Account suspended.",
	LOGIN_REFUSED	:	"Account logins currently offline.",
	LOGIN_SERVERR	:	"Login failed due to server error.",
	LOGIN_TIMEOUT	:	"Server failed to respond."
}
remote func login_response(id,status,acctID):
	login_timer.stop()
	login_timer.disconnect("timeout",self,"login_response")
	if id==1:
		if status==LOGIN_OK:
			emit_signal("LoginOK",acctID)
		else:
			emit_signal("LoginFail",status,LOGIN_ERR[status])
	else:
		print("Invalid login_response from peer %d." % id)

func _ready():
	pass

