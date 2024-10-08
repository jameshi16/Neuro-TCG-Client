class_name CardState

var id: int
var health: int
var ability_was_used: bool
var phase: int
var shield: int

func _init(id_: int, health_: int, ability_was_used_: bool, phase_: int, shield_: int):
	id = id_
	health = health_
	ability_was_used = ability_was_used_
	phase = phase_
	shield = shield_

func to_dict() -> Dictionary:
	return {
		"id": id,
		"health": health,
		"ability_was_used": ability_was_used,
		"phase": phase,
		"shield": shield,
	}

static func from_dict(d):
	if d == null:
		return null

	return CardState.new(d["id"], d["health"], d["ability_was_used"], d["phase"], d["shield"])
