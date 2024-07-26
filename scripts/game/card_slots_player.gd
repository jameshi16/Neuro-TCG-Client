extends CardSlots
## When moving a card, keep track of card.placement, Slots,
## cards, and selected_card

var cards := []
var destroyed_cards := [] 
var selected_card = null

func _ready() -> void:
	Global.show_slots.connect(show_slots)
	Global.slot_chosen.connect(_on_slot_chosen)
	Global.enemy_slot_chosen.connect(_on_enemy_slot_chosen)
	Global.playmat_card_selected.connect(_on_card_selected)
	Global.playmat_card_unselected.connect(_on_card_unselected)
	Global.fill_slot.connect(_on_fill_slot)
	Global.unfill_slot.connect(_on_unfill_slot)
	MatchManager.action_switch.connect(_on_action_switch)
	MatchManager.action_attack.connect(_on_action_attack)
	#MatchManager.action_view.connect(_on_action_view)
	#User.attack.connect(_on_any_attack)

	for slot in get_children():
		slot.visible = false

func _on_fill_slot(slot_no: int, card: Card) -> void:
	if card.owned_by_player:
		cards.append(card)

func _on_unfill_slot(slot_no: int, card: Card) -> void:
	if card.owned_by_player:
		cards.erase(card)

#func _on_any_attack(packet: AttackPacket) -> void:
	#if (packet.attacker_card == null and packet.is_you):
		#var atk_card_pos = CardSlots.convert_to_index(packet.attacker_position.to_array(), false)
		#var atk_card: Card = get_node("Slot"+ str(atk_card_pos)).stored_card
		#atk_card.render_attack(packet.attacker_card.health)
		##Global.unfill_slot.emit(atk_card_pos, atk_card)
		##atk_card.destroy()
	#if (packet.target_card == null and !packet.is_you):
		#var card_pos = CardSlots.convert_to_index(packet.target_position.to_array(), false)
		#var card: Card = get_node("Slot"+ str(card_pos)).stored_card
		#card.render_attack(packet.target_card.health)
		##Global.unfill_slot.emit(card_pos, card)
		##card.destroy()

func show_slots(flag: bool) -> void:
	if flag:
		for slot in get_children():
			if not slot.stored_card:
				slot.visible = true
			else:
				slot.visible = false
	else:
		for slot in get_children():
			slot.visible = false

func show_slots_for_transfer(flag: bool) -> void:
	if flag:
		for slot in get_children():
			slot.visible = true
			
			# Don't show selected card  
			if slot.stored_card:
				if slot.stored_card == selected_card:
					slot.visible = false
	
func _on_card_selected(card: Card) -> void:
	if MatchManager.current_action == MatchManager.Actions.SWITCH:
		MatchManager.current_action = MatchManager.Actions.IDLE
		card.unselect()
		VerifyClientAction.switch.emit(get_slot_array(card), get_slot_array(selected_card))
		switch_cards(card, selected_card)
		
		# Update card slots 
		selected_card = null
		show_slots(false)
	else:
		card.show_buttons([MatchManager.Actions.SWITCH, MatchManager.Actions.ATTACK, MatchManager.Actions.VIEW])
		selected_card = card
		card.select()

func _on_card_unselected(card: Card) -> void:
	card.hide_buttons()
	card.unselect()
	Global.unhighlight_enemy_cards.emit(selected_card)
	
	# If another card has been selected, 
	# Update these values from the _on_card_selected
	# that will run from that card being clicked on 
	if not another_card_selected(card):
		selected_card = null
		show_slots(false)
		MatchManager.current_action = MatchManager.Actions.IDLE

func another_card_selected(card: Card) -> bool:
	for c in cards:
		if c != card and c.mouse_over:
			return true
	
	return false

func _on_action_switch() -> void:
	show_slots_for_transfer(true)

func _on_action_attack() -> void:
	Global.highlight_enemy_cards.emit(selected_card, selected_card.card_info.attack_range)

#func _on_action_view() -> void:
	#if selected_card:
		#Global.view_card.emit(selected_card)

func _on_slot_chosen(slot_no: int, card: Card) -> void:
	if card:
		return
	
	if selected_card:
		# Send packet
		VerifyClientAction.switch.emit(get_slot_array(selected_card), convert_to_array(slot_no))

		# Change slots 
		Global.unfill_slot.emit(get_slot_no(selected_card), selected_card)
		Global.fill_slot.emit(slot_no, selected_card)
		
		# Change visuals 
		selected_card.move_card(get_slot_pos(slot_no), true)

## When the client attacks the opponent 
func _on_enemy_slot_chosen(slot_no: int, card: Card) -> void:
	assert(card, "Enemy slot chosen but no card in enemy slot!")
	assert(selected_card, "Enemy slot chosen but no player card selected!")
	
	card.render_attack_client(selected_card)
	VerifyClientAction.attack.emit(selected_card.id, convert_to_array(slot_no), get_slot_array(selected_card))
	if card.hp == 0: 
		destroy_card(slot_no, card)
	
	selected_card.render_attack(max(selected_card.hp - (card.atk - 1), 0))
	if selected_card.hp == 0:
		destroy_card(get_slot_no(card), card)

func destroy_card(slot:int, card: Card) -> void:
	print("Card Destroyed!")
	Global.unfill_slot.emit(slot, card)
	cards.erase(card)
	if selected_card == card:
		selected_card = null 
	card.placement = Card.Placement.DESTROYED
	
	destroyed_cards.append(card)
	card.visible = false
	card.global_position = Vector2.ZERO 
