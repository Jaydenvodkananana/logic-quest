class_name UiTheme
extends RefCounted
## Logic Quest-ийн нэгдсэн дүр төрх («цаасан диорама»): өнгө, үсгийн фонт, Godot Theme,
## болон _draw()-д ашиглах цаасан зургийн туслах функцууд (хүрээ + зөөлөн сүүдэр).
## Бүх скрипт өнгийг энд нэрээр нь авна (UiTheme.INK гэх мэт) — тараагдсан өнгийн код бичихгүй.

# ---------------------------------------------------------------- өнгө
const CREAM := Color("FFF8EC")        # дэлгэцийн суурь
const CARD := Color("FFFFFF")         # цаасан карт
const CARD_DIM := Color("FBF6EC")
const SAND := Color("F3EAD8")         # бага ач холбогдолтой дэвсгэр (chip, terminal)
const LINE := Color("E6DCC8")         # зөөлөн зураас
const INK := Color("2B2D42")          # бүх хүрээ, гол бичиг
const INK2 := Color("6B6E80")         # туслах бичиг
const MUTED := Color("B3AC9E")        # идэвхгүй бичиг
const MUTED_LINE := Color("D6CCB8")
const SHADOW := Color(0.17, 0.18, 0.26, 0.18)
const CODE_BG := Color("22253A")      # код засварлагч (харанхуй «дэлгэц»)
const CODE_BAR := Color("2C3048")
const CODE_HL := Color("30344F")      # одоогийн мөр
const CODE_TXT := Color("E8ECF4")
const CODE_DIM := Color("7D839C")
const CODE_KW := Color("5FD4C4")      # if, else
const CODE_NUM := Color("F7A072")
const CODE_SYM := Color("A9B1D6")
const GLOW := Color("FFC93C")         # «дараа нь үүнийг хий» гэрэл
const INT_TAG := Color("FFD23F")      # int наалт (CLAUDE.md: шар int шошго)
const TRUE := Color("3BB273")
const FALSE := Color("E5534B")
const TRUE_BG := Color("E7F5EC")
const FALSE_BG := Color("FDECEA")
const HILITE := Color("D9480F")       # хайрцагт дөнгөж өөрчлөгдсөн утга
const VAR_ACC := Color("F4B740")      # 1-р бүлэг: Хувьсагч
const COND_ACC := Color("2BB3A3")     # 2-р бүлэг: Нөхцөл
const LOOP_ACC := Color("F26B5B")     # 3-р бүлэг: Давталт (удахгүй)
const BUS := Color("F7C548")
const BUS_DARK := Color("E0A92E")
const GLASS := Color("CDEBF5")
const BOX := Color("E7C08A")          # картон хайрцаг (хувьсагч)
const BOX_DARK := Color("C99A5B")
const CARD_BLUE := Color("4C8DFF")    # зорчигчийн карт
const SHIRTS := [Color("8E7CC3"), Color("E5534B"), Color("4FA3D9"), Color("6CBF6A"), Color("F28FB1"), Color("E8A33D")]
const SKINS := [Color("F1C9A5"), Color("D9A27C"), Color("B07A55"), Color("F6D8BE")]

## Бүлгүүд: levels.gd-ийн "chapter" түлхүүр → нэр, өнгө, тэмдэг.
const CHAPTERS := {
	"var": {"name": "Хувьсагч", "acc": VAR_ACC, "icon": "▣"},
	"cond": {"name": "Нөхцөл", "acc": COND_ACC, "icon": "◇"},
	"loop": {"name": "Давталт", "acc": LOOP_ACC, "icon": "↻"},
}

## Өнгөт дэвсгэр дээрх бичгийн өнгө: цайвар (шар) дээр бараан, бусад дээр цагаан.
static func on_color(bg: Color) -> Color:
	return INK if bg.get_luminance() > 0.55 else Color.WHITE


# ---------------------------------------------------------------- фонт

static var _fonts := {}


