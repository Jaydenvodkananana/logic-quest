class_name GuardView
extends Control
## Хамгаалагч, дараалалд зогсох хүмүүс, хаалгыг зурж, шалгалтыг хөдөлгөөнөөр үзүүлнэ.

class Person extends RefCounted:
	var age: int = 0
	var ticket: int = 0
	var pos: Vector2 = Vector2.ZERO
	var alpha: float = 1.0
	var mark: int = 0   # 0 хоосон, 1 зөв, 2 буруу
	var shirt: Color = Color(0.3, 0.5, 0.8)
	var skin: Color = Color(0.9, 0.75, 0.6)

const SPACING := 76.0
const SHIRTS := [Color(0.3, 0.5, 0.8), Color(0.75, 0.35, 0.35), Color(0.35, 0.65, 0.45), Color(0.7, 0.55, 0.25), Color(0.55, 0.4, 0.7)]
const SKINS := [Color(0.92, 0.76, 0.62), Color(0.8, 0.6, 0.45), Color(0.6, 0.42, 0.3), Color(0.95, 0.82, 0.7)]

var speed := 1.0
var running := false
var show_ticket := false
var people: Array = []
var door_open := 0.0
var guard_stop := false
var bubble_text := ""
var bubble_color := Color.WHITE
var sign_text := ""


func _ready() -> void:
	custom_minimum_size = Vector2(560, 300)
	clip_contents = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL


func _process(_delta: float) -> void:
	queue_redraw()


func _d(t: float) -> float:
	return maxf(0.001, t * speed)


func _ground() -> float:
	return size.y - 40.0


func _door_x() -> float:
	return size.x - 130.0


func _guard_x() -> float:
	return _door_x() - 95.0


func _spot_x() -> float:
	return _guard_x() - 75.0


func reset() -> void:
	people.clear()
	door_open = 0.0
	guard_stop = false
	bubble_text = ""
	running = false


func show_crowd(crowd: Array, two: bool) -> void:
	show_ticket = two
	door_open = 0.0
	guard_stop = false
	bubble_text = ""
	_build_people(crowd)


func _build_people(crowd: Array) -> void:
	people.clear()
	for k in crowd.size():
		var c: Dictionary = crowd[k]
		var p := Person.new()
		p.age = c.age
		p.ticket = c.ticket
		p.pos = Vector2(_spot_x() - k * SPACING, _ground())
		p.shirt = SHIRTS[k % SHIRTS.size()]
		p.skin = SKINS[(k * 3 + 1) % SKINS.size()]
		people.append(p)


## judge: Callable(Dictionary{age, ticket}) -> {allowed, expect, text}. Буцаах: {let_in, denied, wrong: [{age, ticket}]}
func run_test(crowd: Array, two: bool, free: bool, judge: Callable) -> Dictionary:
	running = true
	show_ticket = two
	guard_stop = false
	door_open = 0.0
	bubble_text = ""
	_build_people(crowd)
	var result := {"let_in": 0, "denied": 0, "wrong": []}
	await get_tree().process_frame
	for i in people.size():
		var p: Person = people[i]
		var verdict: Dictionary = judge.call({"age": p.age, "ticket": p.ticket})
		var allowed: bool = verdict.allowed
		bubble_text = verdict.text
		if free:
			bubble_color = Color(0.9, 0.9, 1.0)
		else:
			bubble_color = Color(0.5, 0.95, 0.55) if allowed else Color(1.0, 0.5, 0.5)
		await get_tree().create_timer(_d(0.6)).timeout
		if not free:
			var ok: bool = verdict.expect == allowed
			p.mark = 1 if ok else 2
			if not ok:
				result.wrong.append({"age": p.age, "ticket": p.ticket})
		if allowed:
			result.let_in += 1
			var tw := create_tween().set_parallel(true)
			tw.tween_property(self, "door_open", 1.0, _d(0.2))
			tw.tween_property(p, "pos", Vector2(_door_x(), p.pos.y), _d(0.6))
			tw.tween_property(p, "alpha", 0.0, _d(0.4)).set_delay(_d(0.25))
			await tw.finished
			create_tween().tween_property(self, "door_open", 0.0, _d(0.2))
		else:
			result.denied += 1
			guard_stop = true
			var tw2 := create_tween().set_parallel(true)
			tw2.tween_property(p, "pos", p.pos + Vector2(-30.0, -50.0), _d(0.7))
			tw2.tween_property(p, "alpha", 0.0, _d(0.7))
			await tw2.finished
			guard_stop = false
		if i + 1 < people.size():
			var shift := create_tween().set_parallel(true)
			for k in range(i + 1, people.size()):
				var q: Person = people[k]
				shift.tween_property(q, "pos", q.pos + Vector2(SPACING, 0.0), _d(0.3))
			await shift.finished
	bubble_text = ""
	running = false
	return result


