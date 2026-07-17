extends Resource
class_name CoffeeBatch

@export var completed_stages: Array[int] = []

@export var aroma: int = 0
@export var acidity: int = 50
@export var body: int = 0
@export var moisture: float = 25.0
@export var defect_rate: float = 10.0
@export var yield_kg: int = 0
@export var growth_rate: int = 0

func apply_effects(card_data: CardData) -> void:
	if not completed_stages.has(card_data.stage_id):
		completed_stages.append(card_data.stage_id)
	aroma = clamp(aroma + card_data.effect_aroma, 0, 100)
	acidity = clamp(acidity + card_data.effect_acidity, 0, 100)
	body = clamp(body + card_data.effect_body, 0, 100)
	moisture = clamp(moisture + card_data.effect_moisture, 0.0, 30.0)
	defect_rate = clamp(defect_rate + card_data.effect_defect, 0.0, 100.0)
	yield_kg = clamp(yield_kg + card_data.effect_yield, 0, 500)
	growth_rate += card_data.effect_growth_rate
