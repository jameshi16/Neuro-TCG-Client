extends Button

@export var button_action: MatchManager.Actions 
@export var shortcut_key: String

@onready var buttons = get_parent()

var mouse_over := false 

# Called when the node enters the scene tree for the first time.
func _ready():
	pressed.connect(_on_pressed)

func _process(delta) -> void:
	if buttons.visible and Input.is_action_just_pressed(shortcut_key):
		_on_pressed() 

func _on_pressed() -> void:
	release_focus()
	
	if button_action == MatchManager.Actions.VIEW: 
		MatchManager.action_view.emit(get_parent().get_parent())
		return 
	
	if MatchManager.input_paused or MatchManager._opponent_turn:
		return 
		
	if button_action == MatchManager.Actions.SUMMON:
		var player_ram = get_tree().get_first_node_in_group("ram_manager").player_ram
		if player_ram < buttons.get_parent().cost:
			#TODO: Use a popup or something like that to warn the player
			print("Insufficient Ram to Summon this card!") 
			return 
	
	MatchManager.current_action = button_action 
	
	if button_action:
		buttons.hide()

func _on_mouse_entered():
	mouse_over = true 

func _on_mouse_exited():
	mouse_over = false 
