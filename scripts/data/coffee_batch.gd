extends Resource
class_name CoffeeBatch

@export var batch_year: int = 2025
@export var completed_stages: Array[int] = []

@export var aroma: int = 0
@export var acidity: int = 0
@export var body: int = 0
@export var sweetness: int = 0
@export var complexity: int = 0
@export var aftertaste: int = 0
@export var moisture: float = 25.0
@export var defect_rate: float = 10.0
@export var cherry_kg: int = 0 # Disimpan di Hopper
@export var green_bean_kg: float = 0.0 # Disimpan di Silo
@export var roasted_bean_kg: float = 0.0
@export var growth_rate: int = 0

func apply_effects(tile_dict: Dictionary) -> void:
	var card_data: CardData = tile_dict["data"]
	
	if not completed_stages.has(card_data.stage_id):
		completed_stages.append(card_data.stage_id)
		
	# --- CUSTOM PRUNING LOGIC PLACEHOLDER ---
	if card_data.card_name == "Pruning" and tile_dict.has("pruning_method"):
		var method = tile_dict["pruning_method"]
		var intensity = tile_dict["pruning_intensity"]
		# TODO: Implement mathematical effects for pruning based on method and intensity
		# print("Pruning Applied: ", method, " at ", intensity, "% intensity")
	# ----------------------------------------
	aroma = clamp(aroma + card_data.effect_aroma, 0, 100)
	acidity = clamp(acidity + card_data.effect_acidity, 0, 100)
	body = clamp(body + card_data.effect_body, 0, 100)
	sweetness = clamp(sweetness + card_data.effect_sweetness, 0, 100)
	complexity = clamp(complexity + card_data.effect_complexity, 0, 100)
	aftertaste = clamp(aftertaste + card_data.effect_aftertaste, 0, 100)
	moisture = clamp(moisture + card_data.effect_moisture, 0.0, 100.0)
	defect_rate = clamp(defect_rate + card_data.effect_defect, 0.0, 100.0)
	cherry_kg = clamp(cherry_kg + card_data.effect_yield, 0, 5000)
	growth_rate += card_data.effect_growth_rate
