extends Control
## Logic Quest - 1-р хэсэг. UI бүхлээрээ кодоор бүтдэг.

const OPS := [">", ">=", "<", "<=", "==", "!="]
# Кодын мөрийн өнгө (харанхуй код самбар дээр). Бусад өнгө UiTheme-д.
const ROW_BASE := Color("282B42")
const ROW_CURRENT := Color("3A3B4A")
const ROW_DONE := Color("223A31")
const ROW_SKIP := Color("2A2C3A")
const ROW_ERR := Color("4A2430")
const YELLOW := UiTheme.GLOW

var templates: Array = Levels.get_levels()
var level_index := 0
var cur: Dictionary = {}
var interp := Interp.new()
var program: Array = []
var states: Array = []   # мөр бүрт: 0 хүлээж буй, 1 дууссан, 2 алгассан, 3 алдаа
var started := false
var finished := false
var busy := false
var run_token := 0
var anim_speed := 1.0
var sel_index := -1
var row_tokens: Array = []
var box_panels: Dictionary = {}
var pending_crowd: Array = []
var guess_entered := false   # predict: тоглогч энэ оролдлогод таамаглалаа оруулсан эсэх
# Бүлэг сонгох дэлгэц (route_view.gd) ба хадгалсан ахиц.
var progress: Progress
var route_view: RouteView
var level_ui: MarginContainer   # түвшний бүх UI (маршрут харагдах үед нуугдана)
var level_mistakes := 0         # энэ түвшинд гаргасан алдаа (од тооцоход)
var level_cleared := false      # энэ түвшин энэ удаа давагдсан эсэх (од нэг л удаа бичигдэнэ)
var mono_font: Font
var chapter_chip: PanelContainer   # дээд мөр: бүлгийн нэр (бүлгийн өнгөөр)
var chapter_label: Label
var stars_label: Label             # дээд мөр: энэ түвшний хамгийн сайн од
var hint_btn: Button               # «?»: нэмэлт тайлбар (cur.hint)
var top_bar: HBoxContainer
var code_card: PanelContainer      # predict / arrange: харанхуй C++ самбар

var title_label: Label
var story_label: Label
var main_row: HBoxContainer
var code_box: VBoxContainer
var boxes: HFlowContainer
var guard_panel: HBoxContainer
var guard_view: GuardView
var op1: OptionButton
var val1: SpinBox
var rule2_row: HBoxContainer
var join_opt: OptionButton
var op2: OptionButton
var val2: SpinBox
var guard_code: Label
var cinema_panel: HBoxContainer
var ca_op: OptionButton
var ca_val: SpinBox
var ca_price: SpinBox
var cb_op: OptionButton
var cb_val: SpinBox
var cb_price: SpinBox
var cc_price: SpinBox
var cd_val: SpinBox
var cd_minus: SpinBox
var ce_val: SpinBox
var ce_mult: SpinBox
var cin_list: ItemList
var tutorial_panel: VBoxContainer
# Нөхцлийн (flow) түвшнүүд: тайлбар (explain) → мини тест (test) → дууссан (done)
var flow_panel: VBoxContainer
var challenge: ChallengePanel
var flow_code: VBoxContainer
var flow_view: FlowView
var flow_in_slot: VBoxContainer
var flow_out_slot: VBoxContainer
var flow_in_panel: PanelContainer
var flow_in_val: Label
var flow_out_panel: PanelContainer
var flow_out_val: Label
var flow_rows: Array = []
var flow_phase := ""
var flow_step := 0
var flow_busy := false
var flow_correct := 0
var flow_round := 0
var flow_op := ">"
var flow_op_queue: Array = []   # тестийн операторуудын ээлж
var flow_input := 0
var flow_big := 0
var flow_small := 0
const FLOW_NEED := 3   # тестийг давахад шаардлагатай зөв хариулт
var code_row: HBoxContainer
var tut_name: Label
var tut_name_tag: PanelContainer
var glow_tween: Tween      # дараагийн хийх товчны анивчих гэрэл (_update_glow)
var glow_target: Control
var glow_saved: Dictionary = {}   # гэрэлтэхээс өмнөх stylebox override-ууд
var tut_type_tag: PanelContainer
var tut_box: PanelContainer
var tut_value: Label
var tut_caption: Label
var fly_layer: Control
var tut_step := 0
var tut_busy := false
# Таамгийн хайрцаг (predict): «Таны таамаг» тасархай хайрцаг + дууссаны дараа «Жинхэнэ» хайрцаг.
var predict_row: HBoxContainer
var guess_name: Label
var guess_edit: LineEdit
var guess_mark: Label
var real_col: VBoxContainer
var real_box: PanelContainer
var real_value: Label
var real_name: Label
var row_panels: Array = []   # кодын мөр бүрийн карт
# Мөр чирэх (түвшин 5)
var drag_card: PanelContainer = null
var drag_candidate: PanelContainer = null
var drag_press := Vector2.ZERO
var drag_grab := Vector2.ZERO
var wrong_tries := 0   # predict: энэ тойрогт буруу таамагласан тоо (3 дахь дээр хариу харагдана)
var tut_v := 2         # үзүүлэн заавар: санамсаргүй анхны утга
var tut_k := 1         # үзүүлэн заавар: санамсаргүй нэмэх тоо
var controls: HBoxContainer
var message_label: Label
var btn_start: Button
var btn_step: Button
var btn_run: Button
var btn_reset: Button
var btn_test: Button
var btn_tut: Button
var btn_replay: Button
var btn_next: Button
var btn_skip: Button
var btn_false: Button   # нөхцлийн тест: «← ХУДАЛ»
var btn_true: Button    # нөхцлийн тест: «ҮНЭН →»
var choice_styles: Array = []
# Анимаци алгасах (F): ажиллаж буй ба шинэ анимацийн tween-үүдийг SKIP_SCALE дахин хурдасгана.
const SKIP_SCALE := 60.0
var skipping := false
var anim_tweens: Array = []


## Хувьсагчийн картон хайрцаг: дээд хавхаг (зураас) нэмж зурна.
class CardboardBox extends PanelContainer:
	func _draw() -> void:
		var r := Rect2(Vector2(5, 5), Vector2(size.x - 10, 9))
		draw_rect(r, UiTheme.BOX_DARK)
		draw_line(Vector2(size.x / 2.0, 5), Vector2(size.x / 2.0, 14), UiTheme.INK, 1.5)


## Таамгийн хайрцгийн тасархай хүрээ: «энэ бол жинхэнэ утга биш, таны таамаг» гэдгийг харуулна.
class DashedBox extends PanelContainer:
	var dash_color := UiTheme.INK2

	func _draw() -> void:
		var r := Rect2(Vector2(2, 2), size - Vector2(4, 4))
		var c := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		for i in 4:
			draw_dashed_line(c[i], c[(i + 1) % 4], dash_color, 3.0, 10.0)


func _ready() -> void:
	# Цаасан диорама загвар: нэг Theme + нэг өнгөний сан (ui_theme.gd).
	theme = UiTheme.make_theme()
	RenderingServer.set_default_clear_color(UiTheme.CREAM)
	mono_font = UiTheme.font("mono_b")
	progress = Progress.new(templates.size())
	_build_ui()
	_load_level(0)
	_show_map()


func _t(x: float) -> float:
	return maxf(0.001, x * anim_speed)


func _label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	return l


func _code_label(text: String, size: int = 22) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", mono_font)
	l.add_theme_font_size_override("font_size", size)
	return l


func _row(parent: Control) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	parent.add_child(h)
	return h


