class_name ChallengePanel
extends VBoxContainer
## Сорилтын түвшин (нэмэлт): автобусны карт уншигчийн эвдэрсэн програмыг засна. Яриагүй: дүрэм нь
## чипээр, тайлбар нь үзэгдэл доторх тэмдэглэлээр харагдана.
## Flowgorithm маягаар: палитраас блок чирч блок схемийн сум дээр тавина (FlowCanvas), эсвэл
## C++ кодыг шууд бичнэ. Хоёулаа нэг програм (model): блок өөрчлөгдвөл код, код өөрчлөгдвөл блок.
## Шалгалт: 8 зорчигч (хилийн утгууд). Зөв үнэ 3 дахь буруу шалгалтаас хойш л харагдана.

signal solved
signal skipped
signal message(text: String, kind: int)

const INPUTS := ["age", "card"]
const OPS := [">", ">=", "<", "<=", "==", "!="]
const JOINS := ["—", "&&", "||"]
const YELLOW := UiTheme.GLOW
const T_COL := UiTheme.TRUE
const F_COL := UiTheme.FALSE
## Үнийн дүрэм: богино чипүүд (бичвэр биш).
const RULES := ["60+ нас → 0₮", "карт && < 18 → 250₮", "бусад → 500₮"]

var mono: Font
var glow_request: Callable   # main.gd-ийн _update_glow
var bus: BusView
var canvas: FlowCanvas
var phase := "build"         # build ⇄ testing → done
var model: Array = []
var cases: Array = []
var fails := 0
var busy := false
var updating_code := false   # кодыг блокоос бичиж байх үед text_changed-ийг үл тооно

var build_area: HBoxContainer
var inspector: HBoxContainer
var code_edit: CodeEdit
var code_error: Label
var parse_timer: Timer
var btn_skip: Button
var btn_test: Button
var info_label: Label
var note_panel: PanelContainer   # тайлбар/алдааны тэмдэглэл (яриа биш)
var note_label: Label
var status_label: Label


## Палитрын блок: чирж аваад блок схемийн сум дээр тавина.
class PaletteItem extends PanelContainer:
	var kind := ""
	var label_text := ""
	var mono: Font

	func _get_drag_data(_at: Vector2) -> Variant:
		var p := Label.new()
		p.text = label_text
		if mono:
			p.add_theme_font_override("font", mono)
		p.modulate = Color(1, 1, 1, 0.85)
		set_drag_preview(p)
		return {"new": kind}


# ---------------------------------------------------------------- UI бүтээх

