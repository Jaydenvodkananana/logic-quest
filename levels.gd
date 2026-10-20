class_name Levels
extends RefCounted
## 1-р хэсгийн түвшингүүд. Тоонууд оролдлого бүрт санамсаргүй өөрчлөгдөнө ({A}, {B}... нь параметр).
## mode "predict": `ask` хувьсагчийн эцсийн утгыг таа.
## mode "arrange": мөрүүдийг зөв дараалалд оруулж `goal_var`-г {G} болго.
## mode "guard": хамгаалагчийн дүрмийг өөрөө бүтээ.


static func get_levels() -> Array:
	return [
		{
			"title": "Хайрцаг: үзүүлэн заавар",
			"mode": "tutorial",
			"story": "Хувьсагч бол утга хадгалдаг хайрцаг. Алхам бүрийг нэг нэгээр нь үзээрэй.",
			"hint": "",
		},
		{
			"title": "Хуулбар, холбоос биш",
			"mode": "predict",
			"ask": "b",
			"params": {"A": [2, 9], "B": [1, 5]},
			"story": "Хувьсагч бол НЭГ утга хадгалдаг хайрцаг. '=' нь «тэнцүү» гэсэн үг биш. Энэ нь: баруун талыг бодоод, үр дүнг зүүн талын хайрцагт хадгал гэсэн үг.",
			"hint": "'b = a' нь a-н утгыг b хайрцагт ХУУЛСАН. Дараа нь a өөрчлөгдсөн ч b өөрчлөгдөхгүй. Хайрцгууд хэзээ ч хоорондоо холбогдоогүй.",
			"lines": ["a = {A}", "b = a", "a = a + {B}"],
		},
		{
			"title": "a = a + 1 бол математикийн худал биш",
			"mode": "predict",
			"ask": "count",
			"params": {"A": [2, 8], "B": [2, 4]},
			"story": "Математикт a = a + 1 боломжгүй. Кодод энэ бол заавар: хуучин утгыг ав, нэм, тэр хайрцагтаа буцааж хадгал.",
			"hint": "Мөр бүр хайрцгийг уншиж, бодож, хуучин утгыг дарж бичдэг. 'a = a + 1' нь тэгшитгэл биш, заавар.",
			"lines": ["count = {A}", "count = count + 1", "count = count + {B}"],
		},
		{
			"title": "Үйлдлүүд",
			"mode": "predict",
			"ask": "w",
			"params": {"X": [11, 29], "D": [2, 4]},
			"nonzero_rem": ["X", "D"],
			"story": "Бүхэл тоо таны мэдэх тооны машинаас өөрөөр ажилладаг. '/' үлдэгдлийг хаядаг, '%' зөвхөн үлдэгдлийг өгдөг. w-г олохын тулд хоёуланг нь ойлгох хэрэгтэй.",
			"hint": "'/' бүхэл тоон дээр үлдэгдлийг хаядаг, '%' зөвхөн үлдэгдлийг өгдөг. w-г бодохын тулд y ба z хоёулаа хэрэгтэй байсан.",
			"lines": ["x = {X}", "y = x / {D}", "z = x % {D}", "w = y * 10 + z"],
		},
		{
			"title": "Дараалал чухал",
			"mode": "arrange",
			"goal_var": "total",
			"params": {"A": [2, 5], "B": [2, 4], "C": [1, 9]},
			"story": "Мөрүүд дээрээс доош нэг нэгээр ажиллана. Мөр сонгоод Дээш/Доош товчоор зөөж, 'total' төгсгөлд {G} болгоорой. Зөвлөгөө: юу ч засахаасаа өмнө Эхлэх товчийг дарж үзээрэй.",
			"hint": "Хайрцагт утга байж байж л ашиглаж болно. total = {A}, дараа нь * {B}, дараа нь + {C} нийлээд {G} болно.",
			"lines": ["total = {A}", "total = total * {B}", "total = total + {C}"],
		},
		{
			"title": "Нөхцөл: Хамгаалагч",
			"mode": "guard",
			"rules": 1,
			"params": {"T": [16, 21]},
			"story": "Манай клубт {T} ба түүнээс дээш настай хүн орно. Хамгаалагчийн дүрмийг тохируулаад Турших товчийг дар. Хамгаалагч шинэ хүмүүсийг нэг нэгээр нь шалгана.",
			"hint": "'>' нь {T}-г оруулдаггүй, '>=' оруулдаг. Яг хилийн настай хүн л ялгааг гаргадаг. Хилийн утгыг үргэлж шалга.",
		},
		{
			"title": "Хоёр дүрэм (and / or)",
			"mode": "guard",
			"rules": 2,
			"params": {"T": [16, 21]},
			"story": "Одоо {T} ба түүнээс дээш настай БӨГӨӨД тасалбартай хүн л орно. ticket: 1 = тасалбартай, 0 = тасалбаргүй. Хоёр нөхцөлийг 'and' эсвэл 'or'-оор холбоно.",
			"hint": "'and' нь хоёр нөхцөл ХОЁУЛАА үнэн байхыг шаарддаг. 'or' нь аль нэг нь үнэн бол хангалттай.",
		},
		{
			"title": "Boss: Киноны билетийн үнэ",
			"mode": "cinema",
			"story": "Киноны театрын билетийн үнийг бод. Үндсэн үнэ: хүүхэд (нас 12-оос бага) 8$, насанд хүрэгч (12-64) 15$, ахмад (65+) 10$. Мягмар гарагт (day = 2) үндсэн үнээс 2$ хасна. Купонтой (coupon = 1) бол өдрийн хөнгөлөлтийн ДАРАА үнээс 10% хасна. Бөглөөд Турших товчийг дар.",
			"hint": "Жишээ: 70 нас, баасан гараг, купонтой -> 10 * 0.9 = 9. Хилийн насууд (11, 12, 64, 65) болон «10% хасах = 0.9-өөр үржүүлэх» гэдгийг санаарай.",
		},
		{
			"title": "Өөрийн клуб",
			"mode": "guard",
			"rules": 2,
			"free": true,
			"story": "Одоо өөрөө зохио! Өөрийн клубийн дүрмийг бич: хэнийг оруулах вэ? Турших товчоор шинэ хүмүүс дээр шалга. Зөв, буруу гэж байхгүй: дүрэм чинь яг хүссэн зүйлээ хийж байгаа эсэхийг л хар.",
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
		inst.solution = lines.duplicate()
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
