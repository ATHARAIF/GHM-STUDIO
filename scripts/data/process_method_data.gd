extends Resource
class_name ProcessMethodData

@export var method_name: String = ""
@export var description: String = ""
@export var override_cost: int = 0

@export_group("Quality Modifiers")
@export var mod_acidity: float = 0.0
@export var mod_aroma: float = 0.0
@export var mod_sweetness: float = 0.0
@export var mod_flavor: float = 0.0
@export var mod_body: float = 0.0
@export var mod_bitterness: float = 0.0
@export var mod_defect: float = 0.0
@export var mod_quant_pct: float = 0.0

@export_group("UI Display")
@export var ui_qual_text: String = ""
@export var ui_qual_color: Color = Color.WHITE
@export var ui_rip_text: String = ""
@export var ui_rip_color: Color = Color.WHITE
@export var ui_quant_text: String = ""
@export var ui_quant_color: Color = Color.WHITE

@export_group("Slider Data (Optional)")
@export var slider_levels: Array[ProcessMethodLevel] = []