func setup(mono_font: Font, glow_cb: Callable) -> void:
	mono = mono_font
	glow_request = glow_cb
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 6)
	bus = BusView.new()
	add_child(bus)

	var rules := HBoxContainer.new()
	rules.add_theme_constant_override("separation", 8)
	add_child(rules)
	var rl := Label.new()
	rl.text = "Дүрэм"
	rl.add_theme_font_override("font", UiTheme.font("bold"))
	rl.add_theme_font_size_override("font_size", 15)
	rl.add_theme_color_override("font_color", UiTheme.INK2)
	rules.add_child(rl)
	for r in RULES:
		var chip := PanelContainer.new()
		chip.add_theme_stylebox_override("panel", UiTheme.tag(UiTheme.COND_ACC.lerp(Color.WHITE, 0.8)))
		var cl0 := Label.new()
		cl0.text = r
		cl0.add_theme_font_override("font", UiTheme.font("mono_b"))
		cl0.add_theme_font_size_override("font_size", 14)
		chip.add_child(cl0)
		rules.add_child(chip)
	# Тайлбарын тэмдэглэл (шалгалтын дараа): дүрмийн мөрийн баруун талд, үзэгдлийг таглахгүй.
	note_panel = PanelContainer.new()
	note_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var ns := UiTheme.paper(Color("FFF6D6"), 10, 2, UiTheme.INK, 3, 6)
	ns.border_width_left = 6
	ns.border_color = UiTheme.INK
	note_panel.add_theme_stylebox_override("panel", ns)
	note_label = Label.new()
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.add_theme_font_override("font", UiTheme.font("bold"))
	note_label.add_theme_font_size_override("font_size", 14)
	note_panel.add_child(note_label)
	note_panel.visible = false
	rules.add_child(note_panel)

	build_area = HBoxContainer.new()
	build_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	build_area.add_theme_constant_override("separation", 10)
	add_child(build_area)

	# --- Палитр (зүүн) ---
	var pal_card := PanelContainer.new()
	pal_card.add_theme_stylebox_override("panel", UiTheme.paper(UiTheme.CARD, 14, 2, UiTheme.INK, 6, 10))
	build_area.add_child(pal_card)
	var pal := VBoxContainer.new()
	pal.custom_minimum_size = Vector2(130, 0)
	pal.add_theme_constant_override("separation", 10)
	pal_card.add_child(pal)
	var pl := Label.new()
	pl.text = "Блок"
	pl.tooltip_text = "Чирээд сум дээр тавь"
	pl.mouse_filter = Control.MOUSE_FILTER_PASS
	pl.add_theme_font_override("font", UiTheme.font("bold"))
	pl.add_theme_font_size_override("font_size", 16)
	pl.add_theme_color_override("font_color", UiTheme.INK2)
	pal.add_child(pl)
	var cond_bg := UiTheme.COND_ACC.lerp(Color.WHITE, 0.8)
	for item in [["int x = …", "decl", UiTheme.SAND], ["x = …", "assign", UiTheme.CARD],
			["◇ if", "if", cond_bg], ["◇ if/else", "ifelse", cond_bg]]:
		pal.add_child(_palette_item(item[0], item[1], item[2]))

	# --- Блок схем (дунд) + сонгосон блокийн засвар ---
	var mid := VBoxContainer.new()
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid.size_flags_stretch_ratio = 1.4
	build_area.add_child(mid)
	canvas = FlowCanvas.new()   # өөрөө томруулж/зөөдөг тул ScrollContainer хэрэггүй
	canvas.mono = mono
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.make_block = make_block
	canvas.changed.connect(_on_blocks_changed)
	canvas.selection_changed.connect(func(_b): _refresh_inspector())
	mid.add_child(canvas)
	inspector = HBoxContainer.new()
	inspector.custom_minimum_size = Vector2(0, 40)
	inspector.add_theme_constant_override("separation", 6)
	mid.add_child(inspector)

	# --- C++ код (баруун): шууд бичиж болно ---
	var right_card := PanelContainer.new()
	right_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_card.add_theme_stylebox_override("panel", UiTheme.code_panel(10))
	build_area.add_child(right_card)
	var right := VBoxContainer.new()
	right_card.add_child(right)
	var cl := Label.new()
	cl.text = "C++"
	cl.tooltip_text = "Кодыг шууд бичиж болно"
	cl.mouse_filter = Control.MOUSE_FILTER_PASS
	cl.add_theme_font_override("font", UiTheme.font("mono_b"))
	cl.add_theme_font_size_override("font_size", 14)
	cl.add_theme_color_override("font_color", UiTheme.CODE_DIM)
	right.add_child(cl)
	code_edit = CodeEdit.new()
	code_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	code_edit.gutters_draw_line_numbers = true
	code_edit.add_theme_font_override("font", mono)
	code_edit.add_theme_font_size_override("font_size", 16)
	code_edit.syntax_highlighter = _highlighter()
	code_edit.text_changed.connect(_on_code_typed)
	right.add_child(code_edit)
	code_error = Label.new()
	code_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	code_error.add_theme_font_size_override("font_size", 14)
	code_error.add_theme_color_override("font_color", Color("FF9A93"))
	right.add_child(code_error)
	parse_timer = Timer.new()
	parse_timer.one_shot = true
	parse_timer.wait_time = 0.5
	parse_timer.timeout.connect(_parse_code)
	add_child(parse_timer)

	# --- Доод мөр ---
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 8)
	add_child(bottom)
	info_label = Label.new()
	info_label.add_theme_font_override("font", UiTheme.font("xbold"))
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", UiTheme.TRUE.darkened(0.2))
	bottom.add_child(info_label)
	status_label = Label.new()
	status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label.clip_text = true
	status_label.add_theme_font_override("font", UiTheme.font("bold"))
	status_label.add_theme_font_size_override("font_size", 15)
	bottom.add_child(status_label)
	btn_skip = _button(bottom, "Алгасах »", func(): skipped.emit(), "Нэмэлт түвшин: алгасаж болно")
	btn_test = _button(bottom, "▶  Турших", _on_test, "Enter")


