extends CanvasLayer

@onready var tab_buttons_container = $menu_panel/MarginContainer/HBoxContainer/tab_buttons
@onready var tab_contents_container = $menu_panel/MarginContainer/HBoxContainer/tab_contents

# Pemetaan antara nama tombol tab dengan nama node kontennya
var tab_mapping = {
	"tab_farmland": "tab_farmland",
	"tab_coffee_log": "tab_coffeelog",
	"tab_storage": "tab_storage",
	"tab_order": "tab_order",
	"tab_upgrade": "", # Belum ada konten
	"tab_balance": ""  # Belum ada konten
}

func _ready() -> void:
	# Hubungkan sinyal pressed dari setiap tombol tab
	for button in tab_buttons_container.get_children():
		if button is Button:
			button.pressed.connect(func(): _on_tab_pressed(button.name))
			
	# Tampilkan tab pertama secara default
	_on_tab_pressed("tab_farmland")

func _on_tab_pressed(button_name: String) -> void:
	var target_content_name = tab_mapping.get(button_name, "")
	
	# Sembunyikan semua konten terlebih dahulu
	for content in tab_contents_container.get_children():
		content.hide()
		
	# Tampilkan konten yang sesuai (jika ada)
	if target_content_name != "":
		var target_content = tab_contents_container.get_node_or_null(target_content_name)
		if target_content != null:
			target_content.show()
	else:
		print("Tab '", button_name, "' ditekan, tetapi belum memiliki konten.")
