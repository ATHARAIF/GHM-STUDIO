extends Control

const BatchItemScene: PackedScene = preload("res://scenes/tiles/farm/batch_list_item.tscn")

@onready var list_vbox: VBoxContainer = $HBox/ListPanel/ScrollContainer/ListVBox

@onready var lbl_radar_placeholder: Label = $HBox/DetailPanel/DetailVBox/LblRadarPlaceholder
@onready var val_score: Label = $HBox/DetailPanel/DetailVBox/ValScore
@onready var val_note: Label = $HBox/DetailPanel/DetailVBox/ValNote

var selected_batch: CoffeeBatch = null

func _ready() -> void:
	StageManager.stats_changed.connect(_refresh_list)
	_refresh_list()

func _refresh_list() -> void:
	for child in list_vbox.get_children():
		child.queue_free()

	# Cuma batch yang udah lewat panen (FP04) yang muncul di coffee log.
	# Yang belum dipanen dianggap masih di storage/lahan, bukan tanggung jawab tab ini.
	var harvested_batches: Array = []
	for year in StageManager.batches.keys():
		var b: CoffeeBatch = StageManager.batches[year]
		if b.completed_processes.has("FP04"):
			harvested_batches.append(b)

	for batch in harvested_batches:
		var item = BatchItemScene.instantiate()
		list_vbox.add_child(item)
		_populate_list_item(item, batch)

	# Auto-select batch pertama biar detail panel gak kosong
	if harvested_batches.size() > 0:
		_select_batch(harvested_batches[0])
	else:
		selected_batch = null
		_update_detail_panel()

func _populate_list_item(item: Node, batch: CoffeeBatch) -> void:
	var lbl_name: Label = item.get_node_or_null("HBox/LblName")
	var lbl_score: Label = item.get_node_or_null("HBox/LblScore")
	var lbl_remaining: Label = item.get_node_or_null("HBox/LblRemaining")

	var variety_name = "Unknown"
	if StageManager.current_location and StageManager.current_location.variety_data:
		variety_name = StageManager.current_location.variety_data.variety_name

	if lbl_name: lbl_name.text = "%s %d" % [variety_name, batch.batch_year]
	if lbl_score: lbl_score.text = "%.1f" % batch.get_score()
	# Asumsi "jumlah tersisa" = green_bean_kg (siap diproses lanjut/dijual).
	# Ganti ke roasted_bean_kg di sini kalau ternyata itu yang dimaksud.
	if lbl_remaining: lbl_remaining.text = "%.1f kg" % batch.green_bean_kg

	if item is BaseButton:
		item.pressed.connect(func(): _select_batch(batch))
	else:
		item.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed:
				_select_batch(batch)
		)

func _select_batch(batch: CoffeeBatch) -> void:
	selected_batch = batch
	_update_detail_panel()

func _update_detail_panel() -> void:
	if not selected_batch:
		if lbl_radar_placeholder: lbl_radar_placeholder.text = "Belum ada batch"
		if val_score: val_score.text = "-"
		if val_note: val_note.text = "-"
		return

	if lbl_radar_placeholder:
		lbl_radar_placeholder.text = "Aci %.0f | Aro %.0f | Swe %.0f | Fla %.0f | Body %.0f | Bit %.0f" % [
			selected_batch.acidity, selected_batch.aroma, selected_batch.sweetness,
			selected_batch.flavor, selected_batch.body, selected_batch.bitterness
		]
	if val_score: val_score.text = "%.1f" % selected_batch.get_score()
	if val_note: val_note.text = selected_batch.note if selected_batch.note != "" else "(belum ada catatan)"
