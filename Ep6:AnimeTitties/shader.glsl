float boob_size = 2.0;
float nipple_width = 0.5;
float nipple_size = 0.07;
float nipple_pointiness = 4.0;

vec4 skin_color = vec4(0.9254901960784314, 0.7372549019607844, 0.7058823529411765, 1.0);
vec4 nipple_color = vec4(0.7333333333333333, 0.4666666666666667, 0.4666666666666667, 1.0);

float feathering = 0.05;
float blending = 0.03;

float tittie_f(in float x, out float boob, out float nipple){
    boob = -boob_size*x*log(x);
    nipple = nipple_size*exp(-pow(
        10.0*(1.0/nipple_width)*x-4.0*(1.0/nipple_width),
        nipple_pointiness));
    
    return nipple + boob;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    uv.x = 1.0-uv.x;
    
    float boob, nipple;
    float value = tittie_f(uv.x, boob, nipple);
    
    // Mask
    vec4 tittie_mask = 
        mix(vec4(1), vec4(0),
            smoothstep(clamp(-value+uv.y+feathering,
                             0.0, 1.0), 0.0,
                       feathering)
           );
    
    // Final Color
    fragColor = 
        mix(skin_color, nipple_color,
            smoothstep(clamp(-boob+uv.y+blending, 0.0, 1.0), 0.0, blending))
        * tittie_mask;
}
