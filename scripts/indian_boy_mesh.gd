class_name IndianBoyMesh
extends RefCounted

## Utility class that transforms the UAL1_Standard model into an authentic,
## stylized teenage Indian boy character with hair, face, traditional kurta-shirt,
## denim jeans, kalava wristband, watch, sling satchel, and leather sandals.

# Color palette
const SKIN_COLOR := Color(0.72, 0.48, 0.32, 1.0) # Warm golden-brown Indian skin tone
const HAIR_COLOR := Color(0.10, 0.08, 0.07, 1.0) # Jet dark brown/black textured hair
const KURTA_COLOR := Color(0.92, 0.46, 0.12, 1.0) # Vibrant marigold / saffron orange cotton
const KURTA_TRIM := Color(0.96, 0.78, 0.28, 1.0) # Golden yellow embroidery trim
const JEANS_COLOR := Color(0.18, 0.26, 0.38, 1.0) # Classic dark indigo denim
const JEANS_CUFF := Color(0.24, 0.33, 0.46, 1.0) # Lighter rolled denim cuff
const LEATHER_COLOR := Color(0.42, 0.24, 0.14, 1.0) # Rich rustic brown leather
const BRASS_GOLD := Color(0.88, 0.75, 0.25, 1.0) # Brass buckles & buttons
const KALAVA_RED := Color(0.88, 0.18, 0.14, 1.0) # Sacred red thread
const KALAVA_GOLD := Color(0.95, 0.75, 0.15, 1.0) # Sacred yellow thread
const WATCH_BLACK := Color(0.14, 0.14, 0.16, 1.0) # Digital sports watch
const EYE_WHITE := Color(0.98, 0.98, 0.98, 1.0)
const EYE_IRIS := Color(0.22, 0.14, 0.08, 1.0) # Deep warm brown eyes
const EYE_PUPIL := Color(0.05, 0.05, 0.05, 1.0)
const TILAK_RED := Color(0.85, 0.15, 0.12, 1.0) # Auspicious vermilion tilak

static func setup_character(character_model: Node3D) -> void:
	if not character_model:
		return
	
	var skel: Skeleton3D = character_model.find_child("Skeleton3D", true, false)
	var mannequin: MeshInstance3D = character_model.find_child("Mannequin", true, false)
	
	if mannequin and skel:
		_recolor_mannequin(mannequin, skel)
	
	if skel:
		_attach_teenage_features(skel)