func _palette_item(text: String, kind: String, border: Color) -> PaletteItem:
	var it := PaletteItem.new()
	it.kind = kind
	it.label_text = text
	it.mono = mono
	it.mouse_default_cursor_shape = Control.CURSOR_DRAG
	it.tooltip_text = "Чирээд блок схемийн сум дээр тавь"
	var st := UiTheme.paper(border, 10, 2, UiTheme.INK, 4, 8)
	it.add_theme_stylebox_override("panel", st)
	if kind == "decl":
		# Хувьсагчийн блок: [нэр] / [утга] / [int] — түвшин 1-5-ын хайрцаг шиг.
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for part in [["x", UiTheme.CARD, UiTheme.INK, 14], ["= …", UiTheme.BOX, UiTheme.INK, 16], ["int", UiTheme.INT_TAG, UiTheme.INK, 12]]:
			var pc := PanelContainer.new()
			pc.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var ps := UiTheme.paper(part[1], 8 if part[0] == "int" else 4, 2, UiTheme.INK, 0)
			ps.content_margin_left = 26 if part[0] == "= …" else 10
			ps.content_margin_right = ps.content_margin_left
			pc.add_theme_stylebox_override("panel", ps)
			var pl2 := Label.new()
			pl2.text = part[0]
			pl2.add_theme_font_override("font", mono)
			pl2.add_theme_font_size_override("font_size", part[3])
			pl2.add_theme_color_override("font_color", part[2])
			pc.add_child(pl2)
			v.add_child(pc)
		it.add_child(v)
		return it
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", mono)
	l.add_theme_font_size_override("font_size", 15)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	it.add_child(l)
	return it


func _highlighter() -> CodeHighlighter:
	var h := CodeHighlighter.new()
	h.add_keyword_color("int", UiTheme.INT_TAG)
	for kw in ["if", "else"]:
		h.add_keyword_color(kw, UiTheme.CODE_KW)
	h.number_color = UiTheme.CODE_NUM
	h.symbol_color = UiTheme.CODE_SYM
	h.function_color = UiTheme.CODE_TXT
	h.member_variable_color = UiTheme.CODE_TXT
	h.add_color_region("//", "", UiTheme.CODE_DIM, true)
	return h


func _button(parent: Control, text: String, handler: Callable, hint: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 40)
	b.focus_mode = Control.FOCUS_NONE
	b.tooltip_text = hint
	b.pressed.connect(handler)
	parent.add_child(b)
	return b


# ---------------------------------------------------------------- урсгал

func start() -> void:
	phase = "build"
	fails = 0
	busy = false
	model = broken_program()
	canvas.model = model
	canvas.selected = null
	canvas._need_center = true
	bus.set_compact(false)
	cases = make_cases()
	bus.riders.clear()
	_note("")
	info_label.text = ""
	_status("", 0)
	code_error.text = ""
	_accept()   # яриагүй: эвдэрсэн програм шууд засварт нээгдэнэ


func _update_bottom() -> void:
	btn_skip.visible = phase == "build"
	btn_test.visible = phase == "build" or phase == "testing"
	btn_test.disabled = busy
	canvas.editable = phase == "build"
	code_edit.editable = phase == "build"
	if glow_request.is_valid():
		glow_request.call()


func glow_target() -> Control:
	match phase:
		"build": return btn_test
	return null


## → / D: яриа байхгүй болсон тул юу ч хийхгүй (main.gd дуудсаар байна).
func key_next() -> void:
	pass


func key_enter() -> void:
	if phase == "build":
		_on_test()


func _accept() -> void:
	phase = "build"
	build_area.visible = true
	_note("")
	bus.set_compact(true)   # програмын талбай томорно
	bus.set_queue(cases)
	canvas._need_center = true
	_rebuild()
	_update_bottom()


## Тайлбарын тэмдэглэл: хоосон бол нуугдана.
func _note(text: String) -> void:
	note_label.text = text
	note_panel.visible = text != ""


func _status(text: String, kind: int) -> void:
	status_label.text = text
	status_label.add_theme_color_override("font_color", [UiTheme.INK, T_COL.darkened(0.2), F_COL.darkened(0.1)][kind if kind >= 0 else 2])
	message.emit(text, kind)


# ---------------------------------------------------------------- бодлого, шалгах өгөгдөл

## Эвдэрсэн програм (3 алдаа): > нь >= байх ёстой; || нь && байх ёстой; 250 өгөх мөр дутуу.
static func broken_program() -> Array:
	return [
		{"t": "decl", "var": "price", "expr": "500"},
		{"t": "if", "cond": {"a": "age", "op": ">", "b": "60", "join": "—", "a2": "card", "op2": "==", "b2": "1"},
			"then": [{"t": "assign", "var": "price", "expr": "0"}], "else": null},
		{"t": "if", "cond": {"a": "card", "op": "==", "b": "1", "join": "||", "a2": "age", "op2": "<", "b2": "18"},
			"then": [], "else": null},
	]


