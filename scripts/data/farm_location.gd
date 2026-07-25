extends Resource
class_name FarmLocation

@export var location_name: String = "Ladang 1"
@export var altitude: int = 1400 # dalam meter
@export var soil_quality: int = 80 # skala 0 - 100

# Base stat untuk varietas yang ditanam di lahan ini (Arabika Gayo)
@export_group("Base Coffee Stats")
@export var base_aroma: int = 2
@export var base_body: int = 1
@export var base_acidity: int = 2
@export var base_sweetness: int = 1
@export var base_complexity: int = 1
@export var base_aftertaste: int = 1
@export var base_moisture: float = 25.0
@export var base_defect_rate: float = 10.0
@export var base_yield: int = 1000

# --- REKOMENDASI STAT LAHAN TAMBAHAN ---
# Anda bisa menghapus tanda '#' (uncomment) pada variabel di bawah ini 
# di masa depan jika ingin mekanik lingkungannya lebih kompleks (contoh untuk cuaca):
#
# @export var temperature_avg: float = 20.0  # Suhu rata-rata, bisa mempengaruhi growth rate
# @export var rainfall_mm: float = 1500.0    # Curah hujan, bisa mempengaruhi moisture & risiko jamur
# @export var pest_risk: float = 5.0         # Risiko hama alami, menambah/mengurangi base defect rate