## kind: "ui", "bold", "xbold", "mono", "mono_b"
static func font(kind: String = "ui") -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var mono := kind.begins_with("mono")
	var base: FontFile = load("res://assets/fonts/JetBrainsMono.ttf" if mono else "res://assets/fonts/Nunito.ttf")
	var weight: int = {"ui": 600, "bold": 750, "xbold": 900, "mono": 500, "mono_b": 700}.get(kind, 600)
	var v := FontVariation.new()
	v.base_font = base
	var ts := TextServerManager.get_primary_interface()
	v.variation_opentype = {ts.name_to_tag("wght"): weight}
	if mono:
		# «==» нэг урт тэмдэг болж нийлэхгүй (эхлэгчдэд ойлгомжгүй).
		v.opentype_features = {ts.name_to_tag("calt"): 0, ts.name_to_tag("liga"): 0}
	# ✓ ✗ ◇ ★ гэх мэт тэмдэг энэ фонтуудад байхгүй: системийн тэмдгийн фонт нөхнө.
	var sym := SystemFont.new()
	sym.font_names = PackedStringArray(["Segoe UI Symbol", "Segoe UI", "Noto Sans Symbols 2", "DejaVu Sans"])
	v.fallbacks = [sym]
	_fonts[kind] = v
	return v


# ---------------------------------------------------------------- StyleBox

