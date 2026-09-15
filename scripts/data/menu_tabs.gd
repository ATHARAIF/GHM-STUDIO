extends CanvasLayer

# --- Tombol tab (sesuai struktur: header/tabs/...) ---
@onready var btn_terroir = $header/tabs/terroir
@onready var btn_coffee_log = $header/tabs/coffee_log
@onready var btn_storage = $header/tabs/storage
@onready var btn_order = $header/tabs/order
@onready var btn_upgrade = $header/tabs/upgrade
@onready var btn_balance = $header/tabs/balance

# --- Konten tiap tab (node kosong "content/Terroir" dst) ---
@onready var content_terroir = $content/Terroir
@onready var content_coffee_log = $content/CoffeeLog
@onready var content_storage = $content/Storage
@onready var content_order = $content/Order
@onready var content_upgrade = $content/Upgrade
@onready var content_balance = $content/Balance

var tab_map: Array = []

func _ready() -> void:
	tab_map = [
		{"button": btn_terroir, "content": content_terroir},
		{"button": btn_coffee_log, "content": content_coffee_log},
		{"button": btn_storage, "content": content_storage},
		{"button": btn_order, "content": content_order},
		{"button": btn_upgrade, "content": content_upgrade},
		{"button": btn_balance, "content": content_balance},
	]

	for tab in tab_map:
		if tab.button:
			tab.button.pressed.connect(func(): _switch_tab(tab.content))

	# Default: tab pertama yang kebuka duluan waktu panel muncul
	_switch_tab(content_terroir)

func _switch_tab(active_content: Control) -> void:
	for tab in tab_map:
		if tab.content:
			tab.content.visible = (tab.content == active_content)
