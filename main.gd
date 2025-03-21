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
	earth.size = Vector3(1, 2, 1)
	
	# terrain generation
	for i in earth.size.x:
		for j in earth.size.y:
			for k in earth.size.z:
				var start_time = Time.get_unix_time_from_system()
				print(i+j+k, " ", Vector3(i, j, k))
				earth.data.append_array(generate_chunk_data(Vector3i(i, j, k), iv))
				earth.chunk_pos.append(i)
				earth.chunk_pos.append(j)
				earth.chunk_pos.append(k)
				earth.chunk_pos.append(0)
				print("chunk generation time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	
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
	for mesh in mesh_pool:
		var instance = MeshInstance3D.new()
		instance.position.x = objects[0].pos_x*32
		instance.position.y = objects[0].pos_y*32
		instance.position.z = objects[0].pos_z*32
		#instance.rotation_edit_mode = Node3D.ROTATION_EDIT_MODE_QUATERNION
		#instance.rotation = objects[0].rot
		mesh_pool[i] = instance
	
	# generate the meshes
	for i in range(objects[0].get_chunk_data_size()):
		var chunk_data = objects[0].data.slice(32768*i,32768*(i+1))
		
		var start_time = Time.get_unix_time_from_system()
		var mesh = generate_chunk_mesh_simple_optimized(chunk_data)
		#var mesh = generate_lod_chunk_mesh_naive()
		print("mesh generation time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
		
		mesh_pool[i].mesh = mesh
	
	# add all the mesh instances
	for mesh in mesh_pool:
		mesh.set_surface_override_material(0, material)
		add_child(mesh)
	

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
	
	for i in range(objects[0].get_chunk_data_size()):
		# emulates player movement
		mesh_pool[i].position.x = world_offset.x + objects[0].pos_x*32
		mesh_pool[i].position.y = world_offset.y + objects[0].pos_y*32
		mesh_pool[i].position.z = world_offset.z + objects[0].pos_z*32
	
	$HUD/Label.text = str("fps: ", Engine.get_frames_per_second(), " delta: ", 
	delta, "\ncam rot: ", $Node3D/Camera3D.rotation.x, " ", $Node3D.rotation.y,
	"\npos: ", world_offset)

# pass a PackedByteArray of size 32768 (16**3)
static func generate_chunk_mesh_naive(chunk_data : PackedByteArray) -> Mesh:
	var result = ArrayMesh.new()
	
	var vertices = []
	vertices.resize(Mesh.ARRAY_MAX)
	vertices[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	vertices[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	vertices[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	var index = 0
	for i in chunk_data:
		if i == 1:
			var pos : Vector3 = Vector3(index % 32, index / 32 % 32, index / 32 / 32 % 32)
			# Front Face
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,1))
			
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,1))
			
			#Left Face
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(-1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(-1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(-1,0,0))
			
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(-1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(-1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(-1,0,0))
			
			#Back Face
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,-1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,-1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,-1))
			
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,-1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,-1))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,0,-1))
			
			#Right Face
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(1,0,0))
			
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(1,0,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(1,0,0))
			
			#Up Face
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,1,0))
			
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 1, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,1,0))
			
			#Bottom Face
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,-1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,-1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,-1,0))
			
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 0) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,0.5))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,-1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(0, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(1,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,-1,0))
			vertices[Mesh.ARRAY_VERTEX].append(Vector3(1, 0, 1) + pos)
			vertices[Mesh.ARRAY_TEX_UV].append(Vector2(0,1))
			vertices[Mesh.ARRAY_NORMAL].append(Vector3(0,-1,0))
		
		index += 1
	#vertices[Mesh.ARRAY_TEX_UV].append(Vector2.ZERO)
	
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, vertices)
	
	return result

