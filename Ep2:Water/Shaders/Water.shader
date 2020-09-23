/*
Copyright © 2020 Shapkofil

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files 
(the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished 
to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

shader_type spatial;
render_mode unshaded;

const vec3 ocean_normal = vec3(0.0, 1.0, 0.0);

uniform vec4 ocean_color: hint_color = vec4(1.0);
uniform vec4 deep_ocean_color: hint_color = vec4(0.5);
uniform vec4 specular_color: hint_color = vec4(1.0);
uniform float ocean_depth = 5.0;
uniform float sea_level = 20.0;

uniform float specular_smoothness :hint_range(0.0,1.0) = 0.9;
uniform float specular_strenght = 0.2;
uniform vec3 sun_pos = vec3(-20.0);

uniform float wave_scale = 0.6;
uniform float wave_speed = 0.7;
uniform float wave_strength:hint_range(0,1) = 0.5;

// 	<www.shadertoy.com/view/XsX3zB>
//	by Nikita Miropolskiy

/* discontinuous pseudorandom uniformly distributed in [-0.5, +0.5]^3 */
vec3 random3(vec3 c) {
	float j = 4096.0*sin(dot(c,vec3(17.0, 59.4, 15.0)));
	vec3 r;
	r.z = fract(512.0*j);
	j *= .125;
	r.x = fract(512.0*j);
	j *= .125;
	r.y = fract(512.0*j);
	return r-0.5;
}

const float F3 =  0.3333333;
const float G3 =  0.1666667;
float snoise(vec3 p) {

	vec3 s = floor(p + dot(p, vec3(F3)));
	vec3 x = p - s + dot(s, vec3(G3));
	 
	vec3 e = step(vec3(0.0), x - x.yzx);
	vec3 i1 = e*(1.0 - e.zxy);
	vec3 i2 = 1.0 - e.zxy*(1.0 - e);
	 	
	vec3 x1 = x - i1 + G3;
	vec3 x2 = x - i2 + 2.0*G3;
	vec3 x3 = x - 1.0 + 3.0*G3;
	 
	vec4 w, d;
	 
	w.x = dot(x, x);
	w.y = dot(x1, x1);
	w.z = dot(x2, x2);
	w.w = dot(x3, x3);
	 
	w = max(0.6 - w, 0.0);
	 
	d.x = dot(random3(s), x);
	d.y = dot(random3(s + i1), x1);
	d.z = dot(random3(s + i2), x2);
	d.w = dot(random3(s + 1.0), x3);
	 
	w *= w;
	w *= w;
	d *= w;
	 
	return dot(d, vec4(52.0));
}

float snoiseFractal(vec3 m) {
	return   0.5333333* snoise(m)
				+0.2666667* snoise(2.0*m)
				+0.1333333* snoise(4.0*m)
				+0.0666667* snoise(8.0*m);
}



void vertex()
{
	POSITION = vec4(VERTEX, 1.0);
}

float plaIntersect( in vec3 ro, in vec3 rd, in vec4 p )
{
	float dst = -(dot(ro,p.xyz)+p.w)/dot(rd,p.xyz);
	dst = dst<0.0?99999.0:dst;
	if(ro.y < -p.w)
		return 0.0;
	return dst;
}

void fragment()
{
	float depth = texture(DEPTH_TEXTURE, SCREEN_UV).x;
	vec3 ndc = vec3(SCREEN_UV,depth) * 2.0 - 1.0;
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec4 pos = CAMERA_MATRIX * view;
	pos.xyz /= pos.w;
	
	view.xyz /= view.w;
	float linear_depth = -view.z;
	
	vec3 camera_pos = (CAMERA_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	vec3 ray_dir = (pos.xyz - camera_pos)/linear_depth ;

	float dstToOcean = plaIntersect(camera_pos.xyz, ray_dir, vec4(ocean_normal, -sea_level));
	float oceanViewDepth = linear_depth - dstToOcean;
	vec3 oceanIntersection = camera_pos + ray_dir * dstToOcean;
	ALBEDO = vec3(oceanViewDepth);
	
	if(oceanViewDepth > 0.0)
	{
		float t = 1.0 - exp(-oceanViewDepth / ocean_depth);

    	vec3 wave_normal = vec3(snoise(vec3(oceanIntersection.xz * wave_scale, TIME * wave_speed)));
    	wave_normal = mix(ocean_normal, wave_normal, wave_strength);
		
		float specular_angle = dot(normalize(sun_pos), reflect(ray_dir,wave_normal));
		float specular_exponent = specular_angle / (1.0 - specular_smoothness);
		float specular_highlight = exp(-specular_exponent * specular_exponent);
		
		ALBEDO = mix(ocean_color, deep_ocean_color, t).xyz;
		ALBEDO += specular_highlight * specular_color.xyz * specular_strenght * float(dstToOcean>0.0);
	}
	else
	{
		ALBEDO = texture(SCREEN_TEXTURE,SCREEN_UV).xyz;
	}
}