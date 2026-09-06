extends Button

func _on_toggled(toggled_on: bool) -> void:
	# Bikin animasi baru
	var tween = create_tween()
	
	# Tentukan ukuran: 120 kalau lagi pressed, 96 kalau normal
	var target_width = 120 if toggled_on else 96
	
	# Animasi mengubah custom_minimum_size.x selama 0.15 detik
	tween.tween_property(self, "custom_minimum_size:x", target_width, 0.15).set_trans(Tween.TRANS_SINE)
