extends Control
## Logic Quest - 1-р хэсэг. UI бүхлээрээ кодоор бүтдэг.

const OPS := [">", ">=", "<", "<=", "==", "!="]
const ROW_BASE := Color(0.13, 0.15, 0.2)
const ROW_CURRENT := Color(0.45, 0.38, 0.1)
const ROW_DONE := Color(0.12, 0.3, 0.18)
const ROW_SKIP := Color(0.25, 0.25, 0.28)
const ROW_ERR := Color(0.5, 0.15, 0.15)
const YELLOW := Color(1.0, 0.85, 0.3)

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
var mono_font: SystemFont

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
var code_row: HBoxContainer
var tut_name: Label
var tut_box: PanelContainer
var tut_value: Label
var tut_caption: Label
var fly_layer: Control
var tut_step := 0
var tut_busy := false
var predict_row: HBoxContainer
var predict_label: Label
var predict_spin: SpinBox
var controls: HBoxContainer
var message_label: Label
var btn_start: Button
var btn_step: Button
var btn_run: Button
var btn_reset: Button
var btn_up: Button
var btn_down: Button
var btn_test: Button
var btn_tut: Button
var btn_replay: Button
var btn_next: Button


func _ready() -> void:
	var t := Theme.new()
	t.default_font_size = 20
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Arial", "Noto Sans", "DejaVu Sans", "sans-serif"])
	t.default_font = sf
	theme = t
	mono_font = SystemFont.new()
	mono_font.font_names = PackedStringArray(["Consolas", "Courier New", "DejaVu Sans Mono", "monospace"])
	_build_ui()
	_load_level(0)


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
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 24)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 32)
	root.add_child(title_label)

	story_label = Label.new()
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(story_label)

	# --- Програм + хайрцгууд (predict / arrange) ---
	main_row = HBoxContainer.new()
	main_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_row.add_theme_constant_override("separation", 24)
	root.add_child(main_row)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.3
	left.add_theme_constant_override("separation", 8)
	main_row.add_child(left)
	left.add_child(_label("ПРОГРАМ (дээрээс доош ажиллана)"))
	code_box = VBoxContainer.new()
	code_box.add_theme_constant_override("separation", 6)
	left.add_child(code_box)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_row.add_child(right)
	right.add_child(_label("САНАХ ОЙН ХАЙРЦАГ"))
	boxes = HFlowContainer.new()
	boxes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	boxes.add_theme_constant_override("h_separation", 12)
	boxes.add_theme_constant_override("v_separation", 12)
	right.add_child(boxes)

	# --- Хамгаалагч ---
	guard_panel = HBoxContainer.new()
	guard_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	guard_panel.add_theme_constant_override("separation", 16)
	root.add_child(guard_panel)

	var gl := VBoxContainer.new()
	gl.custom_minimum_size = Vector2(430, 0)
	gl.add_theme_constant_override("separation", 10)
	guard_panel.add_child(gl)
	gl.add_child(_label("ХАМГААЛАГЧИЙН ДҮРЭМ"))
	var row1 := _row(gl)
	row1.add_child(_code_label("if age"))
	op1 = _make_op_option(true)
	row1.add_child(op1)
	val1 = _make_spin(0, 99, true)
	row1.add_child(val1)
	rule2_row = _row(gl)
	join_opt = OptionButton.new()
	join_opt.add_item("and")
	join_opt.add_item("or")
	join_opt.custom_minimum_size = Vector2(100, 44)
	join_opt.item_selected.connect(func(_i): _update_guard_code())
	rule2_row.add_child(join_opt)
	rule2_row.add_child(_code_label("ticket"))
	op2 = _make_op_option(true)
	rule2_row.add_child(op2)
	val2 = _make_spin(0, 1, true)
	rule2_row.add_child(val2)
	guard_code = _code_label("", 20)
	gl.add_child(guard_code)

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
	cl.add_child(_label("ПРОГРАМ (хоосон талбаруудыг өөрөө бөглө)"))
	cl.add_child(_code_label("price = 0"))
	var r1 := _row(cl)
	r1.add_child(_code_label("if age"))
	ca_op = _make_op_option(false)
	r1.add_child(ca_op)
	ca_val = _make_spin(0, 100)
	r1.add_child(ca_val)
	r1.add_child(_code_label(":  price ="))
	ca_price = _make_spin(0, 50)
	r1.add_child(ca_price)
	var r2 := _row(cl)
	r2.add_child(_code_label("elif age"))
	cb_op = _make_op_option(false)
	r2.add_child(cb_op)
	cb_val = _make_spin(0, 100)
	r2.add_child(cb_val)
	r2.add_child(_code_label(":  price ="))
	cb_price = _make_spin(0, 50)
	r2.add_child(cb_price)
	var r3 := _row(cl)
	r3.add_child(_code_label("else:  price ="))
	cc_price = _make_spin(0, 50)
	r3.add_child(cc_price)
	var r4 := _row(cl)
	r4.add_child(_code_label("if day =="))
	cd_val = _make_spin(0, 7)
	r4.add_child(cd_val)
	r4.add_child(_code_label(":  price = price -"))
	cd_minus = _make_spin(0, 20)
	r4.add_child(cd_minus)
	var r5 := _row(cl)
	r5.add_child(_code_label("if coupon =="))
	ce_val = _make_spin(0, 1)
	r5.add_child(ce_val)
	r5.add_child(_code_label(":  price = price *"))
	ce_mult = _make_spin(0, 2)
	ce_mult.step = 0.05
	r5.add_child(ce_mult)
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
	tutorial_panel.add_child(code_row)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tutorial_panel.add_child(spacer)
	tut_name = Label.new()
	tut_name.text = "a"
	tut_name.add_theme_font_size_override("font_size", 36)
	var name_center := CenterContainer.new()
	name_center.add_child(tut_name)
	tutorial_panel.add_child(name_center)
	tut_box = PanelContainer.new()
	tut_box.custom_minimum_size = Vector2(200, 130)
	tut_box.add_theme_stylebox_override("panel", _box_style())
	var box_center := CenterContainer.new()
	box_center.add_child(tut_box)
	tutorial_panel.add_child(box_center)
	tut_value = Label.new()
	tut_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tut_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tut_value.add_theme_font_size_override("font_size", 64)
	tut_box.add_child(tut_value)
	tut_caption = Label.new()
	tut_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tut_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tut_caption.custom_minimum_size = Vector2(0, 80)
	tutorial_panel.add_child(tut_caption)

	# --- Таамаглал ---
	predict_row = HBoxContainer.new()
	root.add_child(predict_row)
	predict_label = Label.new()
	predict_row.add_child(predict_label)
	predict_spin = SpinBox.new()
	predict_spin.min_value = -1000
	predict_spin.max_value = 1000
	predict_spin.step = 1
	predict_spin.custom_minimum_size = Vector2(140, 0)
	predict_row.add_child(predict_spin)

	# --- Товчнууд ---
	controls = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root.add_child(controls)
	btn_start = _make_button("Эхлэх", _on_start)
	btn_step = _make_button("Алхам", _on_step)
	btn_run = _make_button("Бүгдийг ажиллуулах", _on_run_all)
	btn_reset = _make_button("Дахин эхлэх", _on_reset)
	btn_up = _make_button("Дээш зөөх", func(): _move(-1))
	btn_down = _make_button("Доош зөөх", func(): _move(1))
	btn_test = _make_button("Турших", _on_test)
	btn_tut = _make_button("Дараагийн алхам", _on_tut_next)
	btn_replay = _make_button("Дахин үзэх", _on_tut_replay)
	btn_next = _make_button("Дараагийн түвшин", _on_next)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(0, 70)
	root.add_child(message_label)

	# Нисдэг утгууд хамгийн дээр зурагдана.
	fly_layer = Control.new()
	fly_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	fly_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fly_layer)


