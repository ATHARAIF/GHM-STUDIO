extends Resource
class_name FarmLocation

@export var location_name: String = "Lahan 1"
@export var altitude: int = 1400 # dalam meter
@export var soil_quality: int = 80 # skala 0 - 100

@export var variety_id: String = "arabika_kintamani"
var variety_data: CoffeeVariety

func _init() -> void:
	# Memuat data varietas secara default
	var dict = CoffeeVariety.get_dictionary()
	if dict.has(variety_id):
		variety_data = dict[variety_id]
	else:
		variety_data = CoffeeVariety.new() # Default fallback