static func expected(age: int, card: int) -> int:
	if age >= 60:
		return 0
	if card == 1 and age < 18:
		return 250
	return 500


## 7 тогтмол (хилийн) + 1 санамсаргүй насанд хүрэгч.
static func make_cases() -> Array:
	var list := [
		{"age": 17, "card": 1}, {"age": 18, "card": 1}, {"age": 59, "card": 0}, {"age": 60, "card": 1},
		{"age": 60, "card": 0}, {"age": 10, "card": 0}, {"age": 30, "card": 1},
	]
	list.append({"age": randi_range(19, 58), "card": randi_range(0, 1)})
	return list


## Палитрын шинэ блок.
func make_block(kind: String) -> Dictionary:
	match kind:
		"assign": return {"t": "assign", "var": "price", "expr": "0"}
		"decl": return {"t": "decl", "var": "x", "expr": "0"}
	return {"t": "if", "cond": {"a": "age", "op": ">=", "b": "0", "join": "—", "a2": "card", "op2": "==", "b2": "1"},
		"then": [], "else": [] if kind == "ifelse" else null}


# ---------------------------------------------------------------- програм ажиллуулах (C++ дүрмээр)

func run(age: int, card: int) -> Dictionary:
	var vars := {"age": age, "card": card}
	var err := _exec(model, vars)
	if err != "":
		return {"ok": false, "error": err}
	if not vars.has("price"):
		return {"ok": false, "error": "'price' хувьсагч алга. int price = ...; хэрэгтэй."}
	return {"ok": true, "price": vars.price}


func _exec(list: Array, vars: Dictionary) -> String:
	for b in list:
		match b.t:
			"decl":
				var vname := str(b.var).strip_edges()
				if not vname.is_valid_identifier():
					return "'%s' хувьсагчийн нэр биш." % vname
				if vars.has(vname):
					return "'%s' аль хэдийн зарлагдсан. Хоёр удаа int бичиж болохгүй." % vname
				var r := _eval(str(b.expr), vars)
				if r.has("error"):
					return r.error
				if typeof(r.value) != TYPE_INT:
					return "'%s' хайрцаг зөвхөн бүхэл тоо (int) хадгална." % vname
				vars[vname] = r.value
			"assign":
				if not vars.has(b.var):
					return "'%s' зарлагдаагүй. Эхлээд int %s = ...; гэж зарла." % [b.var, b.var]
				var r := _eval(str(b.expr), vars)
				if r.has("error"):
					return r.error
				if typeof(r.value) != TYPE_INT:
					return "'%s' хайрцаг зөвхөн бүхэл тоо (int) хадгална." % b.var
				vars[b.var] = r.value
			"if":
				var r := _eval(cond_text(b.cond), vars)
				if r.has("error"):
					return r.error
				var truth: bool = r.value if typeof(r.value) == TYPE_BOOL else int(r.value) != 0
				var branch = b.then if truth else b.get("else")
				if branch != null:
					var e := _exec(branch, vars)
					if e != "":
						return e
	return ""


func _eval(text: String, vars: Dictionary) -> Dictionary:
	if text.strip_edges() == "":
		return {"error": "Хоосон талбар байна. Утга бич."}
	var ident := RegEx.create_from_string("[A-Za-z_][A-Za-z0-9_]*")
	for m in ident.search_all(text):
		var w := m.get_string()
		if w in ["true", "false"]:
			continue
		if not vars.has(w):
			return {"error": "'%s' хувьсагч зарлагдаагүй." % w}
	var e := Expression.new()
	if e.parse(text, PackedStringArray(vars.keys())) != OK:
		return {"error": "Уншиж чадсангүй: %s" % text}
	var v = e.execute(vars.values(), null, false)
	if e.has_execute_failed():
		return {"error": "Бодож чадсангүй: %s (тэг рүү хуваасан уу?)" % text}
	return {"value": v}


static func cond_text(c: Dictionary) -> String:
	var s := "%s %s %s" % [c.a, c.op, str(c.b).strip_edges()]
	if c.join != "—":
		s += " %s %s %s %s" % [c.join, c.a2, c.op2, str(c.b2).strip_edges()]
	return s


func check() -> Array:
	var results := []
	for c in cases:
		var r := run(c.age, c.card)
		var exp := expected(c.age, c.card)
		results.append({"age": c.age, "card": c.card, "exp": exp,
			"got": r.get("price", -1), "error": r.get("error", ""),
			"ok": r.ok and r.price == exp})
	return results


