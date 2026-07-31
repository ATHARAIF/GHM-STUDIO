extends CanvasLayer

@onready var lbl_season = $MarginContainer/VBoxContainer/TopBar/SeasonTurn/LblSeason
@onready var lbl_turn = $MarginContainer/VBoxContainer/TopBar/SeasonTurn/LblTurn
@onready var lbl_budget = $MarginContainer/VBoxContainer/TopBar/Budget/LblBudget
@onready var lbl_stage = $MarginContainer/VBoxContainer/TopBar/Stage/LblStage

@onready var lbl_body = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Body
@onready var lbl_acidity = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Acidity
@onready var lbl_sweetness = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Sweetness
@onready var lbl_aroma = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Aroma
@onready var lbl_flavor = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Flavor
@onready var lbl_bitterness = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Bitterness
@onready var lbl_complexity = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Complexity
@onready var lbl_aftertaste = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Aftertaste
@onready var lbl_moisture = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Moisture
@onready var lbl_defect = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Defect
@onready var lbl_yield = $MarginContainer/VBoxContainer/StatsPanel/Margin/StatsGrid/Yield
@onready var btn_end_turn = $MarginContainer/Control/BtnEndTurn

func _ready() -> void:
	StageManager.turn_changed.connect(_on_turn_changed)
	StageManager.stage_changed.connect(_on_stage_changed)
	StageManager.budget_changed.connect(_on_budget_changed)
	StageManager.stats_changed.connect(_on_stats_changed)
	StageManager.interaction_requested.connect(_on_interaction_requested)
	
	btn_end_turn.pressed.connect(_on_end_turn_pressed)
	
	if lbl_stage:
		lbl_stage.hide()
		
	_update_all()

func _update_all() -> void:
	_on_turn_changed(TimeManager.turn_in_year, TimeManager.season, TimeManager.year)
	_on_stage_changed(StageManager.current_stage)
	_on_budget_changed(StageManager.budget)
	_on_stats_changed()

func _on_turn_changed(turn_in_year: int, season: int, year: int) -> void:
	lbl_turn.text = "Turn: %d/5" % TimeManager.turn_in_season
	var season_name = ""
	match season:
		TimeManager.Season.SPRING: season_name = "Spring"
		TimeManager.Season.SUMMER: season_name = "Summer"
		TimeManager.Season.FALL: season_name = "Fall"
		TimeManager.Season.WINTER: season_name = "Winter"
		
	lbl_season.text = "%s %d" % [season_name, year]
	btn_end_turn.disabled = false
	btn_end_turn.disabled = false

func _on_interaction_requested(interaction_type: String, tile_data: Dictionary) -> void:
	if interaction_type == "DRY":
		if has_node("DryPopup"):
			$DryPopup.show_popup(tile_data)
			btn_end_turn.disabled = true
	elif interaction_type == "HARVEST":
		if has_node("HarvestResultPopup"):
			$HarvestResultPopup.show_popup(tile_data)
			btn_end_turn.disabled = true

func _on_stage_changed(stage: int) -> void:
	lbl_stage.text = "Stage: " + str(stage)

func _on_budget_changed(budget: int) -> void:
	lbl_budget.text = "Budget: $%d" % budget

func _on_stats_changed() -> void:
	var b = StageManager.get_active_farm_batch()
	lbl_body.text = "Body: %.2f" % b.body
	lbl_acidity.text = "Acidity: %.2f" % b.acidity
	lbl_sweetness.text = "Sweetness: %.2f" % b.sweetness
	lbl_aroma.text = "Aroma: %.2f" % b.aroma
	lbl_flavor.text = "Flavor: %.2f" % b.flavor
	lbl_bitterness.text = "Bitterness: %.2f" % b.bitterness
	lbl_complexity.text = "Complexity: %.2f" % b.complexity
	lbl_aftertaste.text = "Aftertaste: %.2f" % b.aftertaste
	lbl_moisture.text = "Moisture: %.1f%%" % b.moisture
	lbl_defect.text = "Defect: %.1f%%" % b.defect_rate
	lbl_yield.text = "Yield: %dkg" % b.cherry_kg

func _on_end_turn_pressed() -> void:
	StageManager.advance_turn()