# ---------------------------------------------------------------- UI

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["margin_left", "margin_right"]:
		margin.add_theme_constant_override(side, 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	add_child(margin)
	level_ui = margin

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# --- Дээд мөр: ← Бүлэг · [бүлэг] · гарчиг ······ од · ? ---
	top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 12)
	root.add_child(top_bar)
	var back := Button.new()
	back.text = "← Бүлэг"
	back.focus_mode = Control.FOCUS_NONE
	back.tooltip_text = "Esc"
	back.custom_minimum_size = Vector2(0, 40)
	back.pressed.connect(_show_map)
	top_bar.add_child(back)
	chapter_chip = PanelContainer.new()
	chapter_chip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	chapter_label = Label.new()
	chapter_label.add_theme_font_override("font", UiTheme.font("bold"))
	chapter_label.add_theme_font_size_override("font_size", 15)
	chapter_label.add_theme_color_override("font_color", Color.WHITE)
	chapter_chip.add_child(chapter_label)
	top_bar.add_child(chapter_chip)
	title_label = Label.new()
	title_label.add_theme_font_override("font", UiTheme.font("xbold"))
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.clip_text = true
	top_bar.add_child(title_label)
	stars_label = Label.new()
	stars_label.add_theme_font_size_override("font_size", 24)
	stars_label.add_theme_color_override("font_color", UiTheme.GLOW)
	stars_label.add_theme_color_override("font_outline_color", UiTheme.INK)
	stars_label.add_theme_constant_override("outline_size", 3)
	top_bar.add_child(stars_label)
	hint_btn = Button.new()
	hint_btn.text = "?"
	hint_btn.focus_mode = Control.FOCUS_NONE
	hint_btn.tooltip_text = "Тайлбар"
	hint_btn.custom_minimum_size = Vector2(42, 40)
	hint_btn.add_theme_font_override("font", UiTheme.font("xbold"))
	hint_btn.add_theme_font_size_override("font_size", 20)
	var round_sb := UiTheme.paper(UiTheme.CARD, 20, 2, UiTheme.INK, 4)
	hint_btn.add_theme_stylebox_override("normal", round_sb)
	hint_btn.add_theme_stylebox_override("hover", round_sb)
	hint_btn.pressed.connect(_on_hint)
	top_bar.add_child(hint_btn)

	story_label = Label.new()
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.add_theme_font_size_override("font_size", 17)
	story_label.add_theme_color_override("font_color", UiTheme.INK2)
	root.add_child(story_label)

	# --- Програм + хайрцгууд (predict / arrange) ---
	main_row = HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 24)
	root.add_child(main_row)

	# Зүүн: харанхуй C++ самбар (кодын «дэлгэц»).
	code_card = PanelContainer.new()
	code_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	code_card.size_flags_stretch_ratio = 1.3
	code_card.add_theme_stylebox_override("panel", UiTheme.code_panel(14))
	main_row.add_child(code_card)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	code_card.add_child(left)
	left.add_child(_panel_title("C++", true))
	code_box = VBoxContainer.new()
	code_box.add_theme_constant_override("separation", 6)
	left.add_child(code_box)

	# Баруун: цаасан «Санах ой» самбар — хайрцгууд ба таамаг.
	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.add_theme_stylebox_override("panel", UiTheme.paper(UiTheme.CARD, 14, 2, UiTheme.INK, 6, 14))
	main_row.add_child(right_card)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	right_card.add_child(right)
	right.add_child(_panel_title("Санах ой", false))
	boxes = HFlowContainer.new()
	boxes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	boxes.add_theme_constant_override("h_separation", 18)
	boxes.add_theme_constant_override("v_separation", 18)
	right.add_child(boxes)
	_build_guess_area(right)

	# --- Хамгаалагч ---
	guard_panel = HBoxContainer.new()
	guard_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guard_panel.add_theme_constant_override("separation", 16)
	root.add_child(guard_panel)

	var gl := VBoxContainer.new()
	gl.custom_minimum_size = Vector2(430, 0)
	gl.add_theme_constant_override("separation", 10)
	guard_panel.add_child(gl)
	gl.add_child(_panel_title("Хаалганы дүрэм", false))
	var row1 := _row(gl)
	row1.add_child(_code_label("age"))
	op1 = _make_op_option(true)
	row1.add_child(op1)
	val1 = _make_spin(0, 99, true)
	row1.add_child(val1)
	rule2_row = _row(gl)
	join_opt = OptionButton.new()
	join_opt.add_item("&&")
	join_opt.add_item("||")
	join_opt.custom_minimum_size = Vector2(100, 44)
	join_opt.item_selected.connect(func(_i): _update_guard_code())
	rule2_row.add_child(join_opt)
	rule2_row.add_child(_code_label("card"))
	op2 = _make_op_option(true)
	rule2_row.add_child(op2)
	val2 = _make_spin(0, 1, true)
	rule2_row.add_child(val2)
	guard_code = _code_label("", 20)
	guard_code.add_theme_color_override("font_color", UiTheme.CODE_TXT)
	var gcode := PanelContainer.new()
	gcode.add_theme_stylebox_override("panel", UiTheme.code_panel(14))
	gcode.add_child(guard_code)
	gl.add_child(gcode)

	guard_view = GuardView.new()
	guard_panel.add_child(guard_view)

	# --- Киноны билет (boss) ---
	cinema_panel = HBoxContainer.new()
	cinema_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cinema_panel.add_theme_constant_override("separation", 24)
	root.add_child(cinema_panel)
	var cl := VBoxContainer.new()
	cl.add_theme_constant_override("separation", 6)
	cinema_panel.add_child(cl)
	cl.add_child(_label("C++ ПРОГРАМ (хоосон талбаруудыг өөрөө бөглө)"))
	cl.add_child(_code_label("double price = 0;"))
	var r1 := _row(cl)
	r1.add_child(_code_label("if (age"))
	ca_op = _make_op_option(false)
	r1.add_child(ca_op)
	ca_val = _make_spin(0, 100)
	r1.add_child(ca_val)
	r1.add_child(_code_label(")  price ="))
	ca_price = _make_spin(0, 50)
	r1.add_child(ca_price)
	r1.add_child(_code_label(";"))
	var r2 := _row(cl)
	r2.add_child(_code_label("else if (age"))
	cb_op = _make_op_option(false)
	r2.add_child(cb_op)
	cb_val = _make_spin(0, 100)
	r2.add_child(cb_val)
	r2.add_child(_code_label(")  price ="))
	cb_price = _make_spin(0, 50)
	r2.add_child(cb_price)
	r2.add_child(_code_label(";"))
	var r3 := _row(cl)
	r3.add_child(_code_label("else  price ="))
	cc_price = _make_spin(0, 50)
	r3.add_child(cc_price)
	r3.add_child(_code_label(";"))
	var r4 := _row(cl)
	r4.add_child(_code_label("if (day =="))
	cd_val = _make_spin(0, 7)
	r4.add_child(cd_val)
	r4.add_child(_code_label(")  price = price -"))
	cd_minus = _make_spin(0, 20)
	r4.add_child(cd_minus)
	r4.add_child(_code_label(";"))
	var r5 := _row(cl)
	r5.add_child(_code_label("if (coupon =="))
	ce_val = _make_spin(0, 1)
	r5.add_child(ce_val)
	r5.add_child(_code_label(")  price = price *"))
	ce_mult = _make_spin(0, 2)
	ce_mult.step = 0.05
	r5.add_child(ce_mult)
	r5.add_child(_code_label(";"))
	var cr := VBoxContainer.new()
	cr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cinema_panel.add_child(cr)
	cr.add_child(_label("ҮРД ДҮН (өөрийн программ vs зөв үнэ)"))
	cin_list = ItemList.new()
	cin_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cin_list.focus_mode = Control.FOCUS_NONE
	cin_list.add_theme_font_override("font", mono_font)
	cin_list.add_theme_font_size_override("font_size", 18)
	cr.add_child(cin_list)

	# --- Үзүүлэн заавар (tutorial) ---
	tutorial_panel = VBoxContainer.new()
	tutorial_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_panel.add_theme_constant_override("separation", 10)
	root.add_child(tutorial_panel)
	code_row = HBoxContainer.new()
	code_row.alignment = BoxContainer.ALIGNMENT_CENTER
	code_row.add_theme_constant_override("separation", 28)
	code_row.custom_minimum_size = Vector2(0, 90)
	var tut_code := PanelContainer.new()
	tut_code.add_theme_stylebox_override("panel", UiTheme.code_panel(10))
	tut_code.add_child(code_row)
	var tut_code_c := CenterContainer.new()
	tut_code_c.add_child(tut_code)
	tutorial_panel.add_child(tut_code_c)
	code_row.custom_minimum_size = Vector2(620, 90)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_panel.add_child(spacer)
	# Хайрцаг = нэрийн шошго (таг) + хайрцаг + төрлийн наалт (int). Тайлбар биш, дүрс өөрөө ярина.
	var box_stack := VBoxContainer.new()
	box_stack.add_theme_constant_override("separation", 0)
	var box_center := CenterContainer.new()
	box_center.add_child(box_stack)
	tutorial_panel.add_child(box_center)
	tut_name_tag = PanelContainer.new()
	tut_name_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tut_name_tag.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.CARD))
	tut_name = _code_label("people", 34)
	tut_name_tag.add_child(tut_name)
	box_stack.add_child(tut_name_tag)
	tut_box = CardboardBox.new()
	tut_box.custom_minimum_size = Vector2(200, 130)
	tut_box.add_theme_stylebox_override("panel", UiTheme.box_style())
	box_stack.add_child(tut_box)
	tut_value = Label.new()
	tut_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tut_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tut_value.add_theme_font_size_override("font_size", 64)
	tut_value.add_theme_font_override("font", mono_font)
	tut_box.add_child(tut_value)
	tut_type_tag = PanelContainer.new()
	tut_type_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tut_type_tag.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.INT_TAG))
	var type_label := _code_label("int", 26)
	tut_type_tag.add_child(type_label)
	box_stack.add_child(tut_type_tag)
	tut_caption = Label.new()
	tut_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tut_caption.custom_minimum_size = Vector2(0, 80)
	tut_caption.add_theme_font_size_override("font_size", 26)
	tut_caption.add_theme_font_override("font", UiTheme.font("bold"))
	tutorial_panel.add_child(tut_caption)

	# --- Нөхцөл (flow): дээр нь код, доор нь блок схем + хувьсагчийн хайрцгууд (түвшин 1-ийн загвар) ---
	flow_panel = VBoxContainer.new()
	flow_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flow_panel.add_theme_constant_override("separation", 8)
	root.add_child(flow_panel)
	flow_code = VBoxContainer.new()
	flow_code.add_theme_constant_override("separation", 2)
	var fc_panel := PanelContainer.new()
	fc_panel.add_theme_stylebox_override("panel", UiTheme.code_panel(10))
	fc_panel.add_child(flow_code)
	var fc_center := CenterContainer.new()
	fc_center.add_child(fc_panel)
	flow_panel.add_child(fc_center)
	var flow_row := HBoxContainer.new()
	flow_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	flow_row.add_theme_constant_override("separation", 16)
	flow_panel.add_child(flow_row)
	flow_in_slot = VBoxContainer.new()
	flow_in_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flow_row.add_child(flow_in_slot)
	flow_view = FlowView.new()
	flow_view.mono = mono_font
	flow_view.side_chosen.connect(_flow_choose)
	flow_row.add_child(flow_view)
	flow_out_slot = VBoxContainer.new()
	flow_out_slot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	flow_row.add_child(flow_out_slot)

	# --- Сорилт (нэмэлт түвшин): автобусны карт уншигч, блокоор програм засах ---
	challenge = ChallengePanel.new()
	root.add_child(challenge)
	challenge.setup(mono_font, _update_glow)
	challenge.solved.connect(_on_challenge_solved)
	challenge.skipped.connect(_on_challenge_skipped)
	challenge.message.connect(_show_message)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(0, 30)
	message_label.add_theme_font_override("font", UiTheme.font("bold"))
	root.add_child(message_label)

	# --- Товчнууд (гарын товчлол: _unhandled_input). «← Бүлэг» нь дээд мөрөнд. ---
	controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	root.add_child(controls)
	btn_start = _make_button("Эхлэх", _on_start, "Enter")
	btn_step = _make_button("Алхам", _on_step_pressed, "Enter")
	btn_run = _make_button("Бүгдийг ажиллуулах", _on_run_all, "Space")
	btn_reset = _make_button("Дахин эхлэх", _on_reset)
	btn_test = _make_button("Турших", _on_test)
	btn_tut = _make_button("Дараагийн алхам", _on_tut_next, "→ / D")
	btn_replay = _make_button("Дахин үзэх", _on_tut_replay)
	btn_next = _make_button("Дараагийн түвшин", _on_next, "→ / D")
	btn_skip = _make_button("Алгасах »", _on_skip, "F")
	# Нөхцлийн тестийн хариултын товчнууд (улаан/ногоон, анивчина).
	btn_false = _make_button("←  ХУДАЛ", func(): _flow_choose(0), "← (F зам)")
	btn_true = _make_button("ҮНЭН  →", func(): _flow_choose(1), "→ (T зам)")
	for pair in [[btn_false, UiTheme.FALSE], [btn_true, UiTheme.TRUE]]:
		var b: Button = pair[0]
		b.custom_minimum_size = Vector2(150, 44)
		b.add_theme_font_size_override("font_size", 20)
		var sb := UiTheme.paper(pair[1], 12, 2, UiTheme.INK, 0, 8)
		sb.shadow_color = Color(pair[1], 0.55)
		for state in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, sb)
		for c in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(c, Color.WHITE)
		choice_styles.append(sb)
		b.visible = false
	# Анивчих гэрэл (байнга ажиллана; товч харагдах үед л мэдэгдэнэ).
	var ct := create_tween().set_loops()
	for target in [10, 0]:
		ct.tween_property(choice_styles[0], "shadow_size", target, 0.6).set_trans(Tween.TRANS_SINE)
		ct.parallel().tween_property(choice_styles[1], "shadow_size", target, 0.6).set_trans(Tween.TRANS_SINE)

	# Бүлэг сонгох дэлгэц: түвшний UI-ийн оронд бүтэн дэлгэцээр харагдана.
	route_view = RouteView.new()
	route_view.visible = false
	route_view.stop_chosen.connect(_on_stop_chosen)
	add_child(route_view)
	route_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Нисдэг утгууд хамгийн дээр зурагдана.
	fly_layer = Control.new()
	fly_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fly_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fly_layer)


## Самбарын жижиг гарчиг: харанхуй код самбар дээр (dark) эсвэл цаасан карт дээр.
func _panel_title(text: String, dark: bool) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", UiTheme.font("mono_b") if dark else UiTheme.font("bold"))
	l.add_theme_font_size_override("font_size", 14 if dark else 16)
	l.add_theme_color_override("font_color", UiTheme.CODE_DIM if dark else UiTheme.INK2)
	return l


