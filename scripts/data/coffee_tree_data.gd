extends Resource
class_name CoffeeTreeData

@export_group("Tree Health & Disease")
## Umur pohon kopi dalam satuan tahun.
@export var age_years: float = 2.0
## Persentase kesehatan pohon kopi (0-100%).
@export var health_pct: float = 75.0
## Tingkat penyakit pada pohon (Disease) yang bisa menjalar. Berbeda dengan defect pada biji.
@export var disease_rate: float = 0.0
## Kerapatan tanam (Jumlah pohon per Hektar).
@export var planting_density: int = 1600 # Pohon/Ha

@export_group("Cherry & Bean Stats (Phenotype)")
## Kadar gula (Brix) pada ceri kopi di pohon ini.
## Nilai mutakhir Acidity (Keasaman) kopi.
@export var current_acidity: float = 0.0
## Nilai mutakhir Aroma kopi.
@export var current_aroma: float = 0.0
## Nilai mutakhir Sweetness (Manis) kopi.
@export var current_sweetness: float = 0.0
## Nilai mutakhir Body (Kekentalan) kopi.
@export var current_body: float = 0.0
## Nilai mutakhir Flavor (Rasa) kopi.
@export var current_flavor: float = 0.0
## Nilai mutakhir Bitterness (Pahit) kopi.
@export var current_bitterness: float = 0.0

## Persentase cacat pada biji ceri kopi (sensoris).
@export var current_defect: float = 0.0
## Persentase kadar air awal pada ceri.
@export var current_moisture: float = 0.0
## Potensi kuantitas hasil panen (Kg).
@export var current_yield_potential: int = 0

var cached_adaptation_rate: float = 1.0

# Calculate how well this tree adapts to the given farm location, returning 0.0 to 1.0
func calculate_adaptation_rate(farm: FarmLocation) -> float:
	if farm == null or farm.variety_data == null:
		return 0.5
		
	var var_data = farm.variety_data
	var score: float = 0.0
	
	# 1. Altitude Score (Weight: 30%)
	var alt_score = 0.0
	var alt = farm.altitude
	if alt >= var_data.ideal_altitude_min and alt <= var_data.ideal_altitude_max:
		alt_score = 1.0
	elif alt >= var_data.safe_altitude_min and alt <= var_data.safe_altitude_max:
		alt_score = 0.5
	else:
		alt_score = 0.0
	
	# 2. pH Score (Weight: 20%)
	var ph_score = 0.0
	var ph = farm.ph_level
	if ph >= var_data.ideal_ph_min and ph <= var_data.ideal_ph_max:
		ph_score = 1.0
	elif ph >= var_data.safe_ph_min and ph <= var_data.safe_ph_max:
		ph_score = 0.5
	else:
		ph_score = 0.0
		
	# 3. Slope Score (Weight: 10%)
	var slp_score = 0.0
	var slp = farm.slope
	if slp >= var_data.ideal_slope_min and slp <= var_data.ideal_slope_max:
		slp_score = 1.0
	elif slp >= var_data.safe_slope_min and slp <= var_data.safe_slope_max:
		slp_score = 0.5
	else:
		slp_score = 0.0
		
	# 4. Soil Score (Weight: 20%)
	var soil_score = 0.0
	var sand = farm.soil_sand
	var clay = farm.soil_clay
	if (sand >= var_data.ideal_sand_min and sand <= var_data.ideal_sand_max) and (clay >= var_data.ideal_clay_min and clay <= var_data.ideal_clay_max):
		soil_score = 1.0
	else:
		# Very simplified soil penalty
		soil_score = 0.5
		
	# 5. Density Score (Weight: 20%)
	var den_score = 0.0
	if planting_density >= var_data.ideal_density_min and planting_density <= var_data.ideal_density_max:
		den_score = 1.0
	elif planting_density >= var_data.safe_density_min and planting_density <= var_data.safe_density_max:
		den_score = 0.5
	else:
		den_score = 0.0
		
	# Total Calculation
	score = (alt_score * 0.3) + (ph_score * 0.2) + (slp_score * 0.1) + (soil_score * 0.2) + (den_score * 0.2)
	cached_adaptation_rate = score
	return score

# Utility function to get color for UI based on score
static func get_color_for_score(score: float) -> Color:
	if score >= 0.8:
		return Color(0.2, 0.8, 0.2) # Green (Ideal)
	elif score >= 0.4:
		return Color(0.8, 0.8, 0.2) # Yellow (Safe)
	else:
		return Color(0.8, 0.2, 0.2) # Red (Bad)

func get_age_yield_pct(age: int) -> float:
	if age < 2: return 0.0
	elif age == 2: return 0.30
	elif age == 3: return 0.40
	elif age == 4: return 0.50
	elif age == 5: return 0.50
	elif age == 6: return 0.70
	elif age == 7: return 0.80
	elif age == 8: return 0.85
	elif age == 9: return 0.90
	elif age == 10: return 0.95
	elif age <= 15: return 0.90
	elif age <= 20: return 0.70
	else: return 0.60

# Initialize tree stats based on terroir match
func initialize_from_terroir(farm: FarmLocation) -> void:
	if farm == null or farm.variety_data == null:
		return
		
	var score = calculate_adaptation_rate(farm)
	
	# Terroir is temporarily DISABLED per user request. Multiplier is always 100% (1.0).
	var actual_multiplier = 1.0
	
	var v_data = farm.variety_data
	
	# Apply multiplier to sensory stats (Phenotype)
	current_acidity = clamp(v_data.base_acidity * actual_multiplier, 0.0, 10.0)
	current_aroma = clamp(v_data.base_aroma * actual_multiplier, 0.0, 10.0)
	current_sweetness = clamp(v_data.base_sweetness * actual_multiplier, 0.0, 10.0)
	current_body = clamp(v_data.base_body * actual_multiplier, 0.0, 10.0)
	current_flavor = clamp(v_data.base_flavor * actual_multiplier, 0.0, 10.0)
	current_bitterness = clamp(v_data.base_bitterness * actual_multiplier, 0.0, 10.0)
	
	# Base yields and defects
	current_moisture = v_data.base_moisture
	var plant_density: int = planting_density
	var max_yield_per_plant: float = 10.0
	var max_yield = farm.surface_area * plant_density * max_yield_per_plant
	var age_pct = get_age_yield_pct(age_years)
	var yield_age = max_yield * age_pct
	# current_yield_potential is now calculated dynamically at harvest
	
	# Defects and Diseases might INCREASE if the score is low!
	# E.g., if match is 100%, disease is 0%. If match is 50%, disease is higher.
	var penalty_factor = 1.0 - actual_multiplier # 0.0 to 0.5
	
	disease_rate = penalty_factor * 20.0 # up to 10% disease instantly for bad terroir
	current_defect = v_data.base_defect_rate + (penalty_factor * 10.0) # up to 5% extra defect

func calculate_harvest_yield() -> int:
	var plant_density: int = planting_density
	var max_yield_per_plant: float = 10.0
	
	# Try to find the farm to get surface area
	var em = Engine.get_main_loop().root.get_node_or_null("StageManager")
	var surface_area = 1.0 # Default 1 Ha
	if em and em.current_location:
		surface_area = em.current_location.surface_area
		
	var max_yield = surface_area * plant_density * max_yield_per_plant
	var age_pct = get_age_yield_pct(age_years)
	var yield_age = max_yield * age_pct
	return int(yield_age * (health_pct / 100.0))
