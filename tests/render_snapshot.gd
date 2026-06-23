extends SceneTree

const SNAPSHOT_PATH := "user://render_snapshot.png"

func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/Main.tscn")
	if packed == null:
		push_error("Could not load Main.tscn")
		quit(1)
		return

	var scene: Node = packed.instantiate()
	root.add_child(scene)
	await process_frame
	scene._hit_shuttle(scene.PLAYER_SIDE, "clear")
	for i in range(12):
		scene._physics_process(1.0 / 60.0)
		await process_frame

	var viewport_texture := root.get_viewport().get_texture()
	if viewport_texture == null:
		push_error("Viewport texture is unavailable. Run this script without --headless for pixel verification.")
		quit(1)
		return

	var image := viewport_texture.get_image()
	if image == null or image.is_empty():
		push_error("Could not capture viewport image")
		quit(1)
		return

	image.save_png(SNAPSHOT_PATH)
	var min_luma := 10.0
	var max_luma := -10.0
	var alpha_sum := 0.0
	var color_spread := 0.0
	var sample_count := 0
	for x in range(120, image.get_width(), 160):
		for y in range(80, image.get_height(), 120):
			var color := image.get_pixel(x, y)
			var luma := color.r * 0.299 + color.g * 0.587 + color.b * 0.114
			min_luma = minf(min_luma, luma)
			max_luma = maxf(max_luma, luma)
			alpha_sum += color.a
			color_spread += absf(color.r - color.g) + absf(color.g - color.b)
			sample_count += 1

	var luma_range := max_luma - min_luma
	var average_alpha := alpha_sum / float(sample_count)
	var average_spread := color_spread / float(sample_count)
	if luma_range < 0.12 or average_alpha < 0.95 or average_spread < 0.03:
		push_error("Snapshot looks too flat; render may be blank")
		quit(1)
		return

	print("Render snapshot saved to %s luma_range=%.3f color_spread=%.3f" % [ProjectSettings.globalize_path(SNAPSHOT_PATH), luma_range, average_spread])
	quit()
