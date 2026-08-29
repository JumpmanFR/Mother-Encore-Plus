shader_type canvas_item;

uniform vec4 mirrorTint : hint_color = vec4(0.22, 0.57, 0.35, 1.0);
uniform bool enable_ripple = false;
uniform bool grayscale_pre_processing = true;
uniform float ripple_frequency = 50;
uniform float ripple_amplitude = 2;
uniform float time_scale = 1;

vec4 soft_light(vec4 base, vec4 blend){
	vec4 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), 
	sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}

void fragment() {
	// Ripple effects
	vec2 uv = UV;
    if (enable_ripple){
		// TODO: Scale distortion to texture
        float offset = sin(uv.y * ripple_frequency + (TIME * time_scale))
						* ripple_amplitude * TEXTURE_PIXEL_SIZE.x;
        uv.x += offset;
    }
	vec4 tex_color = texture(TEXTURE, uv);
	
	// Desaturates texture
	if (grayscale_pre_processing){
		COLOR.rgb = mix(vec3(dot(tex_color.rgb, vec3(0.3, 0.6, 0.1)))
								, tex_color.rgb, 0.0);
	}
	
	//vec4 screenColor = texture(SCREEN_TEXTURE, SCREEN_UV);
    COLOR = soft_light(mirrorTint, (COLOR * mirrorTint));
	COLOR.a *= tex_color.a;
}
