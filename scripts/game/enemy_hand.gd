extends Hand

@export var game: Node2D 

# Called when the node enters the scene tree for the first time.
func _ready():
	RenderOpponentAction.summon.connect(_on_summon)
	RenderOpponentAction.draw_card.connect(_on_draw_card)
	
	# Set hand positions  
	for i in range(5):
		get_node("Pos" + str(i+1)).position.x = 4 * CARD_LENGTH - i * CARD_LENGTH
	
	await game.ready

func _on_summon(packet: SummonPacket) -> void:
	assert(cards.size() > 0, "Failed to render enemy.  Cards should exist at hand when summoning") 
	
	var slot_no = Field.convert_to_index(packet.position.to_array(), true)
	var slot_pos = game.get_node("EnemyField").get_slot_pos(slot_no)
	var hand_pos := get_hand_pos_from_id(packet.new_card.id)
	var summon_card = cards.pop_at(hand_pos)
		
	# Shift all cards right of summoned card
	for i in range(hand_pos, cards.size()):
		cards[i].move_card(card_positions[i].global_position, true)
	
	Global.fill_slot.emit(slot_no, summon_card)  # Update slot 
	summon_card.move_card(slot_pos, true) 
	
	Global.update_enemy_ram.emit(packet.new_ram)
	
func _on_draw_card(packet: DrawCardPacket) -> void:
	assert(packet.card_id >= 0, "The server sent an invalid opponent action")
	add_card(packet.card_id)

func get_hand_pos_from_id(id: int) -> int: 
	for card in cards: 
		if card.id == id: 
			return cards.find(card) 
	
	assert(false, "Failed to render enemy. The card with the requested id does not exist in enemy hand.")	
	return 0 

func add_card(id: int) -> void:
	assert(cards.size() < 5, "Hand should only store 5 cards")
	
	# Create new card 
	var new_card = Card.create_card(game, id)
	new_card.global_position = game.get_node("EnemyDeck").global_position
	new_card.flip_card(true)
	cards.append(new_card)
	await new_card.move_card(card_positions[cards.size()-1].global_position, true)
	
	new_card.owned_by_player = false 

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
