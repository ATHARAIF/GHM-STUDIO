extends Resource
class_name CoffeeBatch

@export var batch_year: int = 2025
@export var completed_processes: Array[String] = []

@export var aroma: float = 0.0
@export var acidity: float = 0.0
@export var body: float = 0.0
@export var sweetness: float = 0.0
@export var flavor: float = 0.0
@export var bitterness: float = 0.0
@export var complexity: float = 0.0
@export var aftertaste: float = 0.0
@export var moisture: float = 25.0
@export var defect_rate: float = 10.0

@export var quality: int = 6
@export var ripeness: int = 5

@export var cherry_kg: int = 0 # Disimpan di Hopper
@export var green_bean_kg: float = 0.0 # Disimpan di Silo
@export var roasted_bean_kg: float = 0.0
@export var growth_rate: int = 0

func apply_effects(tile_dict: Dictionary) -> void:
	var card_data: CardData = tile_dict["data"]
	
	if not completed_processes.has(card_data.process_id):
		completed_processes.append(card_data.process_id)
		
	# --- CUSTOM LOGIC (Pruning, Harvest, etc) ---
	if tile_dict.has("mod_acidity"): acidity += tile_dict["mod_acidity"]
	if tile_dict.has("mod_aroma"): aroma += tile_dict["mod_aroma"]
	if tile_dict.has("mod_sweetness"): sweetness += tile_dict["mod_sweetness"]
	if tile_dict.has("mod_flavor"): flavor += tile_dict["mod_flavor"]
	if tile_dict.has("mod_body"): body += tile_dict["mod_body"]
	if tile_dict.has("mod_bitterness"): bitterness += tile_dict["mod_bitterness"]
	if tile_dict.has("mod_defect"): defect_rate += tile_dict["mod_defect"]
	if tile_dict.has("mod_quant_pct"): cherry_kg = int(float(cherry_kg) * (1.0 + float(tile_dict["mod_quant_pct"])))
	# ----------------------------------------
	aroma = clamp(aroma + card_data.effect_aroma, 0.0, 100.0)
	acidity = clamp(acidity + card_data.effect_acidity, 0.0, 100.0)
	body = clamp(body + card_data.effect_body, 0.0, 100.0)
	sweetness = clamp(sweetness + card_data.effect_sweetness, 0.0, 100.0)
	flavor = clamp(flavor + card_data.effect_flavor, 0.0, 100.0)
	bitterness = clamp(bitterness + card_data.effect_bitterness, 0.0, 100.0)
	complexity = clamp(complexity + card_data.effect_complexity, 0.0, 100.0)
	aftertaste = clamp(aftertaste + card_data.effect_aftertaste, 0.0, 100.0)
	moisture = clamp(moisture + card_data.effect_moisture, 0.0, 100.0)
	defect_rate = clamp(defect_rate + card_data.effect_defect, 0.0, 100.0)
	cherry_kg = clamp(cherry_kg + card_data.effect_yield, 0, 5000)
	#growth_rate += card_data.effect_growth_rate