## C++ токены өнгө (харанхуй самбар дээр): int шар (int наалттай ижил), if/else ногоон-цэнхэр, тоо улбар шар.
func _token_color(part: String) -> Color:
	if part == "int":
		return UiTheme.INT_TAG
	if part in ["if", "else"]:
		return UiTheme.CODE_KW
	if part.is_valid_int():
		return UiTheme.CODE_NUM
	if part.length() > 0 and not (part[0] == "_" or part[0].to_lower() != part[0].to_upper()):
		return UiTheme.CODE_SYM
	return UiTheme.CODE_TXT


## «?»: түвшний нэмэлт тайлбар (cur.hint). Дахин дарвал нуугдана.
func _on_hint() -> void:
	var h: String = cur.get("hint", "")
	if h == "":
		return
	if message_label.text == h:
		_show_message("")
	else:
		_show_message(h)


func _make_button(text: String, handler: Callable, key_hint: String = "") -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	# Товч фокус авахгүй: эс бөгөөс Enter/Space нь сүүлд дарсан товчийг дахин дарна.
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = key_hint
	b.pressed.connect(handler)
	controls.add_child(b)
	return b


## «Таны таамаг» тасархай хайрцаг ба (дууссаны дараа) «Жинхэнэ» хайрцаг, хооронд нь ✓/✗.
func _build_guess_area(parent: Control) -> void:
	predict_row = HBoxContainer.new()
	predict_row.add_theme_constant_override("separation", 18)
	parent.add_child(predict_row)

	var guess_col := VBoxContainer.new()
	guess_col.add_theme_constant_override("separation", 0)
	predict_row.add_child(guess_col)
	guess_col.add_child(_panel_title("Таны таамаг", false))
	var gtag := PanelContainer.new()
	gtag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gtag.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.CARD))
	guess_name = _code_label("note", 22)
	gtag.add_child(guess_name)
	guess_col.add_child(gtag)
	var dbox := DashedBox.new()
	dbox.custom_minimum_size = Vector2(120, 72)
	var empty := UiTheme.paper(Color("F8F2E6"), 10, 0, UiTheme.INK, 0)
	empty.set_content_margin_all(6)   # тодорхой зай: гэрэлтэх үед хайрцаг томрохгүй
	dbox.add_theme_stylebox_override("panel", empty)
	guess_col.add_child(dbox)
	guess_edit = LineEdit.new()
	guess_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	guess_edit.max_length = 5
	guess_edit.custom_minimum_size = Vector2(100, 56)
	guess_edit.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	guess_edit.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	guess_edit.add_theme_font_size_override("font_size", 36)
	guess_edit.add_theme_font_override("font", mono_font)
	var clear := StyleBoxFlat.new()
	clear.bg_color = Color(0, 0, 0, 0)
	clear.set_content_margin_all(4)
	for state in ["normal", "focus", "read_only"]:
		guess_edit.add_theme_stylebox_override(state, clear)
	guess_edit.text_changed.connect(_on_guess_changed)
	guess_edit.gui_input.connect(_on_guess_key)   # тоог физик товчоор (монгол гарын байрлалд ч)
	# Хайрцгийн аль ч хэсэгт дарахад бичих нүд идэвхжинэ.
	dbox.gui_input.connect(func(e: InputEvent):
		if e is InputEventMouseButton and e.pressed and guess_edit.editable:
			guess_edit.grab_focus())
	guess_edit.text_submitted.connect(func(_t): _on_start())   # таамаг бичээд Enter = Эхлэх
	dbox.add_child(guess_edit)
	var gtype := PanelContainer.new()
	gtype.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	gtype.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.INT_TAG))
	var gtl := _code_label("int", 18)
	gtype.add_child(gtl)
	guess_col.add_child(gtype)

	guess_mark = Label.new()
	guess_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	guess_mark.add_theme_font_size_override("font_size", 48)
	predict_row.add_child(guess_mark)

	real_col = VBoxContainer.new()
	real_col.add_theme_constant_override("separation", 0)
	predict_row.add_child(real_col)
	real_col.add_child(_panel_title("Жинхэнэ", false))
	var rtag := PanelContainer.new()
	rtag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rtag.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.CARD))
	real_name = _code_label("note", 22)
	rtag.add_child(real_name)
	real_col.add_child(rtag)
	real_box = CardboardBox.new()
	real_box.custom_minimum_size = Vector2(120, 72)
	real_box.add_theme_stylebox_override("panel", UiTheme.box_style())
	real_value = Label.new()
	real_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	real_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	real_value.add_theme_font_size_override("font_size", 36)
	real_value.add_theme_font_override("font", mono_font)
	real_box.add_child(real_value)
	real_col.add_child(real_box)
	var rtype := PanelContainer.new()
	rtype.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rtype.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.INT_TAG))
	var rtl := _code_label("int", 18)
	rtype.add_child(rtl)
	real_col.add_child(rtype)


func _make_op_option(live: bool) -> OptionButton:
	var o := OptionButton.new()
	for op in OPS:
		o.add_item(op)
	o.custom_minimum_size = Vector2(90, 44)
	if live:
		o.item_selected.connect(func(_i): _update_guard_code())
	return o


func _make_spin(lo: float, hi: float, live: bool = false) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = lo
	s.max_value = hi
	s.step = 1
	s.custom_minimum_size = Vector2(110, 44)
	# Бичсэн тоо шууд утга болно (Enter дарах, өөр газар дарах шаардлагагүй).
	s.update_on_text_changed = true
	s.get_line_edit().gui_input.connect(_on_spin_key.bind(s))
	if live:
		s.value_changed.connect(func(_v): _update_guard_code())
	return s


## SpinBox-д монгол (кирилл) гарын байрлалаар ч тоо бичигдэнэ (таамгийн хайрцагтай адил).
func _on_spin_key(event: InputEvent, s: SpinBox) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var ch := _physical_digit(event)
	if ch == "":
		return
	var le := s.get_line_edit()
	le.accept_event()
	# Шинэ бичвэрийг өөрсдөө бүтээнэ: SpinBox тоо бүрийн дараа бичвэрээ дахин форматлахад
	# курсор эхэнд үсрээд дараагийн цифр алга болдог байсан («20» → 2).
	var text := le.text
	var caret := le.caret_column
	if le.has_selection():
		var from := le.get_selection_from_column()
		text = text.substr(0, from) + text.substr(le.get_selection_to_column())
		caret = from
		le.deselect()
	text = text.substr(0, caret) + ch + text.substr(caret)
	if text.is_valid_int():
		s.value = int(text)              # min/max-аар хязгаарлагдана
		text = str(int(s.value))
	le.text = text
	le.caret_column = text.length()


# ---------------------------------------------------------------- түвшин

func _load_level(i: int) -> void:
	level_index = i
	level_mistakes = 0
	level_cleared = false
	route_view.visible = false
	level_ui.visible = true
	cur = Levels.make(templates[i])
	_setup_level()


# ---------------------------------------------------------------- бүлэг сонгох дэлгэц

## Анимаци явж байх үед түвшнээс гарахгүй (хагас дууссан анимаци нуугдсан UI-г өөрчлөх эрсдэлтэй).
func _is_animating() -> bool:
	return busy or tut_busy or flow_busy or guard_view.running or challenge.busy or route_view.busy


func _route_stops() -> Array:
	var out: Array = []
	for i in templates.size():
		var t: Dictionary = templates[i]
		var state := 0
		if progress.stars[i] > 0:
			state = 2
		elif progress.is_open(i):
			state = 1
		out.append({"label": t.get("map", t.title), "stars": progress.stars[i], "state": state,
			"optional": t.get("optional", false), "chapter": t.get("chapter", "var")})
	return out


## Маршрутыг харуулна. Автобус одоогийн түвшний буудал дээр зогсоно.
func _show_map(bubble: String = "Аль буудал руу?") -> void:
	if _is_animating():
		return
	run_token += 1
	_set_glow(null)
	level_ui.visible = false
	route_view.visible = true
	route_view.set_stops(_route_stops())
	route_view.bubble = bubble
	route_view.bus_f = float(level_index)
	route_view.selected = level_index
	# Дараагийн нээлттэй (давж амжаагүй) буудлыг санал болгоно.
	for i in templates.size():
		if progress.is_open(i) and progress.stars[i] == 0:
			route_view.selected = i
			break


func _on_stop_chosen(i: int) -> void:
	if route_view.busy:
		return
	if i == level_index:
		_load_level(i)
		return
	# Автобус шинэ буудал руу явж очоод түвшин нээгдэнэ.
	await route_view.travel(level_index, i, clampf(0.45 * absf(i - level_index), 0.6, 1.6))
	await get_tree().create_timer(0.25).timeout
	_load_level(i)


func _setup_level() -> void:
	var mode: String = cur.mode
	program = cur.lines.duplicate()
	sel_index = -1
	wrong_tries = 0   # шинэ тоонууд = шинэ тойрог, 3 оролдлого
	title_label.text = "%d · %s" % [level_index + 1, cur.title]
	var ch: Dictionary = UiTheme.CHAPTERS.get(templates[level_index].get("chapter", "var"), UiTheme.CHAPTERS["var"])
	chapter_label.text = "%s  %s" % [ch.icon, ch.name]
	chapter_chip.add_theme_stylebox_override("panel", UiTheme.chip(ch.acc))
	chapter_label.add_theme_color_override("font_color", UiTheme.on_color(ch.acc))
	_update_stars()
	hint_btn.visible = str(cur.get("hint", "")) != ""
	story_label.text = cur.story
	guess_name.text = cur.get("ask", "")
	real_name.text = cur.get("ask", "")
	var is_play := mode == "predict" or mode == "arrange"
	main_row.visible = is_play
	guard_panel.visible = mode == "guard"
	cinema_panel.visible = mode == "cinema"
	tutorial_panel.visible = mode == "tutorial"
	flow_panel.visible = mode == "flow"
	challenge.visible = mode == "challenge"
	# Сорилт: дүрэм ба мессеж нь үзэгдэл дотроо (дээд мөр харагдсаар).
	story_label.visible = mode != "challenge" and str(cur.story) != ""
	message_label.visible = mode != "challenge"
	predict_row.visible = mode == "predict"
	btn_start.visible = is_play
	btn_step.visible = is_play
	btn_run.visible = is_play
	btn_reset.visible = is_play
	btn_skip.visible = not (mode in ["cinema", "challenge"])   # сорилтод F товч хангалттай (2 «Алгасах» товч төөрөгдүүлнэ)
	btn_false.visible = false   # зөвхөн нөхцлийн тестийн үед харагдана
	btn_true.visible = false
	btn_test.visible = mode == "guard" or mode == "cinema"
	btn_tut.visible = mode == "tutorial" or mode == "flow"
	btn_replay.visible = mode == "tutorial" or mode == "flow"
	if mode == "guard":
		_setup_guard()
	elif mode == "cinema":
		_setup_cinema()
	_reset_state()


