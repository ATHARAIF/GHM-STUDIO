extends Resource
class_name FarmLocation

@export var location_name: String = "Lahan 1"

# Geography & Environment
@export var surface_area: float = 3.0 # Ha
@export var exposure: String = "East"
@export var altitude: int = 1300 # mdpl
@export var slope: float = 25.0 # %

# Soil
@export var ph_level: float = 5.5
@export var soil_sand: float = 40.0 # %
@export var soil_clay: float = 20.0 # %
@export var soil_quality: int = 80 # skala 0 - 100%
@export var soil_loam: float = 40.0 # % (Must sum to 100 with sand & clay)

# Infrastructure
# @export var has_terracing: bool = false
# @export var has_irrigation: bool = false

@export var variety_id: String = "arabika_kintamani"
var variety_data: CoffeeVariety

var current_tree: CoffeeTreeData

func _init() -> void:
	# Memuat data varietas secara default
	var dict = CoffeeVariety.get_dictionary()
	if dict.has(variety_id):
		variety_data = dict[variety_id]
	else:
		variety_data = CoffeeVariety.new() # Default fallback
		
	# Inisialisasi data pohon untuk demo
	current_tree = CoffeeTreeData.new()
	current_tree.calculate_adaptation_rate(self)
