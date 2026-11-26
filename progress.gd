class_name Progress
extends RefCounted
## Тоглогчийн ахиц: хэдэн түвшин нээгдсэн, түвшин бүрийн хамгийн сайн од (0-3).
## user://progress.cfg-д хадгалагдана, тоглоом хаагдсан ч алга болохгүй.

const DEFAULT_PATH := "user://progress.cfg"

var path := DEFAULT_PATH
var unlocked := 1        # нээлттэй түвшний тоо (эхний түвшин үргэлж нээлттэй)
var stars: Array = []    # түвшин бүрт 0 = давж амжаагүй, 1-3 = од


func _init(level_count: int, file_path: String = DEFAULT_PATH) -> void:
	path = file_path
	stars.resize(level_count)
	stars.fill(0)
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	unlocked = clampi(int(cfg.get_value("progress", "unlocked", 1)), 1, level_count)
	var saved: Array = cfg.get_value("progress", "stars", [])
	for i in mini(saved.size(), level_count):
		stars[i] = clampi(int(saved[i]), 0, 3)


func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.set_value("progress", "stars", stars)
	cfg.save(path)


## Түвшин i давагдлаа: хамгийн сайн одыг хадгалж, дараагийн түвшнийг нээнэ.
func record(i: int, star_count: int) -> void:
	stars[i] = maxi(stars[i], clampi(star_count, 1, 3))
	unlocked = clampi(maxi(unlocked, i + 2), 1, stars.size())
	save()


func is_open(i: int) -> bool:
	return i < unlocked


## Алдааны тооноос од: 0 алдаа = 3, 1-2 алдаа = 2, түүнээс олон = 1.
static func stars_for(mistakes: int) -> int:
	if mistakes <= 0:
		return 3
	return 2 if mistakes <= 2 else 1
