extends Button

var tween: Tween

func _ready():
	# Mengatur titik tengah scale otomatis ke tengah tombol
	pivot_offset = size / 2
	
	# Nyambungin sinyal ditekan dan dilepas
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down():
	# Hentikan animasi sebelumnya kalau ada biar nggak error/tabrakan
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Efek ditekan: X melar jadi 110% (1.1), Y menciut jadi 80% (0.8)
	# Waktunya dibikin cepet (0.1 detik) biar responsif
	tween.tween_property(self, "scale", Vector2(1.1, 0.8), 0.1).set_trans(Tween.TRANS_SINE)

func _on_button_up():
	if tween:
		tween.kill()
	tween = create_tween()
	
	# Efek dilepas: Balik ke ukuran normal (1, 1) dengan gaya mantul (Elastic)
	# Waktunya agak dipanjangin (0.5 detik) biar efek goyang/bouncynya kelihatan
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.5)\
		.set_trans(Tween.TRANS_ELASTIC)\
		.set_ease(Tween.EASE_OUT)
