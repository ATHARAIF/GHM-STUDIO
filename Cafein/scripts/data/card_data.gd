extends Resource
class_name CardData

@export var card_name: String = ""
@export var stage_id: int = 0
@export var cost: int = 0
@export var duration: int = 1

@export_group("Effects")
@export var effect_aroma: int = 0
@export var effect_acidity: int = 0
@export var effect_body: int = 0
@export var effect_moisture: float = 0.0
@export var effect_defect: float = 0.0
@export var effect_yield: int = 0
@export var effect_growth_rate: int = 0

@export_group("Interaction")
@export var requires_interaction: bool = false
@export var interaction_type: String = "" # e.g., "HARVEST"


@export_group("Availability")
@export var turn_start: int = 0
@export var turn_over: int = 0
@export var unlock_condition: String = ""
