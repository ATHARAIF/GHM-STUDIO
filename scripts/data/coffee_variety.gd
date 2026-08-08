extends Resource
class_name CoffeeVariety

@export var variety_name: String = "Arabika Kintamani"

@export_group("Base Stats")
@export var base_acidity: int = 8
@export var base_aroma: int = 7
@export var base_sweetness: int = 6
@export var base_body: int = 4
@export var base_flavor: int = 7
@export var base_bitterness: int = 3

@export_group("Farm Baseline")
@export var base_moisture: float = 25.0
@export var base_defect_rate: float = 5.0
@export var base_yield_potential: int = 1000 # kg per Ha

@export_group("Ideal Thresholds (Terroir)")
# Altitude
@export var ideal_altitude_min: int = 1200
@export var ideal_altitude_max: int = 1500
@export var safe_altitude_min: int = 1000
@export var safe_altitude_max: int = 1800

# pH
@export var ideal_ph_min: float = 5.2
@export var ideal_ph_max: float = 6.0
@export var safe_ph_min: float = 4.8
@export var safe_ph_max: float = 6.5

# Slope (%)
@export var ideal_slope_min: float = 15.0
@export var ideal_slope_max: float = 30.0
@export var safe_slope_min: float = 0.0
@export var safe_slope_max: float = 45.0

# Soil Composition
@export var ideal_sand_min: float = 30.0
@export var ideal_sand_max: float = 50.0
@export var ideal_clay_min: float = 15.0
@export var ideal_clay_max: float = 25.0
# Loam/Silt is the remainder

# Planting Density
@export var ideal_density_min: int = 1300
@export var ideal_density_max: int = 2000
@export var safe_density_min: int = 1000
@export var safe_density_max: int = 2500

# Kamus Varietas
static func get_dictionary() -> Dictionary:
	var dict = {}
	
	var kintamani = CoffeeVariety.new()
	kintamani.variety_name = "Arabika Kintamani"
	kintamani.base_acidity = 8
	kintamani.base_aroma = 7
	kintamani.base_sweetness = 6
	kintamani.base_body = 4
	kintamani.base_flavor = 7
	kintamani.base_bitterness = 3
	# Terroir is already initialized to Arabica defaults above
	dict["arabika_kintamani"] = kintamani
	
	var robusta = CoffeeVariety.new()
	robusta.variety_name = "Robusta Dampit"
	robusta.base_acidity = 1
	robusta.base_aroma = 5
	robusta.base_sweetness = 2
	robusta.base_body = 9
	robusta.base_flavor = 4
	robusta.base_bitterness = 8
	# Robusta Terroir Adjustments
	robusta.ideal_altitude_min = 400
	robusta.ideal_altitude_max = 800
	robusta.safe_altitude_min = 200
	robusta.safe_altitude_max = 900
	dict["robusta_dampit"] = robusta
	
	return dict
