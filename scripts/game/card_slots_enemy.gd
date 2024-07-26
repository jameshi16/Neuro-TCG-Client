extends CardSlots
## Enemy cards only need to worry about Slots and 
## Placement when moving them around. 

@export var player_card_slots: CardSlots

## List to store all destroyed enemy cards 
var destroyed_cards := [] 

func _ready() -> void:
	Global.highlight_enemy_cards.connect(_on_highlight_enemy_cards)
	Global.unhighlight_enemy_cards.connect(_on_unhighlight_enemy_cards)
	RenderOpponentAction.attack.connect(_on_attack)
	RenderOpponentAction.switch.connect(_on_switch)
	#User.attack.connect(_on_any_attack)
	
	for slot in get_children():
		slot.visible = false

func show_slots_for_attack(flag: bool, atk_range:=CardInfo.AttackRange.STANDARD) -> void:
	if flag:
		for slot in get_children():
			if slot.stored_card:
				if slot.slot_no in [8, 9, 10] and atk_range == CardInfo.AttackRange.STANDARD:
					slot.visible = false
				else:
					slot.visible = true
			else:
				slot.visible = false
	else:
		for slot in get_children():
			slot.visible = false

func _on_switch(packet: SwitchPlacePacket) -> void:
	var card1_pos = CardSlots.convert_to_index(packet.position1.to_array(), true)
	var card2_pos = CardSlots.convert_to_index(packet.position2.to_array(), true)
	var slot1 := get_node("Slot"+ str(card1_pos))
	var slot2 := get_node("Slot"+ str(card2_pos))
	var card1: Card = slot1.stored_card
	var card2: Card = slot2.stored_card
	
	if card1 == null:
		assert(card2 != null)
		Global.unfill_slot.emit(card2_pos, card2)
		Global.fill_slot.emit(card1_pos, card2)
		card2.move_card(slot1.global_position)
	elif card2 == null:
		assert(card1 != null)
		Global.unfill_slot.emit(card1_pos, card1)
		Global.fill_slot.emit(card2_pos, card1)
		card1.move_card(slot2.global_position)
	else:
		switch_cards(card1, card2)

## When the opponent attacks the client
func _on_attack(packet: AttackPacket) -> void:
	# Update attacking card's status 
	var atk_card_slot = CardSlots.convert_to_index(packet.attacker_position.to_array(), true)
	var atk_card: Card = get_node("Slot"+ str(atk_card_slot)).stored_card

	if packet.attacker_card == null:
		destroy_card(atk_card_slot, atk_card)
	else:
		atk_card.render_attack(packet.attacker_card.health)
	
	# Update target card's status 
	var card_slot = CardSlots.convert_to_index(packet.target_position.to_array())
	var card: Card = player_card_slots.get_node("Slot"+ str(card_slot)).stored_card
	
	if packet.target_card == null: 
		destroy_card(card_slot, card)
	else:
		card.render_attack(packet.target_card.health)

#func _on_any_attack(packet: AttackPacket) -> void:
	#if (packet.attacker_card == null and !packet.is_you):
		#var atk_card_pos = CardSlots.convert_to_index(packet.attacker_position.to_array(), true)
		#var atk_card: Card = get_node("Slot"+ str(atk_card_pos)).stored_card
		#atk_card.render_attack(packet.attacker_card.health)
		##Global.unfill_slot.emit(atk_card_pos, atk_card)
		##atk_card.destroy()
	#if (packet.target_card == null and packet.is_you):
		#var card_pos = CardSlots.convert_to_index(packet.target_position.to_array(), true)
		#var card: Card = get_node("Slot"+ str(card_pos)).stored_card
		#card.render_attack(packet.target_card.health)
		##Global.unfill_slot.emit(card_pos, card)
		##card.destroy()
	#pass

func _on_highlight_enemy_cards(card: Card, atk_range: CardInfo.AttackRange) -> void:
	show_slots_for_attack(true, atk_range)

func _on_unhighlight_enemy_cards(card: Card) -> void:
	show_slots_for_attack(false)

func destroy_card(slot:int, card: Card) -> void:
	print("(From Opponent) Card Destroyed!")
	Global.unfill_slot.emit(slot, card) 
	destroyed_cards.append(card)
	card.visible = false 
	card.global_position = Vector2.ZERO 
