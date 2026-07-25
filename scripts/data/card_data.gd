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
@export var effect_sweetness: int = 0
@export var effect_complexity: int = 0
@export var effect_aftertaste: int = 0
@export var effect_moisture: float = 0.0
@export var effect_defect: float = 0.0
@export var effect_yield: int = 0
@export var effect_growth_rate: int = 0

@export_group("Interaction")
@export var requires_interaction: bool = false
@export var interaction_type: String = "" # e.g., "HARVEST"


@export_group("Availability")
enum AvailabilityType { RECURRING_ANNUAL, ONE_TIME_UNLOCK, EVENT_DRIVEN }
@export var availability: AvailabilityType = AvailabilityType.RECURRING_ANNUAL

# For RECURRING_ANNUAL
@export var active_start_turn: int = 1
@export var active_end_turn: int = 20

# For ONE_TIME_UNLOCK
@export var unlock_year: int = 2025
@export var unlock_turn: int = 1

# For EVENT_DRIVEN
@export var unlock_condition: String = ""