func _box_style() -> StyleBoxFlat:
	var bs := StyleBoxFlat.new()
	bs.bg_color = Color(0.12, 0.14, 0.2)
	bs.set_border_width_all(4)
	bs.border_color = Color(0.9, 0.9, 0.95)
	bs.set_corner_radius_all(8)
	return bs


func _make_button(text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 44)
	b.pressed.connect(handler)
	controls.add_child(b)
	return b


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
	if live:
		s.value_changed.connect(func(_v): _update_guard_code())
	return s


# ---------------------------------------------------------------- түвшин

func _load_level(i: int) -> void:
	level_index = i
	cur = Levels.make(templates[i])
	_setup_level()


func _setup_level() -> void:
	var mode: String = cur.mode
	program = cur.lines.duplicate()
	sel_index = -1
	title_label.text = "Түвшин %d / %d  -  %s" % [level_index + 1, templates.size(), cur.title]
	story_label.text = cur.story
	predict_label.text = "Ажиллуулахаас өмнө: төгсгөлд '%s' хэд болох вэ?   " % cur.get("ask", "")
	var is_play := mode == "predict" or mode == "arrange"
	main_row.visible = is_play
	guard_panel.visible = mode == "guard"
	cinema_panel.visible = mode == "cinema"
	tutorial_panel.visible = mode == "tutorial"
	predict_row.visible = mode == "predict"
	btn_start.visible = is_play
	btn_step.visible = is_play
	btn_run.visible = is_play
	btn_reset.visible = is_play
	btn_up.visible = mode == "arrange"
	btn_down.visible = mode == "arrange"
	btn_test.visible = mode == "guard" or mode == "cinema"
	btn_tut.visible = mode == "tutorial"
	btn_replay.visible = mode == "tutorial"
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
	predict_spin.editable = true
	if cur.mode == "guard":
		message_label.text = "Дүрмээ тохируулаад Турших товчийг дар."
	elif cur.mode == "cinema":
		message_label.text = "Талбаруудыг бөглөөд Турших товчийг дар."
	elif cur.mode == "tutorial":
		message_label.text = ""
		_tut_reset()
	else:
		message_label.text = "Бэлэн болмогц Эхлэх товчийг дар."
	message_label.remove_theme_color_override("font_color")
	btn_next.visible = false
	_refresh_code()
	_refresh_boxes({})
	_update_buttons()