## Цаасан карт: дугуй булан, бараан хүрээ, доошоо зөөлөн сүүдэр.
static func paper(bg: Color = CARD, radius: float = 14.0, border: float = 2.0, border_col: Color = INK,
		shadow: float = 6.0, margin: float = -1.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_corner_radius_all(int(radius))
	s.set_border_width_all(int(border))
	s.border_color = border_col
	if shadow > 0.0:
		s.shadow_color = SHADOW
		s.shadow_size = int(shadow)
		s.shadow_offset = Vector2(0, maxf(2.0, shadow * 0.6))
	if margin >= 0.0:
		s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s


static func code_panel(margin: float = 12.0) -> StyleBoxFlat:
	return paper(CODE_BG, 14, 2, INK, 6, margin)


## Хайрцгийн шошго (нэр / int).
static func tag(bg: Color, border_col: Color = INK, radius: float = 8.0) -> StyleBoxFlat:
	var s := paper(bg, radius, 2, border_col, 2)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 1
	s.content_margin_bottom = 1
	return s


## Хувьсагчийн картон хайрцаг.
static func box_style() -> StyleBoxFlat:
	var s := paper(BOX, 10, 3, INK, 6)
	s.content_margin_top = 14   # дээд хавхаг (CardboardBox зурна)
	return s


static func chip(bg: Color, radius: float = 16.0) -> StyleBoxFlat:
	var s := paper(bg, radius, 0, INK, 0)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


# ---------------------------------------------------------------- Theme

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font("ui")
	t.default_font_size = 18
	t.set_color("font_color", "Label", INK)

	# Товч: цаасан таб, дарахад 2px доошилно.
	var normal := paper(CARD, 12, 2, INK, 4)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	normal.content_margin_top = 5
	normal.content_margin_bottom = 5
	var hover := normal.duplicate()
	hover.bg_color = Color("FFFDF6")
	hover.border_color = Color("15161F")
	var pressed := normal.duplicate()
	pressed.bg_color = SAND
	pressed.shadow_size = 0
	pressed.content_margin_top = 7
	pressed.content_margin_bottom = 3
	var disabled := normal.duplicate()
	disabled.bg_color = Color("F1EADB")
	disabled.border_color = MUTED_LINE
	disabled.shadow_size = 0
	for type in ["Button", "OptionButton"]:
		t.set_stylebox("normal", type, normal)
		t.set_stylebox("hover", type, hover)
		t.set_stylebox("pressed", type, pressed)
		t.set_stylebox("hover_pressed", type, pressed)
		t.set_stylebox("disabled", type, disabled)
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_font("font", type, font("bold"))
		for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			t.set_color(c, type, INK)
		t.set_color("font_disabled_color", type, MUTED)
		t.set_color("icon_normal_color", type, INK)
	t.set_constant("modulate_arrow", "OptionButton", 1)

	# Бичих нүд
	var le := paper(CARD, 8, 2, INK, 0)
	le.content_margin_left = 8
	le.content_margin_right = 8
	var le_focus := le.duplicate()
	le_focus.border_color = Color("C99A00")
	le_focus.set_border_width_all(3)
	var le_ro := le.duplicate()
	le_ro.bg_color = Color("F6F0E4")
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", le_focus)
	t.set_stylebox("read_only", "LineEdit", le_ro)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_uneditable_color", "LineEdit", INK2)
	t.set_color("caret_color", "LineEdit", INK)
	t.set_color("selection_color", "LineEdit", Color(GLOW, 0.5))
	t.set_color("font_selected_color", "LineEdit", INK)

	# Унжих цэс, tooltip
	var pm := paper(CARD, 10, 2, INK, 6, 6)
	t.set_stylebox("panel", "PopupMenu", pm)
	var pm_hover := paper(Color(GLOW, 0.45), 6, 0, INK, 0)
	t.set_stylebox("hover", "PopupMenu", pm_hover)
	t.set_color("font_color", "PopupMenu", INK)
	t.set_color("font_hover_color", "PopupMenu", INK)
	t.set_font("font", "PopupMenu", font("mono_b"))
	var tip := paper(INK, 8, 0, INK, 4, 8)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", CREAM)
	t.set_font_size("font_size", "TooltipLabel", 15)

	# Код засварлагч: харанхуй дэлгэц
	var ce := paper(CODE_BG, 0, 0, INK, 0, 10)
	for type in ["CodeEdit", "TextEdit"]:
		t.set_stylebox("normal", type, ce)
		t.set_stylebox("focus", type, StyleBoxEmpty.new())
		t.set_stylebox("read_only", type, ce)
		t.set_color("font_color", type, CODE_TXT)
		t.set_color("font_readonly_color", type, CODE_TXT)
		t.set_color("caret_color", type, GLOW)
		t.set_color("current_line_color", type, CODE_HL)
		t.set_color("selection_color", type, Color(GLOW, 0.3))
		t.set_color("background_color", type, CODE_BG)
		t.set_font("font", type, font("mono"))
	t.set_color("line_number_color", "CodeEdit", CODE_DIM)

	# Суурь контейнерууд саарал хайрцаг зурахгүй.
	t.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	t.set_stylebox("panel", "Panel", StyleBoxEmpty.new())
	return t


# ---------------------------------------------------------------- _draw() туслахууд (цаасан зураг)

static func box(ci: CanvasItem, r: Rect2, bg: Color, radius: float = 10.0, border: float = 2.0,
		shadow: float = 4.0, border_col: Color = INK) -> void:
	ci.draw_style_box(paper(bg, radius, border, border_col, shadow), r)


## Хүрээтэй, сүүдэртэй олон өнцөгт.
static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, outline: bool = true,
		shadow: bool = true, width: float = 2.0, a: float = 1.0) -> void:
	if shadow:
		var s := PackedVector2Array()
		for p in pts:
			s.append(p + Vector2(0, 4))
		ci.draw_colored_polygon(s, Color(SHADOW, SHADOW.a * a))
	ci.draw_colored_polygon(pts, Color(col, col.a * a))
	if outline:
		var o := pts.duplicate()
		o.append(pts[0])
		ci.draw_polyline(o, Color(INK, a), width, true)


static func circ(ci: CanvasItem, c: Vector2, r: float, col: Color, outline: bool = true,
		shadow: bool = true, a: float = 1.0) -> void:
	if shadow:
		ci.draw_circle(c + Vector2(0, 3), r, Color(SHADOW, SHADOW.a * a))
	ci.draw_circle(c, r, Color(col, col.a * a))
	if outline:
		ci.draw_arc(c, r, 0, TAU, 40, Color(INK, a), 2.0, true)


## Дугуй өнцөгтэй «чип» дээр бичиг. Буцаах: зурсан тэгш өнцөгт.
static func chip_text(ci: CanvasItem, center: Vector2, text: String, size: int, bg: Color, fg: Color,
		f: Font = null, border: float = 2.0) -> Rect2:
	var fo := f if f else font("bold")
	var w := fo.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + 24.0
	var h := size + 14.0
	var r := Rect2(center - Vector2(w, h) / 2.0, Vector2(w, h))
	ci.draw_style_box(paper(bg, h / 2.0, border, INK, 3), r)
	text_in(ci, r, text, size, fg, fo)
	return r


