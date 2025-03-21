extends Node

class physics_object:
	# These will all be 64 bit floating point numbers to hopefully avoid some precision issues
	var pos_x : float = 0
	var pos_y : float = 0
	var pos_z : float = 0
	
	var rot : Quaternion = Quaternion.IDENTITY
	
	var size : Vector3i = Vector3i.ZERO
	var data : PackedByteArray = []
	# Stores the position and lod of the desired chunk Vector3i + LOD value
	var chunk_pos : PackedInt32Array = []
	
	func _init() ->void:
		pass
	
	func get_chunk_data_size() -> int:
		return size.x*size.y*size.z
	

# Thread pool for generating chunk meshes
var thread_pool : Array[Thread] = []

# For now chunk data is processed on the main thread and will remain there

# another name for seed
var iv : int = randi()

# Maybe have a maximum number of meshes?
var mesh_pool : Array[MeshInstance3D] = []

#KSP strat for avoiding floating point precision issues
var world_offset : Vector3 = Vector3(1,-2,1)

var objects : Array[physics_object] = []

# how close does the player need to be in order for the chunk to be rendered at full detail
const render_distance : int = 2

# TODO for performance make the main thread demand chunk generation and chunk mesh generation, 
# but do these operations on seperate threads as to ensure stable performance on the main thread
# TODO game tick on seperate thread, parallelize the game tick according to rough regions of a certain size

