class_name Meshers
extends Object

static func index_to_pos(index : int):
	return Vector3i(index % 32, index / 32 % 32, index / 32 / 32 % 32)

static func pos_to_index(pos : Vector3i):
	return pos.x + (pos.y * 32) + (pos.z * 32 * 32)

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

# TODO make a chunk lattice for 32**3 chunks just to compare the overdraw price
# (Could still be better on average than the simple and naive approach, but likely worse than a greedy mesh, and hopefully raymarching)
static func generate_chunk_lattice() -> void:
	pass

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