# ---------------------------------------------------------------- блок → C++

func to_cpp() -> String:
	var out: Array = ["// оролт: int age, card;"]
	_cpp_list(model, 0, out)
	return "\n".join(PackedStringArray(out))


func _cpp_list(list: Array, depth: int, out: Array) -> void:
	var pad := "    ".repeat(depth)
	if list.is_empty() and depth > 0:
		out.append(pad + "// ???")
	for b in list:
		match b.t:
			"decl":
				out.append(pad + "int %s = %s;" % [b.var, b.expr])
			"assign":
				out.append(pad + "%s = %s;" % [b.var, b.expr])
			"if":
				out.append(pad + "if (%s) {" % cond_text(b.cond))
				_cpp_list(b.then, depth + 1, out)
				if b.get("else") != null:
					out.append(pad + "} else {")
					_cpp_list(b.else, depth + 1, out)
				out.append(pad + "}")


## Блок өөрчлөгдсөн → код дахин бичигдэнэ (тоглогч кодыг бичиж байгаа үед биш).
func _code_from_blocks() -> void:
	updating_code = true
	code_edit.text = to_cpp()
	updating_code = false
	code_error.text = ""


func _rebuild() -> void:
	canvas.model = model
	canvas.relayout()
	_refresh_inspector()
	_code_from_blocks()


func _on_blocks_changed() -> void:
	_refresh_inspector()
	_code_from_blocks()


# ---------------------------------------------------------------- C++ → блок (задлагч)

func _on_code_typed() -> void:
	if updating_code:
		return
	parse_timer.start()   # бичиж дуусахыг хагас секунд хүлээгээд задална


func _parse_code() -> void:
	var res := parse_cpp(code_edit.text)
	if not res.ok:
		code_error.text = "✗ " + res.error + "   (блокууд сүүлийн зөв хувилбараараа үлдлээ)"
		return
	code_error.text = ""
	model.clear()
	model.append_array(res.model)
	canvas.selected = null
	canvas.relayout()
	_refresh_inspector()


## Энэ сорилтын C++ дэд хэсгийг задална:
##   int x = expr;   x = expr;   if (a op b [&&|| a2 op2 b2]) { ... } [else { ... } | else if ...]
## Буцаах: {ok, model} эсвэл {ok: false, error}.
static func parse_cpp(text: String) -> Dictionary:
	var toks := _tokenize(text)
	if toks.size() > 0 and toks[0].t == "err":
		return {"ok": false, "error": toks[0].v}
	var st := {"toks": toks, "i": 0}
	var list := []
	while st.i < toks.size():
		var r := _parse_stmt(st)
		if not r.ok:
			return r
		list.append(r.block)
	return {"ok": true, "model": list}


static func _tokenize(text: String) -> Array:
	var toks := []
	var i := 0
	var line := 1
	var two := ["==", "!=", ">=", "<=", "&&", "||"]
	while i < text.length():
		var ch := text[i]
		if ch == "\n":
			line += 1
			i += 1
		elif ch == " " or ch == "\t" or ch == "\r":
			i += 1
		elif text.substr(i, 2) == "//":
			while i < text.length() and text[i] != "\n":
				i += 1
		elif ch.is_valid_identifier() or ch == "_":
			var j := i
			while j < text.length() and (text[j].is_valid_identifier() or text[j] == "_" or text[j].is_valid_int()):
				j += 1
			toks.append({"t": "id", "v": text.substr(i, j - i), "line": line})
			i = j
		elif ch.is_valid_int():
			var j := i
			while j < text.length() and text[j].is_valid_int():
				j += 1
			toks.append({"t": "num", "v": text.substr(i, j - i), "line": line})
			i = j
		elif text.substr(i, 2) in two:
			toks.append({"t": "op", "v": text.substr(i, 2), "line": line})
			i += 2
		elif ch in ["=", "<", ">", "+", "-", "*", "/", "%", "(", ")", "{", "}", ";", "!"]:
			toks.append({"t": "op", "v": ch, "line": line})
			i += 1
		else:
			return [{"t": "err", "v": "%d-р мөр: '%s' тэмдэгт танигдсангүй." % [line, ch]}]
	return toks


static func _peek(st: Dictionary, k := 0) -> Dictionary:
	var i: int = st.i + k
	return st.toks[i] if i < st.toks.size() else {"t": "eof", "v": "", "line": -1}


static func _line_of(st: Dictionary) -> int:
	var t := _peek(st)
	if t.line == -1 and st.toks.size() > 0:
		return st.toks[st.toks.size() - 1].line
	return t.line


