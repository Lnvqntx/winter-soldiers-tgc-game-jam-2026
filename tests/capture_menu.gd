extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	print("Capturing 1280x720 Main Menu Screenshots with Focus/Hover...")
	root.size = Vector2i(1280, 720)
	
	var menu_scene = load("res://scenes/main_menu.tscn")
	var menu_inst = menu_scene.instantiate()
	root.add_child(menu_inst)
	
	for i in range(35):
		await process_frame
	
	# 1. Normal state
	var img: Image = root.get_texture().get_image()
	img.save_png("assets/main_menu_preview.png")

	# 2. Hover on Credits
	menu_inst.credits_btn.grab_focus()
	menu_inst.credits_btn.mouse_entered.emit()
	for i in range(15):
		await process_frame
	var img_cred: Image = root.get_texture().get_image()
	img_cred.save_png("assets/main_menu_credits_hover.png")

	# 3. Hover on Exit
	menu_inst.exit_btn.grab_focus()
	menu_inst.exit_btn.mouse_entered.emit()
	for i in range(15):
		await process_frame
	var img_exit: Image = root.get_texture().get_image()
	img_exit.save_png("assets/main_menu_exit_hover.png")

	print("Saved all hover screenshots successfully!")
	quit(0)
