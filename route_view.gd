class_name RouteView
extends Control
## Бүлэг сонгох дэлгэц («цаасан диорама»): дээр нь бүлгийн картууд (Хувьсагч, Нөхцөл, Давталт — удахгүй),
## доор нь сонгосон бүлгийн түвшний зам: давсан буудал өнгөтэй + од, нээлттэй нь шар гэрэлтэй, түгжээтэй нь саарал.
## Хулгана: карт дээр дарвал тэр бүлэг, буудал дээр дарвал тэр түвшин. Гар: ← / → буудал, Enter явах (main.gd дамжуулна).
## (Нэр нь хуучнаараа RouteView: main.gd ба тестүүд stops / selected / travel / move_sel / activate-ийг ашиглана.)

signal stop_chosen(index: int)

const R := 30.0          # буудлын тойргийн радиус
const TEASER := "loop"   # удахгүй гарах бүлэг (үргэлж түгжээтэй)

## {label: String, stars: int, state: int (0 түгжээтэй, 1 нээлттэй, 2 давсан), optional: bool, chapter: String}
var stops: Array = []
var bubble := ""        # хуучин API (ярианы бөмбөлөг байхгүй болсон)
var bus_f := 0.0        # жижиг автобусны байрлал (буудлын индекс, бутархай = хооронд нь явж байна)
var view_chapter := ""  # харагдаж буй бүлэг
## Сонгосон буудал. Гаднаас (main.gd) өөрчлөхөд харагдах бүлэг нь дагана.
var selected := 0:
	set(v):
		selected = v
		if v >= 0 and v < stops.size():
			view_chapter = stops[v].chapter
var busy := false
var _time := 0.0
var _hover_card := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	if is_visible_in_tree():
		_time += delta
		queue_redraw()


func set_stops(data: Array) -> void:
	stops = data
	selected = clampi(selected, 0, maxi(0, stops.size() - 1))
	if not stops.is_empty():
		view_chapter = stops[selected].chapter


## Бүлгүүд дарааллаараа (levels.gd-ээс) + удахгүй гарах бүлэг.
func chapters() -> Array:
	var out: Array = []
	for s in stops:
		if not out.has(s.chapter):
			out.append(s.chapter)
	if not out.has(TEASER):
		out.append(TEASER)
	return out


func _chapter_stops(ch: String) -> Array:
	var out: Array = []
	for i in stops.size():
		if stops[i].chapter == ch:
			out.append(i)
	return out


## Автобус нэг буудлаас нөгөө рүү зам дагуу явна (өөр бүлэг рүү бол замын эхнээс орж ирнэ).
func travel(from_i: int, to_i: int, secs: float = 1.0) -> void:
	busy = true
	selected = to_i
	view_chapter = stops[to_i].chapter
	var idx := _chapter_stops(view_chapter)
	bus_f = float(from_i) if stops[from_i].chapter == view_chapter else float(idx[0]) - 0.7
	var tw := create_tween()
	tw.tween_property(self, "bus_f", float(to_i), secs).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	busy = false


## ← / →: дараагийн нээлттэй буудал руу (бүлгийн хил давж болно).
func move_sel(dir: int) -> void:
	var j := selected + dir
	while j >= 0 and j < stops.size():
		if stops[j].state > 0:
			selected = j
			view_chapter = stops[j].chapter
			return
		j += dir


func activate() -> void:
	if not busy and selected < stops.size() and stops[selected].state > 0 and stops[selected].chapter == view_chapter:
		stop_chosen.emit(selected)


## Бүлэг сонгоход: давж амжаагүй нээлттэй буудал, эсвэл сүүлийн нээлттэй буудал сонгогдоно.
func _open_chapter(ch: String) -> void:
	view_chapter = ch
	var best := -1
	for i in _chapter_stops(ch):
		if stops[i].state == 1:
			best = i
			break
		if stops[i].state == 2:
			best = i
	if best >= 0:
		selected = best


