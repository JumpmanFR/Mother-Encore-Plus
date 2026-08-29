shader_type canvas_item;

uniform float speed = 1.0;
uniform vec2 img1_speed;
uniform sampler2D noise_img;
uniform float img1_size = 100;
uniform float img1_opacity = 1.0;

uniform vec2 img2_speed;
uniform sampler2D noise_img2;
uniform float img2_size = 100;
uniform float img2_opacity = 1.0;


varying vec2 world_position;
varying vec2 tex_position;

void vertex(){
	// calculate the world position for use in the fragment shader
	world_position = (vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment(){
	vec2 worldpos1 = world_position * (1.0/img1_size);
	vec2 worldpos2 = world_position * (1.0/img2_size);
	
	vec2 uv1 = worldpos1 - img1_speed * TIME * speed;
	vec2 uv2 = worldpos2 - img2_speed * TIME * speed;
	
	float noise = pow(texture(noise_img, uv1).r, img1_opacity);
	float noise2 = pow(texture(noise_img2, uv2).r, img2_opacity);
	
	vec3 new_color = vec3(noise, noise2, noise);
	
	float new_alpha = COLOR.a * noise * noise2 ;
	COLOR.a = new_alpha;
	
}