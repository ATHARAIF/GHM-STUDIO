extends Resource
class_name CoffeeVariety


## Spesies kopi (misal: 'Arabika', 'Robusta').
@export var species_name: String = "Arabica"
## Nama varietas kopi (misal: 'Kintamani').
@export var variety_name: String = "Kintamani"


@export_group("Base Stats")
## Nilai bawaan (Base) Acidity untuk varietas ini (1-10).
@export var base_acidity: int = 8
## Nilai bawaan (Base) Aroma untuk varietas ini (1-10).
@export var base_aroma: int = 7
## Nilai bawaan (Base) Sweetness untuk varietas ini (1-10).
@export var base_sweetness: int = 6
## Nilai bawaan (Base) Body untuk varietas ini (1-10).
@export var base_body: int = 4
## Nilai bawaan (Base) Flavor untuk varietas ini (1-10).
@export var base_flavor: int = 7
## Nilai bawaan (Base) Bitterness untuk varietas ini (1-10).
@export var base_bitterness: int = 3


@export_group("Target Ideal")
@export var target_acidity: float = 9.0
@export var target_aroma: float = 9.0
@export var target_sweetness: float = 7.0
@export var target_flavor: float = 10.0
@export var target_body: float = 5.0
@export var target_bitterness: float = 2.0

@export_group("Penalty Weights")
@export var penalty_weight_acidity: float = 0.05
@export var penalty_weight_aroma: float = 0.05
@export var penalty_weight_sweetness: float = 0.03
@export var penalty_weight_flavor: float = 0.03
@export var penalty_weight_body: float = 0.01
@export var penalty_weight_bitterness: float = 0.01

@export_group("Farm Baseline")
## Persentase bawaan awal Moisture ceri untuk varietas ini (%).
@export var base_moisture: float = 25.0
## Persentase bawaan rata-rata cacat untuk varietas ini (%).
@export var base_defect_rate: float = 5.0
## Potensi hasil panen maksimal per Hektar (Kg/Ha).
@export var base_yield_potential: int = 1000 # kg per Ha

@export_group("Ideal Thresholds (Terroir)")
# Altitude
## Batas bawah ketinggian ideal (mdpl).
@export var ideal_altitude_min: int = 1200
## Batas atas ketinggian ideal (mdpl).
@export var ideal_altitude_max: int = 1500
## Batas bawah ketinggian yang masih bisa ditoleransi (mdpl).
@export var safe_altitude_min: int = 1000
## Batas atas ketinggian yang masih bisa ditoleransi (mdpl).
@export var safe_altitude_max: int = 1800

# pH
## Batas bawah pH tanah ideal.
@export var ideal_ph_min: float = 5.2
## Batas atas pH tanah ideal.
@export var ideal_ph_max: float = 6.0
## Batas bawah pH tanah yang masih bisa ditoleransi.
@export var safe_ph_min: float = 4.8
## Batas atas pH tanah yang masih bisa ditoleransi.
@export var safe_ph_max: float = 6.5

# Slope (%)
## Batas bawah kemiringan lahan ideal (%).
@export var ideal_slope_min: float = 15.0
## Batas atas kemiringan lahan ideal (%).
@export var ideal_slope_max: float = 30.0
## Batas bawah kemiringan lahan yang masih ditoleransi (%).
@export var safe_slope_min: float = 0.0
## Batas atas kemiringan lahan yang masih ditoleransi (%).
@export var safe_slope_max: float = 45.0

# Soil Composition
## Kadar minimum Pasir (Sand) ideal di tanah (%).
@export var ideal_sand_min: float = 30.0
## Kadar maksimum Pasir (Sand) ideal di tanah (%).
@export var ideal_sand_max: float = 50.0
## Kadar minimum Liat (Clay) ideal di tanah (%).
@export var ideal_clay_min: float = 15.0
## Kadar maksimum Liat (Clay) ideal di tanah (%).
@export var ideal_clay_max: float = 25.0
# Loam/Silt is the remainder

# Planting Density
## Kerapatan tanam minimum yang ideal (Pohon/Ha).
@export var ideal_density_min: int = 1300
## Kerapatan tanam maksimum yang ideal (Pohon/Ha).
@export var ideal_density_max: int = 2000
## Kerapatan tanam minimum yang masih ditoleransi (Pohon/Ha).
@export var safe_density_min: int = 1000
## Kerapatan tanam maksimum yang masih ditoleransi (Pohon/Ha).
@export var safe_density_max: int = 2500


# Kamus Varietas
static func get_dictionary() -> Dictionary:
	var dict = {}
	
	var k_path = "res://resources/varieties/kintamani.tres"
	if ResourceLoader.exists(k_path):
		dict["arabika_kintamani"] = load(k_path)
		
	return dict