func _draw() -> void:
	var font := get_theme_default_font()
	var w := size.x
	var g := _ground()
	var dx := _door_x()
	draw_rect(Rect2(0.0, 0.0, w, size.y), Color(0.08, 0.1, 0.18))
	draw_rect(Rect2(0.0, g, w, size.y - g), Color(0.17, 0.19, 0.22))
	var bx := dx - 90.0
	draw_rect(Rect2(bx, g - 190.0, w - bx - 6.0, 190.0), Color(0.27, 0.21, 0.32))
	draw_rect(Rect2(bx + 6.0, g - 184.0, w - bx - 18.0, 32.0), Color(0.07, 0.07, 0.1))
	draw_string(font, Vector2(bx + 6.0, g - 162.0), sign_text, HORIZONTAL_ALIGNMENT_CENTER, w - bx - 18.0, 15, Color(1.0, 0.9, 0.4))
	draw_rect(Rect2(dx - 45.0, g - 130.0, 90.0, 130.0), Color(0.03, 0.03, 0.05))
	draw_rect(Rect2(dx - 45.0, g - 130.0, 90.0 * (1.0 - door_open), 130.0), Color(0.55, 0.35, 0.2))
	_draw_guard(g)
	for p in people:
		_draw_person(font, p)
	if bubble_text != "":
		var rx := maxf(4.0, _guard_x() - 260.0)
		var r := Rect2(rx, g - 240.0, 310.0, 34.0)
		draw_rect(r, Color(0.04, 0.04, 0.07, 0.92))
		draw_rect(r, bubble_color, false, 2.0)
		draw_string(font, Vector2(rx, g - 240.0 + 24.0), bubble_text, HORIZONTAL_ALIGNMENT_CENTER, 310.0, 18, bubble_color)


func _draw_guard(g: float) -> void:
	var x := _guard_x()
	var leg := Color(0.14, 0.14, 0.24)
	var armor := Color(0.25, 0.35, 0.68)
	var skin := Color(0.9, 0.75, 0.6)
	# жад
	draw_line(Vector2(x + 36.0, g), Vector2(x + 36.0, g - 175.0), Color(0.6, 0.5, 0.35), 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(x + 30.0, g - 175.0), Vector2(x + 42.0, g - 175.0), Vector2(x + 36.0, g - 197.0)]), Color(0.8, 0.82, 0.88))
	# хөл, бие
	draw_line(Vector2(x - 11.0, g), Vector2(x - 11.0, g - 42.0), leg, 9.0)
	draw_line(Vector2(x + 11.0, g), Vector2(x + 11.0, g - 42.0), leg, 9.0)
	draw_rect(Rect2(x - 26.0, g - 104.0, 52.0, 64.0), armor)
	draw_rect(Rect2(x - 26.0, g - 66.0, 52.0, 8.0), Color(0.8, 0.7, 0.2))
	# гар
	draw_line(Vector2(x + 26.0, g - 96.0), Vector2(x + 36.0, g - 70.0), armor, 8.0)
	if guard_stop:
		draw_line(Vector2(x - 26.0, g - 96.0), Vector2(x - 52.0, g - 136.0), armor, 8.0)
		draw_circle(Vector2(x - 54.0, g - 142.0), 9.0, skin)
	else:
		draw_line(Vector2(x - 26.0, g - 96.0), Vector2(x - 33.0, g - 62.0), armor, 8.0)
	# толгой, дуулга
	draw_circle(Vector2(x, g - 122.0), 18.0, skin)
	var pts := PackedVector2Array()
	for k in range(0, 11):
		var a := PI + PI * k / 10.0
		pts.append(Vector2(x + 21.0 * cos(a), g - 124.0 + 21.0 * sin(a)))
	draw_colored_polygon(pts, Color(0.55, 0.58, 0.65))
	draw_colored_polygon(PackedVector2Array([Vector2(x - 5.0, g - 144.0), Vector2(x + 5.0, g - 144.0), Vector2(x, g - 162.0)]), Color(0.85, 0.2, 0.2))


func _draw_person(font: Font, p: Person) -> void:
	var a := p.alpha
	var x := p.pos.x
	var g := p.pos.y
	var skin := Color(p.skin.r, p.skin.g, p.skin.b, a)
	var shirt := Color(p.shirt.r, p.shirt.g, p.shirt.b, a)
	var pants := Color(0.2, 0.2, 0.3, a)
	draw_line(Vector2(x - 6.0, g), Vector2(x - 6.0, g - 34.0), pants, 6.0)
	draw_line(Vector2(x + 6.0, g), Vector2(x + 6.0, g - 34.0), pants, 6.0)
	draw_rect(Rect2(x - 13.0, g - 72.0, 26.0, 40.0), shirt)
	draw_line(Vector2(x - 13.0, g - 68.0), Vector2(x - 20.0, g - 42.0), skin, 5.0)
	draw_line(Vector2(x + 13.0, g - 68.0), Vector2(x + 20.0, g - 42.0), skin, 5.0)
	draw_circle(Vector2(x, g - 86.0), 14.0, skin)
	draw_string(font, Vector2(x - 30.0, g - 106.0), str(p.age), HORIZONTAL_ALIGNMENT_CENTER, 60.0, 20, Color(1.0, 1.0, 1.0, a))
	if show_ticket and p.ticket == 1:
		draw_rect(Rect2(x + 17.0, g - 52.0, 20.0, 13.0), Color(1.0, 0.85, 0.3, a))
		draw_line(Vector2(x + 22.0, g - 45.0), Vector2(x + 32.0, g - 45.0), Color(0.5, 0.3, 0.0, a), 2.0)
	if p.mark == 2:
		draw_arc(Vector2(x, g - 52.0), 52.0, 0.0, TAU, 32, Color(1.0, 0.3, 0.3, a), 3.0)
	elif p.mark == 1:
		draw_arc(Vector2(x, g - 52.0), 52.0, 0.0, TAU, 32, Color(0.4, 0.9, 0.5, a), 3.0)
