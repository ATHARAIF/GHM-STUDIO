extends PanelContainer

enum DayState { PAST, TODAY, FUTURE }

@export var day_number: int = 1:
	set(value):
		day_number = value
		if is_node_ready():
			_update_display()

@onready var number_label: Label = $VBox/TopMargin/TopVBox/NumberLabel
@onready var footer_label: Label = $VBox/FooterBar/FooterHBox/ValueLabel

var state: DayState = DayState.FUTURE

func _ready() -> void:
	_update_display()
	set_footer_value("90°") # placeholder, panggil ulang manual kalau datanya udah ada

func set_state(new_state: DayState) -> void:
	state = new_state
	match state:
		DayState.PAST:
			theme_type_variation = "DayCellPast"
			modulate = Color(1, 1, 1, 0.55)
		DayState.TODAY:
			theme_type_variation = "DayCellToday"
			modulate = Color(1, 1, 1, 1)
		DayState.FUTURE:
			theme_type_variation = "DayCellFuture"
			modulate = Color(1, 1, 1, 1)

func set_footer_value(text: String) -> void:
	if footer_label:
		footer_label.text = text

func _update_display() -> void:
	if number_label:
		number_label.text = str(day_number)
