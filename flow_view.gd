class_name FlowView
extends Control
## if / if-else-ийн блок схем: дээр нь нөхцлийн зууван, зүүн тийш F (худал), баруун тийш T (үнэн),
## блокийн хайрцаг(ууд), доор нь замууд нийлнэ. Утгын «токен» замаар явна.
## main.gd анимацийг удирдана; энэ анги зөвхөн зурж, сонголтын товшилтыг дамжуулна.

signal side_chosen(side: int)   # 0 = F (зүүн), 1 = T (баруун)

const LINE := UiTheme.INK2
const GREEN := UiTheme.TRUE
const RED := UiTheme.FALSE
const YELLOW := UiTheme.GLOW
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
	return 150.0   # нөхцлийн ромбын хагас өргөн


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


## Нөхцлийн ромб (блок схемийн «шийдвэр»): үнэн бол ногоон, худал бол улаан.
func _draw_oval(mf: Font) -> void:
	var c := cond_center()
	var hh := 27.0
	var pts := PackedVector2Array([c + Vector2(0, -hh), c + Vector2(_rx(), 0), c + Vector2(0, hh), c + Vector2(-_rx(), 0)])
	var fill := UiTheme.COND_ACC.lerp(Color.WHITE, 0.82)
	if eval_state == 1:
		fill = UiTheme.TRUE_BG
	elif eval_state == 2:
		fill = UiTheme.FALSE_BG
	UiTheme.poly(self, pts, fill, true, true, 2.5)
	var txt := cond_text
	var col := UiTheme.INK
	if eval_state == 1:
		txt += "  → true"
		col = GREEN.darkened(0.2)
	elif eval_state == 2:
		txt += "  → false"
		col = RED.darkened(0.1)
	UiTheme.text_in(self, Rect2(c - Vector2(_rx(), hh), Vector2(_rx() * 2.0, hh * 2.0)), txt, 20, col, mf)


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
		if k == 0:
			draw_arc(p, 32.0, 0.0, TAU, 40, YELLOW.darkened(0.1), 4.0, true)   # хилийн утга
		UiTheme.circ(self, p, 25.0, UiTheme.TRUE_BG if on else UiTheme.CARD)
		if on:
			draw_arc(p, 25.0, 0.0, TAU, 40, GREEN, 3.0, true)
		UiTheme.text_in(self, Rect2(p - Vector2(30, 25), Vector2(60, 50)), str(v), 22, UiTheme.INK, mf)
		UiTheme.text_in(self, Rect2(p + Vector2(-40, 32), Vector2(80, 24)), "үнэн" if on else "худал", 16,
			GREEN.darkened(0.2) if on else UiTheme.MUTED, UiTheme.font("bold"))


func _draw() -> void:
	var font := UiTheme.font("bold")
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
		draw_polyline(path(active_side), UiTheme.INK, 8.0, true)
		draw_polyline(path(active_side), YELLOW, 5.0, true)
	# T / F шошго (үнэн / худал гэсэн монгол утгатай нь)
	var c := cond_center()
	UiTheme.chip_text(self, c + Vector2(_rx() + 52.0, -16.0), "T  үнэн", 15, GREEN, Color.WHITE, font, 0)
	UiTheme.chip_text(self, c + Vector2(-_rx() - 52.0, -16.0), "худал  F", 15, RED, Color.WHITE, font, 0)
	# Нийлэх цэг
	UiTheme.circ(self, Vector2(size.x / 2.0, size.y - 34.0), 6.0, UiTheme.INK2, false, false)
	# Блокийн хайрцгууд
	for side in [0, 1]:
		if not has_box(side):
			continue
		var bc := box_center(side)
		var r := Rect2(bc - Vector2(BOX_W, BOX_H) / 2.0, Vector2(BOX_W, BOX_H))
		var ran: bool = flash_side == side
		draw_style_box(UiTheme.paper(UiTheme.TRUE_BG if ran else UiTheme.CARD, 8, 3 if ran else 2,
			GREEN if ran else UiTheme.INK, 4), r)
		draw_rect(Rect2(r.position + Vector2(3, 3), Vector2(6, r.size.y - 6)), UiTheme.VAR_ACC)
		var stmt := t_stmt if side == 1 else f_stmt
		UiTheme.text_in(self, r, stmt, 20, UiTheme.INK, mf)
	_draw_oval(mf)
	# Тоглогчийн сонголтын тэмдэг
	if chosen_side != -1:
		var mark := "✓" if chosen_ok else "✗"
		var mp := Vector2(_branch_x(chosen_side) + (34.0 if chosen_side == 1 else -60.0), c.y + 46.0)
		draw_string(font, mp, mark, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, GREEN if chosen_ok else RED)
	# Утгын токен
	if token_visible:
		UiTheme.circ(self, token_pos, 20.0, YELLOW)
		UiTheme.text_in(self, Rect2(token_pos - Vector2(30, 20), Vector2(60, 40)), token_text, 18, UiTheme.INK, mf)
