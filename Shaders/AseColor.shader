shader_type canvas_item;

// Rough reimplementation of Aseprite's "Color" blend layer.
// Esstentially gets the color of the sprite, and sets the luminance.
// Original credits for the algorithm belong to the Aseprite team.

uniform vec4 apply_color : hint_color;
uniform bool enable_ripple = false;
uniform float ripple_frequency = 50;
uniform float ripple_amplitude = 2;
uniform float time_scale = 1;
uniform float darkness_scale = 0.0;

// Frame data
uniform float instance_vframes = 1.0;

float get_luminance(vec3 col){
	return dot(col, vec3(0.3, 0.59, 0.11));
}

vec3 clip_color(vec3 col){
	float l = get_luminance(col);
	float n = min(col.r, min(col.g, col.b));
	float x = max(col.r, max(col.g, col.b));
	
	if (n < 0.0){
		col = l + ((col - l) * l) / (l - n);
	}
	if (x > 1.0) {
		col = l + ((col - l) * (1.0 - l)) / (x - l);
	}
	return col;
}

vec3 set_luminance(vec3 col, float l){
	float d = (l - get_luminance(col));
	col += vec3(d);
	return clip_color(col);
}

// As referenced in the original Aseprite code, the backdrop
// would be the sprite. src color is the provided color.
void fragment(){
	vec2 uv = UV;
    if (enable_ripple){
		// TODO: Scale distortion to texture
        float offset = sin(uv.y * ripple_frequency + (TIME * time_scale))
						* ripple_amplitude * TEXTURE_PIXEL_SIZE.x;
        uv.x += offset;
    }
	vec4 base = texture(TEXTURE, uv) * COLOR;
	vec3 base_rgb = base.rgb;
	vec3 src_rgb  = apply_color.rgb;

	float lum = get_luminance(base_rgb);
	vec3 result_rgb = set_luminance(src_rgb, lum);
	
	// Darkness scale
	result_rgb = mix(result_rgb, (result_rgb * vec3(0.0)), clamp(darkness_scale, 0.0, 1.0));

	COLOR = vec4(result_rgb, base.a);
	//COLOR = mix(vec4(result_rgb, 0.0), vec4(result_rgb, base.a)*1.75, mod((uv.y * instance_vframes), 1.0));
}