## Тэгш өнцөгтийн голд бичиг.
static func text_in(ci: CanvasItem, r: Rect2, text: String, size: int, col: Color, f: Font = null) -> void:
	var fo := f if f else font("ui")
	var y := r.position.y + (r.size.y + fo.get_ascent(size) - fo.get_descent(size)) / 2.0
	ci.draw_string(fo, Vector2(r.position.x, y), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, size, col)


static func star(ci: CanvasItem, c: Vector2, r: float, filled: bool) -> void:
	var pts := PackedVector2Array()
	for k in 10:
		var ang := -PI / 2 + k * PI / 5
		pts.append(c + Vector2(cos(ang), sin(ang)) * (r if k % 2 == 0 else r * 0.45))
	if filled:
		ci.draw_colored_polygon(pts, GLOW)
	var o := pts.duplicate()
	o.append(pts[0])
	ci.draw_polyline(o, INK if filled else Color("C9BFAD"), 1.6, true)


## Цаасан дэвсгэр үзэгдэл: тэнгэр (дугуй булантай карт), хоёр давхар байшингийн дүрс, газар.
static func diorama(ci: CanvasItem, r: Rect2, sky: Color, back: Color, mid: Color, ground_h: float,
		seed_v: int = 7, frame: bool = true) -> float:
	if frame:
		ci.draw_style_box(paper(sky, 18, 2.5, INK, 8), r)
	else:
		ci.draw_rect(r, sky)
	var g := r.end.y - ground_h
	skyline(ci, r.position.x + 18, r.end.x - 18, g, back, seed_v, r.size.y * 0.28, r.size.y * 0.55)
	skyline(ci, r.position.x + 36, r.end.x - 36, g, mid, seed_v + 5, r.size.y * 0.1, r.size.y * 0.28)
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color("EADFC8")
	if frame:
		gs.corner_radius_bottom_left = 16
		gs.corner_radius_bottom_right = 16
	gs.anti_aliasing = true
	var inset := 2.5 if frame else 0.0
	ci.draw_style_box(gs, Rect2(r.position.x + inset, g, r.size.x - inset * 2, ground_h - inset))
	ci.draw_line(Vector2(r.position.x + inset, g), Vector2(r.end.x - inset, g), Color(INK, 0.5), 2.0)
	return g


