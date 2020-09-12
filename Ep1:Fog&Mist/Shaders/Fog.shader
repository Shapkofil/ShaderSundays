shader_type spatial;
render_mode unshaded;

uniform vec4 fog_color : hint_color = vec4(1);
uniform float max_distance = 20;
uniform float min_distance = 5;

void vertex()
{
	POSITION = vec4(VERTEX, 1.0);
}

vec3 mixRGB(vec3 a, vec3 b, float fac)
{
	fac = clamp(fac, 0.0, 1.0);
	return a*(1.0 - fac) + b*fac;
}

void fragment()
{
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV,depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z -min_distance;
	ALBEDO = mixRGB(texture(SCREEN_TEXTURE, SCREEN_UV).xyz,fog_color.xyz,linear_depth/(max_distance-min_distance));
}