extends Resource
class_name CardData

## Nama kartu yang akan ditampilkan di UI.
@export var card_name: String = ""
## ID unik untuk kartu ini (misal: "FP01", "WP01"). Digunakan sistem untuk tracking apakah proses ini sudah diselesaikan.
@export var process_id: String = ""
## Biaya (Uang) yang dikurangi saat kartu dimainkan. (Akan digantikan oleh biaya dari ProcessMethod jika memiliki override_cost).
@export var cost: int = 0
## Jumlah Turn yang akan dihabiskan untuk menyelesaikan aksi dari kartu ini.
@export var duration: int = 1

@export_group("Interaction")
## Centang jika kartu ini memunculkan popup/UI interaksi LANGSUNG SAAT ditaruh di atas tile (Drag & Drop). Contoh: Roasting/Processing yang butuh setting sebelum mulai.
@export var placement_interaction: bool = false
## Centang jika kartu ini memunculkan popup/interaksi SETELAH durasi turn-nya habis di atas tile. (Tile akan berstatus 'Ready' dan harus diklik untuk mengambil hasil/popup lanjutan). Contoh: Panen (Harvest).
@export var requires_interaction: bool = false


## (Wajib jika Requires Interaction dicentang) File scene UI (.tscn) untuk interaksi awal (misal milih method/slider).
@export var custom_popup_ui: PackedScene
## (Opsional) File scene UI (.tscn) yang dimunculkan setelah proses selesai (Result Screen).
@export var custom_result_popup_ui: PackedScene

@export_group("Popup Data (For Complex Cards)")
## Daftar pilihan metode/alat yang dimasukkan ke popup UI. (Misal: Washed, Natural, Honey).
@export var popup_methods: Array[ProcessMethodData] = []
## Daftar pilihan tools (alat tambahan) yang dimasukkan ke popup UI.
@export var popup_tools: Array[ProcessMethodData] = []


@export_group("Effects")
## Tambahan poin Aroma ke batch kopi saat kartu ini sukses.
@export var effect_aroma: float = 0.0
## Tambahan poin Acidity ke batch kopi saat kartu ini sukses.
@export var effect_acidity: float = 0.0
## Tambahan poin Body ke batch kopi saat kartu ini sukses.
@export var effect_body: float = 0.0
## Tambahan poin Sweetness ke batch kopi saat kartu ini sukses.
@export var effect_sweetness: float = 0.0
## Tambahan poin Flavor ke batch kopi saat kartu ini sukses.
@export var effect_flavor: float = 0.0
## Tambahan poin Bitterness ke batch kopi saat kartu ini sukses.
@export var effect_bitterness: float = 0.0
## Perubahan % Moisture kopi (kelembaban) saat sukses.
@export var effect_moisture: float = 0.0
## Perubahan persentase defect (cacat) pada biji kopi saat sukses.
@export var effect_defect: float = 0.0
## Multiplier panen. (Misal 0.1 berarti nambah hasil 10%).
@export var effect_yield: float = 0.0
## Perubahan pada persentase Health (Kesehatan) pohon kopi saat sukses.
@export var effect_health: float = 0.0
#@export var effect_growth_rate: int = 0


@export_group("Penalty Effects (If missed)")
## Hukuman (pengurangan poin) Aroma jika pemain melewatkan (expired) kartu ini.
@export var penalty_aroma: float = 0.0
## Hukuman (pengurangan poin) Acidity jika pemain melewatkan kartu ini.
@export var penalty_acidity: float = 0.0
## Hukuman (pengurangan poin) Body jika pemain melewatkan kartu ini.
@export var penalty_body: float = 0.0
## Hukuman (pengurangan poin) Sweetness jika pemain melewatkan kartu ini.
@export var penalty_sweetness: float = 0.0
## Hukuman (pengurangan poin) Flavor jika pemain melewatkan kartu ini.
@export var penalty_flavor: float = 0.0
## Hukuman poin Bitterness jika pemain melewatkan kartu ini.
@export var penalty_bitterness: float = 0.0
## Hukuman % Moisture jika pemain melewatkan kartu ini.
@export var penalty_moisture: float = 0.0
## Penambahan Defect (cacat) jika pemain melewatkan kartu ini.
@export var penalty_defect: float = 0.0
## Pengurangan hasil panen jika kartu perawatan ini dilewatkan.
@export var penalty_yield: float = 0.0
## Pengurangan health (kesehatan pohon) karena pemain mengabaikan kartu ini.
@export var penalty_health: float = 0.0



@export_group("Availability")
## Tipe kemunculan kartu.
## RECURRING_ANNUAL = Muncul berulang tiap tahun di batas turn tertentu (bisa kena penalti missed).
## ONE_TIME_UNLOCK = Terkunci sampai tahun/turn tertentu tercapai, lalu ada selamanya.
## EVENT_DRIVEN = Terkunci sampai aksi di Unlock Condition selesai, lalu muncul terus menerus.
enum AvailabilityType { RECURRING_ANNUAL, ONE_TIME_UNLOCK, EVENT_DRIVEN }
@export var availability: AvailabilityType = AvailabilityType.RECURRING_ANNUAL


#RECURRING_ANNUAL
#
#Fungsi: Kartu muncul rutin setiap tahun pada jendela waktu tertentu (diatur oleh Active Start Turn sampai Active End Turn).
#Aturan: Jika waktu sudah habis dan kartu belum dimainkan, kartu tersebut akan hangus dan Sistem Penalti akan aktif.
#Dipakai oleh: Kartu Perawatan Lahan (Weeding, Pruning, Suckering) & Harvest.

## Turn dimulainya kartu ini muncul di tangan (khusus RECURRING_ANNUAL).
@export var active_start_turn: int = 1
## Turn batas akhir. Lewat dari turn ini kartu akan hangus & pemain kena penalti (khusus RECURRING_ANNUAL).
@export var active_end_turn: int = 20


#ONE_TIME_UNLOCK
#
#Fungsi: Kartu disembunyikan sampai Tahun & Turn tertentu tercapai, lalu terbuka secara permanen.
#Dipakai oleh: Biasanya untuk kartu-kartu perkenalan fitur baru (tutorial) atau upgrade mesin di masa depan.
## Tahun dimana kartu ini pertama kali boleh dimunculkan (khusus ONE_TIME_UNLOCK).
@export var unlock_year: int = 2025
## Turn spesifik di tahun tersebut dimana kartu baru akan terbuka (khusus ONE_TIME_UNLOCK).
@export var unlock_turn: int = 1

#EVENT_DRIVEN (Baru saja saya terapkan!)
#
#Fungsi: Kartu disembunyikan sampai syarat event tertentu (Unlock Condition) terpenuhi. Begitu syaratnya terpenuhi, kartu ini akan terus muncul dan TIDAK dibatasi oleh waktu (tidak akan pernah hangus/terlewat).
#Penerapan: Saya sudah menyetel kartu pasca-panen ke tipe ini.
#Kartu Cleaning sekarang mencari syarat "FP04" (Selesai Harvest).
#Kartu Dry mencari syarat "WP01" (Selesai Cleaning).
#Kartu Roasting mencari syarat "WP02" (Selesai Dry).
#Efek: Berkat ini, kartu pasca-panen akan muncul berantai secara otomatis setelah panen beres, dan Anda bisa santai mengerjakannya tanpa diburu target batas Turn!
## ID Proses kartu lain yang harus diselesaikan dulu sebelum kartu ini muncul. (misal isi dengan "FP04" agar kartu ini muncul setelah panen) (Khusus EVENT_DRIVEN).
@export var unlock_condition: String = ""