static func _err(st: Dictionary, msg: String) -> Dictionary:
	return {"ok": false, "error": "%d-р мөр: %s" % [_line_of(st), msg]}


static func _expect(st: Dictionary, v: String) -> bool:
	if _peek(st).v == v:
		st.i += 1
		return true
	return false


## «;» хүртэлх илэрхийлэл (мөр болгож нэгтгэнэ; утгыг ажиллуулах үед шалгана).
static func _parse_expr(st: Dictionary) -> Dictionary:
	var parts := []
	var last_line := -1
	while _peek(st).t != "eof" and _peek(st).v != ";":
		var t := _peek(st)
		if t.v in ["{", "}"]:
			return _err(st, "';' дутуу байна.")
		# Дараагийн мөрөнд шинэ мөр (int/if/else эсвэл «нэр =») эхэлсэн бол өмнөх мөрийн ';' дутуу.
		var new_stmt: bool = t.v in ["int", "if", "else"] or (t.t == "id" and _peek(st, 1).v == "=")
		if not parts.is_empty() and t.line > last_line and new_stmt:
			return {"ok": false, "error": "%d-р мөр: ';' дутуу байна." % last_line}
		parts.append(t.v)
		last_line = t.line
		st.i += 1
	if not _expect(st, ";"):
		return _err(st, "';' дутуу байна.")
	if parts.is_empty():
		return _err(st, "'=' -ийн ард утга алга.")
	return {"ok": true, "expr": " ".join(PackedStringArray(parts))}


static func _parse_stmt(st: Dictionary) -> Dictionary:
	var t := _peek(st)
	if t.v == "int":
		st.i += 1
		var vt := _peek(st)
		if vt.t != "id":
			return _err(st, "'int'-ийн ард хувьсагчийн нэр бичнэ.")
		st.i += 1
		if not _expect(st, "="):
			return _err(st, "'int %s' -ийн ард '= утга;' хэрэгтэй (жишээ: int %s = 0;)." % [vt.v, vt.v])
		var e := _parse_expr(st)
		if not e.ok:
			return e
		return {"ok": true, "block": {"t": "decl", "var": vt.v, "expr": e.expr}}
	if t.v == "if":
		st.i += 1
		if not _expect(st, "("):
			return _err(st, "'if'-ийн ард нөхцөл хаалтанд: if (...)")
		var c := _parse_cond(st)
		if not c.ok:
			return c
		if not _expect(st, ")"):
			return _err(st, "Нөхцлийн ард ')' хэрэгтэй.")
		var th := _parse_block(st)
		if not th.ok:
			return th
		var el = null
		if _peek(st).v == "else":
			st.i += 1
			var eb := _parse_block(st)   # «else if» нь else дотор нэг if байна
			if not eb.ok:
				return eb
			el = eb.list
		return {"ok": true, "block": {"t": "if", "cond": c.cond, "then": th.list, "else": el}}
	if t.t == "id":
		st.i += 1
		if not _expect(st, "="):
			return _err(st, "'%s' -ийн ард '=' хэрэгтэй." % t.v)
		var e2 := _parse_expr(st)
		if not e2.ok:
			return e2
		return {"ok": true, "block": {"t": "assign", "var": t.v, "expr": e2.expr}}
	if t.v == "}":
		return _err(st, "Илүү '}' байна.")
	return _err(st, "'%s' -ээр мөр эхэлж болохгүй." % t.v)


## { ... } эсвэл ганц мөр.
static func _parse_block(st: Dictionary) -> Dictionary:
	var list := []
	if _expect(st, "{"):
		while _peek(st).v != "}":
			if _peek(st).t == "eof":
				return _err(st, "'{' хаагдаагүй: '}' дутуу.")
			var r := _parse_stmt(st)
			if not r.ok:
				return r
			list.append(r.block)
		st.i += 1
	else:
		var r2 := _parse_stmt(st)
		if not r2.ok:
			return r2
		list.append(r2.block)
	return {"ok": true, "list": list}


## Нөхцөл: «a op b» эсвэл «a op b && a2 op2 b2» (|| ч мөн).
static func _parse_cond(st: Dictionary) -> Dictionary:
	var c := {"join": "—", "a2": "card", "op2": "==", "b2": "1"}
	var p1 := _parse_cmp(st)
	if not p1.ok:
		return p1
	c.a = p1.a
	c.op = p1.op
	c.b = p1.b
	if _peek(st).v in ["&&", "||"]:
		c.join = _peek(st).v
		st.i += 1
		var p2 := _parse_cmp(st)
		if not p2.ok:
			return p2
		c.a2 = p2.a
		c.op2 = p2.op
		c.b2 = p2.b
	if _peek(st).v in ["&&", "||"]:
		return _err(st, "Энэ сорилтод нөхцөл дээд тал нь 2 хэсэгтэй.")
	return {"ok": true, "cond": c}