func _reset_state() -> void:
	run_token += 1
	started = false
	finished = false
	busy = false
	interp.load_program(program)
	states.resize(program.size())
	states.fill(0)
	# Өмнөх түвшний таамаглал дараагийнх руу шилжихгүй.
	guess_edit.editable = true
	guess_edit.text = ""
	guess_entered = false
	guess_mark.text = ""
	real_col.visible = false
	if cur.mode == "predict":
		guess_edit.call_deferred("grab_focus")   # шууд бичиж эхэлж болно
	if cur.mode == "guard":
		message_label.text = "Дүрмээ тохируулаад Турших товчийг дар."
	elif cur.mode == "cinema":
		message_label.text = "Талбаруудыг бөглөөд Турших товчийг дар."
	elif cur.mode == "tutorial":
		message_label.text = ""
		_tut_reset()
	elif cur.mode == "flow":
		message_label.text = ""
		_flow_reset()
	elif cur.mode == "challenge":
		message_label.text = ""
		challenge.start()
	else:
		message_label.text = ""   # predict / arrange: дараагийн товч гэрэлтэж заана
	message_label.remove_theme_color_override("font_color")
	message_label.remove_theme_font_size_override("font_size")
	btn_next.visible = false
	_refresh_code()
	_refresh_boxes({})
	_update_buttons()


func _update_buttons() -> void:
	btn_start.disabled = started or busy
	btn_step.disabled = not started or finished or busy
	btn_run.disabled = not started or finished or busy
	btn_reset.disabled = not started or busy
	_update_glow()


## Тоглогчийн дараагийн хийх ёстой зүйлийг гэрэлтүүлнэ (заавар бичгийн оронд).
## Түвшин 1-5 л ашиглана. Нөхцөлийн түвшнүүдэд гэрэл байхгүй.
func _update_glow() -> void:
	var target: Control = null
	match cur.get("mode", ""):
		"tutorial":
			if tut_step == 0 and not tut_busy:
				target = btn_tut
		"challenge":
			target = btn_next if btn_next.visible else challenge.glow_target()
		"flow":
			# Тайлбарын үед «Дараагийн алхам», тестийн үед схем өөрөө (гэрэлгүй), дууссан бол «Дараагийн түвшин».
			if btn_next.visible:
				target = btn_next
			elif flow_phase == "explain" and not flow_busy:
				target = btn_tut
		"predict", "arrange":
			if btn_next.visible:
				target = btn_next
			elif busy:
				target = null
			elif finished:
				target = btn_reset
			elif started:
				target = btn_step
			elif cur.mode == "predict" and not guess_entered:
				target = guess_edit.get_parent()   # тасархай таамгийн хайрцаг
			else:
				target = btn_start
	_set_glow(target)


func _glow_states(c: Control) -> Array:
	if c is PanelContainer:
		return ["panel"]
	if c is LineEdit:
		return ["normal", "focus", "read_only"]
	return ["normal", "hover", "pressed", "focus"]


## Шар хүрээ + зөөлөн анивчих гэрэл. null өгвөл гэрлийг унтраана.
func _set_glow(target: Control) -> void:
	if target == glow_target:
		return
	if glow_tween != null:
		glow_tween.kill()
		glow_tween = null
	if glow_target != null:
		# Гэрлээс өмнөх өөрийн загварыг (байсан бол) сэргээнэ.
		for state in _glow_states(glow_target):
			if glow_saved.has(state):
				glow_target.add_theme_stylebox_override(state, glow_saved[state])
			else:
				glow_target.remove_theme_stylebox_override(state)
	glow_saved = {}
	glow_target = target
	if target == null:
		return
	for state in _glow_states(target):
		if target.has_theme_stylebox_override(state):
			glow_saved[state] = target.get_theme_stylebox(state)
	# Товч: шар дүүргэлт + бараан хүрээ; бусад (таамгийн хайрцаг): шар хүрээ. Хоёулаа шар туяатай.
	var base: StyleBox = target.get_theme_stylebox(_glow_states(target)[0])
	var sb := UiTheme.paper(YELLOW if target is Button else Color("FFF6D6"), 12, 2 if target is Button else 3,
		UiTheme.INK if target is Button else YELLOW.darkened(0.15), 0)
	sb.shadow_color = Color(YELLOW, 0.65)
	sb.shadow_size = 0
	sb.shadow_offset = Vector2.ZERO
	# Өөрийн дотоод зайг хуулна: гэрэлтэх үед товч томрохгүй, бусад нь шилжихгүй.
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		sb.set_content_margin(side, base.get_content_margin(side))
	for state in _glow_states(target):
		target.add_theme_stylebox_override(state, sb)
	# Тогтмол хугацаа (_t() биш): хязгааргүй давталт 0 хугацаатай байж болохгүй.
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(sb, "shadow_size", 12, 0.7).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(sb, "shadow_size", 0, 0.7).set_trans(Tween.TRANS_SINE)


## Тоглогчид тавих асуулт: том, шар үсгээр (энгийн мессежээс ялгарна).
func _show_question(text: String) -> void:
	message_label.text = text
	message_label.add_theme_color_override("font_color", UiTheme.INK)
	message_label.add_theme_font_size_override("font_size", 26)
	message_label.add_theme_font_override("font", UiTheme.font("xbold"))


func _show_message(text: String, good_or_bad: int = 0) -> void:
	message_label.remove_theme_font_size_override("font_size")
	message_label.add_theme_font_override("font", UiTheme.font("bold"))
	message_label.text = text
	match good_or_bad:
		1: message_label.add_theme_color_override("font_color", UiTheme.TRUE.darkened(0.15))
		-1: message_label.add_theme_color_override("font_color", UiTheme.FALSE.darkened(0.1))
		_: message_label.remove_theme_color_override("font_color")


func _offer_next() -> void:
	if not level_cleared:
		level_cleared = true
		var mistakes := challenge.fails if cur.mode == "challenge" else level_mistakes
		var s := Progress.stars_for(mistakes)
		progress.record(level_index, s)
		_update_stars()
	btn_next.text = "Дараагийн түвшин" if level_index + 1 < templates.size() else "Дуусгах"
	btn_next.visible = true
	_update_glow()


## Дээд мөрийн од: энэ түвшний хамгийн сайн үр дүн.
func _update_stars() -> void:
	var n: int = progress.stars[level_index]
	stars_label.text = "★".repeat(n) + "☆".repeat(3 - n)


func _on_challenge_solved() -> void:
	_offer_next()


## Сорилтыг алгасвал 1-р хэсэг шууд дуусна (энэ бол сүүлийн, нэмэлт түвшин).
func _on_challenge_skipped() -> void:
	challenge.phase = "done"
	challenge._update_bottom()
	challenge._note("")
	challenge._status("Сорилт алгаслаа", 1)
	_update_glow()


func _on_next() -> void:
	if busy or tut_busy or flow_busy or guard_view.running or challenge.busy:
		return
	if level_index + 1 < templates.size():
		# Маршрут дээр автобус дараагийн буудал руу явж очно.
		_show_map("Явцгаая!")
		_on_stop_chosen(level_index + 1)
	else:
		_show_map("1-р хэсэг дууслаа!")


# ---------------------------------------------------------------- програм ба хайрцгууд

func _refresh_code() -> void:
	for c in code_box.get_children():
		code_box.remove_child(c)
		c.queue_free()
	row_tokens.clear()
	row_panels.clear()
	var can_arrange: bool = cur.mode == "arrange" and not started
	for i in program.size():
		var current := started and not finished and i == interp.pc
		var bg := ROW_BASE
		if current:
			bg = ROW_CURRENT
		else:
			match states[i]:
				1: bg = ROW_DONE
				2: bg = ROW_SKIP
				3: bg = ROW_ERR
		var sb := StyleBoxFlat.new()
		sb.bg_color = bg
		sb.set_corner_radius_all(8)
		sb.set_content_margin_all(8)
		sb.border_color = YELLOW
		if can_arrange and i == sel_index:
			sb.set_border_width_all(3)
		elif current:
			sb.border_width_left = 5   # одоогийн мөр: шар зүүн тууз
		# Мөр бүр = «слот» (VBox-д байр эзэлнэ) + доторх «карт» (харагдах мөр).
		# Карт контейнерт захирагддаггүй тул чирэх ба гулсах анимацид чөлөөтэй хөдөлнө.
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 16)
		card.add_child(h)
		if can_arrange:
			var grip := _code_label("≡", 30)   # «чирж болно» гэсэн бариул
			grip.add_theme_color_override("font_color", UiTheme.CODE_DIM)
			h.add_child(grip)
			card.mouse_default_cursor_shape = Control.CURSOR_DRAG
			card.gui_input.connect(_on_card_input.bind(card))
		var num := _code_label(("» %d" if current else "  %d") % (i + 1), 30)
		num.add_theme_color_override("font_color", YELLOW if current else UiTheme.CODE_DIM)
		h.add_child(num)
		var toks: Array = []
		for part in _split_tokens(str(program[i])):
			var l := _code_label(part, 34)
			l.add_theme_color_override("font_color", _token_color(part))
			h.add_child(l)
			toks.append(l)
		row_tokens.append(toks)
		var slot := Control.new()
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.set_meta("card", card)
		slot.add_child(card)
		code_box.add_child(slot)
		slot.custom_minimum_size = Vector2(0, card.get_combined_minimum_size().y)
		slot.resized.connect(_fit_card.bind(slot))
		row_panels.append(card)


## Картыг слотынхоо хэмжээнд тааруулна (чирэгдэж байх үед биш).
func _fit_card(slot: Control) -> void:
	var card: Control = slot.get_meta("card")
	if not card.top_level:
		card.position = Vector2.ZERO
		card.size = slot.size


func _update_selection() -> void:
	var slots := code_box.get_children()
	for k in slots.size():
		var card: Control = slots[k].get_meta("card")
		var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
		sb.set_border_width_all(3 if k == sel_index else 0)


