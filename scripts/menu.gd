extends Node2D

var simultaneous_scene = preload("res://scenes/main.tscn").instantiate()
var audio: AnimationPlayer = null
@export var klik: AudioStreamPlayer2D = null
func load_main() -> void:
	for c in get_children():
		if c.get_class() == "AudioStreamPlayer2D":
			audio = c.get_child(0) as AnimationPlayer
			audio.play("fade")
		c.queue_free()
	get_tree().root.add_child(simultaneous_scene)

func delete_audio_stream_player() -> void:
	if audio != null:
		audio.queue_free()

func focus() -> void:
	if klik != null and !klik.playing:
		klik.play()

func _on_texture_button_pressed() -> void:
	load_main()

func _on_audio_stream_player_2d_finished() -> void:
	delete_audio_stream_player()