func _update_buttons() -> void:
	btn_start.disabled = started or busy
	btn_step.disabled = not started or finished or busy
	btn_run.disabled = not started or finished or busy
	btn_reset.disabled = not started or busy
	btn_up.disabled = started or busy
	btn_down.disabled = started or busy


func _show_message(text: String, good_or_bad: int = 0) -> void:
	message_label.text = text
	match good_or_bad:
		1: message_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
		-1: message_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
		_: message_label.remove_theme_color_override("font_color")


func _offer_next() -> void:
	btn_next.text = "Дараагийн түвшин" if level_index + 1 < templates.size() else "Дуусгах"
	btn_next.visible = true


func _on_next() -> void:
	if busy or tut_busy or guard_view.running:
		return
	if level_index + 1 < templates.size():
		_load_level(level_index + 1)
	else:
		btn_next.visible = false
		btn_test.disabled = true
		btn_start.disabled = true
		btn_step.disabled = true
		btn_run.disabled = true
		_show_message("1-р хэсэг дууслаа!  Дараа нь: 2-р хэсэг (Давталт).", 1)


# ---------------------------------------------------------------- програм ба хайрцгууд

func _refresh_code() -> void:
	for c in code_box.get_children():
		code_box.remove_child(c)
		c.queue_free()
	row_tokens.clear()
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
		sb.set_corner_radius_all(6)
		sb.set_content_margin_all(10)
		if cur.mode == "arrange" and not started and i == sel_index:
			sb.set_border_width_all(3)
			sb.border_color = YELLOW
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", sb)
		panel.gui_input.connect(_on_row_input.bind(i))
		var h := HBoxContainer.new()
		h.mouse_filter = Control.MOUSE_FILTER_IGNORE
		h.add_theme_constant_override("separation", 16)
		panel.add_child(h)
		h.add_child(_code_label(("> %d" if current else "  %d") % (i + 1), 30))
		var toks: Array = []
		for part in str(program[i]).split(" "):
			var l := _code_label(part, 34)
			h.add_child(l)
			toks.append(l)
		row_tokens.append(toks)
		code_box.add_child(panel)


func _on_row_input(event: InputEvent, i: int) -> void:
	if cur.mode != "arrange" or started or busy:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		sel_index = i
		call_deferred("_refresh_code")


func _refresh_boxes(vals: Dictionary, changed: String = "") -> void:
	for c in boxes.get_children():
		boxes.remove_child(c)
		c.queue_free()
	box_panels.clear()
	for k in vals:
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(120, 100)
		panel.add_theme_stylebox_override("panel", _box_style())
		var v := VBoxContainer.new()
		panel.add_child(v)
		var n := Label.new()
		n.text = str(k)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(n)
		var val := Label.new()
		val.text = "" if vals[k] == null else str(vals[k])
		val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		val.add_theme_font_size_override("font_size", 40)
		if str(k) == changed:
			val.add_theme_color_override("font_color", YELLOW)
		v.add_child(val)
		boxes.add_child(panel)
		box_panels[str(k)] = panel