## Мөрийг from-оос to байр руу зөөнө. Бусад мөрүүд шинэ байр руугаа зөөлөн гулсана.
## Хулганаар чирэх ба W/S товч хоёулаа үүнийг ашиглана.
func _reorder(from: int, to: int) -> void:
	if from == to:
		return
	var slots := code_box.get_children()
	var old_y := {}
	for s in slots:
		old_y[s] = (s as Control).global_position.y
	var line = program[from]
	program.remove_at(from)
	program.insert(to, line)
	code_box.move_child(slots[from], to)
	code_box.notification(Container.NOTIFICATION_SORT_CHILDREN)   # байрлалыг шууд шинэчилнэ
	slots = code_box.get_children()
	for k in slots.size():
		var s: Control = slots[k]
		var card: PanelContainer = s.get_meta("card")
		_set_line_number(card, k)
		if card == drag_card:
			continue
		var dy: float = old_y[s] - s.global_position.y
		if absf(dy) > 0.5:
			card.position.y = dy
			var tw := create_tween()
			tw.tween_property(card, "position:y", 0.0, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sel_index = to
	_update_selection()


func _set_line_number(card: PanelContainer, k: int) -> void:
	var h := card.get_child(0)
	var num: Label = h.get_child(1) if h.get_child_count() > 1 and (h.get_child(0) as Label).text == "≡" else h.get_child(0)
	num.text = "  %d" % (k + 1)


func _on_card_input(event: InputEvent, card: PanelContainer) -> void:
	if cur.mode != "arrange" or started or busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			drag_candidate = card
			drag_press = event.global_position
			sel_index = card.get_parent().get_index()
			_update_selection()
		else:
			if drag_card != null:
				_end_drag()
			drag_candidate = null
	elif event is InputEventMouseMotion and drag_candidate == card:
		if drag_card == null and event.global_position.distance_to(drag_press) > 6.0:
			_begin_drag(card, event.global_position)
		if drag_card != null:
			_drag_to(event.global_position)


## Картыг «өргөнө»: сүүдэр, бага зэрэг томорно, хулганыг дагана. Хуучин байранд хоосон зай үлдэнэ.
func _begin_drag(card: PanelContainer, mpos: Vector2) -> void:
	drag_card = card
	drag_grab = mpos - card.global_position
	var gp := card.global_position
	var sz := card.size
	card.top_level = true
	card.global_position = gp
	card.size = sz
	card.z_index = 10
	card.pivot_offset = sz / 2.0
	var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	create_tween().tween_property(card, "scale", Vector2(1.03, 1.03), 0.1)
	# Хоосон байр (placeholder): карт хаана буух вэ гэдгийг харуулна.
	var ghost := Panel.new()
	ghost.name = "Ghost"
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color(1, 1, 1, 0.04)
	gs.set_border_width_all(2)
	gs.border_color = Color(1, 1, 1, 0.25)
	gs.set_corner_radius_all(6)
	ghost.add_theme_stylebox_override("panel", gs)
	var slot: Control = card.get_parent()
	slot.add_child(ghost)
	slot.move_child(ghost, 0)
	ghost.size = slot.size


func _drag_to(mpos: Vector2) -> void:
	drag_card.global_position.y = mpos.y - drag_grab.y
	var slot: Control = drag_card.get_parent()
	var center_y := drag_card.global_position.y + drag_card.size.y / 2.0
	var target := 0
	for s in code_box.get_children():
		if s != slot and (s as Control).global_position.y + (s as Control).size.y / 2.0 < center_y:
			target += 1
	if target != slot.get_index():
		_reorder(slot.get_index(), target)


## Тавих: карт шинэ байрандаа зөөлөн суугаад сүүдэр нь арилна.
func _end_drag() -> void:
	var card := drag_card
	drag_card = null
	drag_candidate = null
	if not is_instance_valid(card):
		return
	var slot: Control = card.get_parent()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "global_position", slot.global_position, 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "scale", Vector2.ONE, 0.12)
	await tw.finished
	if not is_instance_valid(card):
		return
	card.top_level = false
	card.z_index = 0
	var sb: StyleBoxFlat = card.get_theme_stylebox("panel")
	sb.shadow_size = 0
	sb.shadow_offset = Vector2.ZERO
	var ghost := slot.get_node_or_null("Ghost")
	if ghost:
		ghost.queue_free()
	_fit_card(slot)


func _refresh_boxes(vals: Dictionary, changed: String = "") -> void:
	for c in boxes.get_children():
		boxes.remove_child(c)
		c.queue_free()
	box_panels.clear()
	# Түвшин 1-ийн адил шошготой хайрцаг: дээр нь нэр, доор нь int наалт.
	for k in vals:
		var vb := _make_var_box(str(k), "" if vals[k] == null else str(vals[k]))   # утга ирээгүй хайрцаг хоосон
		if str(k) == changed:
			(vb.value as Label).add_theme_color_override("font_color", UiTheme.HILITE)
		boxes.add_child(vb.stack)
		box_panels[str(k)] = vb.panel


## Шошготой хувьсагчийн хайрцаг: дээр нэрийн шошго, дунд нь утга, доор int наалт.
## Буцаах: {stack, panel, value}.
func _make_var_box(var_name: String, value_text: String, box_size := Vector2(120, 80), font_size := 40) -> Dictionary:
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 0)
	var name_tag := PanelContainer.new()
	name_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	name_tag.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.CARD))
	name_tag.add_child(_code_label(var_name, 22))
	stack.add_child(name_tag)
	var panel := CardboardBox.new()
	panel.custom_minimum_size = box_size
	panel.add_theme_stylebox_override("panel", UiTheme.box_style())
	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	val.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	val.add_theme_font_size_override("font_size", font_size)
	val.add_theme_font_override("font", mono_font)
	panel.add_child(val)
	stack.add_child(panel)
	var type_tag := PanelContainer.new()
	type_tag.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	type_tag.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.INT_TAG))
	var type_label := _code_label("int", 18)
	type_tag.add_child(type_label)
	stack.add_child(type_tag)
	return {"stack": stack, "panel": panel, "value": val}


## Зөвхөн бүхэл тоо (сөрөг тэмдэгтэй байж болно) үлдээнэ.
func _on_guess_changed(text: String) -> void:
	var clean := ""
	for ch in text:
		if ch.is_valid_int() or (ch == "-" and clean == ""):
			clean += ch
	if clean != text:
		var caret := guess_edit.caret_column
		guess_edit.text = clean
		guess_edit.caret_column = mini(caret, clean.length())
	guess_entered = clean.is_valid_int()
	if not finished:
		guess_mark.text = ""   # шинэ таамаг бичиж эхлэхэд өмнөх ✗ арилна
	_update_glow()   # таамаг орсон бол гэрэл Эхлэх товч руу шилжинэ


## Буруу таамаг (1, 2 дахь удаа): хайрцаг сэгсрэгдэж ✗ гарна, тоонууд хэвээр, дахин бодно.
func _reject_guess() -> void:
	_show_message("✗  Дахин бод.  %d оролдлого үлдлээ." % (3 - wrong_tries), -1)
	guess_mark.text = "✗"
	guess_mark.add_theme_color_override("font_color", UiTheme.FALSE)
	var x0 := guess_edit.position.x
	var tw := create_tween()
	for dx in [10.0, -10.0, 6.0, -4.0, 0.0]:
		tw.tween_property(guess_edit, "position:x", x0 + dx, 0.05)
	guess_edit.grab_focus()
	guess_edit.select_all()   # шинэ тоо бичихэд хуучин нь солигдоно
	_update_glow()


