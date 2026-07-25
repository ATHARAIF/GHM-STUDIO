extends CanvasLayer # Ganti ini sesuai tipe node tempat script ini nempel (kalo CanvasLayer ya biarin aja)

# 1. Ambil referensi ke semua layer shader
@onready var crt_shader = $CRT_Shader
@onready var basic_shader = $basic_Shader
@onready var rain_shader = $raining
@onready var snow_shader = $snow

# 2. Ambil referensi ke semua tombol di dalam HBoxContainer
@onready var btn_crt = $HBoxContainer/CRT
@onready var btn_basic = $HBoxContainer/basic
@onready var btn_rain = $HBoxContainer/rain
@onready var btn_snow = $HBoxContainer/snow

func _ready():
	
	# Opsional: Atur shader mana yang nyala pertama kali pas game mulai
	# Di sini gw set default-nya ke 'snow' sesuai screenshot lo
	matikan_semua_shader()
	basic_shader.visible = true


# Fungsi helper buat nyembunyiin semua shader sekaligus biar ga repot
func matikan_semua_shader():
	crt_shader.visible = false
	basic_shader.visible = false
	rain_shader.visible = false
	snow_shader.visible = false


# ==========================================
# FUNGSI YANG JALAN PAS TOMBOL DIPENCET
# ==========================================

func _on_crt_pressed():
	matikan_semua_shader() # Matiin semua dulu
	crt_shader.visible = true # Baru nyalain yang CRT

func _on_basic_pressed():
	matikan_semua_shader()
	basic_shader.visible = true

func _on_rain_pressed():
	matikan_semua_shader()
	rain_shader.visible = true

func _on_snow_pressed():
	matikan_semua_shader()
	snow_shader.visible = true
