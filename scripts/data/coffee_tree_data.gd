extends Resource
class_name CoffeeTreeData

@export var age_years: float = 2.0
@export var health_pct: float = 75.0
@export var current_brix: float = 8.0
@export var current_acidity: float = 88.0
@export var planting_density: int = 1450 # Pohon/Ha

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
