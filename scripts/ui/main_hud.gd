extends CanvasLayer

@onready var lbl_season = $MarginContainer/VBoxContainer/TopBar/SeasonTurn/LblSeason
@onready var lbl_turn = $MarginContainer/VBoxContainer/TopBar/SeasonTurn/LblTurn
@onready var lbl_budget = $MarginContainer/VBoxContainer/TopBar/Budget/LblBudget
@onready var lbl_stage = $MarginContainer/VBoxContainer/TopBar/Stage/LblStage

@onready var lbl_aroma = $MarginContainer/VBoxContainer/StatsBar/Aroma
@onready var lbl_acidity = $MarginContainer/VBoxContainer/StatsBar/Acidity
@onready var lbl_body = $MarginContainer/VBoxContainer/StatsBar/Body
@onready var lbl_moisture = $MarginContainer/VBoxContainer/StatsBar/Moisture
@onready var lbl_defect = $MarginContainer/VBoxContainer/StatsBar/Defect
@onready var lbl_yield = $MarginContainer/VBoxContainer/StatsBar/Yield
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
	_on_turn_changed(StageManager.current_turn, StageManager.current_season)
	_on_stage_changed(StageManager.current_stage)
	_on_budget_changed(StageManager.budget)
	_on_stats_changed()

func _on_turn_changed(turn: int, season: int) -> void:
	lbl_turn.text = "Turn: %d/5" % (((turn - 1) % 5) + 1)
	var season_name = ""
	match season:
		StageManager.Season.SPRING: season_name = "Spring"
		StageManager.Season.SUMMER: season_name = "Summer"
		StageManager.Season.FALL: season_name = "Fall"
		StageManager.Season.WINTER: season_name = "Winter"
		
	var current_year = 2025 + int((turn - 1) / 20)
	lbl_season.text = "%s %d" % [season_name, current_year]
	
	lbl_turn.text += " (Total: %d)" % turn
	btn_end_turn.disabled = false

func _on_interaction_requested(interaction_type: String, tile_data: Dictionary) -> void:
	if interaction_type == "DRY":
		if has_node("DryPopup"):
			$DryPopup.show_popup(tile_data)
			btn_end_turn.disabled = true

func _on_stage_changed(stage: int) -> void:
	lbl_stage.text = "Stage: " + str(stage)

func _on_budget_changed(budget: int) -> void:
	lbl_budget.text = "Budget: $%d" % budget
	
func _on_stats_changed() -> void:
	var b = StageManager.coffee_batch
	lbl_aroma.text = "Aroma: %d" % b.aroma
	lbl_acidity.text = "Acidity: %d" % b.acidity
	lbl_body.text = "Body: %d" % b.body
	lbl_moisture.text = "Moisture: %.1f%%" % b.moisture
	lbl_defect.text = "Defect: %.1f%%" % b.defect_rate
	lbl_yield.text = "Yield: %dkg" % b.yield_kg

func _on_end_turn_pressed() -> void:
	StageManager.advance_turn()