func _on_start() -> void:
	if started or busy:
		return
	started = true
	finished = false
	interp.load_program(program)
	states.fill(0)
	predict_spin.editable = false
	_show_message("Мөр бүрийг ажиллуулахын тулд Алхам, эсвэл Бүгдийг ажиллуулах товчийг дар.")
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
		_show_message("%d-р мөр:  %s" % [row + 1, res.error], -1)
	else:
		states[row] = 2 if res.skipped else 1
		_show_message("%d-р мөр:  %s" % [row + 1, res.note])
		if not res.skipped and res.var != "" and not str(program[row]).begins_with("if "):
			await _animate_assign(row, old_vars, res)
		if interp.is_done():
			_finish()
	_refresh_code()
	_refresh_boxes(interp.vars, res.var)
	busy = false
	_update_buttons()


## Утгууд хайрцгаас кодруу нисч, үйлдэл бодогдож, үр дүн хайрцагт орно.
func _animate_assign(row: int, old_vars: Dictionary, res: Dictionary) -> void:
	var toks: Array = row_tokens[row]
	var parts: PackedStringArray = str(program[row]).split(" ")
	var target: String = res.var
	var new_value = interp.vars[target]
	for k in range(2, parts.size()):
		var vn: String = parts[k]
		if old_vars.has(vn) and box_panels.has(vn):
			var lbl: Label = toks[k]
			await _fly(str(old_vars[vn]), _center_of(box_panels[vn]), _center_of(lbl), false, 34)
			lbl.text = str(old_vars[vn])
	if parts.size() > 3:
		await get_tree().create_timer(_t(0.5)).timeout
		for k in range(parts.size() - 1, 2, -1):
			var lbl2: Label = toks[k]
			lbl2.get_parent().remove_child(lbl2)
			lbl2.queue_free()
		(toks[2] as Label).text = str(new_value)
		await get_tree().create_timer(_t(0.4)).timeout
	if not box_panels.has(target):
		var with_target := old_vars.duplicate()
		with_target[target] = null
		_refresh_boxes(with_target)
		await _layout()
	await _fly(str(new_value), _center_of(toks[2]), _center_of(box_panels[target]), true, 34)


func _on_run_all() -> void:
	if not started or finished or busy:
		return
	run_token += 1
	var token := run_token
	while started and not finished and token == run_token:
		await _on_step()
		if not finished:
			await get_tree().create_timer(_t(0.4)).timeout


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
		var guess := int(predict_spin.value)
		if actual != null and guess == actual:
			solved = true
			text = "ЗӨВ.  " + cur.hint
		else:
			text = "БУРУУ.  Та %d гэж таамагласан, гэвч '%s' төгсгөлд %s болсон.\n%s\nДахин эхлэх товчийг дарна уу (тоонууд шинэчлэгдэнэ)." % [guess, cur.ask, str(actual), cur.hint]
	else:
		var actual = interp.vars.get(cur.goal_var, null)
		if actual != null and actual == cur.goal:
			solved = true
			text = "БОДЛОГО ШИЙДЛЭЭ.  " + cur.hint
		else:
			text = "'%s' төгсгөлд %s болсон, харин зорилт %d.  Дахин эхлэх товчийг дарж, мөрүүдийг дахин эрэмбэлээд оролд." % [cur.goal_var, str(actual), cur.goal]
	_show_message(text, 1 if solved else -1)
	if solved:
		_offer_next()


func _move(dir: int) -> void:
	if started or busy or sel_index < 0:
		return
	var j := sel_index + dir
	if j < 0 or j >= program.size():
		return
	var tmp = program[sel_index]
	program[sel_index] = program[j]
	program[j] = tmp
	sel_index = j
	_refresh_code()


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
		c += " %s ticket %s %d" % [join_opt.get_item_text(join_opt.selected), OPS[op2.selected], int(val2.value)]
	return c


func _update_guard_code() -> void:
	if guard_code == null or guard_view == null or cur.is_empty() or cur.mode != "guard":
		return
	guard_code.text = "if %s:\n    let_in()\nelse:\n    turn_away()" % _guard_condition()
	guard_view.sign_text = _guard_condition()


