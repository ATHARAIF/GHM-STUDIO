class_name ItemData
extends Resource

## Data satu jenis item yang bisa dibeli di Shop / muncul di Inventory.
## Buat file .tres dari script ini lewat: klik kanan di FileSystem
## -> New Resource -> cari "ItemData", lalu isi field-nya di Inspector.

@export var item_name: String = ""
@export var icon: Texture2D
@export var price: int = 0
@export_enum("storage", "rooms") var category: String = "storage"
@export_multiline var description: String = ""

## Ukuran item dalam satuan TILE, sebelum rotate. x = lebar, y = kedalaman.
## Contoh: mesin roasting 2x1 -> Vector2i(2, 1). Item persegi biasa -> Vector2i(1, 1).
## Ini yang nentuin berapa kotak grid yang "kepake" pas item ditaro.
@export var footprint_size: Vector2i = Vector2i(1, 1)

## Tinggi collision box (meter), buat area klik/drag/select. Nggak perlu presisi,
## asal kira-kira sesuai tinggi item aslinya.
@export var collision_height: float = 0.5

## OPSIONAL: kalau diisi, PlacedItem bakal pake model 3D ini alih-alih dummy box.
## Model harus PackedScene (.tscn), pivot-nya diasumsikan ada di ALAS/BAWAH model
## (bukan di tengah), biar nempel pas di lantai.
@export var model_scene: PackedScene

## Skala mesh visual model_scene (1.0 = ukuran asli). Naikin/turunin kalau
## modelnya kegedean/kekecilan dibanding footprint_size. Diabaikan kalau model_scene kosong.
## Kalau Auto Fit To Footprint aktif, ini jadi skala TAMBAHAN di atas hasil auto-fit
## (biasanya biarin aja 1.0).
@export var model_scale: Vector3 = Vector3.ONE

## Kalau true (default), model otomatis diskalain biar pas muat di area
## footprint_size (nggak perlu tebak-tebak angka Model Scale manual).
## Matiin kalau mau kontrol skala 100% manual lewat Model Scale di atas.
@export var auto_fit_to_footprint: bool = true

## AKTIFKAN ini kalau Model Scene yang kamu pasang itu udah scene GABUNGAN
## (plate + model jadi satu, di-scale/posisiin manual di editor kayak
## workflow bikin tile decoration). Kalau true, sistem SAMA SEKALI nggak
## nambahin plate lagi & nggak ngatur ulang scale/posisi model -- scene-nya
## di-pasang APA ADANYA. Semua field auto-fit/scale/offset di bawah bakal
## diabaikan.
@export var model_includes_own_plate: bool = false

## Tinggi TARGET model (meter, dalam skala yang sama kayak tile_size).
## Dipake buat auto-fit sumbu Y, biar model nggak keliatan menjulang gede
## atau kekecilan dibanding tile-nya. Diabaikan kalau Auto Fit To Footprint mati.
@export var target_height: float = 1.0

## Geser mesh visual ke atas/bawah (meter) buat kompensasi kalau pivot model
## nggak persis di alas/bawah. Negatif = turun, positif = naik.
@export var model_y_offset: float = 0.0

## Putar mesh visual di tempat (derajat, sumbu Y) buat koreksi kalau arah
## hadap model aslinya nggak lurus sama grid tile kita. Ini KOREKSI SEKALI
## di awal, terpisah dari rotate 90 derajat pas main (tombol R).
@export var model_rotation_offset: float = 0.0