# pass a PackedByteArray of size 32768 (16**3)
static func generate_chunk_mesh_naive_optimized(chunk_data : PackedByteArray) -> Mesh:
	var start_time = Time.get_unix_time_from_system()
	
	var result = ArrayMesh.new()
	
	var data = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	data[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	data[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	
	print("init time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	
	start_time = Time.get_unix_time_from_system()
	for i in chunk_data:
		if i == 1:
			const uv : PackedVector2Array = [
				Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
				Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
				
				Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
				Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
				
				Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
				Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
				
				Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
				Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
				
				Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
				Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
				
				Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
				Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
			];
			data[Mesh.ARRAY_TEX_UV].append_array(uv)
	print("uv time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	
	start_time = Time.get_unix_time_from_system()
	for i in chunk_data:
		if i == 1:
			const normal : PackedVector3Array = [
				# Front Face
				Vector3(0,0,1), Vector3(0,0,1), Vector3(0,0,1),
				Vector3(0,0,1), Vector3(0,0,1), Vector3(0,0,1),
				
				# Left Face
				Vector3(-1,0,0), Vector3(-1,0,0), Vector3(-1,0,0),
				Vector3(-1,0,0), Vector3(-1,0,0), Vector3(-1,0,0),
				
				# Back Face
				Vector3(0,0,-1), Vector3(0,0,-1), Vector3(0,0,-1),
				Vector3(0,0,-1), Vector3(0,0,-1), Vector3(0,0,-1),
				
				# Right Face
				Vector3(1,0,0), Vector3(1,0,0), Vector3(1,0,0),
				Vector3(1,0,0), Vector3(1,0,0), Vector3(1,0,0),
				
				# Up Face
				Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0),
				Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0),
				
				# Bottom Face
				Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0),
				Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0),
			];
			
			data[Mesh.ARRAY_NORMAL].append_array(normal)
	print("normal time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	
	start_time = Time.get_unix_time_from_system()
	var index = 0
	for i in chunk_data:
		if i == 1:
			var pos : Vector3 = Vector3(index % 32, index / 32 % 32, index / 32 / 32 % 32)
			# This could probably be parallelized in a simd instruction since the vertex array itself could
			# be const and the pos could just be added to every single block
			var vertex : PackedVector3Array = [
				Vector3(0, 0, 1) + pos, Vector3(0, 1, 1) + pos, Vector3(1, 1, 1) + pos,
				Vector3(1, 1, 1) + pos, Vector3(1, 0, 1) + pos, Vector3(0, 0, 1) + pos,
				Vector3(0, 0, 0) + pos, Vector3(0, 1, 0) + pos, Vector3(0, 1, 1) + pos,
				Vector3(0, 1, 1) + pos, Vector3(0, 0, 1) + pos, Vector3(0, 0, 0) + pos,
				Vector3(1, 0, 0) + pos, Vector3(1, 1, 0) + pos, Vector3(0, 1, 0) + pos,
				Vector3(0, 1, 0) + pos, Vector3(0, 0, 0) + pos, Vector3(1, 0, 0) + pos,
				Vector3(1, 0, 1) + pos, Vector3(1, 1, 1) + pos, Vector3(1, 1, 0) + pos,
				Vector3(1, 1, 0) + pos, Vector3(1, 0, 0) + pos, Vector3(1, 0, 1) + pos,
				Vector3(1, 1, 1) + pos, Vector3(0, 1, 1) + pos, Vector3(0, 1, 0) + pos,
				Vector3(0, 1, 0) + pos, Vector3(1, 1, 0) + pos, Vector3(1, 1, 1) + pos,
				Vector3(1, 0, 1) + pos, Vector3(1, 0, 0) + pos, Vector3(0, 0, 0) + pos,
				Vector3(0, 0, 0) + pos, Vector3(0, 0, 1) + pos, Vector3(1, 0, 1) + pos,
				]
			
			# adding this weird array saves us like 30 ms per chunk
			data[Mesh.ARRAY_VERTEX].append_array(vertex)
		
		index += 1
	#vertices[Mesh.ARRAY_TEX_UV].append(Vector2.ZERO)
	print("normal time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	
	# TODO this add surface from arrays function is slow as hell adding 20 ms to our mesh generation
	# We need to see if we can produce a mesh that can be injected directly into the render server hopefully
	# bypassing this step (Will be a non issue in a custom engine)
	start_time = Time.get_unix_time_from_system()
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	print("surface array time: ", (Time.get_unix_time_from_system() - start_time) * 1000, "ms")
	
	return result

static func index_to_pos(index : int):
	return Vector3i(index % 32, index / 32 % 32, index / 32 / 32 % 32)

static func pos_to_index(pos : Vector3i):
	return pos.x + (pos.y * 32) + (pos.z * 32 * 32)

# 0b1
const FRONT_FLAG = 0x1
# 0b10
const LEFT_FLAG = 0x2
# 0b100
const BACK_FLAG = 0x4
# ob1000
const RIGHT_FLAG = 0x8
# ob10000
const UP_FLAG = 0x10
# ob100000
const DOWN_FLAG = 0x20

# pass a PackedByteArray of size 32768 (16**3)
static func generate_chunk_mesh_simple_optimized(chunk_data : PackedByteArray) -> Mesh:
	
	var result = ArrayMesh.new()
	
	var data = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	data[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	data[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	
	var index = 0
	for i in range(chunk_data.size()):
		var pos : Vector3 = index_to_pos(index)
		var neighbor_flags : int = 0
		
		if chunk_data[i] != 0:
			if pos.z < 31:
				#neighbor_flags |= FRONT_FLAG
				var front_index : int = pos_to_index(Vector3i(pos.x, pos.y, pos.z+1))
				var front = chunk_data[front_index] == 0
				if front:
					neighbor_flags |= FRONT_FLAG
			else:
				neighbor_flags |= FRONT_FLAG
			
			if pos.z > 0:
				var back_index : int = pos_to_index(Vector3i(pos.x, pos.y, pos.z-1))
				var back = chunk_data[back_index] == 0
				if back:
					neighbor_flags |= BACK_FLAG
			else:
				neighbor_flags |= BACK_FLAG
			
			if pos.x > 0:
				var left_index : int = pos_to_index(Vector3i(pos.x-1, pos.y, pos.z))
				if chunk_data[left_index] == 0:
					neighbor_flags |= LEFT_FLAG
			else:
				neighbor_flags |= LEFT_FLAG
			
			if pos.x < 31:
				var left_index : int = pos_to_index(Vector3i(pos.x+1, pos.y, pos.z))
				if chunk_data[left_index] == 0:
					neighbor_flags |= RIGHT_FLAG
			else:
				neighbor_flags |= RIGHT_FLAG
			
			if pos.y > 0:
				var down_index : int = pos_to_index(Vector3i(pos.x, pos.y-1, pos.z))
				if chunk_data[down_index] == 0:
					neighbor_flags |= DOWN_FLAG
			else:
				neighbor_flags |= DOWN_FLAG
			
			if pos.y < 31:
				var up_index : int = pos_to_index(Vector3i(pos.x, pos.y+1, pos.z))
				if chunk_data[up_index] == 0:
					neighbor_flags |= UP_FLAG
			else:
				neighbor_flags |= UP_FLAG
		
		const uv_front : PackedVector2Array = [
			# Front
			Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
			Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		]
		const uv_left : PackedVector2Array = [
			# Left
			Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
			Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		]
		const uv_back : PackedVector2Array = [
			# Back
			Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
			Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		]
		const uv_right : PackedVector2Array = [
			# Right
			Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
			Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		]
		const uv_up : PackedVector2Array = [
			# Up
			Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
			Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		]
		const uv_down : PackedVector2Array = [
			# Down
			Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
			Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		];
		
		const normal_front : PackedVector3Array = [
			# Front Face
			Vector3(0,0,1), Vector3(0,0,1), Vector3(0,0,1),
			Vector3(0,0,1), Vector3(0,0,1), Vector3(0,0,1),
		]
		const normal_left : PackedVector3Array = [
			# Left Face
			Vector3(-1,0,0), Vector3(-1,0,0), Vector3(-1,0,0),
			Vector3(-1,0,0), Vector3(-1,0,0), Vector3(-1,0,0),
		]
		const normal_back : PackedVector3Array = [
			# Back Face
			Vector3(0,0,-1), Vector3(0,0,-1), Vector3(0,0,-1),
			Vector3(0,0,-1), Vector3(0,0,-1), Vector3(0,0,-1),
		]
		const normal_right : PackedVector3Array = [
			# Right Face
			Vector3(1,0,0), Vector3(1,0,0), Vector3(1,0,0),
			Vector3(1,0,0), Vector3(1,0,0), Vector3(1,0,0),
		]
		const normal_up : PackedVector3Array = [
			# Up Face
			Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0),
			Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0),
		]
		const normal_bottom : PackedVector3Array = [
			# Bottom Face
			Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0),
			Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0),
		];
		
		# This could probably be parallelized in a simd instruction since the vertex array itself could
		# be const and the pos could just be added to every single block
		var front_vertex : PackedVector3Array = [
			# Front
			Vector3(0, 0, 1) + pos, Vector3(0, 1, 1) + pos, Vector3(1, 1, 1) + pos,
			Vector3(1, 1, 1) + pos, Vector3(1, 0, 1) + pos, Vector3(0, 0, 1) + pos,
		]
		var left_vertex : PackedVector3Array = [
			# Left
			Vector3(0, 0, 0) + pos, Vector3(0, 1, 0) + pos, Vector3(0, 1, 1) + pos,
			Vector3(0, 1, 1) + pos, Vector3(0, 0, 1) + pos, Vector3(0, 0, 0) + pos,
		]
		var back_vertex : PackedVector3Array = [
			# Back
			Vector3(1, 0, 0) + pos, Vector3(1, 1, 0) + pos, Vector3(0, 1, 0) + pos,
			Vector3(0, 1, 0) + pos, Vector3(0, 0, 0) + pos, Vector3(1, 0, 0) + pos,
		]
		var right_vertex : PackedVector3Array = [
			# Right
			Vector3(1, 0, 1) + pos, Vector3(1, 1, 1) + pos, Vector3(1, 1, 0) + pos,
			Vector3(1, 1, 0) + pos, Vector3(1, 0, 0) + pos, Vector3(1, 0, 1) + pos,
		]
		var up_vertex : PackedVector3Array = [
			# Up
			Vector3(1, 1, 1) + pos, Vector3(0, 1, 1) + pos, Vector3(0, 1, 0) + pos,
			Vector3(0, 1, 0) + pos, Vector3(1, 1, 0) + pos, Vector3(1, 1, 1) + pos,
		]
		var bottom_vertex : PackedVector3Array = [
			# Down
			Vector3(1, 0, 1) + pos, Vector3(1, 0, 0) + pos, Vector3(0, 0, 0) + pos,
			Vector3(0, 0, 0) + pos, Vector3(0, 0, 1) + pos, Vector3(1, 0, 1) + pos,
		]
		
		# Do this for all the neighbor flags
		if neighbor_flags & FRONT_FLAG:
			data[Mesh.ARRAY_TEX_UV].append_array(uv_front)
			data[Mesh.ARRAY_NORMAL].append_array(normal_front)
			data[Mesh.ARRAY_VERTEX].append_array(front_vertex)
		if neighbor_flags & BACK_FLAG:
			data[Mesh.ARRAY_TEX_UV].append_array(uv_back)
			data[Mesh.ARRAY_NORMAL].append_array(normal_back)
			data[Mesh.ARRAY_VERTEX].append_array(back_vertex)
		if neighbor_flags & LEFT_FLAG:
			data[Mesh.ARRAY_TEX_UV].append_array(uv_left)
			data[Mesh.ARRAY_NORMAL].append_array(normal_left)
			data[Mesh.ARRAY_VERTEX].append_array(left_vertex)
		if neighbor_flags & RIGHT_FLAG:
			data[Mesh.ARRAY_TEX_UV].append_array(uv_right)
			data[Mesh.ARRAY_NORMAL].append_array(normal_right)
			data[Mesh.ARRAY_VERTEX].append_array(right_vertex)
		if neighbor_flags & UP_FLAG:
			data[Mesh.ARRAY_TEX_UV].append_array(uv_up)
			data[Mesh.ARRAY_NORMAL].append_array(normal_up)
			data[Mesh.ARRAY_VERTEX].append_array(up_vertex)
		if neighbor_flags & DOWN_FLAG:
			data[Mesh.ARRAY_TEX_UV].append_array(uv_down)
			data[Mesh.ARRAY_NORMAL].append_array(normal_bottom)
			data[Mesh.ARRAY_VERTEX].append_array(bottom_vertex)
		
		index += 1
	
	# TODO this add surface from arrays function is slow as hell adding 20 ms to our mesh generation
	# We need to see if we can produce a mesh that can be injected directly into the render server hopefully
	# bypassing this step (Will be a non issue in a custom engine)
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	
	return result

