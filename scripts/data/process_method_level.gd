extends Resource
class_name ProcessMethodLevel

## Nama level/intensitas ini (misal: 'Very Low', 'Medium', 'High').
@export var level_name: String = "Medium"
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

@export_group("UI Display")
## Teks indikator Kualitas yang akan muncul di Grid2 UI (misal: '+++' atau '-').
@export var ui_qual_text: String = ""
## Warna font untuk teks indikator Kualitas di UI.
@export var ui_qual_color: Color = Color.WHITE
## Teks indikator Kematangan (Ripeness) yang akan muncul di Grid2 UI.
@export var ui_rip_text: String = ""
## Warna font untuk teks indikator Kematangan di UI.
@export var ui_rip_color: Color = Color.WHITE
## Teks indikator Kuantitas yang akan muncul di Grid2 UI.
@export var ui_quant_text: String = ""
## Warna font untuk teks indikator Kuantitas di UI.
@export var ui_quant_color: Color = Color.WHITE