# ---------------------------------------------------------------- геометр

func _card_rect(k: int) -> Rect2:
	var n := chapters().size()
	var gap := 32.0
	var w := (size.x - 80.0 - gap * (n - 1)) / n
	var r := Rect2(40.0 + k * (w + gap), 104.0, w, 262.0)
	if chapters()[k] == view_chapter:
		r.position.y -= 8.0
		r.size.y += 8.0
	return r


func _panel_rect() -> Rect2:
	return Rect2(40.0, 398.0, size.x - 80.0, size.y - 398.0 - 24.0)


func _stop_pos(i: int) -> Vector2:
	var idx := _chapter_stops(view_chapter)
	var p := _panel_rect()
	var k := idx.find(i)
	var x0 := p.position.x + 250.0
	var x1 := p.end.x - 160.0
	var t := 0.5 if idx.size() <= 1 else float(k) / float(idx.size() - 1)
	return Vector2(lerpf(x0, x1, t), p.position.y + 118.0)


func _point_at(f: float) -> Vector2:
	var idx := _chapter_stops(view_chapter)
	if idx.is_empty():
		return Vector2.ZERO
	var first: int = idx[0]
	var last: int = idx[idx.size() - 1]
	if f <= first:
		return _stop_pos(first) - Vector2((first - f) * 140.0, 0)
	var i := clampi(floori(f), first, last)
	var j := mini(i + 1, last)
	return _stop_pos(i).lerp(_stop_pos(j), f - floorf(f))


func _stop_at(p: Vector2) -> int:
	for i in _chapter_stops(view_chapter):
		if p.distance_to(_stop_pos(i)) <= R + 10.0:
			return i
	return -1


func _card_at(p: Vector2) -> int:
	for k in chapters().size():
		if _card_rect(k).has_point(p):
			return k
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var i := _stop_at(event.position)
		var open: bool = i >= 0 and stops[i].state > 0
		_hover_card = _card_at(event.position)
		var card_ok: bool = _hover_card >= 0 and chapters()[_hover_card] != TEASER
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if open or card_ok else Control.CURSOR_ARROW
		if open and not busy:
			selected = i
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var i := _stop_at(event.position)
		if i >= 0 and stops[i].state > 0 and not busy:
			selected = i
			stop_chosen.emit(i)
		else:
			var k := _card_at(event.position)
			if k >= 0 and chapters()[k] != TEASER and not busy:
				_open_chapter(chapters()[k])
		accept_event()


# ---------------------------------------------------------------- зураг

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), UiTheme.CREAM)
	draw_string(UiTheme.font("xbold"), Vector2(40, 66), "Logic Quest", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, UiTheme.INK)
	_draw_total()
	var ch := chapters()
	for k in ch.size():
		_draw_card(k, ch[k])
	_draw_path()


func _draw_total() -> void:
	var total := 0
	for s in stops:
		total += int(s.stars)
	var text := "%d / %d" % [total, stops.size() * 3]
	var f := UiTheme.font("xbold")
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20).x + 62.0
	var r := Rect2(size.x - 40.0 - w, 30, w, 42)
	UiTheme.box(self, r, UiTheme.CARD, 21, 2, 4)
	UiTheme.star(self, r.position + Vector2(26, 21), 11, true)
	draw_string(f, r.position + Vector2(44, 29), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, UiTheme.INK)