## Custom vertex colors & materials on the underlying skinned mesh
static func _recolor_mannequin(mesh_inst: MeshInstance3D, skel: Skeleton3D) -> void:
	var orig_mesh: ArrayMesh = mesh_inst.mesh
	if not orig_mesh:
		return
	
	var new_mesh := ArrayMesh.new()
	
	for s in range(orig_mesh.get_surface_count()):
		var arr = orig_mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arr[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arr[Mesh.ARRAY_WEIGHTS]
		
		var colors := PackedColorArray()
		colors.resize(verts.size())
		
		for i in range(verts.size()):
			# Find dominant bone
			var max_w := 0.0
			var dominant_bone := 0
			for b in range(4):
				var w = weights[i * 4 + b]
				if w > max_w:
					max_w = w
					dominant_bone = bones[i * 4 + b]
			
			var bname := skel.get_bone_name(dominant_bone)
			colors[i] = _get_vertex_color(bname, s)
		
		arr[Mesh.ARRAY_COLOR] = colors
		new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		
		var mat := StandardMaterial3D.new()
		mat.vertex_color_use_as_albedo = true
		mat.roughness = 0.72
		new_mesh.surface_set_material(s, mat)
	
	mesh_inst.mesh = new_mesh

static func _get_vertex_color(bname: String, surface_idx: int) -> Color:
	# Head and Neck -> Warm Indian skin
	if bname == "Head" or bname == "neck_01":
		return SKIN_COLOR
	
	# Hands and Forearms -> Warm Indian skin
	if bname in ["lowerarm_l", "lowerarm_r", "hand_l", "hand_r"] or "thumb" in bname or "index" in bname or "middle" in bname or "ring" in bname or "pinky" in bname:
		return SKIN_COLOR
	
	# Upper arms and Clavicles -> Kurta sleeves
	if bname in ["upperarm_l", "upperarm_r", "clavicle_l", "clavicle_r"]:
		return KURTA_TRIM if surface_idx == 1 else KURTA_COLOR
	
	# Torso & Chest -> Vibrant Saffron/Marigold Kurta
	if bname in ["spine_01", "spine_02", "spine_03"]:
		return KURTA_TRIM if surface_idx == 1 else KURTA_COLOR
	
	# Pelvis, Thighs, Calves -> Denim Jeans
	if bname in ["pelvis", "thigh_l", "thigh_r", "calf_l", "calf_r"]:
		return JEANS_CUFF if surface_idx == 1 else JEANS_COLOR
	
	# Feet -> Indian leather sandals
	if bname in ["foot_l", "foot_r", "ball_l", "ball_r"]:
		return LEATHER_COLOR
	
	return SKIN_COLOR

## Attach detailed 3D meshes for hair, facial features, kurta collar/placket, satchel, and accessories
static func _attach_teenage_features(skel: Skeleton3D) -> void:
	# Prevent duplicate attachments if re-run
	if skel.find_child("IndianBoy_HeadAttachment", false, false):
		return
	
	_build_head_features(skel)
	_build_torso_features(skel)
	_build_arm_accessories(skel)
	_build_leg_features(skel)

static func _create_material(color: Color, roughness: float = 0.6, specular: float = 0.5) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.specular_mode = StandardMaterial3D.SPECULAR_SCHLICK_GGX
	mat.metallic_specular = specular
	return mat

static func _build_head_features(skel: Skeleton3D) -> void:
	var head_att := BoneAttachment3D.new()
	head_att.name = "IndianBoy_HeadAttachment"
	head_att.bone_name = "Head"
	skel.add_child(head_att)
	
	var mat_hair := _create_material(HAIR_COLOR, 0.85, 0.2)
	var mat_skin := _create_material(SKIN_COLOR, 0.65, 0.3)
	var mat_eye_white := _create_material(EYE_WHITE, 0.2, 0.8)
	var mat_eye_iris := _create_material(EYE_IRIS, 0.3, 0.7)
	var mat_eye_pupil := _create_material(EYE_PUPIL, 0.2, 0.5)
	var mat_tilak := _create_material(TILAK_RED, 0.5, 0.2)
	
	# 1. Stylized Voluminous Indian Teen Hair
	# Top main hair cap
	var hair_top := MeshInstance3D.new()
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 0.165
	cap_mesh.height = 0.24
	cap_mesh.material = mat_hair
	hair_top.mesh = cap_mesh
	hair_top.transform.origin = Vector3(0.0, 0.09, -0.015)
	hair_top.scale = Vector3(1.05, 0.95, 1.1)
	head_att.add_child(hair_top)
	
	# Front side-swept quiff fringe (signature youthful Indian teen look)
	var fringe := MeshInstance3D.new()
	var f_mesh := BoxMesh.new()
	f_mesh.size = Vector3(0.18, 0.08, 0.12)
	f_mesh.material = mat_hair
	fringe.mesh = f_mesh
	fringe.transform.origin = Vector3(-0.02, 0.12, 0.09)
	fringe.rotation = Vector3(deg_to_rad(-18), deg_to_rad(-12), deg_to_rad(8))
	head_att.add_child(fringe)
	
	# Front left bang curl
	var bang_l := MeshInstance3D.new()
	var bl_mesh := BoxMesh.new()
	bl_mesh.size = Vector3(0.09, 0.07, 0.08)
	bl_mesh.material = mat_hair
	bang_l.mesh = bl_mesh
	bang_l.transform.origin = Vector3(0.06, 0.09, 0.11)
	bang_l.rotation = Vector3(deg_to_rad(-22), deg_to_rad(15), deg_to_rad(-14))
	head_att.add_child(bang_l)
	
	# Sideburns (Left & Right)
	for side in [-1.0, 1.0]:
		var sideburn := MeshInstance3D.new()
		var sb_mesh := BoxMesh.new()
		sb_mesh.size = Vector3(0.035, 0.10, 0.06)
		sb_mesh.material = mat_hair
		sideburn.mesh = sb_mesh
		sideburn.transform.origin = Vector3(side * 0.135, 0.01, 0.01)
		sideburn.rotation = Vector3(deg_to_rad(8), 0, deg_to_rad(side * -5))
		head_att.add_child(sideburn)
	
	# Back tapered neck hair
	var hair_back := MeshInstance3D.new()
	var hb_mesh := BoxMesh.new()
	hb_mesh.size = Vector3(0.19, 0.12, 0.08)
	hb_mesh.material = mat_hair
	hair_back.mesh = hb_mesh
	hair_back.transform.origin = Vector3(0.0, -0.01, -0.11)
	hair_back.rotation = Vector3(deg_to_rad(15), 0, 0)
	head_att.add_child(hair_back)
	
	# 2. Stylized Expressive Teenage Eyes
	for side in [-1.0, 1.0]:
		# Eye socket white
		var eye_w := MeshInstance3D.new()
		var ew_mesh := SphereMesh.new()
		ew_mesh.radius = 0.026
		ew_mesh.height = 0.042
		ew_mesh.material = mat_eye_white
		eye_w.mesh = ew_mesh
		eye_w.transform.origin = Vector3(side * 0.052, 0.035, 0.122)
		eye_w.scale = Vector3(1.1, 0.85, 0.5)
		head_att.add_child(eye_w)
		
		# Warm brown Iris
		var eye_i := MeshInstance3D.new()
		var ei_mesh := SphereMesh.new()
		ei_mesh.radius = 0.018
		ei_mesh.height = 0.032
		ei_mesh.material = mat_eye_iris
		eye_i.mesh = ei_mesh
		eye_i.transform.origin = Vector3(side * 0.052, 0.035, 0.134)
		eye_i.scale = Vector3(0.9, 0.9, 0.3)
		head_att.add_child(eye_i)
		
		# Dark pupil
		var eye_p := MeshInstance3D.new()
		var ep_mesh := SphereMesh.new()
		ep_mesh.radius = 0.010
		ep_mesh.height = 0.018
		ep_mesh.material = mat_eye_pupil
		eye_p.mesh = ep_mesh
		eye_p.transform.origin = Vector3(side * 0.052, 0.035, 0.139)
		eye_p.scale = Vector3(0.8, 0.8, 0.3)
		head_att.add_child(eye_p)
		
		# Eye specular catchlight (spark in the eye)
		var eye_h := MeshInstance3D.new()
		var eh_mesh := SphereMesh.new()
		eh_mesh.radius = 0.005
		eh_mesh.height = 0.008
		eh_mesh.material = mat_eye_white
		eye_h.mesh = eh_mesh
		eye_h.transform.origin = Vector3(side * 0.048, 0.042, 0.142)
		head_att.add_child(eye_h)
		
		# Youthful expressive Eyebrow
		var eyebrow := MeshInstance3D.new()
		var eb_mesh := BoxMesh.new()
		eb_mesh.size = Vector3(0.046, 0.014, 0.02)
		eb_mesh.material = mat_hair
		eyebrow.mesh = eb_mesh
		eyebrow.transform.origin = Vector3(side * 0.052, 0.065, 0.125)
		eyebrow.rotation = Vector3(deg_to_rad(-10), 0, deg_to_rad(side * -8))
		head_att.add_child(eyebrow)
	
	# 3. Stylized Nose & Youthful Smile
	var nose := MeshInstance3D.new()
	var n_mesh := SphereMesh.new()
	n_mesh.radius = 0.016
	n_mesh.height = 0.028
	n_mesh.material = mat_skin
	nose.mesh = n_mesh
	nose.transform.origin = Vector3(0.0, 0.012, 0.142)
	nose.scale = Vector3(0.8, 1.1, 1.2)
	head_att.add_child(nose)
	
	# Friendly smile
	var mouth := MeshInstance3D.new()
	var m_mesh := BoxMesh.new()
	m_mesh.size = Vector3(0.042, 0.009, 0.014)
	m_mesh.material = _create_material(Color(0.55, 0.25, 0.20), 0.6)
	mouth.mesh = m_mesh
	mouth.transform.origin = Vector3(0.0, -0.026, 0.128)
	mouth.rotation = Vector3(deg_to_rad(-6), 0, 0)
	head_att.add_child(mouth)
	
	# 4. Auspicious Red Tilak / Tika Dot on Forehead
	var tilak := MeshInstance3D.new()
	var t_mesh := BoxMesh.new()
	t_mesh.size = Vector3(0.014, 0.024, 0.01)
	t_mesh.material = mat_tilak
	tilak.mesh = t_mesh
	tilak.transform.origin = Vector3(0.0, 0.068, 0.134)
	tilak.rotation = Vector3(deg_to_rad(-14), 0, 0)
	head_att.add_child(tilak)

static func _build_torso_features(skel: Skeleton3D) -> void:
	var chest_att := BoneAttachment3D.new()
	chest_att.name = "IndianBoy_ChestAttachment"
	chest_att.bone_name = "spine_03"
	skel.add_child(chest_att)
	
	var mat_kurta_collar := _create_material(KURTA_COLOR, 0.7)
	var mat_trim := _create_material(KURTA_TRIM, 0.5, 0.6)
	var mat_button := _create_material(BRASS_GOLD, 0.3, 0.8)
	var mat_leather := _create_material(LEATHER_COLOR, 0.55, 0.4)
	var mat_buckle := _create_material(BRASS_GOLD, 0.2, 0.9)
	
	# 1. Nehru / Mandarin Collar
	var collar := MeshInstance3D.new()
	var c_mesh := BoxMesh.new()
	c_mesh.size = Vector3(0.22, 0.055, 0.19)
	c_mesh.material = mat_kurta_collar
	collar.mesh = c_mesh
	collar.transform.origin = Vector3(0.0, 0.155, 0.01)
	chest_att.add_child(collar)
	
	# Golden piping on collar
	var collar_trim := MeshInstance3D.new()
	var ct_mesh := BoxMesh.new()
	ct_mesh.size = Vector3(0.226, 0.012, 0.196)
	ct_mesh.material = mat_trim
	collar_trim.mesh = ct_mesh
	collar_trim.transform.origin = Vector3(0.0, 0.18, 0.01)
	chest_att.add_child(collar_trim)
	
	# 2. Kurta Front Button Placket
	var placket := MeshInstance3D.new()
	var p_mesh := BoxMesh.new()
	p_mesh.size = Vector3(0.046, 0.26, 0.02)
	p_mesh.material = mat_trim
	placket.mesh = p_mesh
	placket.transform.origin = Vector3(0.0, 0.03, 0.135)
	chest_att.add_child(placket)
	
	# 3 Brass Buttons down the placket
	for i in range(3):
		var btn := MeshInstance3D.new()
		var b_mesh := CylinderMesh.new()
		b_mesh.top_radius = 0.008
		b_mesh.bottom_radius = 0.008
		b_mesh.height = 0.014
		b_mesh.material = mat_button
		btn.mesh = b_mesh
		btn.transform.origin = Vector3(0.0, 0.11 - i * 0.08, 0.145)
		btn.rotation = Vector3(deg_to_rad(90), 0, 0)
		chest_att.add_child(btn)
	
	# 3. Breast Pocket with Pen/Note
	var pocket := MeshInstance3D.new()
	var pk_mesh := BoxMesh.new()
	pk_mesh.size = Vector3(0.065, 0.075, 0.015)
	pk_mesh.material = mat_trim
	pocket.mesh = pk_mesh
	pocket.transform.origin = Vector3(0.09, 0.06, 0.132)
	chest_att.add_child(pocket)
	
	# Small pocket pen clip
	var pen := MeshInstance3D.new()
	var pn_mesh := BoxMesh.new()
	pn_mesh.size = Vector3(0.008, 0.035, 0.01)
	pn_mesh.material = mat_button
	pen.mesh = pn_mesh
	pen.transform.origin = Vector3(0.09, 0.095, 0.138)
	chest_att.add_child(pen)
	
	# 4. Crossbody Adventurer Sling Bag Strap (Right shoulder to Left hip)
	var strap_front := MeshInstance3D.new()
	var sf_mesh := BoxMesh.new()
	sf_mesh.size = Vector3(0.048, 0.38, 0.018)
	sf_mesh.material = mat_leather
	strap_front.mesh = sf_mesh
	strap_front.transform.origin = Vector3(0.01, 0.04, 0.138)
	strap_front.rotation = Vector3(0, 0, deg_to_rad(-34))
	chest_att.add_child(strap_front)
	
	# Brass strap buckle
	var buckle := MeshInstance3D.new()
	var bk_mesh := BoxMesh.new()
	bk_mesh.size = Vector3(0.06, 0.038, 0.024)
	bk_mesh.material = mat_buckle
	buckle.mesh = bk_mesh
	buckle.transform.origin = Vector3(0.03, 0.08, 0.142)
	buckle.rotation = Vector3(0, 0, deg_to_rad(-34))
	chest_att.add_child(buckle)
	
	# Strap back
	var strap_back := MeshInstance3D.new()
	var sb_mesh := BoxMesh.new()
	sb_mesh.size = Vector3(0.048, 0.38, 0.018)
	sb_mesh.material = mat_leather
	strap_back.mesh = sb_mesh
	strap_back.transform.origin = Vector3(0.01, 0.04, -0.135)
	strap_back.rotation = Vector3(0, 0, deg_to_rad(34))
	chest_att.add_child(strap_back)
	
	# Leather Adventurer Satchel Pouch (at left hip, attached to spine_01/pelvis)
	var pelvis_att := BoneAttachment3D.new()
	pelvis_att.name = "IndianBoy_PelvisAttachment"
	pelvis_att.bone_name = "pelvis"
	skel.add_child(pelvis_att)
	
	var pouch := MeshInstance3D.new()
	var pc_mesh := BoxMesh.new()
	pc_mesh.size = Vector3(0.12, 0.17, 0.22)
	pc_mesh.material = mat_leather
	pouch.mesh = pc_mesh
	pouch.transform.origin = Vector3(0.24, 0.05, 0.02)
	pouch.rotation = Vector3(deg_to_rad(12), 0, deg_to_rad(-8))
	pelvis_att.add_child(pouch)
	
	# Pouch flap & buckle
	var flap := MeshInstance3D.new()
	var fl_mesh := BoxMesh.new()
	fl_mesh.size = Vector3(0.126, 0.10, 0.08)
	fl_mesh.material = _create_material(Color(0.36, 0.20, 0.11), 0.5)
	flap.mesh = fl_mesh
	flap.transform.origin = Vector3(0.25, 0.07, 0.07)
	pelvis_att.add_child(flap)
	
	# Belt with brass buckle on waist
	var belt := MeshInstance3D.new()
	var blt_mesh := BoxMesh.new()
	blt_mesh.size = Vector3(0.32, 0.048, 0.25)
	blt_mesh.material = mat_leather
	belt.mesh = blt_mesh
	belt.transform.origin = Vector3(0.0, 0.04, 0.0)
	pelvis_att.add_child(belt)
	
	var belt_buckle := MeshInstance3D.new()
	var bb_mesh := BoxMesh.new()
	bb_mesh.size = Vector3(0.065, 0.058, 0.03)
	bb_mesh.material = mat_buckle
	belt_buckle.mesh = bb_mesh
	belt_buckle.transform.origin = Vector3(0.0, 0.04, 0.13)
	pelvis_att.add_child(belt_buckle)

static func _build_arm_accessories(skel: Skeleton3D) -> void:
	# 1. Rolled-up Kurta Sleeves (Upper Arms)
	var mat_sleeve := _create_material(KURTA_TRIM, 0.65)
	
	for arm_bone in ["upperarm_l", "upperarm_r"]:
		var arm_att := BoneAttachment3D.new()
		arm_att.name = "IndianBoy_Sleeve_" + arm_bone
		arm_att.bone_name = arm_bone
		skel.add_child(arm_att)
		
		var cuff := MeshInstance3D.new()
		var c_mesh := BoxMesh.new()
		c_mesh.size = Vector3(0.12, 0.06, 0.12)
		c_mesh.material = mat_sleeve
		cuff.mesh = c_mesh
		cuff.transform.origin = Vector3(0.0, -0.22, 0.0)
		arm_att.add_child(cuff)
	
	# 2. Left Wrist: Sporty Digital Watch
	var l_arm_att := BoneAttachment3D.new()
	l_arm_att.name = "IndianBoy_Watch_lowerarm_l"
	l_arm_att.bone_name = "lowerarm_l"
	skel.add_child(l_arm_att)
	
	var mat_watch := _create_material(WATCH_BLACK, 0.3, 0.8)
	var watch_strap := MeshInstance3D.new()
	var ws_mesh := BoxMesh.new()
	ws_mesh.size = Vector3(0.085, 0.038, 0.085)
	ws_mesh.material = mat_watch
	watch_strap.mesh = ws_mesh
	watch_strap.transform.origin = Vector3(0.0, -0.21, 0.0)
	l_arm_att.add_child(watch_strap)
	
	var watch_face := MeshInstance3D.new()
	var wf_mesh := BoxMesh.new()
	wf_mesh.size = Vector3(0.04, 0.032, 0.02)
	wf_mesh.material = _create_material(Color(0.2, 0.35, 0.3), 0.2, 0.9)
	watch_face.mesh = wf_mesh
	watch_face.transform.origin = Vector3(0.0, -0.21, 0.046)
	l_arm_att.add_child(watch_face)
	
	# 3. Right Wrist: Sacred Red-and-Yellow Kalava (protective village wrist thread)
	var r_arm_att := BoneAttachment3D.new()
	r_arm_att.name = "IndianBoy_Kalava_lowerarm_r"
	r_arm_att.bone_name = "lowerarm_r"
	skel.add_child(r_arm_att)
	
	var mat_kalava_red := _create_material(KALAVA_RED, 0.8)
	var mat_kalava_gold := _create_material(KALAVA_GOLD, 0.8)
	
	var kalava_1 := MeshInstance3D.new()
	var k1_mesh := BoxMesh.new()
	k1_mesh.size = Vector3(0.082, 0.016, 0.082)
	k1_mesh.material = mat_kalava_red
	kalava_1.mesh = k1_mesh
	kalava_1.transform.origin = Vector3(0.0, -0.20, 0.0)
	r_arm_att.add_child(kalava_1)
	
	var kalava_2 := MeshInstance3D.new()
	var k2_mesh := BoxMesh.new()
	k2_mesh.size = Vector3(0.083, 0.014, 0.083)
	k2_mesh.material = mat_kalava_gold
	kalava_2.mesh = k2_mesh
	kalava_2.transform.origin = Vector3(0.0, -0.215, 0.0)
	r_arm_att.add_child(kalava_2)

static func _build_leg_features(skel: Skeleton3D) -> void:
	# 1. Rolled-up denim cuffs at ankles (Calves)
	var mat_cuff := _create_material(JEANS_CUFF, 0.7)
	for calf_bone in ["calf_l", "calf_r"]:
		var calf_att := BoneAttachment3D.new()
		calf_att.name = "IndianBoy_Cuff_" + calf_bone
		calf_att.bone_name = calf_bone
		skel.add_child(calf_att)
		
		var cuff := MeshInstance3D.new()
		var cf_mesh := BoxMesh.new()
		cf_mesh.size = Vector3(0.14, 0.05, 0.14)
		cf_mesh.material = mat_cuff
		cuff.mesh = cf_mesh
		cuff.transform.origin = Vector3(0.0, -0.36, 0.0)
		calf_att.add_child(cuff)
	
	# 2. Handcrafted Leather Kolhapuri Chappals / Indian Sandals
	var mat_sandal := _create_material(LEATHER_COLOR, 0.6, 0.3)
	var mat_strap := _create_material(Color(0.55, 0.32, 0.18), 0.5, 0.4)
	var mat_gold_trim := _create_material(BRASS_GOLD, 0.3, 0.8)
	
	for foot_bone in ["foot_l", "foot_r"]:
		var foot_att := BoneAttachment3D.new()
		foot_att.name = "IndianBoy_Sandal_" + foot_bone
		foot_att.bone_name = foot_bone
		skel.add_child(foot_att)
		
		# Leather sole base
		var sole := MeshInstance3D.new()
		var s_mesh := BoxMesh.new()
		s_mesh.size = Vector3(0.11, 0.03, 0.24)
		s_mesh.material = mat_sandal
		sole.mesh = s_mesh
		sole.transform.origin = Vector3(0.0, -0.06, 0.06)
		foot_att.add_child(sole)
		
		# Kolhapuri braided cross strap
		var strap := MeshInstance3D.new()
		var st_mesh := BoxMesh.new()
		st_mesh.size = Vector3(0.116, 0.024, 0.06)
		st_mesh.material = mat_strap
		strap.mesh = st_mesh
		strap.transform.origin = Vector3(0.0, -0.02, 0.04)
		foot_att.add_child(strap)
		
		# Brass decorative center stud on sandal
		var stud := MeshInstance3D.new()
		var sd_mesh := SphereMesh.new()
		sd_mesh.radius = 0.012
		sd_mesh.height = 0.02
		sd_mesh.material = mat_gold_trim
		stud.mesh = sd_mesh
		stud.transform.origin = Vector3(0.0, -0.005, 0.04)
		foot_att.add_child(stud)
