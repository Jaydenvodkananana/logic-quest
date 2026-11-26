class_name FlowCanvas
extends Control
## Flowgorithm маягийн блок схем: програмын модоос (model) автоматаар дээрээс доош зурна.
## Эхлэл → Оролт (age, card) → блокууд → Төгсгөл. if: T баруун, F зүүн салаа, доор нь нийлнэ.
## Палитраас блок чирч СУМ дээр тавина; байгаа блокийг өөр сум руу чирч зөөнө; дарж сонгоно.
## Хулганы дугуй = томруулах/жижигрүүлэх, дунд товч (mouse 3) дарж чирэх = харагдацыг зөөх.
## Хувьсагчийн блок = түвшин 1-5-ын хайрцаг: дээр нэрийн шошго, дунд утга, доор «int» наалт.

signal changed                       # бүтэц өөрчлөгдсөн (нэмэх/зөөх)
signal selection_changed(block)      # сонгосон блок (эсвэл null)

const BOX_W := 170.0       # хувьсагчийн хайрцгийн өргөн
const BOX_H := 34.0        # хайрцгийн өндөр
const TAG_H := 22.0        # нэрийн шошго
const PILL_H := 18.0       # «int» наалт
const IF_W := 280.0       # нөхцлийн ромб
const IF_H := 46.0
const IN_W := 220.0        # оролтын параллелограмм
const IN_H := 32.0
const GAP := 24.0          # сумны урт (блок хооронд)
const BR_GAP := 36.0       # T ба F салааны хоорондох зай
const MARGIN := 24.0
const TERM_W := 120.0
const TERM_H := 30.0
const LINE := UiTheme.INK2
const YELLOW := UiTheme.GLOW
const GREEN := UiTheme.TRUE
const RED := UiTheme.FALSE
const BG := UiTheme.CARD

var model: Array = []
var inputs_text := "Оролт:  age, card"
var mono: Font
var editable := true
var make_block: Callable        # kind -> Dictionary (шинэ блок)
var selected = null             # сонгосон блок (Dictionary) эсвэл null

# Харагдац (дэлгэц = дэлхий * zoom + pan)
var zoom := 1.0
var pan := Vector2.ZERO
var panning := false
var world_w := 0.0
var world_h := 0.0
var _need_center := true

var nodes: Array = []           # {block, rect, list, index}
var arrows: Array = []          # {list, index, a, b}  (блок оруулж болох байр)
var lines: Array = []           # PackedVector2Array (сумгүй шугамууд)
var terms: Array = []           # [Rect2, text]
var input_rect := Rect2()
var empties: Array = []         # [Vector2] хоосон салааны «// ???»
var labels: Array = []          # [Vector2, text, color]
var hover_arrow := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	tooltip_text = "Дугуй: томруулах · Дунд товч: зөөх"
	clip_contents = true
	resized.connect(func():
		if _need_center:
			reset_view())


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and hover_arrow != -1:
		hover_arrow = -1
		queue_redraw()


## Томруулалтыг 100% болгож, схемийг дээд талд нь голлуулна.
func reset_view() -> void:
	zoom = 1.0
	pan = Vector2((size.x - world_w) / 2.0, 0.0)
	_need_center = size.x <= 1.0
	queue_redraw()


func to_world(p: Vector2) -> Vector2:
	return (p - pan) / zoom


# ---------------------------------------------------------------- хэмжээ ба байрлал

func _h(b: Dictionary) -> float:
	match b.t:
		"decl": return TAG_H + BOX_H + PILL_H
		"assign": return TAG_H + BOX_H
	return IF_H


func _w_list(list: Array) -> float:
	var w := BOX_W + 40.0
	for b in list:
		w = maxf(w, _w_block(b))
	return w


func _w_block(b: Dictionary) -> float:
	if b.t != "if":
		return BOX_W + 40.0
	var wt := _w_list(b.then)
	var wf := _w_list(b.else) if b.get("else") != null else 120.0
	return maxf(IF_W, wt + wf + BR_GAP)


func relayout() -> void:
	nodes.clear()
	arrows.clear()
	lines.clear()
	terms.clear()
	empties.clear()
	labels.clear()
	world_w = maxf(_w_list(model), IN_W + 40.0) + MARGIN * 2.0
	var cx := world_w / 2.0
	var y := MARGIN
	terms.append([Rect2(cx - TERM_W / 2.0, y, TERM_W, TERM_H), "Эхлэл"])
	y += TERM_H
	lines.append(PackedVector2Array([Vector2(cx, y), Vector2(cx, y + GAP)]))
	y += GAP
	input_rect = Rect2(cx - IN_W / 2.0, y, IN_W, IN_H)   # оролт: зорчигч бүрийн age, card
	y += IN_H
	y = _layout_list(model, cx, y, true)
	terms.append([Rect2(cx - TERM_W / 2.0, y, TERM_W, TERM_H), "Төгсгөл"])
	world_h = y + TERM_H + MARGIN
	if _need_center:
		reset_view()
	queue_redraw()