func _draw_card(k: int, ch: String) -> void:
	var info: Dictionary = UiTheme.CHAPTERS.get(ch, {"name": ch, "acc": UiTheme.INK2, "icon": ""})
	var acc: Color = info.acc
	var locked := ch == TEASER
	var sel := ch == view_chapter
	var r := _card_rect(k)
	if sel:
		draw_style_box(UiTheme.paper(UiTheme.CARD, 18, 3, acc, 14), r)
	elif locked:
		draw_style_box(UiTheme.paper(UiTheme.CARD_DIM, 18, 2, UiTheme.MUTED_LINE, 6), r)
	else:
		var hov := k == _hover_card
		draw_style_box(UiTheme.paper(UiTheme.CARD, 18, 2, UiTheme.INK, 9 if hov else 6), r)
	# Бүлгийн зураг (жижиг диорама)
	var ill := Rect2(r.position + Vector2(12, 12), Vector2(r.size.x - 24, 150))
	var sky := UiTheme.SAND if locked else acc.lerp(Color.WHITE, 0.72)
	draw_style_box(UiTheme.paper(sky, 12, 0, UiTheme.INK, 0), ill)
	var g := ill.end.y - 26.0
	var hill := Color("DDD4C3") if locked else acc.lerp(Color.WHITE, 0.45)
	UiTheme.skyline(self, ill.position.x + 8, ill.end.x - 8, g, hill, 3 + k, 30, 70)
	var gs := StyleBoxFlat.new()
	gs.bg_color = Color("E3DACB") if locked else Color("EADFC8")
	gs.corner_radius_bottom_left = 12
	gs.corner_radius_bottom_right = 12
	draw_style_box(gs, Rect2(ill.position.x, g, ill.size.x, 26))
	match ch:
		"var":
			_small_bus(Vector2(ill.end.x - 186, g - 70), 0.58, 0.0)
			_mini_box(Vector2(ill.position.x + 60, g - 38))
		"cond":
			_small_bus(Vector2(ill.end.x - 186, g - 70), 0.58, 1.0)
			_mini_reader(Vector2(ill.end.x - 206, g))
			UiTheme.person(self, Vector2(ill.position.x + 40, g + 2), UiTheme.SHIRTS[1], UiTheme.SKINS[0], 0.8, 1.0, true)
			UiTheme.person(self, Vector2(ill.position.x + 80, g + 2), UiTheme.SHIRTS[0], UiTheme.SKINS[2], 0.8)
		TEASER:
			_mini_factory(ill, g)
	var dim := UiTheme.MUTED
	var ty := ill.end.y + 30.0
	var num := "%d-р бүлэг" % (k + 1)
	draw_string(UiTheme.font("bold"), Vector2(r.position.x + 18, ty), num, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, dim if locked else UiTheme.INK2)
	draw_string(UiTheme.font("xbold"), Vector2(r.position.x + 18, ty + 32), info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, dim if locked else UiTheme.INK)
	if locked:
		UiTheme.chip_text(self, Vector2(r.end.x - 66, ty + 22), "Удахгүй", 14, UiTheme.SAND, UiTheme.INK2, null, 0)
		return
	var idx := _chapter_stops(ch)
	var got := 0
	for i in idx:
		got += int(stops[i].stars)
	UiTheme.star(self, Vector2(r.end.x - 104, ty + 21), 9, true)
	draw_string(UiTheme.font("bold"), Vector2(r.end.x - 90, ty + 28), "%d / %d" % [got, idx.size() * 3], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, UiTheme.INK)
	for j in idx.size():
		var c := Vector2(r.end.x - 104 + j * 17, ty + 46)
		var st: int = stops[idx[j]].state
		draw_circle(c, 5.5, acc if st == 2 else UiTheme.LINE)
		if st == 1:
			draw_arc(c, 7.5, 0, TAU, 20, UiTheme.GLOW, 2.5, true)


func _small_bus(pos: Vector2, sc: float, door: float) -> void:
	draw_set_transform(pos, 0, Vector2(sc, sc))
	UiTheme.bus(self, Rect2(0, 0, 300, 120), door, true)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## Хувьсагчийн бүлгийн тэмдэг: «people» нэртэй, int наалттай картон хайрцаг.
