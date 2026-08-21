extends Resource
class_name CoffeeVariety


## Spesies kopi (misal: 'Arabika', 'Robusta').
@export var species_name: String = "Arabika"
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


@export_group("Target Ideal Real")
## Target Ideal Acidity di dunia nyata (1-10).
@export var target_acidity: int = 8
## Target Ideal Aroma di dunia nyata (1-10).
@export var target_aroma: int = 9
## Target Ideal Sweetness di dunia nyata (1-10).
@export var target_sweetness: int = 7
## Target Ideal Flavor di dunia nyata (1-10).
@export var target_flavor: int = 8
## Target Ideal Body di dunia nyata (1-10).
@export var target_body: int = 5
## Target Ideal Bitterness di dunia nyata (1-10).
@export var target_bitterness: int = 2

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
	
	var kintamani = CoffeeVariety.new()
	kintamani.species_name = "Arabika"
	kintamani.variety_name = "Kintamani"
	kintamani.base_acidity = 0
	kintamani.base_aroma = 0
	kintamani.base_sweetness = 3
	kintamani.base_body = 8
	kintamani.base_flavor = 0
	kintamani.base_bitterness = 4
	kintamani.target_acidity = 8
	kintamani.target_aroma = 9
	kintamani.target_sweetness = 7
	kintamani.target_flavor = 8
	kintamani.target_body = 5
	kintamani.target_bitterness = 2

	# Terroir is already initialized to Arabica defaults above
	dict["arabika_kintamani"] = kintamani
	
	var robusta = CoffeeVariety.new()
	robusta.species_name = "Robusta"
	robusta.variety_name = "Dampit"
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