func _init() -> void:
	Engine.max_fps = 0
	
	var earth : physics_object = physics_object.new()
	earth.size = Vector3(10, 10, 10)
	
	var start_time = Time.get_unix_time_from_system()
	
	# terrain generation
	for i in earth.get_chunk_data_size():
		earth.data.append_array(generate_chunk_data())
		earth.chunk_pos.append(i % earth.size.x)
		earth.chunk_pos.append(i / earth.size.x % earth.size.y)
		earth.chunk_pos.append(i / earth.size.x / earth.size.y % earth.size.z)
		earth.chunk_pos.append(0)
	
	print("chunk generation time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	print("chunk data completed")
	
	objects.append(earth)

func _ready() -> void:
	var block_atlas : ImageTexture = generate_block_texture_atlas()
	
	var material = StandardMaterial3D.new() #ShaderMaterial.new()
	material.albedo_texture = block_atlas
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	#material.shader = SHADER
	#material.set_shader_parameter("block_atlas", block_atlas)
	
	# TODO add support for rendering multiple objects
	mesh_pool.resize(objects[0].get_chunk_data_size())
	
	print("chunk data size: ", objects[0].get_chunk_data_size())
	print("mesh pool size: ", mesh_pool.size())
	
	# TODO add check for whether pos is even visible
	# TODO do testing to see if raymarched planets makes sense after a certain distance so that they can be visible at all times (should be very performant since they will cover very few pixels before we switch to rasterization)
	# Raymarched night sky??!?
	# create all mesh instances needed
	
	for i in mesh_pool.size():
		var instance = MeshInstance3D.new()
		#instance.position.x = objects[0].pos_x*32
		#instance.position.y = objects[0].pos_y*32
		#instance.position.z = objects[0].pos_z*32
		#instance.rotation_edit_mode = Node3D.ROTATION_EDIT_MODE_QUATERNION
		#instance.rotation = objects[0].rot
		mesh_pool[i] = instance
		
		var chunk_data = objects[0].data.slice(32768*i,32768*(i+1))
		
		#var start_time = Time.get_unix_time_from_system()
		#var mesh = generate_lod_chunk_mesh_naive()
		var mesh = Meshers.generate_chunk_mesh_simple_optimized(chunk_data)
		#print("mesh generation time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
		
		mesh_pool[i].mesh = mesh
		
		mesh_pool[i].set_surface_override_material(0, material)
		add_child(mesh_pool[i])

var w : bool = false
var a : bool = false
var s : bool = false
var d : bool = false
var space : bool = false
var control : bool = false
var shift : bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			get_tree().quit()
		
		if event.keycode == KEY_W and event.pressed:
			w = true
		if event.keycode == KEY_A and event.pressed:
			a = true
		if event.keycode == KEY_S and event.pressed:
			s = true
		if event.keycode == KEY_D and event.pressed:
			d = true
		if event.keycode == KEY_SPACE and event.pressed:
			space = true
		if event.keycode == KEY_SHIFT and event.pressed:
			shift = true
		if event.keycode == KEY_CTRL and event.pressed:
			control = true
		
		if event.keycode == KEY_W and not event.pressed:
			w = false
		if event.keycode == KEY_A and not event.pressed:
			a = false
		if event.keycode == KEY_S and not event.pressed:
			s = false
		if event.keycode == KEY_D and not event.pressed:
			d = false
		if event.keycode == KEY_SPACE and not event.pressed:
			space = false
		if event.keycode == KEY_SHIFT and not event.pressed:
			shift = false
		if event.keycode == KEY_CTRL and not event.pressed:
			control = false

func _process(delta) -> void:
	var move_speed : float = 5.0
	var look_vector : Vector3 = Vector3(-sin($Node3D.rotation.y), sin($Node3D/Camera3D.rotation.x), -cos($Node3D.rotation.y))#sin(rotation.y))
	look_vector = look_vector.normalized()
	
	#var up_vector : Vector3 = look_vector.cross(Vector3(1,0,0))
	var right_vector : Vector3 = look_vector.cross(Vector3(0,1,0))
	
	if control:
		move_speed = 15
	
	if w:
		world_offset += -look_vector * delta * move_speed
	if s:
		world_offset += look_vector * delta * move_speed
	
	if a:
		world_offset += right_vector * delta * move_speed
	if d:
		world_offset += -right_vector * delta * move_speed
	
	if space:
		world_offset += Vector3(0,-1,0) * delta * move_speed
	if shift:
		world_offset += Vector3(0,1,0) * delta * move_speed
	
	var i = 0
	for mesh in mesh_pool:
		# emulates player movement
		mesh.position.x = world_offset.x + objects[0].pos_x + objects[0].chunk_pos[i*4]*32
		mesh.position.y = world_offset.y + objects[0].pos_y + objects[0].chunk_pos[i*4+1]*32
		mesh.position.z = world_offset.z + objects[0].pos_z + objects[0].chunk_pos[i*4+2]*32
		#print(mesh, " ", mesh.position)
		i += 1
	
	$HUD/Label.text = str("fps: ", Engine.get_frames_per_second(), " delta: ", 
	delta, "\ncam rot: ", $Node3D/Camera3D.rotation.x, " ", $Node3D.rotation.y,
	"\npos: ", world_offset)

#_pos: Vector3i, _seed : int
static func generate_chunk_data() -> PackedByteArray:
	var result : PackedByteArray
	
	for i in range(32*32*32):
		result.append(randi_range(0,1))
	
	return result

static func generate_chunk_bitmask(chunk_data : PackedByteArray) -> PackedByteArray:
	var result : PackedByteArray
	
	for i in range(32*32*32/8):
		var a = 0
		if (chunk_data.decode_u8(i) == 1):
			a |= 1
		a = a << 1
		if (chunk_data.decode_u8(i+1) == 1):
			a |= 1
		a = a << 1
		if (chunk_data.decode_u8(i+2) == 1):
			a |= 1
		a = a << 1
		if (chunk_data.decode_u8(i+3) == 1):
			a |= 1
		a = a << 1
		if (chunk_data.decode_u8(i+4) == 1):
			a |= 1
		a = a << 1
		if (chunk_data.decode_u8(i+5) == 1):
			a |= 1
		a = a << 1
		if (chunk_data.decode_u8(i+6) == 1):
			a |= 1
		a = a << 1
		if (chunk_data.decode_u8(i+7) == 1):
			a |= 1
		a = a << 1
		
		result.append(a)
		print(String.num_int64(a, 2))
	
	return result

func generate_block_texture_atlas() -> ImageTexture:
	var data : PackedByteArray = PackedByteArray()
	
	# 16 * 16 = 256
	var air = []
	for i in range(16*16*4):
		air.append(0x00)
	var dirt = Image.load_from_file("res://0.png")
	dirt.convert(Image.FORMAT_RGBA8)
	#for i in range(16*16):
	#	const stuff = [0xfc, 0x36, 0x00, 0xff]
	#	dirt.append_array(stuff)
	
	data.append_array(air)
	data.append_array(dirt.get_data())
	
	var image : Image = Image.create_from_data(16, 32, false, Image.FORMAT_RGBA8, data)
	
	image.save_png("res://chicken.png")
	
	return ImageTexture.create_from_image(image)
