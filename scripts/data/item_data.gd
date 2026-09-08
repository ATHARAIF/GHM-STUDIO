class_name ItemData
extends Resource

@export_group("Core Settings")
@export var item_name: String = "Mesin Baru"
@export var item_id: String = "item_000"

enum ItemCategory { HOPPER, PULPER, DRYER, ROASTER, PACKAGING, DECORATION, TOOL }
@export var category: ItemCategory = ItemCategory.HOPPER

@export_group("Economy")
## Harga beli di toko
@export var buy_price: int = 1000
## Harga jual kembali
@export var sell_price: int = 500

@export_group("Machine Specs")
## Kapasitas maksimal (dalam kg) yang bisa ditampung oleh mesin ini
@export var max_capacity: int = 4000
## Efisiensi/kecepatan (untuk kalkulasi buff waktu)
@export var efficiency_multiplier: float = 1.0

@export_group("Visuals")
## Ikon untuk ditampilkan di Shop atau UI Pemilihan Mesin
@export var icon: Texture2D
## Wujud 3D untuk lantai pabrik
@export var tile_scene: PackedScene
