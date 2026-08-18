extends CanvasLayer

## Struktur node yang perlu kamu susun di scene ini:
##
## WarehouseHUD (CanvasLayer, script ini)
## ├── BudgetMargin (MarginContainer, anchor preset: Top Left)
## │   └── LblBudget (Label)
## ├── BackMargin (MarginContainer, anchor preset: Top Right)
## │   └── BtnBack (Button, teks "< Back")
## └── NoticeMargin (MarginContainer, anchor preset: Top Wide / Center Top)
##     └── LblNotice (Label, teks default kosong, awalnya hidden/visible=false)
##
## Simpan scene ini sebagai res://ui/warehouse_hud.tscn,
## lalu instance ke dalam warehouse.tscn menggantikan MainHUD lama.

@export var ground_scene_path: String = "res://scenes/ground.tscn"
@export var notice_duration: float = 2.0  # berapa detik notifikasi keliatan sebelum ilang

@onready var lbl_budget: Label = $BudgetMargin/LblBudget
@onready var btn_back: Button = $BackMargin/BtnBack
@onready var lbl_notice: Label = $NoticeMargin/LblNotice

var _notice_timer: Timer

func _ready() -> void:
	StageManager.budget_changed.connect(_on_budget_changed)
	_on_budget_changed(StageManager.budget)

	btn_back.pressed.connect(_on_back_pressed)

	lbl_notice.visible = false
	_notice_timer = Timer.new()
	_notice_timer.one_shot = true
	_notice_timer.wait_time = notice_duration
	_notice_timer.timeout.connect(func(): lbl_notice.visible = false)
	add_child(_notice_timer)

	WarehousePlacement.spawn_failed_full.connect(_on_spawn_failed_full)

func _on_budget_changed(budget: int) -> void:
	lbl_budget.text = "Budget: $%d" % budget

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(ground_scene_path)

func _on_spawn_failed_full() -> void:
	show_notice("Lahan penuh! Nggak ada tempat kosong lagi.")

func show_notice(text: String) -> void:
	lbl_notice.text = text
	lbl_notice.visible = true
	_notice_timer.start()