func _make_crowd(t: int, two: bool) -> Array:
	var crowd: Array = []
	crowd.append({"age": t, "ticket": 1})
	crowd.append({"age": t - 1, "ticket": 1})
	crowd.append({"age": t + 1, "ticket": 1})
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
	var two: bool = cur.get("rules", 1) == 2
	var free: bool = cur.get("free", false)
	var t: int = cur.vals.get("T", 18)
	var cond := _guard_condition()
	var e := Expression.new()
	if e.parse(cond, ["age", "ticket"]) != OK:
		_show_message("Дүрэм уншигдсангүй.", -1)
		return
	var judge := func(p: Dictionary) -> Dictionary:
		var res = e.execute([p.age, p.ticket], null, false)
		var allowed: bool = (res == true)
		var expect: bool = p.age >= t and (p.ticket == 1 or not two)
		var shown := cond.replace("ticket", str(p.ticket)).replace("age", str(p.age))
		return {"allowed": allowed, "expect": expect, "text": "%s   ->   %s" % [shown, "true" if allowed else "false"]}
	btn_test.disabled = true
	btn_next.visible = false
	_show_message("Хамгаалагч хүмүүсийг нэг нэгээр нь шалгаж байна...")
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
		msg += "\nКупон: 10% хасна гэдэг нь үнийг 0.9-өөр үржүүлнэ гэсэн үг. Мөн өдрийн хөнгөлөлт ЭХЛЭЭД, купон ДАРАА."
	_show_message(msg, -1)


# ---------------------------------------------------------------- нисдэг утга (анимаци)

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
	fly_layer.add_child(f)
	var half := f.get_combined_minimum_size() / 2.0
	f.pivot_offset = half
	f.global_position = from_center - half
	var tw := create_tween()
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
	tut_name.modulate.a = 0.0
	tut_value.text = ""
	tut_value.modulate.a = 1.0
	tut_caption.text = "Алхам бүрийг харахын тулд «Дараагийн алхам» товчийг дар."
	btn_tut.disabled = false
	btn_next.visible = false


func _set_tokens(tokens: Array) -> void:
	for c in code_row.get_children():
		code_row.remove_child(c)
		c.queue_free()
	for t in tokens:
		code_row.add_child(_code_label(str(t), 56))


func _tok(i: int) -> Label:
	return code_row.get_child(i) as Label


func _on_tut_next() -> void:
	if tut_busy or tut_step >= 3:
		return
	tut_busy = true
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
	if tut_busy:
		return
	_tut_reset()


func _tut_step1() -> void:
	_set_tokens(["int", "a"])
	tut_caption.text = "int a  -  «a» нэртэй хоосон хайрцаг үүснэ."
	await _layout()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(tut_box, "modulate:a", 1.0, _t(0.6))
	tw.tween_property(tut_name, "modulate:a", 1.0, _t(0.6))
	await tw.finished


func _tut_step2() -> void:
	_set_tokens(["a", "=", "2"])
	tut_caption.text = "a = 2  -  2 гэсэн утга хуулагдан хайрцагт хадгалагдана."
	await _layout()
	await _fly("2", _center_of(_tok(2)), _center_of(tut_box), true)
	tut_value.text = "2"


func _tut_step3() -> void:
	_set_tokens(["a", "=", "a", "+", "1"])
	tut_caption.text = "a = a + 1  -  Энд '=' нь «тэнцүү» биш. Энэ нь '<-' буюу «шинэ утга өгөх» гэсэн үг. Эхлээд баруун тал бодогдож, дараа нь үр дүн хайрцагт орно."
	await _layout()
	_tok(1).add_theme_color_override("font_color", YELLOW)
	await get_tree().create_timer(_t(1.5)).timeout
	# 2 хайрцгаас кодын хоёр дахь 'a' руу нисэж, түүнийг сольно.
	# (Хайрцагт бүдэг 2 үлдэнэ: хайрцгийг унших нь утгыг хуулдаг, шинэ утга ирэх хүртэл хэвээр байна.)
	tut_value.modulate.a = 0.3
	await _fly("2", _center_of(tut_box), _center_of(_tok(2)), false)
	_tok(2).text = "2"
	await get_tree().create_timer(_t(1.0)).timeout
	_set_tokens(["a", "=", "3"])
	await _layout()
	_tok(1).add_theme_color_override("font_color", YELLOW)
	await get_tree().create_timer(_t(0.8)).timeout
	await _fly("3", _center_of(_tok(2)), _center_of(tut_box), true)
	tut_value.text = "3"
	tut_value.modulate.a = 1.0