static func _parse_cmp(st: Dictionary) -> Dictionary:
	var a := _peek(st)
	if a.t != "id" and a.t != "num":
		return _err(st, "Нөхцөл «хувьсагч оператор утга» хэлбэртэй (жишээ: age >= 60).")
	st.i += 1
	var op := _peek(st)
	if not (op.v in OPS):
		if op.v == "=":
			return _err(st, "Харьцуулахад '==' хэрэглэнэ ('=' нь хадгалах).")
		return _err(st, "Харьцуулах оператор (>, >=, <, <=, ==, !=) хэрэгтэй.")
	st.i += 1
	var b := _peek(st)
	if b.t != "id" and b.t != "num":
		return _err(st, "Операторын ард утга хэрэгтэй.")
	st.i += 1
	return {"ok": true, "a": a.v, "op": op.v, "b": b.v}


# ---------------------------------------------------------------- сонгосон блокийн засвар (inspector)

func _var_names() -> Array:
	var names: Array = INPUTS.duplicate()
	_collect_decls(model, names)
	return names


func _collect_decls(list: Array, names: Array) -> void:
	for b in list:
		if b.t == "decl" and not names.has(str(b.var)):
			names.append(str(b.var))
		elif b.t == "if":
			_collect_decls(b.then, names)
			if b.get("else") != null:
				_collect_decls(b.else, names)


func _refresh_inspector() -> void:
	for c in inspector.get_children():
		inspector.remove_child(c)
		c.queue_free()
	var b = canvas.selected
	if b == null or phase != "build":
		var hint := Label.new()
		hint.text = "Блок дээр дар" if phase == "build" else ""
		hint.add_theme_font_size_override("font_size", 14)
		hint.add_theme_color_override("font_color", UiTheme.INK2)
		inspector.add_child(hint)
		return
	var h := inspector
	match b.t:
		"decl":
			h.add_child(_mono_label("int", UiTheme.BOX_DARK.darkened(0.3)))
			h.add_child(_edit(str(b.var), 90, func(t: String): b.var = t))
			h.add_child(_mono_label("="))
			h.add_child(_edit(str(b.expr), 140, func(t: String): b.expr = t))
		"assign":
			h.add_child(_opt(_var_names(), str(b.var), func(t: String): b.var = t))
			h.add_child(_mono_label("="))
			h.add_child(_edit(str(b.expr), 140, func(t: String): b.expr = t))
		"if":
			var c: Dictionary = b.cond
			h.add_child(_mono_label("if ("))
			h.add_child(_opt(_var_names(), str(c.a), func(t: String): c.a = t))
			h.add_child(_opt(OPS, str(c.op), func(t: String): c.op = t))
			h.add_child(_edit(str(c.b), 56, func(t: String): c.b = t))
			h.add_child(_opt(JOINS, str(c.join), func(t: String):
				c.join = t
				_refresh_inspector()))
			if c.join != "—":
				h.add_child(_opt(_var_names(), str(c.a2), func(t: String): c.a2 = t))
				h.add_child(_opt(OPS, str(c.op2), func(t: String): c.op2 = t))
				h.add_child(_edit(str(c.b2), 56, func(t: String): c.b2 = t))
			h.add_child(_mono_label(")"))
			var tog := Button.new()
			tog.focus_mode = Control.FOCUS_NONE
			tog.text = "else хасах" if b.get("else") != null else "else нэмэх"
			tog.pressed.connect(func():
				b["else"] = null if b.get("else") != null else []
				_after_edit(true))
			h.add_child(tog)
	var del := Button.new()
	del.text = "✕ устгах"
	del.focus_mode = Control.FOCUS_NONE
	del.add_theme_color_override("font_color", F_COL)
	del.pressed.connect(func():
		_remove_block(model, b)
		canvas.selected = null
		_after_edit(true))
	h.add_child(del)


func _remove_block(list: Array, target: Dictionary) -> bool:
	for k in list.size():
		if is_same(list[k], target):
			list.remove_at(k)
			return true
		if list[k].t == "if":
			if _remove_block(list[k].then, target):
				return true
			if list[k].get("else") != null and _remove_block(list[k].else, target):
				return true
	return false