func _mini_box(c: Vector2) -> void:
	var r := Rect2(c - Vector2(42, 26), Vector2(84, 52))
	draw_style_box(UiTheme.paper(UiTheme.BOX, 9, 2.5, UiTheme.INK, 5), r)
	draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, 8)), UiTheme.BOX_DARK)
	var slip := Rect2(c + Vector2(-20, -10), Vector2(40, 30))
	draw_style_box(UiTheme.paper(UiTheme.CARD, 5, 2, UiTheme.INK, 2), slip)
	UiTheme.text_in(self, slip, "9", 20, UiTheme.INK, UiTheme.font("mono_b"))
	var mf := UiTheme.font("mono_b")
	var nw := mf.get_string_size("people", HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x + 16
	var nr := Rect2(Vector2(c.x - nw / 2, r.position.y - 20), Vector2(nw, 22))
	draw_style_box(UiTheme.paper(UiTheme.CARD, 6, 2, UiTheme.INK, 2), nr)
	UiTheme.text_in(self, nr, "people", 14, UiTheme.INK, mf)
	var tr := Rect2(Vector2(c.x - 20, r.end.y - 6), Vector2(40, 18))
	draw_style_box(UiTheme.paper(UiTheme.INT_TAG, 9, 2, UiTheme.INK, 0), tr)
	UiTheme.text_in(self, tr, "int", 12, UiTheme.INK, mf)


func _mini_reader(base: Vector2) -> void:
	draw_style_box(UiTheme.paper(Color("8B8FA3"), 3, 2, UiTheme.INK, 0), Rect2(base + Vector2(-3, -50), Vector2(6, 50)))
	var b := Rect2(base + Vector2(-20, -88), Vector2(40, 40))
	UiTheme.box(self, b, UiTheme.CARD, 7, 2, 3)
	var scr := Rect2(b.position + Vector2(5, 5), Vector2(30, 16))
	draw_style_box(UiTheme.paper(UiTheme.CODE_BG, 3, 0, UiTheme.INK, 0), scr)
	UiTheme.text_in(self, scr, "◇", 11, UiTheme.COND_ACC, UiTheme.font("mono_b"))
	draw_style_box(UiTheme.paper(UiTheme.CARD_BLUE, 2, 1.5, UiTheme.INK, 0), Rect2(b.position + Vector2(10, 26), Vector2(20, 9)))


## Давталтын бүлгийн (удахгүй) бүдэг зураг: үйлдвэр, конвейер, түгжээ.
func _mini_factory(ill: Rect2, g: float) -> void:
	var fc := Color("CFC5B3")
	var ln := Color("B8AE9C")
	draw_style_box(UiTheme.paper(fc, 6, 2, ln, 0), Rect2(ill.position.x + 30, g - 80, 120, 80))
	draw_style_box(UiTheme.paper(fc, 4, 2, ln, 0), Rect2(ill.position.x + 120, g - 112, 22, 40))
	draw_style_box(UiTheme.paper(Color("D8CFBF"), 11, 2, ln, 0), Rect2(ill.position.x + 150, g - 30, 150, 22))
	for k in 3:
		draw_style_box(UiTheme.paper(Color("E3DACB"), 4, 2, ln, 0), Rect2(ill.position.x + 162 + k * 46, g - 54, 26, 24))
	draw_arc(Vector2(ill.position.x + 230, g - 76), 16, 0.3, TAU - 0.6, 24, ln, 3, true)
	var lc := ill.get_center() + Vector2(0, -6)
	UiTheme.circ(self, lc, 26, UiTheme.CARD)
	draw_style_box(UiTheme.paper(UiTheme.INK2, 3, 0, UiTheme.INK, 0), Rect2(lc + Vector2(-9, -3), Vector2(18, 14)))
	draw_arc(lc + Vector2(0, -4), 6, PI, TAU, 12, UiTheme.INK2, 3, true)


## Сонгосон бүлгийн түвшний зам.
func _draw_path() -> void:
	var p := _panel_rect()
	UiTheme.box(self, p, UiTheme.CARD, 18, 2, 6)
	var info: Dictionary = UiTheme.CHAPTERS.get(view_chapter, {"name": "", "acc": UiTheme.INK2, "icon": ""})
	var acc: Color = info.acc
	UiTheme.chip_text(self, p.position + Vector2(86, 36), "%s  %s" % [info.icon, info.name], 15, acc, UiTheme.on_color(acc), null, 0)
	UiTheme.bataa(self, p.position + Vector2(78, 130), 1.5)   # түр зуурын дүр (яриагүй)
	var idx := _chapter_stops(view_chapter)
	if idx.is_empty():
		return
	var pts := PackedVector2Array()
	for i in idx:
		pts.append(_stop_pos(i))
	if pts.size() > 1:
		draw_polyline(pts, Color("EFE5D2"), 26, true)
		# Давсан хэсэг: эхнээс автобус хүртэл бүлгийн өнгөөр.
		var done := PackedVector2Array([pts[0]])
		for i in idx:
			if float(i) <= bus_f and i != idx[0]:
				done.append(_stop_pos(i))
		var bp := _point_at(bus_f)
		if bp.x > pts[0].x:
			done.append(bp)
		if done.size() > 1:
			draw_polyline(done, Color(acc, 0.35), 26, true)
		for k in pts.size() - 1:
			draw_dashed_line(pts[k] + Vector2(R + 4, 0), pts[k + 1] - Vector2(R + 4, 0), Color(UiTheme.INK, 0.35), 2.0, 9.0)
	for i in idx:
		_draw_stop(i, acc)
	# Жижиг автобус: аль түвшин дээр байгааг заана (шинэ түвшин рүү явахдаа хөдөлнө).
	var bpos := _point_at(bus_f) + Vector2(-27, -R - 44)
	var bob := sin(_time * 10.0) * 1.5 if busy else 0.0
	if bpos.x > p.position.x + 120:
		_small_bus(bpos + Vector2(0, bob), 0.18, 0.0)


func _draw_stop(i: int, acc: Color) -> void:
	var c := _stop_pos(i)
	var s: Dictionary = stops[i]
	var state: int = s.state
	var cr := Rect2(c - Vector2(R, R), Vector2(R * 2, R * 2))
	var mf := UiTheme.font("xbold")
	if state == 2:
		UiTheme.circ(self, c, R, acc)
		UiTheme.text_in(self, cr, str(i + 1), 26, UiTheme.on_color(acc), mf)
	elif state == 1:
		var pulse := (sin(_time * 4.0) + 1.0) / 2.0
		draw_circle(c, R + 10.0 + pulse * 6.0, Color(UiTheme.GLOW, 0.22 * (1.0 - pulse) + 0.08))
		draw_arc(c, R + 8.0, 0, TAU, 48, UiTheme.GLOW, 4, true)
		UiTheme.circ(self, c, R, UiTheme.CARD)
		UiTheme.text_in(self, cr, str(i + 1), 26, UiTheme.INK, mf)
	else:
		draw_circle(c, R, Color("F1EADB"))
		draw_arc(c, R, 0, TAU, 48, Color("C9BFAD"), 2.5, true)
		UiTheme.text_in(self, cr, str(i + 1), 26, UiTheme.MUTED, mf)
	if i == selected and state > 0:
		draw_arc(c, R + 14.0, 0, TAU, 48, UiTheme.INK, 2.5, true)
	if s.get("optional", false):
		UiTheme.chip_text(self, c + Vector2(0, -R - 22), "нэмэлт", 12, UiTheme.SAND, UiTheme.INK2, null, 0)
	var lc := UiTheme.INK if state > 0 else UiTheme.MUTED
	UiTheme.text_in(self, Rect2(c.x - 80, c.y + R + 16, 160, 26), str(s.label), 17, lc, UiTheme.font("bold"))
	var n: int = s.stars
	if n > 0:
		for k in 3:
			UiTheme.star(self, Vector2(c.x - 18 + k * 18, c.y + R + 56), 8, k < n)