## Жагсаалт: блок бүрийн өмнө, сүүлийнхний дараа «сум» (блок оруулах байр).
func _layout_list(list: Array, cx: float, y: float, droppable: bool) -> float:
	for i in list.size() + 1:
		if droppable:
			arrows.append({"list": list, "index": i, "a": Vector2(cx, y), "b": Vector2(cx, y + GAP)})
		else:
			lines.append(PackedVector2Array([Vector2(cx, y), Vector2(cx, y + GAP)]))
		y += GAP
		if i < list.size():
			y = _layout_block(list, i, cx, y)
	return y


func _layout_block(list: Array, i: int, cx: float, y: float) -> float:
	var b: Dictionary = list[i]
	if b.t != "if":
		var h := _h(b)
		nodes.append({"block": b, "rect": Rect2(cx - BOX_W / 2.0, y, BOX_W, h), "list": list, "index": i})
		return y + h
	var r := Rect2(cx - IF_W / 2.0, y, IF_W, IF_H)
	nodes.append({"block": b, "rect": r, "list": list, "index": i})
	var wt := _w_list(b.then)
	var has_else: bool = b.get("else") != null
	var wf := _w_list(b.else) if has_else else 120.0
	var xt := cx + maxf(BR_GAP / 2.0 + wt / 2.0, IF_W / 2.0 + 16.0)
	var xf := cx - maxf(BR_GAP / 2.0 + wf / 2.0, IF_W / 2.0 + 16.0)
	var mid := y + IF_H / 2.0
	var ys := y + IF_H + 6.0
	lines.append(PackedVector2Array([Vector2(cx + IF_W / 2.0, mid), Vector2(xt, mid), Vector2(xt, ys)]))
	lines.append(PackedVector2Array([Vector2(cx - IF_W / 2.0, mid), Vector2(xf, mid), Vector2(xf, ys)]))
	labels.append([Vector2(cx + IF_W / 2.0 + 16.0, mid - 12.0), "T", GREEN])
	labels.append([Vector2(cx - IF_W / 2.0 - 16.0, mid - 12.0), "F", RED])
	var end_t := _layout_list(b.then, xt, ys, true)
	if b.then.is_empty():
		empties.append(Vector2(xt + 10.0, ys + GAP / 2.0 + 5.0))
	var end_f := ys
	if has_else:
		end_f = _layout_list(b.else, xf, ys, true)
		if b.else.is_empty():
			empties.append(Vector2(xf + 10.0, ys + GAP / 2.0 + 5.0))
	var ym := maxf(end_t, end_f) + 8.0
	lines.append(PackedVector2Array([Vector2(xt, end_t), Vector2(xt, ym), Vector2(cx, ym)]))
	lines.append(PackedVector2Array([Vector2(xf, end_f), Vector2(xf, ym), Vector2(cx, ym)]))
	return ym


# ---------------------------------------------------------------- оролт: сонгох, томруулах, зөөх, чирэх

func _node_at(p: Vector2) -> Dictionary:
	for n in nodes:
		if (n.rect as Rect2).grow(2.0).has_point(p):
			return n
	return {}


func _zoom_at(screen_p: Vector2, factor: float) -> void:
	var w := to_world(screen_p)
	zoom = clampf(zoom * factor, 0.4, 2.2)
	pan = screen_p - w * zoom
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					_zoom_at(event.position, 1.1)
				accept_event()
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					_zoom_at(event.position, 1.0 / 1.1)
				accept_event()
			MOUSE_BUTTON_MIDDLE:
				panning = event.pressed
				mouse_default_cursor_shape = Control.CURSOR_MOVE if panning else Control.CURSOR_ARROW
				accept_event()
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					var n := _node_at(to_world(event.position))
					selected = n.block if not n.is_empty() else null
					selection_changed.emit(selected)
					queue_redraw()
	elif event is InputEventMouseMotion and panning:
		pan += event.relative
		queue_redraw()
		accept_event()


func _get_drag_data(at_position: Vector2) -> Variant:
	if not editable or panning:
		return null
	var n := _node_at(to_world(at_position))
	if n.is_empty():
		return null
	selected = n.block
	selection_changed.emit(selected)
	var prev := Label.new()
	prev.text = _node_text(n.block)
	if mono:
		prev.add_theme_font_override("font", mono)
	prev.modulate = Color(1, 1, 1, 0.85)
	set_drag_preview(prev)
	return {"move": n.block, "list": n.list, "index": n.index}


