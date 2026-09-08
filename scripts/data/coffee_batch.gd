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
@export var moisture: float = 25.0
## Persentase kecacatan biji kopi dalam batch ini (%).
@export var defect_rate: float = 0.0


@export var cherry_kg: int = 0 # Disimpan di Hopper
@export var green_bean_kg: float = 0.0 # Disimpan di Silo
@export var roasted_bean_kg: float = 0.0
@export var species_name: String = "Arabica"
@export var variety_name: String = "Unknown"

var history_log: Array[String] = []
var accumulated_yield_modifier: float = 1.0

func add_history(action_name: String) -> void:
	if not history_log.has(action_name):
		history_log.append(action_name)

func apply_effects(tile_dict: Dictionary) -> void:
	var card_data: CardData = tile_dict["data"]
	
	if not completed_processes.has(card_data.process_id):
		completed_processes.append(card_data.process_id)
		
	# Apply Tree Health effect
	var em = Engine.get_main_loop().root.get_node_or_null("StageManager")
	if em and em.current_location and em.current_location.current_tree:
		var tree = em.current_location.current_tree
		var mod_h = 0.0
		if tile_dict.has("mod_health"): mod_h = tile_dict["mod_health"]
		tree.health_pct = clamp(tree.health_pct + card_data.base_mod_health + mod_h, 0.0, 100.0)
		
	# --- CUSTOM LOGIC (Pruning, Harvest, etc) ---
	if tile_dict.has("mod_quant_pct"): 
		accumulated_yield_modifier *= (1.0 + float(tile_dict["mod_quant_pct"]))
		
	# Taste Stats (Max 10.0)
	var taste_stats = ["aroma", "acidity", "body", "sweetness", "flavor", "bitterness"]
	for stat in taste_stats:
		var mod_val = tile_dict.get("mod_" + stat, 0.0)
		var card_val = card_data.get("base_mod_" + stat)
		var new_val = get(stat) + mod_val + card_val
		set(stat, clamp(new_val, 0.0, 10.0))
		
	# Percentage Stats (Max 100.0)
	var pct_stats = ["moisture"]
	for stat in pct_stats:
		var mod_val = tile_dict.get("mod_" + stat, 0.0)
		var card_val = card_data.get("base_mod_" + stat)
		var new_val = get(stat) + mod_val + card_val
		set(stat, clamp(new_val, 0.0, 100.0))
		
	# Special case for defect (variable name in coffee_batch is defect_rate, but mod name is mod_defect)
	var mod_def = tile_dict.get("mod_defect", 0.0)
	var card_def = card_data.base_mod_defect
	defect_rate = clamp(defect_rate + mod_def + card_def, 0.0, 100.0)
	
	accumulated_yield_modifier *= (1.0 + card_data.base_mod_yield)