## Талбар/бүтэц өөрчлөгдсөний дараа: схем, код (бүтэц бол inspector ч) шинэчлэгдэнэ.
func _after_edit(structural: bool) -> void:
	canvas.relayout()
	_code_from_blocks()
	if structural:
		_refresh_inspector()


func _mono_label(text: String, col := UiTheme.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", mono)
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", col)
	return l


func _edit(text: String, width: float, on_change: Callable) -> LineEdit:
	var e := LineEdit.new()
	e.text = text
	e.custom_minimum_size = Vector2(width, 0)
	e.add_theme_font_override("font", mono)
	e.add_theme_font_size_override("font_size", 16)
	e.text_changed.connect(func(t: String):
		on_change.call(t)
		_after_edit(false))
	return e


func _opt(items: Array, current: String, on_change: Callable) -> OptionButton:
	var o := OptionButton.new()
	o.add_theme_font_override("font", mono)
	o.add_theme_font_size_override("font_size", 16)
	var found := -1
	for k in items.size():
		o.add_item(str(items[k]))
		if str(items[k]) == current:
			found = k
	if found == -1:
		o.add_item(current)
		found = items.size()
	o.select(found)
	o.item_selected.connect(func(idx: int):
		on_change.call(o.get_item_text(idx))
		_after_edit(false))
	return o


# ---------------------------------------------------------------- турших

func _on_test() -> void:
	if phase != "build" or busy:
		return
	if not parse_timer.is_stopped():
		parse_timer.stop()
		_parse_code()   # бичиж байсан кодыг эхлээд блок болгоно
	if code_error.text != "":
		_status("✗ Код алдаатай байна. Эхлээд засаарай.", -1)
		return
	busy = true
	phase = "testing"
	bus.speed = 1.0   # шинэ туршилт: өмнөх алгасалт (F) цуцлагдана
	_update_bottom()
	var results := check()
	for r in results:
		if r.error != "":
			_note("✗  " + r.error)
			_status("✗  " + r.error, -1)
			busy = false
			phase = "build"
			_update_bottom()
			return
	var shown: Array = []
	for r in results:
		shown.append({"price": "%d₮" % r.got, "ok": r.ok})
	_note("")
	_status("", 0)
	await bus.run_test(cases, shown)
	var good := results.filter(func(r): return r.ok).size()
	info_label.text = "✓ %d / %d" % [good, results.size()]
	if good == results.size():
		phase = "done"
		busy = false
		_note("")
		_status("ЗӨВ ✓  Сорилт давлаа ★", 1)
		_update_bottom()
		solved.emit()
		return
	fails += 1
	var wrong: Array = results.filter(func(r): return not r.ok)
	_note(_hint(wrong[0]))
	# Буруу зорчигчид: эхний 2 удаа зөвхөн таны үнэ; 3 дахь удаагаас зөв үнэ ч харагдана.
	var lines: Array = []
	for w in wrong.slice(0, 3):
		var s := "age=%d, card=%d: таны %d₮" % [w.age, w.card, w.got]
		if fails >= 3:
			s += " (зөв %d₮)" % w.exp
		lines.append(s)
	if wrong.size() > 3:
		lines.append("+%d" % (wrong.size() - 3))
	_status("✗  " + "   ".join(PackedStringArray(lines)), -1)
	busy = false
	phase = "build"
	_update_bottom()


## Тайлбарын тэмдэглэл: шинж тэмдгийг хэлнэ, хариуг шууд хэлэхгүй.
func _hint(w: Dictionary) -> String:
	var age: int = w.age
	var card: int = w.card
	var got: int = w.got
	if age >= 60:
		var h := "%d настай өвөө %d₮ төллөө. Тэр үнэгүй явах ёстой шүү дээ…" % [age, got]
		if age == 60:
			h += "  60 нь «60 ба түүнээс дээш»-д орно."
		return h
	if card == 1 and age < 18:
		return "%d настай карттай сурагч %d₮ төллөө. Хөнгөлөлт нь хаана байна?" % [age, got]
	if card == 1:
		var h2 := "%d настай карттай хүн %d₮ төллөө. Карт байгаа ч 18 хүрсэн шүү." % [age, got]
		if age == 18:
			h2 += "  18 нь «18 хүрээгүй»-д орохгүй."
		return h2 + "  && уу, || уу?"
	return "%d настай, картгүй зорчигч %d₮ төллөө. Тэр бүтэн үнэ төлөх ёстой…" % [age, got]
