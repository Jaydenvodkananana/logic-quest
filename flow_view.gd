class_name FlowView
extends Control
## if / if-else-ийн блок схем: дээр нь нөхцлийн зууван, зүүн тийш F (худал), баруун тийш T (үнэн),
## блокийн хайрцаг(ууд), доор нь замууд нийлнэ. Утгын «токен» замаар явна.
## main.gd анимацийг удирдана; энэ анги зөвхөн зурж, сонголтын товшилтыг дамжуулна.

signal side_chosen(side: int)   # 0 = F (зүүн), 1 = T (баруун)

const LINE := Color(0.55, 0.58, 0.66)
const GREEN := Color(0.4, 0.9, 0.5)
const RED := Color(1.0, 0.45, 0.45)
const YELLOW := Color(1.0, 0.85, 0.3)
const BOX_W := 200.0
const BOX_H := 46.0

var kind := "if"            # "if" эсвэл "ifelse"
var cond_text := ""         # зууван доторх бичиг ("temp > 30" эсвэл "35 > 30")
var eval_state := 0         # 0 тодорхойгүй, 1 true, 2 false
var t_stmt := ""            # T блокийн мөр ("fan = 1;")
var f_stmt := ""            # F блокийн мөр (зөвхөн ifelse)
var active_side := -1       # явсан зам (шар)
var flash_side := -1        # ажилласан блок (ногоон)
var hover_side := -1        # сонгох үед хулганы доорх зам
var chosen_side := -1       # тоглогчийн сонгосон зам (✓/✗ тэмдэглэнэ)
var chosen_ok := false
var choosing := false
var token_visible := false
var token_pos := Vector2.ZERO
var token_text := ""
var mono: Font
# Тоон шулуун (оператор тайлбарлах үед): numline_t >= 0 бол блок схемийн оронд зурагдана.
var numline_t := -1         # хилийн утга (жишээ нь 30); -1 = унтраалттай
var numline_op := ""        # ">", ">=", "=="


func _ready() -> void:
	custom_minimum_size = Vector2(620, 190)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(_delta: float) -> void:
	queue_redraw()


# ---------------------------------------------------------------- геометр

func cond_center() -> Vector2:
	return Vector2(size.x / 2.0, 30.0)


func _rx() -> float:
	return 120.0


func _branch_x(side: int) -> float:
	return size.x / 2.0 + (1.0 if side == 1 else -1.0) * 200.0


func box_center(side: int) -> Vector2:
	return Vector2(_branch_x(side), 98.0)


func has_box(side: int) -> bool:
	return side == 1 or kind == "ifelse"


## Замын цэгүүд: нөхцлөөс → хажуу → (блок) → нийлэх цэг → доош.
func path(side: int) -> PackedVector2Array:
	var c := cond_center()
	var x := _branch_x(side)
	var start := c + Vector2((1.0 if side == 1 else -1.0) * _rx(), 0.0)
	var merge_y := size.y - 34.0
	return PackedVector2Array([
		start,
		Vector2(x, c.y),
		Vector2(x, box_center(side).y),
		Vector2(x, merge_y),
		Vector2(size.x / 2.0, merge_y),
		Vector2(size.x / 2.0, size.y),
	])


## t (0..1) замын уртын хэдэн хувь вэ гэдгээр цэг буцаана.
func point_on(side: int, t: float) -> Vector2:
	var pts := path(side)
	var total := 0.0
	for i in pts.size() - 1:
		total += pts[i].distance_to(pts[i + 1])
	var want := clampf(t, 0.0, 1.0) * total
	for i in pts.size() - 1:
		var seg := pts[i].distance_to(pts[i + 1])
		if want <= seg:
			return pts[i].lerp(pts[i + 1], want / maxf(seg, 0.001))
		want -= seg
	return pts[pts.size() - 1]


## Блокийн хайрцаг хүртэлх замын хувь (токен блокийн төвд хүрэх t).
func t_at_box(side: int) -> float:
	var pts := path(side)
	var total := 0.0
	var upto := 0.0
	for i in pts.size() - 1:
		var seg := pts[i].distance_to(pts[i + 1])
		if i < 2:
			upto += seg
		total += seg
	return upto / total


# ---------------------------------------------------------------- оролт

func _gui_input(event: InputEvent) -> void:
	# Сонгох үед гар хэлбэрийн курсор: «энд дарна».
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if choosing else Control.CURSOR_ARROW
	if not choosing:
		return
	if event is InputEventMouseMotion:
		hover_side = 0 if event.position.x < size.x / 2.0 else 1
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		side_chosen.emit(0 if event.position.x < size.x / 2.0 else 1)


func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover_side = -1


# ---------------------------------------------------------------- зураг

## Оператор үнэн эсэх (тоон шулуунд).
static func op_true(v: int, op: String, t: int) -> bool:
	match op:
		">": return v > t
		">=": return v >= t
		"<": return v < t
		"<=": return v <= t
		"==": return v == t
		"!=": return v != t
	return false


