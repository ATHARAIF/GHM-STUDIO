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
@export var base_moisture: float = 12.0
@export var base_defect_rate: float = 5.0
@export var base_yield_potential: int = 1000 # kg per Ha

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
	dict["arabika_kintamani"] = kintamani
	
	var robusta = CoffeeVariety.new()
	robusta.variety_name = "Robusta Dampit"
	robusta.base_acidity = 1
	robusta.base_aroma = 5
	robusta.base_sweetness = 2
	robusta.base_body = 9
	robusta.base_flavor = 4
	robusta.base_bitterness = 8
	dict["robusta_dampit"] = robusta
	
	return dict