## Монгол (кирилл) гарын байрлалд дээд эгнээний товч тоо биш тэмдэгт гаргадаг.
## Иймд товчны физик байрлалаар нь тоо оруулна: ямар ч байрлалд 1-9, 0 ажиллана.
func _on_guess_key(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or not guess_edit.editable:
		return
	var ch := _physical_digit(event)
	if ch == "":
		return
	if guess_edit.has_selection():
		guess_edit.delete_text(guess_edit.get_selection_from_column(), guess_edit.get_selection_to_column())
		guess_edit.deselect()
	guess_edit.insert_text_at_caret(ch)
	_on_guess_changed(guess_edit.text)
	guess_edit.accept_event()


## Товчны физик байрлалаас тоо (эсвэл "-"). Тоо биш товч бол "".
func _physical_digit(event: InputEventKey) -> String:
	var pk: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	if pk >= KEY_0 and pk <= KEY_9:
		return str(pk - KEY_0)
	if pk >= KEY_KP_0 and pk <= KEY_KP_9:
		return str(pk - KEY_KP_0)
	if pk == KEY_MINUS or pk == KEY_KP_SUBTRACT:
		return "-"
	return ""


func _on_start() -> void:
	if started or busy or drag_card != null:
		return
	var reveal_msg := ""
	if cur.mode == "predict":
		if not guess_entered:
			_show_message("Эхлээд таамаглалаа бич.", -1)
			return
		# Эхлээд таамгийг програм ажиллуулалгүйгээр шалгана. Буруу бол 3 дахь удаа хүртэл хариуг нууна.
		var ip := Interp.new()
		ip.load_program(program)
		while not ip.is_done():
			ip.step()
		var actual = ip.vars.get(cur.ask, null)
		if actual == null or int(guess_edit.text) != actual:
			wrong_tries += 1
			level_mistakes += 1
			if wrong_tries < 3:
				_reject_guess()
				return
			reveal_msg = "✗  3 удаа буруу. Програмыг ажиллуулж, яагаад гэдгийг хар."
	started = true
	finished = false
	interp.load_program(program)
	states.fill(0)
	guess_edit.editable = false
	guess_edit.release_focus()   # Enter/Space дараа нь гарын товчлол руу очно
	_show_message(reveal_msg, -1 if reveal_msg != "" else 0)
	_refresh_code()
	_refresh_boxes({})
	_update_buttons()


func _on_step() -> void:
	if not started or finished or busy:
		return
	busy = true
	_update_buttons()
	var old_vars: Dictionary = interp.vars.duplicate()
	var row := interp.pc
	var res := interp.step()
	if not res.ok:
		states[row] = 3
		finished = true
		level_mistakes += 1
		_show_message("%d-р мөр:  %s" % [row + 1, res.error], -1)
	else:
		states[row] = 2 if res.skipped else 1
		# Алхам бүрийн тайлбар бичиг байхгүй: анимаци өөрөө харуулна. Зөвхөн алдаа ба дүгнэлт бичигдэнэ.
		if not res.skipped and res.var != "" and not str(program[row]).strip_edges().begins_with("if"):
			await _animate_assign(row, old_vars, res)
		if interp.is_done():
			await _finish()
	_refresh_code()
	_refresh_boxes(interp.vars, res.var)
	busy = false
	_update_buttons()


## Мөрийг зайгаар хувааж, төгсгөлийн ';'-г тусдаа токен болгоно ("x = 5;" -> ["x", "=", "5", ";"]).
func _split_tokens(line: String) -> Array:
	var out: Array = []
	for part in line.split(" ", false):
		if part.length() > 1 and part.ends_with(";"):
			out.append(part.trim_suffix(";"))
			out.append(";")
		else:
			out.append(part)
	return out


## Утгууд хайрцгаас кодруу нисч, үйлдэл бодогдож, үр дүн хайрцагт орно.
## "int x = a + b;" ба "x = a + b;" хоёуланд ажиллана: '=' ба ';'-ийн хоорондох хэсгийг бодно.
func _animate_assign(row: int, old_vars: Dictionary, res: Dictionary) -> void:
	var toks: Array = row_tokens[row]
	var parts: Array = _split_tokens(str(program[row]))
	var eq := parts.find("=")
	if eq == -1:
		return
	var end := parts.size()
	if parts[end - 1] == ";":
		end -= 1
	var target: String = res.var
	var new_value = interp.vars[target]
	for k in range(eq + 1, end):
		var vn: String = parts[k]
		if old_vars.has(vn) and box_panels.has(vn):
			var lbl: Label = toks[k]
			await _fly(str(old_vars[vn]), _center_of(box_panels[vn]), _center_of(lbl), false, 34)
			lbl.text = str(old_vars[vn])
	if end - eq > 2:
		await _wait(0.5)
		for k in range(end - 1, eq + 1, -1):
			var lbl2: Label = toks[k]
			lbl2.get_parent().remove_child(lbl2)
			lbl2.queue_free()
		(toks[eq + 1] as Label).text = str(new_value)
		await _wait(0.4)
	if not box_panels.has(target):
		var with_target := old_vars.duplicate()
		with_target[target] = null
		_refresh_boxes(with_target)
		await _layout()
	await _fly(str(new_value), _center_of(toks[eq + 1]), _center_of(box_panels[target]), true, 34)


func _on_run_all() -> void:
	if not started or finished or busy:
		return
	_begin_action()
	run_token += 1
	var token := run_token
	while started and not finished and token == run_token:
		await _on_step()
		if not finished:
			await _wait(0.4)


func _on_reset() -> void:
	if busy:
		return
	if cur.mode == "predict":
		# Тоонууд шинээр сонгогдоно: цээжилсэн хариулт ашиггүй.
		cur = Levels.make(templates[level_index])
		_setup_level()
	else:
		_reset_state()


func _finish() -> void:
	finished = true
	var solved := false
	var text := ""
	if cur.mode == "predict":
		var actual = interp.vars.get(cur.ask, null)
		var guess := int(guess_edit.text)
		solved = actual != null and guess == actual
		# Санах ойн хайрцгаас жинхэнэ утга «Жинхэнэ» хайрцаг руу нисч, таамгийн хажууд ✓/✗ гарна.
		real_value.text = str(actual)
		real_col.visible = true
		real_col.modulate.a = 0.0
		await _layout()
		if box_panels.has(cur.ask):
			await _fly(str(actual), _center_of(box_panels[cur.ask]), _center_of(real_box), true, 34)
		real_col.modulate.a = 1.0
		guess_mark.text = "✓" if solved else "✗"
		guess_mark.add_theme_color_override("font_color", UiTheme.TRUE if solved else UiTheme.FALSE)
		# Хайрцгууд утгыг харуулж байгаа тул бичиг нь зөвхөн «яагаад» гэдгийг хэлнэ.
		text = ("ЗӨВ ✓   " if solved else "") + cur.hint
	else:
		var actual = interp.vars.get(cur.goal_var, null)
		if actual != null and actual == cur.goal:
			solved = true
			text = "ЗӨВ ✓   " + cur.hint
		else:
			level_mistakes += 1
			text = "%s = %s,   зорилт: %d" % [cur.goal_var, str(actual), cur.goal]
	_show_message(text, 1 if solved else -1)
	if solved:
		_offer_next()


func _move(dir: int) -> void:
	if cur.mode != "arrange" or started or busy:
		return
	if sel_index < 0:
		# Сонгосон мөр байхгүй бол эхний товчлол дээд мөрийг сонгоно.
		sel_index = 0
		_update_selection()
		return
	var j := sel_index + dir
	if j < 0 or j >= program.size() or drag_card != null:
		return
	_reorder(sel_index, j)


# ---------------------------------------------------------------- хамгаалагч

func _setup_guard() -> void:
	rule2_row.visible = cur.get("rules", 1) == 2
	op1.select(0)
	val1.value = 0
	join_opt.select(0)
	op2.select(4)
	val2.value = 0
	btn_test.disabled = false
	guard_view.reset()
	_update_guard_code()
	var two: bool = cur.get("rules", 1) == 2
	var t: int = cur.vals.get("T", 18)
	pending_crowd = _make_crowd(t, two)
	await _layout()
	guard_view.show_crowd(pending_crowd, two)


func _guard_condition() -> String:
	var c := "age %s %d" % [OPS[op1.selected], int(val1.value)]
	if cur.get("rules", 1) == 2:
		c += " %s card %s %d" % [join_opt.get_item_text(join_opt.selected), OPS[op2.selected], int(val2.value)]
	return c


func _update_guard_code() -> void:
	if guard_code == null or guard_view == null or cur.is_empty() or cur.mode != "guard":
		return
	guard_code.text = "if (%s) {\n    openDoor();\n} else {\n    keepClosed();\n}" % _guard_condition()
	guard_view.sign_text = _guard_condition()


func _make_crowd(t: int, two: bool) -> Array:
	var crowd: Array = []
	crowd.append({"age": t, "ticket": 1})
	crowd.append({"age": t - 1, "ticket": 1})
	crowd.append({"age": t + 1, "ticket": 1})
	# Хилээс хол доор ба хол дээр хүн заавал байна. Ингэснээр «age != 17» мэт
	# буруу дүрэм санамсаргүй тэнцэх боломжгүй.
	crowd.append({"age": randi_range(8, t - 3), "ticket": 1})
	crowd.append({"age": randi_range(t + 5, 40), "ticket": 1})
	if two:
		crowd.append({"age": t, "ticket": 0})
		crowd.append({"age": t + 4, "ticket": 0})
	while crowd.size() < 9:
		crowd.append({"age": randi_range(8, 40), "ticket": randi_range(0, 1)})
	crowd.shuffle()
	return crowd


func _on_test() -> void:
	if cur.mode == "cinema":
		_test_cinema()
	elif cur.mode == "guard":
		await _test_guard()


func _test_guard() -> void:
	if guard_view.running:
		return
	_begin_action()
	var two: bool = cur.get("rules", 1) == 2
	var free: bool = cur.get("free", false)
	var t: int = cur.vals.get("T", 18)
	var cond := _guard_condition()
	var e := Expression.new()
	if e.parse(cond, ["age", "card"]) != OK:
		_show_message("Дүрэм уншигдсангүй.", -1)
		return
	var judge := func(p: Dictionary) -> Dictionary:
		var res = e.execute([p.age, p.ticket], null, false)
		var allowed: bool = (res == true)
		var expect: bool = p.age >= t and (p.ticket == 1 or not two)
		var shown := cond.replace("card", str(p.ticket)).replace("age", str(p.age))
		return {"allowed": allowed, "expect": expect, "text": "%s   ->   %s" % [shown, "true" if allowed else "false"]}
	btn_test.disabled = true
	btn_next.visible = false
	_show_message("Шалгаж байна…")
	var result: Dictionary = await guard_view.run_test(pending_crowd, two, free, judge)
	pending_crowd = _make_crowd(t, two)
	guard_view.show_crowd(pending_crowd, two)
	btn_test.disabled = false
	if free:
		_show_message("%d хүн орлоо, %d хүн буцлаа. Дүрмээ өөрчлөөд дахин турш. Бэлэн болсон бол Дуусгах товчийг дар." % [result.let_in, result.denied], 1)
		_offer_next()
		return
	var wrong: Array = result.wrong
	if wrong.is_empty():
		_show_message("ЗӨВ.  Бүх хүн зөв шийдэгдлээ.  " + cur.hint, 1)
		_offer_next()
		return
	level_mistakes += 1
	var ages: Array = []
	var border_wrong := false
	for w in wrong:
		ages.append(str(w.age))
		if w.age == t:
			border_wrong = true
	var msg := "%d хүн буруу шийдэгдлээ (улаан тойрог): нас %s.  Тэдгээрийг дүрэмтэйгээ харьцуул." % [wrong.size(), ", ".join(ages)]
	if border_wrong:
		msg += "\nЯг %d настай хүн буруу шийдэгдсэн: хилийн утгыг анхаар." % t
	_show_message(msg, -1)


# ---------------------------------------------------------------- киноны билет

func _setup_cinema() -> void:
	for o in [ca_op, cb_op]:
		o.select(0)
	for s in [ca_val, ca_price, cb_val, cb_price, cc_price, cd_val, cd_minus, ce_val]:
		s.value = 0
	ce_mult.value = 1.0
	cin_list.clear()


func _cmp(a: int, op_index: int, b: int) -> bool:
	match OPS[op_index]:
		">": return a > b
		">=": return a >= b
		"<": return a < b
		"<=": return a <= b
		"==": return a == b
	return a != b


func _cinema_price(age: int, day: int, coupon: int) -> float:
	var price := 0.0
	if _cmp(age, ca_op.selected, int(ca_val.value)):
		price = ca_price.value
	elif _cmp(age, cb_op.selected, int(cb_val.value)):
		price = cb_price.value
	else:
		price = cc_price.value
	if day == int(cd_val.value):
		price = price - cd_minus.value
	if coupon == int(ce_val.value):
		price = price * ce_mult.value
	return price


func _cinema_expected(age: int, day: int, coupon: int) -> float:
	var price := 8.0 if age < 12 else (15.0 if age < 65 else 10.0)
	if day == 2:
		price -= 2.0
	if coupon == 1:
		price *= 0.9
	return price


func _cinema_customers() -> Array:
	var other := [1, 3, 4, 5, 6, 7]
	var list := [
		{"age": 11, "day": other.pick_random(), "coupon": 0},
		{"age": 12, "day": 2, "coupon": 0},
		{"age": 64, "day": other.pick_random(), "coupon": 1},
		{"age": 65, "day": 2, "coupon": 1},
		{"age": randi_range(3, 10), "day": 2, "coupon": 1},
		{"age": randi_range(20, 60), "day": other.pick_random(), "coupon": 0},
		{"age": randi_range(66, 90), "day": other.pick_random(), "coupon": 1},
		{"age": randi_range(13, 63), "day": 2, "coupon": 1},
	]
	list.shuffle()
	return list


func _test_cinema() -> void:
	cin_list.clear()
	btn_next.visible = false   # өмнө тэнцсэн ч одоогийн програм дахин шалгагдана
	var wrong := 0
	var edge_wrong := false
	var coupon_wrong := false
	for c in _cinema_customers():
		var mine := _cinema_price(c.age, c.day, c.coupon)
		var want := _cinema_expected(c.age, c.day, c.coupon)
		var ok := absf(mine - want) < 0.005
		var line := "нас %2d | өдөр %d | купон %d  ->  таны: $%.2f | зөв: $%.2f  %s" % [c.age, c.day, c.coupon, mine, want, "OK" if ok else "БУРУУ"]
		var idx := cin_list.add_item(line)
		cin_list.set_item_custom_bg_color(idx, Color(0.12, 0.3, 0.18) if ok else Color(0.5, 0.15, 0.15))
		if not ok:
			wrong += 1
			if c.age in [11, 12, 64, 65]:
				edge_wrong = true
			if c.coupon == 1:
				coupon_wrong = true
	if wrong == 0:
		_show_message("ЗӨВ.  Бүх үнэ таарлаа.  " + cur.hint, 1)
		_offer_next()
		return
	var msg := "%d үнэ буруу байна (улаан мөр). Улаан мөр бүрийг өөрийн программаар гараар бод." % wrong
	if edge_wrong:
		msg += "\nХилийн насуудыг (11, 12, 64, 65) шалга: < ба <= ялгаатай."
	if coupon_wrong:
		msg += "\nКупон: 10% хасна гэдэг нь үнийг 0.9-өөр үржүүлнэ гэсэн үг (price = price * 0.9;). Програм өдрийн хөнгөлөлтийг ЭХЛЭЭД хасдаг, купон ДАРАА нь үйлчилдэг тул гараар бодохдоо ч энэ дарааллыг баримтал."
	_show_message(msg, -1)


# ---------------------------------------------------------------- нисдэг утга (анимаци)

## Анимацийн бүх tween эндээс үүснэ: алгасах (F) үед ажиллаж буй ба шинэ tween-үүд хурдасна.
func _anim_tween() -> Tween:
	var tw := create_tween()
	if skipping:
		tw.set_speed_scale(SKIP_SCALE)
	anim_tweens = anim_tweens.filter(func(t: Tween) -> bool: return t.is_valid())
	anim_tweens.append(tw)
	return tw


## Хүлээх (timer-ийн оронд tween ашиглана, ингэснээр алгасах үед мөн хурдасна).
func _wait(secs: float) -> void:
	var tw := _anim_tween()
	tw.tween_interval(_t(secs))
	await tw.finished


## Тоглогчийн шинэ үйлдэл эхлэхэд алгасах горимыг цуцална.
func _begin_action() -> void:
	skipping = false
	guard_view.speed = 1.0
	challenge.bus.speed = 1.0


func _on_skip() -> void:
	skipping = true
	for tw in anim_tweens:
		if tw.is_valid():
			tw.set_speed_scale(SKIP_SCALE)
	guard_view.speed = 1.0 / SKIP_SCALE   # хамгаалагчийн дараагийн хөдөлгөөнүүд хурдан
	challenge.bus.speed = 1.0 / SKIP_SCALE


func _on_step_pressed() -> void:
	if not started or finished or busy:
		return
	_begin_action()
	await _on_step()


## Хөгжүүлэлтийн товчлол: F9 = дараагийн түвшин (зөвхөн debug хувилбарт; тоглоомын export-д ажиллахгүй).
## _input ашиглана: таамгийн нүд фокустай байсан ч ажиллана.
func _input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	# F11: бүтэн дэлгэц ⇄ цонх.
	if k == KEY_F11:
		var fs := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
		get_viewport().set_input_as_handled()
		return
	if OS.is_debug_build():
		if k == KEY_F9:
			if level_index + 1 < templates.size():
				progress.unlocked = maxi(progress.unlocked, level_index + 2)
				_load_level(level_index + 1)
			get_viewport().set_input_as_handled()


## Гарын товчлол. Товчнууд фокус авдаггүй тул эдгээр нь зөвхөн энд боловсруулагдана.
## physical_keycode: монгол (кирилл) гарын байрлалтай ч W/S/D/F ажиллана.
func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed:
		return
	var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
	var repeatable := key in [KEY_W, KEY_S, KEY_UP, KEY_DOWN]
	if event.echo and not repeatable:
		return
	# Маршрут: ← / → (A / D) буудал сонгох, Enter / Space явах.
	if route_view.visible:
		match key:
			KEY_LEFT, KEY_A:
				route_view.move_sel(-1)
			KEY_RIGHT, KEY_D:
				route_view.move_sel(1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				route_view.activate()
			_:
				return
		get_viewport().set_input_as_handled()
		return
	if key == KEY_ESCAPE:
		_show_map()
		get_viewport().set_input_as_handled()
		return
	# Сорилт: → / D = дуусгасны дараа дараагийн түвшин, Enter = турших.
	if cur.get("mode", "") == "challenge" and key in [KEY_RIGHT, KEY_D, KEY_ENTER, KEY_KP_ENTER]:
		if key in [KEY_ENTER, KEY_KP_ENTER]:
			challenge.key_enter()
		elif btn_next.visible:
			_on_next()
		else:
			challenge.key_next()
		get_viewport().set_input_as_handled()
		return
	# Нөхцлийн тест: ← = F (худал зам), → = T (үнэн зам).
	if cur.get("mode", "") == "flow" and flow_phase == "test" and key in [KEY_LEFT, KEY_RIGHT]:
		_flow_choose(1 if key == KEY_RIGHT else 0)
		get_viewport().set_input_as_handled()
		return
	match key:
		KEY_RIGHT, KEY_D:
			if btn_next.visible:
				_on_next()
			elif btn_tut.visible and not btn_tut.disabled:
				_on_tut_next()
		KEY_ENTER, KEY_KP_ENTER:
			if btn_start.visible and not btn_start.disabled:
				_on_start()
			elif btn_step.visible and not btn_step.disabled:
				_on_step_pressed()
		KEY_SPACE:
			if btn_run.visible and not btn_run.disabled:
				_on_run_all()
		KEY_F:
			if btn_skip.visible:
				_on_skip()
		KEY_W, KEY_UP:
			_move(-1)
		KEY_S, KEY_DOWN:
			_move(1)
		_:
			return
	get_viewport().set_input_as_handled()


func _layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _center_of(c: Control) -> Vector2:
	return c.global_position + c.size / 2.0


## Утга нэг цэгээс нөгөө рүү нисдэг. pulse = true бол «хуулбар» мэт томорч гарна.
func _fly(text: String, from_center: Vector2, to_center: Vector2, pulse: bool, font_size: int = 56) -> void:
	var f := Label.new()
	f.text = text
	f.add_theme_font_size_override("font_size", font_size)
	f.add_theme_font_override("font", mono_font)
	f.add_theme_color_override("font_color", YELLOW)
	f.add_theme_color_override("font_outline_color", UiTheme.INK)
	f.add_theme_constant_override("outline_size", maxi(6, font_size / 6))
	fly_layer.add_child(f)
	var half := f.get_combined_minimum_size() / 2.0
	f.pivot_offset = half
	f.global_position = from_center - half
	var tw := _anim_tween()
	if pulse:
		tw.tween_property(f, "scale", Vector2(1.5, 1.5), _t(0.25))
		tw.tween_property(f, "scale", Vector2.ONE, _t(0.15))
	tw.tween_property(f, "global_position", to_center - half, _t(0.9)).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	f.queue_free()


# ---------------------------------------------------------------- үзүүлэн заавар

func _tut_reset() -> void:
	tut_step = 0
	tut_busy = false
	_set_tokens([])
	tut_box.modulate.a = 0.0
	tut_name_tag.modulate.a = 0.0
	tut_type_tag.modulate.a = 0.0
	tut_value.text = ""
	tut_value.modulate.a = 1.0
	# Оролдлого/үзэлт бүрт өөр тоо: цээжлэх биш, ойлгох.
	tut_v = randi_range(2, 9)
	tut_k = randi_range(1, 5)
	tut_caption.text = ""
	_update_glow()   # бичгийн оронд товч өөрөө «намайг дар» гэж гэрэлтэнэ
	btn_tut.disabled = false
	btn_next.visible = false


func _set_tokens(tokens: Array) -> void:
	for c in code_row.get_children():
		code_row.remove_child(c)
		c.queue_free()
	for t in tokens:
		var l := _code_label(str(t), 56)
		l.add_theme_color_override("font_color", _token_color(str(t)))
		code_row.add_child(l)


func _tok(i: int) -> Label:
	return code_row.get_child(i) as Label


# ---------------------------------------------------------------- нөхцөл (flow): if / if-else блок схем

func _flow_reset() -> void:
	flow_phase = "explain"
	flow_step = 0
	flow_busy = false
	flow_correct = 0
	flow_round = 0
	flow_op_queue.clear()
	var t: int = cur.vals.T
	flow_op = cur.ops[0]
	# Тайлбарын хоёр жишээ: нэг нь үнэн (хилээс дээш), нэг нь худал (хилээс доош).
	flow_big = t + randi_range(3, 10)
	flow_small = maxi(1, t - randi_range(3, 10))
	flow_input = flow_big
	_flow_build_code(flow_op)
	_flow_set_boxes(flow_big, 0)
	flow_view.kind = cur.kind
	flow_view.t_stmt = "%s = %d;" % [cur.out_var, cur.t_val]
	flow_view.f_stmt = "%s = %d;" % [cur.out_var, cur.f_val]
	_flow_clear_view()
	flow_view.cond_text = "%s %s %d" % [cur.in_var, flow_op, t]
	btn_tut.visible = true
	btn_tut.disabled = false
	btn_false.visible = false
	btn_true.visible = false
	_show_message("")
	_update_glow()


func _flow_clear_view() -> void:
	flow_view.eval_state = 0
	flow_view.active_side = -1
	flow_view.flash_side = -1
	flow_view.chosen_side = -1
	flow_view.hover_side = -1
	flow_view.choosing = false
	flow_view.token_visible = false
	_flow_view_numline_off()


## Кодын мөрүүд (C++). Мөр 0 = нөхцөл, 1 = T блок, (3 = F блок ifelse-д), сүүлийнх = «}».
func _flow_lines(op: String) -> Array:
	var lines := [
		"if (%s %s %d) {" % [cur.in_var, op, cur.vals.T],
		"    %s = %d;" % [cur.out_var, cur.t_val],
	]
	if cur.kind == "ifelse":
		lines.append("} else {")
		lines.append("    %s = %d;" % [cur.out_var, cur.f_val])
	lines.append("}")
	return lines


func _flow_build_code(op: String) -> void:
	for c in flow_code.get_children():
		flow_code.remove_child(c)
		c.queue_free()
	flow_rows.clear()
	for line in _flow_lines(op):
		var sb := StyleBoxFlat.new()
		sb.bg_color = ROW_BASE
		sb.set_corner_radius_all(6)
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(440, 0)
		row.add_theme_stylebox_override("panel", sb)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		row.add_child(h)
		var indent: int = str(line).length() - str(line).lstrip(" ").length()
		if indent > 0:
			var sp := Control.new()
			sp.custom_minimum_size = Vector2(indent * 9, 0)
			h.add_child(sp)
		for part in _split_tokens(str(line).strip_edges()):
			var fl := _code_label(part, 26)
			fl.add_theme_color_override("font_color", _token_color(part))
			h.add_child(fl)
		flow_code.add_child(row)
		flow_rows.append(row)


## Мөрийн өнгө: 0 энгийн, 1 ажилласан (ногоон), 2 алгассан (саарал), 3 одоогийн (шар).
func _flow_row(i: int, state: int) -> void:
	if i < 0 or i >= flow_rows.size():
		return
	var sb: StyleBoxFlat = (flow_rows[i] as Control).get_theme_stylebox("panel")
	sb.bg_color = [ROW_BASE, ROW_DONE, ROW_SKIP, ROW_CURRENT][state]


func _flow_set_boxes(in_v: int, out_v: int) -> void:
	for slot in [flow_in_slot, flow_out_slot]:
		for c in slot.get_children():
			slot.remove_child(c)
			c.queue_free()
	var a := _make_var_box(cur.in_var, str(in_v), Vector2(100, 64), 32)
	flow_in_slot.add_child(a.stack)
	flow_in_panel = a.panel
	flow_in_val = a.value
	var b := _make_var_box(cur.out_var, str(out_v), Vector2(100, 64), 32)
	flow_out_slot.add_child(b.stack)
	flow_out_panel = b.panel
	flow_out_val = b.value


func _flow_eval(v: int, op: String) -> bool:
	var e := Expression.new()
	e.parse("%d %s %d" % [v, op, cur.vals.T])
	return e.execute() == true


func _flow_move_token(side: int, from_t: float, to_t: float, secs: float) -> void:
	var tw := _anim_tween()
	tw.tween_method(func(t: float): flow_view.token_pos = flow_view.point_on(side, t), from_t, to_t, _t(secs))
	await tw.finished


## Нэг удаа «компьютер шиг» ажиллуулна: утга нөхцөл рүү нисч, true/false болж, токен зөв замаар явна,
## ажилласан блокийн утга гаралтын хайрцагт нисч орно. Буцаах: нөхцлийн үр дүн.
func _flow_run(value: int, op: String) -> bool:
	var t: int = cur.vals.T
	flow_input = value
	flow_in_val.text = str(value)
	flow_out_val.text = "0"
	flow_out_val.remove_theme_color_override("font_color")
	for i in flow_rows.size():
		_flow_row(i, 0)
	_flow_row(0, 3)
	var keep_choice: int = flow_view.chosen_side
	_flow_clear_view()
	flow_view.chosen_side = -1
	flow_view.cond_text = "%s %s %d" % [cur.in_var, op, t]
	var oval: Vector2 = flow_view.global_position + flow_view.cond_center()
	await _fly(str(value), _center_of(flow_in_panel), oval, false, 30)
	flow_view.cond_text = "%d %s %d" % [value, op, t]   # хувьсагчийн оронд утга нь орлоо
	await _wait(0.5)
	var res := _flow_eval(value, op)
	flow_view.eval_state = 1 if res else 2
	await _wait(0.5)
	var side := 1 if res else 0
	flow_view.active_side = side
	flow_view.token_text = str(value)
	flow_view.token_visible = true
	var tb: float = flow_view.t_at_box(side)
	await _flow_move_token(side, 0.0, tb, 0.6)
	_flow_row(0, 1)
	if flow_view.has_box(side):
		flow_view.flash_side = side
		_flow_row(1 if side == 1 else 3, 1)
		if cur.kind == "ifelse":
			_flow_row(3 if side == 1 else 1, 2)
		var out_v: int = cur.t_val if side == 1 else cur.f_val
		await _fly(str(out_v), flow_view.global_position + flow_view.box_center(side), _center_of(flow_out_panel), true, 30)
		flow_out_val.text = str(out_v)
		flow_out_val.add_theme_color_override("font_color", UiTheme.HILITE)
	else:
		_flow_row(1, 2)   # if-ийн блок алгасагдлаа
	await _flow_move_token(side, tb, 1.0, 0.5)
	flow_view.token_visible = false
	flow_view.chosen_side = keep_choice
	return res


## Тайлбар: 1) нөхцөл, 2) үнэн жишээ, 3) худал жишээ, 4) тест эхэлнэ.
func _flow_next_step() -> void:
	if flow_busy or flow_phase != "explain":
		return
	_begin_action()
	flow_busy = true
	btn_tut.disabled = true
	_update_glow()
	flow_step += 1
	match flow_step:
		1:
			_flow_row(0, 3)
			_show_message("Нөхцөл: үнэн эсвэл худал")
			await _wait(0.2)
		2:
			_show_message("")
			await _flow_run(flow_big, flow_op)
			_show_message("Үнэн → блок ажиллана")
		3:
			_show_message("")
			await _flow_run(flow_small, flow_op)
			_show_message("Худал → алгасна" if cur.kind == "if" else "Худал → else ажиллана")
		_:
			# 4+: (explain_ops) оператор бүрийг тоон шулуунаар; дараа нь тест.
			var k := flow_step - 4
			if cur.get("explain_ops", false) and k < cur.ops.size():
				_flow_show_op(cur.ops[k])
				await _wait(0.3)
			else:
				_flow_view_numline_off()
				flow_busy = false
				_flow_start_test()
				return
	flow_busy = false
	btn_tut.disabled = false
	_update_glow()


## Операторыг тоон шулуунаар үзүүлнэ: хилийн орчмын аль тоо нөхцлийг үнэн болгох вэ.
const OP_CAPTIONS := {
	">": "«>» их:  тэнцүү нь орохгүй",
	">=": "«>=» их эсвэл тэнцүү:  тэнцүү нь орно",
	"==": "«==» яг тэнцүү:  зөвхөн нэг тоо   (= нь хадгалах, == нь харьцуулах!)",
}


func _flow_show_op(op: String) -> void:
	_flow_clear_view()
	flow_op = op
	_flow_build_code(op)
	_flow_row(0, 3)
	flow_view.cond_text = "%s %s %d" % [cur.in_var, op, cur.vals.T]
	flow_view.numline_op = op
	flow_view.numline_t = cur.vals.T
	_show_message(OP_CAPTIONS.get(op, op))


func _flow_view_numline_off() -> void:
	flow_view.numline_t = -1
	flow_view.numline_op = ""


func _flow_start_test() -> void:
	flow_phase = "test"
	btn_tut.visible = false   # тестийн үед хэрэггүй; «Дахин үзэх» тайлбарыг дахин эхлүүлнэ
	_update_glow()
	_flow_new_round()


func _flow_dots() -> String:
	return "●".repeat(flow_correct) + "○".repeat(FLOW_NEED - flow_correct)


func _flow_new_round() -> void:
	flow_round += 1
	var t: int = cur.vals.T
	# Оператор бүр ээлжээр (холилдсон дарааллаар) асуугдана: 3 зөв = оператор бүрээс нэг.
	if flow_op_queue.is_empty():
		flow_op_queue = cur.ops.duplicate()
		flow_op_queue.shuffle()
	flow_op = flow_op_queue.pop_front()
	if cur.get("explain_ops", false):
		# Операторууд зөвхөн хил орчимд ялгагдана: T-1, T, T+1.
		flow_input = t + randi_range(-1, 1)
	elif flow_round == 2:
		flow_input = t   # 2 дахь асуулт үргэлж хилийн утга
	else:
		flow_input = maxi(1, t + randi_range(1, 15) * (1 if randf() < 0.5 else -1))
	_flow_build_code(flow_op)
	_flow_row(0, 3)
	flow_in_val.text = str(flow_input)
	flow_out_val.text = "0"
	flow_out_val.remove_theme_color_override("font_color")
	_flow_clear_view()
	flow_view.cond_text = "%s %s %d" % [cur.in_var, flow_op, t]
	flow_view.choosing = true
	btn_false.visible = true
	btn_true.visible = true
	btn_false.disabled = false
	btn_true.disabled = false
	# Асуулт тодорхой: оролтын утга + «үнэн үү, худал уу?» + ахиц.
	_show_question("%s = %d  →  ҮНЭН үү, ХУДАЛ уу?        %s" % [cur.in_var, flow_input, _flow_dots()])


## Тоглогч замаа сонгоно (товшилт эсвэл ←/→). Дараа нь компьютер жинхэнэ замаар явж ✓/✗ гарна.
func _flow_choose(side: int) -> void:
	if cur.get("mode", "") != "flow" or flow_phase != "test" or flow_busy:
		return
	_begin_action()
	flow_busy = true
	flow_view.choosing = false
	flow_view.hover_side = -1
	btn_false.disabled = true
	btn_true.disabled = true
	var expect := _flow_eval(flow_input, flow_op)
	var ok := (side == 1) == expect
	_show_message("")
	await _flow_run(flow_input, flow_op)
	flow_view.chosen_side = side
	flow_view.chosen_ok = ok
	var t: int = cur.vals.T
	if ok:
		flow_correct += 1
		_show_message("✓   " + _flow_dots(), 1)
	else:
		level_mistakes += 1
		var why := "✗   %d %s %d  →  %s" % [flow_input, flow_op, t, "ҮНЭН (true)" if expect else "ХУДАЛ (false)"]
		if flow_op == "==":
			why += "    («==» зөвхөн яг %d үед үнэн)" % t
		elif flow_input == t:
			if flow_op in [">", "<"]:
				why += "    («%s» тэнцүүг оруулахгүй)" % flow_op
			elif flow_op in [">=", "<="]:
				why += "    («%s» тэнцүүг оруулна)" % flow_op
		_show_message(why + "        " + _flow_dots(), -1)
	if flow_correct >= FLOW_NEED:
		flow_phase = "done"
		flow_busy = false
		btn_false.visible = false
		btn_true.visible = false
		_show_message("ЗӨВ ✓   " + cur.hint, 1)
		_offer_next()
		return
	await _wait(1.0 if ok else 2.4)   # буруу бол тайлбарыг унших хугацаа
	flow_busy = false
	if cur.get("mode", "") == "flow" and flow_phase == "test":
		_flow_new_round()


func _on_tut_next() -> void:
	if cur.mode == "flow":
		await _flow_next_step()
		return
	if tut_busy or tut_step >= 3:
		return
	_begin_action()
	tut_busy = true
	_update_glow()
	btn_tut.disabled = true
	tut_step += 1
	match tut_step:
		1: await _tut_step1()
		2: await _tut_step2()
		3: await _tut_step3()
	tut_busy = false
	if tut_step >= 3:
		_offer_next()
	else:
		btn_tut.disabled = false


func _on_tut_replay() -> void:
	if cur.mode == "flow":
		if not flow_busy:
			_flow_reset()
		return
	if tut_busy:
		return
	_tut_reset()




func _fade_in(c: Control, secs: float = 0.4) -> void:
	var tw := _anim_tween()
	tw.tween_property(c, "modulate:a", 1.0, _t(secs))
	await tw.finished


func _mark(i: int, on: bool) -> void:
	if on:
		_tok(i).add_theme_color_override("font_color", YELLOW)
	else:
		_tok(i).add_theme_color_override("font_color", _token_color(_tok(i).text))


## int people;  ->  'int' төрлийн наалт болж, 'people' нэрийн шошго болж, хайрцаг хоосон.
func _tut_step1() -> void:
	_set_tokens(["int", "people", ";"])
	tut_caption.text = ""
	await _layout()
	_mark(0, true)
	await _fade_in(tut_box)
	await _fly("int", _center_of(_tok(0)), _center_of(tut_type_tag), false, 40)
	await _fade_in(tut_type_tag, 0.2)
	_mark(0, false)
	_mark(1, true)
	await _fly("people", _center_of(_tok(1)), _center_of(tut_name_tag), false, 40)
	await _fade_in(tut_name_tag, 0.2)
	_mark(1, false)
	# Хайрцаг хоосон харагдана. Тайлбар нь «утга өгөөгүй» гэж үнэнээр хэлнэ
	# (C++-д утга өгөөгүй хувьсагчийг уншвал алдаа гэдгийг дараагийн түвшнүүдэд Interp тайлбарлана).
	tut_caption.text = "Хайрцаг бэлэн, утга өгөөгүй"


func _tut_step2() -> void:
	_set_tokens(["people", "=", str(tut_v), ";"])
	tut_caption.text = ""
	await _layout()
	_mark(2, true)
	await _fly(str(tut_v), _center_of(_tok(2)), _center_of(tut_box), true)
	tut_value.text = str(tut_v)
	tut_caption.text = "%d хадгалагдлаа" % tut_v


func _tut_step3() -> void:
	_set_tokens(["people", "=", "people", "+", str(tut_k), ";"])
	tut_caption.text = ""
	await _layout()
	# '=' түр '←' болж хувирна: «тэнцүү» биш, «хайрцагт хийх» гэсэн үг.
	_mark(1, true)
	_tok(1).text = "←"
	tut_caption.text = "«=» нь «хийх, олгох»"
	await _wait(1.5)
	_tok(1).text = "="
	# 2 хайрцгаас кодын хоёр дахь 'people' руу нисэж, түүнийг сольно.
	# (Хайрцагт бүдэг 2 үлдэнэ: хайрцгийг унших нь утгыг хуулдаг, шинэ утга ирэх хүртэл хэвээр байна.)
	tut_value.modulate.a = 0.3
	await _fly(str(tut_v), _center_of(tut_box), _center_of(_tok(2)), false)
	_tok(2).text = str(tut_v)
	await _wait(1.0)
	_set_tokens(["people", "=", str(tut_v + tut_k), ";"])
	await _layout()
	_tok(1).add_theme_color_override("font_color", YELLOW)
	await _wait(0.8)
	await _fly(str(tut_v + tut_k), _center_of(_tok(2)), _center_of(tut_box), true)
	tut_value.text = str(tut_v + tut_k)
	tut_value.modulate.a = 1.0
	tut_caption.text = "Хуучин %d → шинэ %d" % [tut_v, tut_v + tut_k]
