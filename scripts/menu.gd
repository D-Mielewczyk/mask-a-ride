extends Node2D

@export var main_scene: PackedScene = preload("res://scenes/main.tscn")

var audio: AnimationPlayer = null
@export var klik: AudioStreamPlayer2D = null
func load_main() -> void:
	for c in get_children():
		if c.get_class() == "AudioStreamPlayer2D":
			audio = c.get_child(0) as AnimationPlayer
			audio.play("fade")
		c.queue_free()
	get_tree().change_scene_to_packed(main_scene)

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
