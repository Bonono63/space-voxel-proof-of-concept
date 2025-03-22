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

class potato:
	var object_index : int
	var chunk_index : int
	var mesh : MeshInstance3D

# Maybe have a maximum number of meshes?
var mesh_pool : Array[potato] = []

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
	earth.size = Vector3(3, 3, 3)
	
	var start_time = Time.get_unix_time_from_system()
	
	# terrain generation
	for i in earth.get_chunk_data_size():
		#earth.data.append_array(generate_chunk_data())
		earth.chunk_pos.append(i % earth.size.x)
		earth.chunk_pos.append(i / earth.size.x % earth.size.y)
		earth.chunk_pos.append(i / earth.size.x / earth.size.y % earth.size.z)
		earth.chunk_pos.append(0)
	
	print("chunk generation time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	print("chunk data completed")
	
	objects.append(earth)

const RENDER_DISTANCE = 2

var MATERIAL = StandardMaterial3D.new()

func _ready() -> void:
	var block_atlas : ImageTexture = generate_block_texture_atlas()
	
	MATERIAL.albedo_texture = block_atlas
	MATERIAL.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	
	#material.shader = SHADER
	#material.set_shader_parameter("block_atlas", block_atlas)
	
	# TODO add support for rendering multiple objects
	mesh_pool.resize(RENDER_DISTANCE**3)
	
	#for j in mesh_pool.size():
	#	var instance = MeshInstance3D.new()
	#	mesh_pool[j] = instance
	
	# TODO add check for whether pos is even visible
	# TODO do testing to see if raymarched planets makes sense after a certain distance so that they can be visible at all times (should be very performant since they will cover very few pixels before we switch to rasterization)
	# Raymarched night sky??!?

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
	
	# Find the chunks in range of the player
	
	i = 0
	for object in objects:
		for j in object.get_chunk_data_size():
			# get chunk data
			var pos = object.chunk_pos.slice(j*4,j*4+4)
			var distance : int = Vector3(pos[0], pos[1], pos[2]).distance_to(world_offset)
			#32813 = 32768 (flat data array) + 24 (position in object) + 1 (flags)
			#var saved_chunk_size : int = object.data.size() / 32813
			
			if distance > RENDER_DISTANCE*32:
				for instance in mesh_pool:
					if instance.object_index == i:
						
				var mesh = Meshers.generate_lod_chunk_mesh_naive()
				mesh.resource_name = j
			else:
				var chunk_data = generate_chunk_data(object.size, object.chunk_pos.slice(j*4,j*4+4), iv)
				var mesh = Meshers.generate_chunk_mesh_simple_optimized(chunk_data)
				mesh.resource_name = j
			#print("mesh generation time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
			
			
			
			mesh_pool[j].mesh = mesh
			
			mesh_pool[j].set_surface_override_material(0, MATERIAL)
			add_child(mesh_pool[j])
		i+=1

#_pos: Vector3i, _seed : int
static func generate_chunk_data(object_size : Vector3i, chunk_pos : PackedInt32Array, iv : int) -> PackedByteArray:
	var result : PackedByteArray
	
	seed(iv + chunk_pos[0]*object_size.x + chunk_pos[1]*object_size.x*object_size.y + chunk_pos[2]*object_size.x*object_size.y*object_size.z)
	for i in range(32*32*32):
		result.append(randi_range(0,1))
	
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