# pass a PackedByteArray of size 32768 (16**3)
static func generate_lod_chunk_mesh_naive() -> Mesh:
	const scale : float = 32.0;
	var result = ArrayMesh.new()
	
	var data = []
	data.resize(Mesh.ARRAY_MAX)
	data[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	data[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	data[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	
	const uv : PackedVector2Array = [
		Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
		Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		
		Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
		Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		
		Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
		Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		
		Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
		Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		
		Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
		Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
		
		Vector2(0,1), Vector2(0,0.5), Vector2(1,0.5),
		Vector2(1,0.5), Vector2(1,1), Vector2(0,1),
	];
	data[Mesh.ARRAY_TEX_UV].append_array(uv)
	
	const normal : PackedVector3Array = [
		# Front Face
		Vector3(0,0,1), Vector3(0,0,1), Vector3(0,0,1),
		Vector3(0,0,1), Vector3(0,0,1), Vector3(0,0,1),
		
		# Left Face
		Vector3(-1,0,0), Vector3(-1,0,0), Vector3(-1,0,0),
		Vector3(-1,0,0), Vector3(-1,0,0), Vector3(-1,0,0),
		
		# Back Face
		Vector3(0,0,-1), Vector3(0,0,-1), Vector3(0,0,-1),
		Vector3(0,0,-1), Vector3(0,0,-1), Vector3(0,0,-1),
		
		# Right Face
		Vector3(1,0,0), Vector3(1,0,0), Vector3(1,0,0),
		Vector3(1,0,0), Vector3(1,0,0), Vector3(1,0,0),
		
		# Up Face
		Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0),
		Vector3(0,1,0), Vector3(0,1,0), Vector3(0,1,0),
		
		# Bottom Face
		Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0),
		Vector3(0,-1,0), Vector3(0,-1,0), Vector3(0,-1,0),
	];
	
	data[Mesh.ARRAY_NORMAL].append_array(normal)
	
	var vertex : PackedVector3Array = [
	Vector3(0, 0, 1) * scale, Vector3(0, 1, 1) * scale, Vector3(1, 1, 1) * scale,
	Vector3(1, 1, 1) * scale, Vector3(1, 0, 1) * scale, Vector3(0, 0, 1) * scale,
	Vector3(0, 0, 0) * scale, Vector3(0, 1, 0) * scale, Vector3(0, 1, 1) * scale,
	Vector3(0, 1, 1) * scale, Vector3(0, 0, 1) * scale, Vector3(0, 0, 0) * scale,
	Vector3(1, 0, 0) * scale, Vector3(1, 1, 0) * scale, Vector3(0, 1, 0) * scale,
	Vector3(0, 1, 0) * scale, Vector3(0, 0, 0) * scale, Vector3(1, 0, 0) * scale,
	Vector3(1, 0, 1) * scale, Vector3(1, 1, 1) * scale, Vector3(1, 1, 0) * scale,
	Vector3(1, 1, 0) * scale, Vector3(1, 0, 0) * scale, Vector3(1, 0, 1) * scale,
	Vector3(1, 1, 1) * scale, Vector3(0, 1, 1) * scale, Vector3(0, 1, 0) * scale,
	Vector3(0, 1, 0) * scale, Vector3(1, 1, 0) * scale, Vector3(1, 1, 1) * scale,
	Vector3(1, 0, 1) * scale, Vector3(1, 0, 0) * scale, Vector3(0, 0, 0) * scale,
	Vector3(0, 0, 0) * scale, Vector3(0, 0, 1) * scale, Vector3(1, 0, 1) * scale,
	];
	
	# adding this weird array saves us like 30 ms per chunk
	data[Mesh.ARRAY_VERTEX].append_array(vertex)
	
	# TODO this add surface from arrays function is slow as hell adding 20 ms to our mesh generation
	# We need to see if we can produce a mesh that can be injected directly into the render server hopefully
	# bypassing this step (Will be a non issue in a custom engine)
	result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, data)
	
	return result

static func generate_chunk_data(_pos: Vector3i, _seed : int) -> PackedByteArray:
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
