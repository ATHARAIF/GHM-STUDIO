extends CanvasLayer

const DayCellScene := preload("res://scenes/ui/calender/day_cell.tscn")
const DAYS_PER_SEASON := 5
const DAYS_ROW1 := 3
const GRID_ORDER := ["SPRING", "SUMMER", "FALL", "WINTER"]

@onready var year_label: Label = $CalendarBody/Panel/VBoxRoot/YearBarWrapper/YearBar/YearCenter/YearLabel 
@onready var close_button: Button = $CalendarBody/CloseButton
@onready var season_rows := {
	"SPRING": [
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/SpringBox/Spring/DaysMargin/DaysRows/Row1,
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/SpringBox/Spring/DaysMargin/DaysRows/Row2,
	],
	"SUMMER": [
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/SummerBox/Summer/DaysMargin/DaysRows/Row1,
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/SummerBox/Summer/DaysMargin/DaysRows/Row2,
	],
	"FALL": [
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/FallBox/Fall/DaysMargin/DaysRows/Row1,
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/FallBox/Fall/DaysMargin/DaysRows/Row2,
	],
	"WINTER": [
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/WinterBox/Winter/DaysMargin/DaysRows/Row1,
		$CalendarBody/Panel/VBoxRoot/ContentMargin/Seasons/WinterBox/Winter/DaysMargin/DaysRows/Row2,
	],
}

func _ready() -> void:
	visible = false
	close_button.pressed.connect(func(): visible = false)

func refresh() -> void:
	year_label.text = str(TimeManager.year)

	for season_enum in GRID_ORDER.size():
		var rows: Array = season_rows[GRID_ORDER[season_enum]]
		for row in rows:
			for child in row.get_children():
				row.remove_child(child)
				child.queue_free()

		for day in range(1, DAYS_PER_SEASON + 1):
			var cell = DayCellScene.instantiate()
			var row_index := 0 if day <= DAYS_ROW1 else 1
			rows[row_index].add_child(cell)
			cell.day_number = day
			cell.set_state(_get_day_state(season_enum, day))

func _get_day_state(season_enum: int, day: int) -> int:
	if season_enum < TimeManager.season:
		return 0 # PAST
	elif season_enum > TimeManager.season:
		return 2 # FUTURE
	elif day < TimeManager.turn_in_season:
		return 0
	elif day == TimeManager.turn_in_season:
		return 1 # TODAY
	else:
		return 2
