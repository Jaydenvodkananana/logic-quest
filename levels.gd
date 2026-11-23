class_name Levels
extends RefCounted
## 1-р хэсгийн түвшингүүд. Тоонууд оролдлого бүрт санамсаргүй өөрчлөгдөнө ({A}, {B}... нь параметр).
## Програмын мөрүүд C++ хэлээр бичигдэнэ (Interp-ийг үз).
## mode "predict": `ask` хувьсагчийн эцсийн утгыг таа.
## mode "arrange": мөрүүдийг зөв дараалалд оруулж `goal_var`-г {G} болго.
## mode "guard": хамгаалагчийн дүрмийг өөрөө бүтээ.
## mode "flow": if / if-else-ийн блок схем. Тайлбар (3 алхам) + мини тест (3 зөв хариулт).
##   kind "if"/"ifelse", in_var/out_var хувьсагч, t_val/f_val блокийн өгөх утга, {T} хил, ops операторууд.


static func get_levels() -> Array:
	return [
		{
			"title": "Хайрцаг",
			"mode": "tutorial",
			"story": "Хувьсагч = нэртэй хайрцаг.",
			"hint": "",
		},
		{
			"title": "Хуулбар",
			"mode": "predict",
			"ask": "b",
			"params": {"A": [2, 9], "B": [1, 5]},
			"story": "b хайрцаг a-г дагах уу?",
			"hint": "int b = a; нь утгыг хуулна. Хайрцгууд холбогдохгүй.",
			"lines": ["int a = {A};", "int b = a;", "a = a + {B};"],
		},
		{
			"title": "Шинэчлэх",
			"mode": "predict",
			"ask": "count",
			"params": {"A": [2, 8], "B": [2, 4]},
			"story": "Хайрцаг өөрийн утгаа ашиглаж болно.",
			"hint": "count = count + 1; хуучин утгыг уншиж, нэмээд дарж бичнэ.",
			"lines": ["int count = {A};", "count = count + 1;", "count = count + {B};"],
		},
		{
			"title": "/ ба %",
			"mode": "predict",
			"ask": "w",
			"params": {"X": [11, 29], "D": [2, 4]},
			"nonzero_rem": ["X", "D"],
			"story": "int:   17 / 3 = 5,   17 % 3 = 2",
			"hint": "int-д / үлдэгдлийг хаяна, % зөвхөн үлдэгдлийг өгнө.",
			"lines": ["int x = {X};", "int y = x / {D};", "int z = x % {D};", "int w = y * 10 + z;"],
		},
		{
			"title": "Дараалал",
			"mode": "arrange",
			"goal_var": "total",
			"params": {"A": [2, 5], "B": [2, 4], "C": [1, 9]},
			"story": "total = {G} болго. Мөрөө чирж зөө (W / S).",
			"hint": "Эхлээд зарла, дараа нь ашигла:  {A} * {B} + {C} = {G}",
			"lines": ["int total = {A};", "total = total * {B};", "total = total + {C};"],
		},
		{
			"title": "if",
			"mode": "flow",
			"kind": "if",
			"in_var": "temp",
			"out_var": "fan",
			"t_val": 1,
			"f_val": 0,
			"params": {"T": [25, 32]},
			"ops": [">", ">=", "=="],
			"explain_ops": true,   # тайлбарт оператор бүрийг тоон шулуунаар үзүүлнэ; тест хил орчмын утгаар
			"story": "Халуун бол сэнс асна.",
			"hint": "if: үнэн бол блок ажиллана, худал бол алгасна.  > тэнцүүг оруулахгүй, >= оруулна, == зөвхөн тэнцүү.",
		},
		{
			"title": "if / else",
			"mode": "flow",
			"kind": "ifelse",
			"in_var": "score",
			"out_var": "pass",
			"t_val": 1,
			"f_val": 0,
			"params": {"T": [50, 70]},
			"ops": [">=", ">", "<=", "<"],
			"story": "Оноо хүрвэл тэнцэнэ, үгүй бол тэнцэхгүй.",
			"hint": "if / else: хоёр замын яг нэг нь ажиллана.",
		},
		{
			"title": "Хоёр дүрэм (&& / ||)",
			"mode": "guard",
			"rules": 2,
			"params": {"T": [16, 21]},
			"story": "Одоо {T} ба түүнээс дээш настай БӨГӨӨД тасалбартай хүн л орно. ticket: 1 = тасалбартай, 0 = тасалбаргүй. Хоёр нөхцөлийг C++-ийн '&&' (БӨГӨӨД) эсвэл '||' (ЭСВЭЛ)-оор холбоно.",
			"hint": "'&&' нь хоёр нөхцөл ХОЁУЛАА үнэн байхыг шаарддаг. '||' нь аль нэг нь үнэн бол хангалттай.",
		},
		{
			"title": "Сорилт ⚔ (нэмэлт)",
			"mode": "challenge",
			"optional": true,
			"story": "",
			"hint": "",
		},
	]


static func make(tpl: Dictionary) -> Dictionary:
	var inst: Dictionary = tpl.duplicate(true)
	var vals := {}
	var tries := 0
	while true:
		vals = {}
		var params: Dictionary = tpl.get("params", {})
		for k in params:
			var r: Array = params[k]
			vals[k] = randi_range(r[0], r[1])
		tries += 1
		if tries > 100 or not tpl.has("nonzero_rem"):
			break
		var pair: Array = tpl.nonzero_rem
		if vals[pair[0]] % vals[pair[1]] != 0:
			break
	var lines: Array = []
	for l in tpl.get("lines", []):
		lines.append(_fmt(l, vals))
	inst.lines = lines
	if tpl.mode == "arrange":
		var ip := Interp.new()
		ip.load_program(lines)
		while not ip.is_done():
			ip.step()
		inst.goal = ip.vars.get(tpl.goal_var)
		vals["G"] = inst.goal
		var shuffled := lines.duplicate()
		var n := 0
		while n < 50:
			shuffled.shuffle()
			if shuffled != lines:
				break
			n += 1
		inst.lines = shuffled
	inst.story = _fmt(tpl.story, vals)
	inst.hint = _fmt(tpl.hint, vals)
	inst.vals = vals
	return inst


static func _fmt(s: String, vals: Dictionary) -> String:
	var out := s
	for k in vals:
		out = out.replace("{%s}" % k, str(vals[k]))
	return out