static func skyline(ci: CanvasItem, x0: float, x1: float, ground: float, col: Color, seed_v: int,
		hmin: float, hmax: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var x := x0
	while x < x1:
		var w := rng.randf_range(46, 90)
		var h := rng.randf_range(hmin, hmax)
		var rr := Rect2(x, ground - h, minf(w - 8, x1 - x), h + 8)
		if rr.size.x > 10:
			ci.draw_style_box(paper(col, 8, 0, INK, 0), rr)
		x += w


## Цаасан зорчигч. base = хөлийн доод цэг. a = тунгалаг байдал.
static func person(ci: CanvasItem, base: Vector2, shirt: Color, skin: Color, s: float = 1.0, a: float = 1.0,
		has_card: bool = false, grey_hair: bool = false) -> void:
	if a < 0.03:
		return
	var body := Rect2(base + Vector2(-14, -52) * s, Vector2(28, 40) * s)
	var bs := paper(Color(shirt, a), 10 * s, 2, Color(INK, a), 4)
	bs.shadow_color = Color(SHADOW, SHADOW.a * a)
	ci.draw_style_box(bs, body)
	ci.draw_rect(Rect2(base + Vector2(-11, -13) * s, Vector2(8, 13) * s), Color(INK, 0.85 * a))
	ci.draw_rect(Rect2(base + Vector2(3, -13) * s, Vector2(8, 13) * s), Color(INK, 0.85 * a))
	var head := base + Vector2(0, -66) * s
	circ(ci, head, 13 * s, skin, true, true, a)
	if grey_hair:
		ci.draw_arc(head + Vector2(0, -2) * s, 12 * s, PI + 0.2, TAU - 0.2, 14, Color(Color("DADADA"), a), 5 * s, true)
	ci.draw_circle(head + Vector2(-4, -1) * s, 1.6, Color(INK, a))
	ci.draw_circle(head + Vector2(4, -1) * s, 1.6, Color(INK, a))
	if has_card:
		var cr := Rect2(base + Vector2(10, -38) * s, Vector2(20, 13) * s)
		var cs := paper(Color(CARD_BLUE, a), 3, 2, Color(INK, a), 0)
		ci.draw_style_box(cs, cr)
		ci.draw_line(cr.position + Vector2(4, 8) * s, cr.position + Vector2(15, 8) * s, Color(1, 1, 1, a), 2)


## Батаа (түр зуурын дүр): жолоочийн малгайтай, яриагүй.
static func bataa(ci: CanvasItem, c: Vector2, s: float = 1.0) -> void:
	ci.draw_style_box(paper(Color("3D5A99"), 8 * s, 2, INK, 0), Rect2(c + Vector2(-17, 10) * s, Vector2(34, 22) * s))
	circ(ci, c, 14 * s, Color("E0B08A"), true, false)
	ci.draw_style_box(paper(Color("2F3E6B"), 4 * s, 2, INK, 0), Rect2(c + Vector2(-16, -19) * s, Vector2(32, 9) * s))
	ci.draw_rect(Rect2(c + Vector2(-4, -22) * s, Vector2(8, 4) * s), GLOW)
	ci.draw_circle(c + Vector2(-5, -1) * s, 1.8, INK)
	ci.draw_circle(c + Vector2(5, -1) * s, 1.8, INK)
	ci.draw_arc(c + Vector2(0, 3) * s, 6 * s, 0.3, PI - 0.3, 12, INK, 1.8, true)


## Цаасан шар автобус (зүүн тийш харсан): урд шил + Батаа, хаалга, цонх, дугуй.
## door_open: 0 хаалттай .. 1 нээлттэй. Буцаах: хаалганы тэгш өнцөгт.
static func bus(ci: CanvasItem, r: Rect2, door_open: float = 0.0, driver: bool = true) -> Rect2:
	ci.draw_style_box(paper(BUS, 20, 3, INK, 8), r)
	ci.draw_rect(Rect2(r.position + Vector2(3, r.size.y - 38), Vector2(r.size.x - 6, 10)), BUS_DARK)
	var wh := minf(58.0, r.size.y - 60.0)
	var ws := Rect2(r.position + Vector2(12, 16), Vector2(62, wh))
	ci.draw_style_box(paper(GLASS, 10, 2, INK, 0), ws)
	if driver:
		bataa(ci, ws.get_center() + Vector2(0, 4), clampf(wh / 64.0, 0.6, 0.9))
	var door := Rect2(r.position + Vector2(86, 16), Vector2(56, r.size.y - 30))
	ci.draw_style_box(paper(Color("3A3D55"), 6, 2, INK, 0), door)
	var leaf := door.size.x / 2.0 * (1.0 - clampf(door_open, 0.0, 1.0))
	if leaf > 1.0:
		ci.draw_style_box(paper(GLASS, 4, 2, INK, 0), Rect2(door.position, Vector2(leaf, door.size.y)))
		ci.draw_style_box(paper(GLASS, 4, 2, INK, 0), Rect2(Vector2(door.end.x - leaf, door.position.y), Vector2(leaf, door.size.y)))
	var x := r.position.x + 156
	while x + 58 < r.end.x - 10:
		ci.draw_style_box(paper(GLASS, 8, 2, INK, 0), Rect2(x, r.position.y + 16, 56, minf(40.0, wh - 10)))
		x += 68
	for wx in [r.position.x + 52, r.end.x - 60]:
		circ(ci, Vector2(wx, r.end.y), 17, INK, false, true)
		ci.draw_circle(Vector2(wx, r.end.y), 7, Color("C9C3B6"))
	circ(ci, r.position + Vector2(8, r.size.y - 50), 6, Color("FFF3B0"), true, false)
	return door
