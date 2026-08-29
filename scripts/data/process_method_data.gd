extends Resource
class_name ProcessMethodData

## Nama metode/alat yang akan tampil di layar popup (misal: 'Honey', 'Patio').
@export var method_name: String = ""
## Deskripsi singkat mengenai metode/alat ini.
@export var description: String = ""
## Biaya mutlak yang akan digunakan (menggantikan Base Cost kartu) saat metode ini dipilih.
@export var override_cost: int = 0
## Waktu (Turn/Giliran) tambahan yang dibutuhkan jika metode/alat ini dipilih.
@export var turn_duration: int = 0
## Urutan tampil (dari kiri ke kanan) di layar popup. Semakin kecil angkanya, semakin di kiri.
@export var sort_order: int = 0

@export_group("Quality Modifiers")
@export var mod_health: float = 0.0
## Bonus/Penalti (tambah/kurang) ke atribut Acidity kopi.
@export var mod_acidity: float = 0.0
## Bonus/Penalti (tambah/kurang) ke atribut Aroma kopi.
@export var mod_aroma: float = 0.0
## Bonus/Penalti (tambah/kurang) ke atribut Sweetness kopi.
@export var mod_sweetness: float = 0.0
## Bonus/Penalti (tambah/kurang) ke atribut Flavor kopi.
@export var mod_flavor: float = 0.0
## Bonus/Penalti (tambah/kurang) ke atribut Body kopi.
@export var mod_body: float = 0.0
## Bonus/Penalti (tambah/kurang) ke atribut Bitterness kopi.
@export var mod_bitterness: float = 0.0
## Bonus/Penalti (tambah/kurang) persentase Defect (Cacat) kopi.
@export var mod_defect: float = 0.0
## Persentase (desimal 0.0-1.0) perubahan pada kuantitas total hasil panen.
@export var mod_quant_pct: float = 0.0

@export_group("Radar Graph UI")
## Nilai Kualitas (0-10) untuk ditampilkan di Radar Graph.
@export var radar_quality: float = 5.0
## Nilai Kematangan/Ripeness (0-10) untuk ditampilkan di Radar Graph.
@export var radar_ripeness: float = 5.0
## Nilai Kuantitas/Yield (0-10) untuk ditampilkan di Radar Graph.
@export var radar_quantity: float = 5.0

@export_group("Slider Data (Optional)")
## Daftar tingkatan efek jika metode ini menggunakan Slider (seperti pada Pruning). Kosongkan jika tidak memakai Slider.
@export var slider_levels: Array[ProcessMethodLevel] = []

@export_group("Compatibility")
## Daftar ID/Nama metode yang bisa digabungkan dengan alat ini. (Fitur kompatibilitas silang).
@export var allowed_methods: Array[String] = []
