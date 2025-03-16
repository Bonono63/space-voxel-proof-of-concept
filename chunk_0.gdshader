shader_type spatial;

uniform sampler2D block_atlas : filter_nearest;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	vec4 color = texture(block_atlas, UV);
	ALBEDO = color.rgb;
	ALPHA = 1.0;
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