## Нөхцлийн зууван (үнэн бол ногоон, худал бол улаан).
func _draw_oval(mf: Font) -> void:
	var c := cond_center()
	var pts := PackedVector2Array()
	for k in 32:
		var a := TAU * k / 32.0
		pts.append(c + Vector2(cos(a) * _rx(), sin(a) * 24.0))
	var oval_fill := Color(0.13, 0.15, 0.2)
	if eval_state == 1:
		oval_fill = Color(0.12, 0.32, 0.18)
	elif eval_state == 2:
		oval_fill = Color(0.42, 0.14, 0.14)
	draw_colored_polygon(pts, oval_fill)
	pts.append(pts[0])
	draw_polyline(pts, Color(0.9, 0.9, 0.95), 3.0, true)
	var txt := cond_text
	var col := Color.WHITE
	if eval_state == 1:
		txt += "  → true"
		col = GREEN
	elif eval_state == 2:
		txt += "  → false"
		col = RED
	draw_string(mf, Vector2(c.x - _rx(), c.y + 8.0), txt, HORIZONTAL_ALIGNMENT_CENTER, _rx() * 2.0, 22, col)


## Тоон шулуун: хилийн орчмын тоонууд, нөхцлийг үнэн болгодог нь ногоон.
func _draw_numline(font: Font, mf: Font) -> void:
	var y := 112.0
	var step := 76.0
	var cx := size.x / 2.0
	draw_line(Vector2(cx - step * 3.6, y), Vector2(cx + step * 3.6, y), LINE, 3.0)
	for k in range(-3, 4):
		var v := numline_t + k
		var p := Vector2(cx + k * step, y)
		var on := op_true(v, numline_op, numline_t)
		draw_circle(p, 25.0, Color(0.12, 0.32, 0.18) if on else Color(0.16, 0.17, 0.22))
		draw_arc(p, 25.0, 0.0, TAU, 32, GREEN if on else LINE, 3.0 if on else 2.0)
		if k == 0:
			draw_arc(p, 31.0, 0.0, TAU, 32, YELLOW, 2.0)   # хилийн утга
		draw_string(mf, p + Vector2(-30.0, 8.0), str(v), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 22, Color.WHITE)
		draw_string(font, p + Vector2(-40.0, 52.0), "үнэн" if on else "худал", HORIZONTAL_ALIGNMENT_CENTER, 80.0, 16, GREEN if on else Color(1, 1, 1, 0.35))


func _draw() -> void:
	var font := get_theme_default_font()
	var mf: Font = mono if mono != null else font
	if numline_t >= 0:
		_draw_oval(mf)
		_draw_numline(font, mf)
		return
	# Замууд: эхлээд энгийн, дараа нь hover, дараа нь явсан зам дээрээс нь.
	for side in [0, 1]:
		draw_polyline(path(side), LINE, 3.0, true)
	if choosing:
		# Сонгох үед хоёр зам улаан/ногооноор «амьсгалж» гэрэлтэнэ: дарж болно гэдгийг харуулна.
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 260.0)
		for side in [0, 1]:
			var col: Color = GREEN if side == 1 else RED
			var strong: bool = hover_side == side
			col.a = 0.95 if strong else 0.25 + 0.35 * pulse
			draw_polyline(path(side), col, 9.0 if strong else 7.0, true)
	if active_side != -1:
		draw_polyline(path(active_side), YELLOW, 5.0, true)
	# T / F шошго (үнэн / худал гэсэн монгол утгатай нь)
	var c := cond_center()
	draw_string(font, c + Vector2(_rx() + 12.0, -10.0), "T  үнэн", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, GREEN)
	draw_string(font, c + Vector2(-_rx() - 112.0, -10.0), "худал  F", HORIZONTAL_ALIGNMENT_RIGHT, 100.0, 20, RED)
	# Нийлэх цэг
	draw_circle(Vector2(size.x / 2.0, size.y - 34.0), 6.0, LINE)
	# Блокийн хайрцгууд
	for side in [0, 1]:
		if not has_box(side):
			continue
		var bc := box_center(side)
		var r := Rect2(bc - Vector2(BOX_W, BOX_H) / 2.0, Vector2(BOX_W, BOX_H))
		var fill := Color(0.12, 0.3, 0.18) if flash_side == side else Color(0.13, 0.15, 0.2)
		draw_rect(r, fill)
		draw_rect(r, Color(0.9, 0.9, 0.95), false, 3.0)
		var stmt := t_stmt if side == 1 else f_stmt
		draw_string(mf, Vector2(r.position.x, bc.y + 8.0), stmt, HORIZONTAL_ALIGNMENT_CENTER, BOX_W, 22, Color.WHITE)
	_draw_oval(mf)
	# Тоглогчийн сонголтын тэмдэг
	if chosen_side != -1:
		var mark := "✓" if chosen_ok else "✗"
		var mp := Vector2(_branch_x(chosen_side) + (34.0 if chosen_side == 1 else -60.0), c.y + 8.0)
		draw_string(font, mp, mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GREEN if chosen_ok else RED)
	# Утгын токен
	if token_visible:
		draw_circle(token_pos, 20.0, YELLOW)
		draw_string(mf, token_pos + Vector2(-30.0, 7.0), token_text, HORIZONTAL_ALIGNMENT_CENTER, 60.0, 20, Color(0.1, 0.1, 0.12))
