extends Control

@onready var grid = $ScrollContainer/GridContainer
@onready var template = $ScrollContainer/GridContainer/terroir

func _ready() -> void:
	# Sembunyikan template asli agar tidak terlihat dan bisa diduplikasi
	template.hide()
	populate_farmlands()

func populate_farmlands() -> void:
	# Hapus card sebelumnya jika ada (kecuali template)
	for child in grid.get_children():
		if child != template:
			child.queue_free()
			
	# Ambil daftar lokasi kebun yang dimiliki.
	# Untuk saat ini, kita gunakan StageManager.current_location sebagai contoh
	# (Nanti bisa diubah menjadi iterasi dari list farmlands yang dimiliki pemain)
	var owned_locations: Array[FarmLocation] = []
	if StageManager.current_location != null:
		owned_locations.append(StageManager.current_location)
		
	for loc in owned_locations:
		var card = template.duplicate()
		grid.add_child(card)
		card.show()
		
		var var_data = loc.variety_data
		var tree = loc.current_tree
		
		# Set Header
		card.get_node("terroir_header/terroir_name").text = loc.location_name
		if var_data:
			card.get_node("terroir_header/terroir_species").text = var_data.species_name + " " + var_data.variety_name
		
		var stats_path = "details/stats/"
		
		# Soil Profile
		card.get_node(stats_path + "profile/sand/value").text = str(loc.soil_sand) + "%"
		card.get_node(stats_path + "profile/clay/value").text = str(loc.soil_clay) + "%"
		card.get_node(stats_path + "profile/loam/value").text = str(loc.soil_loam) + "%"
		
		# Env Stats
		card.get_node(stats_path + "exposure/value").text = loc.exposure
		card.get_node(stats_path + "altitude/value").text = str(loc.altitude) + " mdpl"
		card.get_node(stats_path + "slope/value").text = str(loc.slope) + "%"
		card.get_node(stats_path + "ph/value").text = str(loc.ph_level)
		
		# Infrastructure (Masih dikunci / belum diimplementasi di data)
		card.get_node(stats_path + "terracing/value").text = "No"
		card.get_node(stats_path + "irrigation/value").text = "No"
		

		# Tree Info
		if tree:
			card.get_node(stats_path + "age/value").text = str(tree.age_years) + " yrs"
			card.get_node(stats_path + "plt_density/value").text = str(tree.planting_density) + "/Ha"
			card.get_node(stats_path + "health/value").text = str(tree.health_pct) + "%"
