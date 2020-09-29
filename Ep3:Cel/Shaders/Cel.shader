shader_type spatial;

uniform sampler2D color_scheme;

void fragment(){
	ALBEDO = vec3(1);
}

void light(){
	vec3 light_map = clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * ALBEDO;
	DIFFUSE_LIGHT += texture(color_scheme, vec2(length(light_map), UV.y)).xyz;
}