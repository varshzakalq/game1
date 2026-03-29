extends Node


var MIN_REWIND_SPEED : float = 0.25
var MAX_REWIND_SPEED : float = 3.0
var REWIND_ACCELERATION : float = 0.1
var SNAPSHOT_INTERVAL : float = 0.05



var player : Player = null
var player_age : float = -1

signal fade_complete
signal level_change(trigger_id : String)
func fade_to_black():
	var rect : ColorRect = ColorRect.new()
	var canvas_layer = CanvasLayer.new()
	
	var root = get_tree().root
	root.add_child(canvas_layer)
	canvas_layer.add_child(rect)
	
	rect.size = get_viewport().get_visible_rect().size
	
	rect.color = Color(0.0, 0.0, 0.0, 0.0)
	
	var tween = create_tween()
	
	tween.tween_property(rect, "color", Color(0.0, 0.0, 0.0, 1.0), 1.0)
	
	await tween.finished
	fade_complete.emit()
	
	get_tree().create_timer(2.0).timeout.connect(canvas_layer.queue_free)
