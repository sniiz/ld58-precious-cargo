extends Control

@onready var panel_container: PanelContainer = $PanelContainer
@onready var texture: NinePatchRect = $PanelContainer/Texture
@onready var text: Label = $PanelContainer/MarginContainer/HBoxContainer/Label
@onready var animator: AnimationPlayer = $Animator
@onready var talk_sound: AudioStreamPlayer = $TalkSound

var phrase_queue: Array[String] = []       # full phrases waiting to be said
var chunk_queue: Array[String] = []        # syllable chunks for the current phrase

@export var is_revealed := false
var last_chunk_time := 0.0
var next_chunk_wait_time := 0.1
var message_done_time := 0.0
var is_typing := false

@export var min_chunk_delay := 0.04
@export var max_chunk_delay := 0.07
@export var hide_delay := 2.5

@export var vowels : Array[AudioStream]

func visibility(show := true) -> void:
	if is_revealed == show:
		return
	if animator.is_playing():
		animator.stop()
	is_revealed = show
	animator.play("reveal" if show else "hide")


func say(message: String) -> void:
	phrase_queue.push_back(message)

func _start_next_phrase() -> void:
	if phrase_queue.is_empty():
		message_done_time = Time.get_ticks_msec() / 1000.0
		is_typing = false
		return

	text.text = ""
	visibility(true)
	if animator.is_playing(): await animator.animation_finished

	var message : String = phrase_queue.pop_front()
	chunk_queue.clear()

	var pattern := RegEx.new()
	# rough syllable matching
	pattern.compile(r"[bcdfghjklmnpqrstvwxyz]*(?:[aeiouy](?:'[a-z])?)+[bcdfghjklmnpqrstvwxyz]*|[\s]+|[^\w'\s]+")
	for m in pattern.search_all(message):
		chunk_queue.push_back(m.get_string())

	is_typing = true


# [a, e, i, o, u], zero-indexed
func _say_vowel(vowel: int) -> void:
	talk_sound.stream = vowels[vowel]
	talk_sound.play()
	talk_sound.volume_db = -10.0 if vowel == 5 else -3.0

func _call_first_vowel(chunk: String) -> void:
	var vowels := "aeiou"
	for i in chunk.to_lower():
		var idx := vowels.find(i)
		if idx != -1:
			_say_vowel(idx)
			return

	_say_vowel(5)

func _physics_process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if animator.is_playing(): return

	if not is_typing and not phrase_queue.is_empty():
		_start_next_phrase()
		return

	if is_typing and not chunk_queue.is_empty():
		if now - last_chunk_time >= next_chunk_wait_time:
			var chunk : String = chunk_queue.pop_front()
			text.text += chunk
			last_chunk_time = now

			if chunk.strip_edges() == "":
				next_chunk_wait_time = max_chunk_delay
			elif "." in chunk or "," in chunk or "!" in chunk or "?" in chunk:
				next_chunk_wait_time = max_chunk_delay * 2.5
			else:
				next_chunk_wait_time = randf_range(min_chunk_delay, max_chunk_delay)
				_call_first_vowel(chunk)


	if is_typing and chunk_queue.is_empty():
		is_typing = false
		message_done_time = now
		return

	if not is_typing and phrase_queue.is_empty() and is_revealed:
		if now - message_done_time >= hide_delay:
			visibility(false)