## Блок өөрийнхөө дотор (салаан дотор) зөөгдөж болохгүй.
func _inside(block: Dictionary, list: Array) -> bool:
	if block.t != "if":
		return false
	for sub in [block.then, block.get("else")]:
		if sub == null:
			continue
		if is_same(sub, list):
			return true
		for b in sub:
			if _inside(b, list):
				return true
	return false


func _nearest_arrow(world_p: Vector2, data: Dictionary) -> int:
	var best := -1
	var best_d := 46.0 / zoom
	for k in arrows.size():
		var ar: Dictionary = arrows[k]
		if data.has("move") and _inside(data.move, ar.list):
			continue
		var d := world_p.distance_to(Geometry2D.get_closest_point_to_segment(world_p, ar.a, ar.b))
		if d < best_d:
			best_d = d
			best = k
	return best


## Чирж байхад ирмэгт ойртвол харагдац өөрөө гулсана (харагдахгүй сум руу тавихын тулд).
func _autopan(p: Vector2) -> void:
	var step := Vector2.ZERO
	if p.y > size.y - 36.0:
		step.y = -10.0
	elif p.y < 36.0:
		step.y = 10.0
	if p.x > size.x - 36.0:
		step.x = -10.0
	elif p.x < 36.0:
		step.x = 10.0
	if step != Vector2.ZERO:
		pan += step
		queue_redraw()


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not editable or not (data is Dictionary) or not (data.has("new") or data.has("move")):
		return false
	_autopan(at_position)
	var k := _nearest_arrow(to_world(at_position), data)
	if k != hover_arrow:
		hover_arrow = k
		queue_redraw()
	return k != -1


func _drop_data(at_position: Vector2, data: Variant) -> void:
	var k := _nearest_arrow(to_world(at_position), data)
	hover_arrow = -1
	if k == -1:
		return
	var ar: Dictionary = arrows[k]
	var target: Array = ar.list
	var idx: int = ar.index
	var block: Dictionary
	if data.has("new"):
		block = make_block.call(data.new)
	else:
		block = data.move
		var from: Array = data.list
		var old: int = data.index
		if is_same(from, target) and (idx == old or idx == old + 1):
			queue_redraw()
			return   # өөрийн байрандаа буцаж тавьсан
		from.remove_at(old)
		if is_same(from, target) and old < idx:
			idx -= 1
	target.insert(idx, block)
	selected = block
	relayout()
	changed.emit()
	selection_changed.emit(selected)


# ---------------------------------------------------------------- зураг

func _node_text(b: Dictionary) -> String:
	match b.t:
		"decl": return "int %s = %s" % [b.var, b.expr]
		"assign": return "%s = %s" % [b.var, b.expr]
		"if": return ChallengePanel.cond_text(b.cond)
	return "?"


func _arrow(a: Vector2, b: Vector2, col: Color, w: float) -> void:
	draw_line(a, b, col, w, true)
	var dir := (b - a).normalized()
	var side := Vector2(-dir.y, dir.x) * 5.0
	draw_colored_polygon(PackedVector2Array([b, b - dir * 9.0 + side, b - dir * 9.0 - side]), col)


func _pill(r: Rect2, fill: Color) -> void:
	draw_style_box(UiTheme.paper(fill, r.size.y / 2.0, 2, UiTheme.INK, 3), r)


