extends Resource
class_name FarmLocation

## Nama lahan perkebunan (tampil di UI).
@export var location_name: String = "Lahan 1"

# Geography & Environment
## Luas lahan dalam satuan Hektar (Ha).
@export var surface_area: float = 1.0 # Ha
## Arah hadap lahan (misal: 'Utara', 'Selatan') terhadap matahari.
@export var exposure: String = "East"
## Ketinggian lahan dari permukaan laut (mdpl).
@export var altitude: int = 1300 # mdpl
## Tingkat kemiringan lahan (%).
@export var slope: float = 10.0 # %

# Soil
## Kadar pH tanah di lahan ini (0-14).
@export var ph_level: float = 5.5
## Kandungan tekstur Pasir (Sand) pada tanah (%).
@export var soil_sand: float = 40.0 # %
## Kandungan tekstur Liat (Clay) pada tanah (%).
@export var soil_clay: float = 20.0 # %
## Kandungan tekstur Debu/Geluh (Loam) pada tanah (%). (Total Pasir + Liat + Debu = 100%).
@export var soil_loam: float = 40.0 # % (Must sum to 100 with sand & clay)
## Kualitas kesuburan tanah secara keseluruhan (0-100%).
@export var soil_quality: int = 80 # skala 0 - 100%

# Infrastructure
# @export var has_terracing: bool = false
# @export var has_irrigation: bool = false

## ID Varietas kopi (merujuk pada data varietas).
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
	current_tree.initialize_from_terroir(self)
