@tool
extends Resource
class_name CardData

@export_group("Card Core Settings")
@export var card_name: String = ""
@export var process_id: String = ""
@export var cost: int = 0
@export var duration: int = 1

@export_group("Feature Toggles")
@export var use_methods: bool = false:
	set(val):
		use_methods = val
		notify_property_list_changed()
		
@export var use_tools: bool = false:
	set(val):
		use_tools = val
		notify_property_list_changed()

@export var has_config_popup: bool = false:
	set(val):
		has_config_popup = val
		notify_property_list_changed()
		
@export var has_result_popup: bool = false:
	set(val):
		has_result_popup = val
		notify_property_list_changed()
		
@export var has_expiration_penalty: bool = false:
	set(val):
		has_expiration_penalty = val
		notify_property_list_changed()

@export_group("Interactive Popups")
@export var custom_popup_ui: PackedScene
@export var custom_result_popup_ui: PackedScene

@export_group("Method & Tools Expansion")
@export var popup_methods: Array[ProcessMethodData] = []
@export var popup_tools: Array[ProcessMethodData] = []

@export_group("Base Modifiers")
@export var base_mod_aroma: float = 0.0
@export var base_mod_acidity: float = 0.0
@export var base_mod_body: float = 0.0
@export var base_mod_sweetness: float = 0.0
@export var base_mod_flavor: float = 0.0
@export var base_mod_bitterness: float = 0.0
@export var base_mod_moisture: float = 0.0
@export var base_mod_defect: float = 0.0
@export var base_mod_yield: float = 0.0
@export var base_mod_health: float = 0.0

@export_group("Availability")
enum AvailabilityType { RECURRING_ANNUAL, ONE_TIME_UNLOCK, EVENT_DRIVEN }
@export var availability: AvailabilityType = AvailabilityType.RECURRING_ANNUAL:
	set(val):
		availability = val
		notify_property_list_changed()

@export var active_start_turn: int = 1
@export var active_end_turn: int = 20
@export var unlock_year: int = 2025
@export var unlock_turn: int = 1
@export var unlock_condition: String = ""

@export_group("Penalty Modifiers (If missed)")
@export var expiration_turns: int = 3
@export var penalty_mod_aroma: float = 0.0
@export var penalty_mod_acidity: float = 0.0
@export var penalty_mod_body: float = 0.0
@export var penalty_mod_sweetness: float = 0.0
@export var penalty_mod_flavor: float = 0.0
@export var penalty_mod_bitterness: float = 0.0
@export var penalty_mod_moisture: float = 0.0
@export var penalty_mod_defect: float = 0.0
@export var penalty_mod_yield: float = 0.0
@export var penalty_mod_health: float = 0.0

func _validate_property(property: Dictionary) -> void:
	# Hide Empty Group Headers
	if property.usage & PROPERTY_USAGE_GROUP:
		if property.name == "Method & Tools Expansion" and not (use_methods or use_tools):
			property.usage = PROPERTY_USAGE_NONE
		if property.name == "Interactive Popups" and not (has_config_popup or has_result_popup):
			property.usage = PROPERTY_USAGE_NONE
		if property.name == "Penalty Modifiers (If missed)" and not has_expiration_penalty:
			property.usage = PROPERTY_USAGE_NONE

	# Hide Method & Tools Expansion
	if property.name == "popup_methods" and not use_methods:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "popup_tools" and not use_tools:
		property.usage = PROPERTY_USAGE_NONE
		
	# Hide Interactive Popups
	if property.name == "custom_popup_ui" and not has_config_popup:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "custom_result_popup_ui" and not has_result_popup:
		property.usage = PROPERTY_USAGE_NONE
		
	# Hide Availability Fields
	if availability != AvailabilityType.RECURRING_ANNUAL and property.name in ["active_start_turn", "active_end_turn"]:
		property.usage = PROPERTY_USAGE_NONE
	if availability != AvailabilityType.ONE_TIME_UNLOCK and property.name in ["unlock_year", "unlock_turn"]:
		property.usage = PROPERTY_USAGE_NONE
	if availability != AvailabilityType.EVENT_DRIVEN and property.name == "unlock_condition":
		property.usage = PROPERTY_USAGE_NONE
		
	# Hide Expiration & Penalties
	var penalty_vars = ["expiration_turns", "penalty_mod_aroma", "penalty_mod_acidity", "penalty_mod_body", "penalty_mod_sweetness", "penalty_mod_flavor", "penalty_mod_bitterness", "penalty_mod_moisture", "penalty_mod_defect", "penalty_mod_yield", "penalty_mod_health"]
	if not has_expiration_penalty and property.name in penalty_vars:
		property.usage = PROPERTY_USAGE_NONE
		
	# Expiration Turns is only for EVENT_DRIVEN / ONE_TIME_UNLOCK (Relative timer)
	if availability == AvailabilityType.RECURRING_ANNUAL and property.name == "expiration_turns":
		property.usage = PROPERTY_USAGE_NONE