## Хувьсагчийн блок: [нэрийн шошго] / [картон хайрцаг] / [int] (int нь зөвхөн зарлахад).
func _draw_var_block(_font: Font, mf: Font, b: Dictionary, r: Rect2, sel: bool) -> void:
	var vname := str(b.var)
	var tw := maxf(44.0, mf.get_string_size(vname, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 20.0)
	var box := Rect2(r.position.x, r.position.y + TAG_H - 2.0, r.size.x, BOX_H)
	if sel:
		draw_style_box(UiTheme.paper(Color(0, 0, 0, 0), 12, 4, YELLOW.darkened(0.1), 0), box.grow(5))
	draw_style_box(UiTheme.paper(UiTheme.BOX, 8, 2, UiTheme.INK, 4), box)
	var val := str(b.expr)
	if b.t == "assign":
		val = "← " + val   # хайрцагт шинэ утга хийнэ
	UiTheme.text_in(self, box, val, 17, UiTheme.INK, mf)
	var tag := Rect2(r.get_center().x - tw / 2.0, r.position.y, tw, TAG_H)
	draw_style_box(UiTheme.paper(UiTheme.CARD, 6, 2, UiTheme.INK, 0), tag)
	UiTheme.text_in(self, tag, vname, 15, UiTheme.INK, mf)
	if b.t == "decl":
		var pill := Rect2(r.get_center().x - 22.0, box.end.y - 3.0, 44.0, PILL_H)
		draw_style_box(UiTheme.paper(UiTheme.INT_TAG, PILL_H / 2.0, 2, UiTheme.INK, 0), pill)
		UiTheme.text_in(self, pill, "int", 13, UiTheme.INK, mf)


func _draw() -> void:
	var font := UiTheme.font("bold")
	var mf: Font = mono if mono else font
	# Цаасан самбар + цэгэн тор (зөөхөд тор хамт хөдөлнө).
	draw_rect(Rect2(Vector2.ZERO, size), BG)
	var step := 22.0 * zoom
	var yy := fposmod(pan.y, step)
	while yy < size.y:
		var xx := fposmod(pan.x, step)
		while xx < size.x:
			draw_circle(Vector2(xx, yy), 1.1, Color("E9E1D2"))
			xx += step
		yy += step
	draw_set_transform(pan, 0.0, Vector2(zoom, zoom))
	for pl in lines:
		draw_polyline(pl, LINE, 2.0, true)
	for k in arrows.size():
		var ar: Dictionary = arrows[k]
		if k == hover_arrow:
			_arrow(ar.a, ar.b, YELLOW.darkened(0.15), 4.0)
			var mc: Vector2 = (ar.a + ar.b) / 2.0
			UiTheme.circ(self, mc, 10.0, YELLOW, true, false)
			UiTheme.text_in(self, Rect2(mc - Vector2(10, 10), Vector2(20, 20)), "+", 16, UiTheme.INK, font)
		else:
			_arrow(ar.a, ar.b, LINE, 2.0)
	for e in empties:
		# Хоосон салаа: тасархай «энд блок тавина» байр.
		var er := Rect2(e + Vector2(-4, -15), Vector2(64, 22))
		var cs := [er.position, Vector2(er.end.x, er.position.y), er.end, Vector2(er.position.x, er.end.y)]
		for k in 4:
			draw_dashed_line(cs[k], cs[(k + 1) % 4], UiTheme.INK2, 2.0, 6.0)
		UiTheme.text_in(self, er, "???", 14, UiTheme.HILITE, mf)
	for t in terms:
		var r: Rect2 = t[0]
		_pill(r, UiTheme.SAND)
		UiTheme.text_in(self, r, t[1], 15, UiTheme.INK, font)
	# Оролт (параллелограмм): зорчигч бүрийн age, card энд програмд орж ирнэ.
	var ir := input_rect
	var sk := 14.0
	var para := PackedVector2Array([ir.position + Vector2(sk, 0), Vector2(ir.end.x, ir.position.y), ir.end - Vector2(sk, 0), Vector2(ir.position.x, ir.end.y)])
	UiTheme.poly(self, para, Color("DCEBFF"))
	UiTheme.text_in(self, ir, inputs_text, 15, UiTheme.INK, mf)
	for n in nodes:
		var b: Dictionary = n.block
		var r: Rect2 = n.rect
		var sel: bool = selected != null and is_same(selected, b)
		if b.t == "if":
			var c := r.get_center()
			var hw := r.size.x / 2.0
			var hh := r.size.y / 2.0
			var pts := PackedVector2Array([c + Vector2(0, -hh), c + Vector2(hw, 0), c + Vector2(0, hh), c + Vector2(-hw, 0)])
			if sel:
				var o := PackedVector2Array([c + Vector2(0, -hh - 6), c + Vector2(hw + 10, 0), c + Vector2(0, hh + 6), c + Vector2(-hw - 10, 0), c + Vector2(0, -hh - 6)])
				draw_polyline(o, YELLOW.darkened(0.1), 4.0, true)
			UiTheme.poly(self, pts, UiTheme.COND_ACC.lerp(Color.WHITE, 0.8))
			UiTheme.text_in(self, r, _node_text(b), 15, UiTheme.INK, mf)
		else:
			_draw_var_block(font, mf, b, r, sel)
	for l in labels:
		UiTheme.chip_text(self, l[0], l[1], 12, l[2], Color.WHITE, font, 0)
	# Томруулалт (баруун доод буланд). Удирдлагын тайлбар нь tooltip-д.
	draw_set_transform_matrix(Transform2D())
	draw_string(font, Vector2(size.x - 56, size.y - 10), "%d%%" % roundi(zoom * 100.0), HORIZONTAL_ALIGNMENT_RIGHT, 46, 13, UiTheme.MUTED)
	draw_style_box(UiTheme.paper(Color(0, 0, 0, 0), 6, 2, UiTheme.INK, 0), Rect2(Vector2.ZERO, size))
