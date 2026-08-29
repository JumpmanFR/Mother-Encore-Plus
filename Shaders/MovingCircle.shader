shader_type canvas_item;
render_mode unshaded;

uniform bool circle_visible = true;

uniform float radius : hint_range(0.0, 500.0) = 64;
uniform vec2 position = vec2(160, 90);
uniform vec2 offset = vec2(0, 0);
uniform vec2 textSize = vec2(320, 180);

uniform bool animated = false;
uniform float speed = 1.0;
uniform float time : hint_range(0.0, 1);

float ratio()
{
	return textSize.x / textSize.y;
}

float circle(vec2 uv, float rad, vec2 pos, vec2 off, float spd)
{
	float newTime = time * 3.14 * 2.0;
	if (animated) newTime += TIME;
	
	
	rad = rad / (textSize.y * 2.0);
	vec2 circlePosition =  vec2(mix(0.5, pos.x/(textSize.x), ratio()), pos.y/(textSize.y));
	vec2 circleOffset =  vec2(mix(0.0, off.x/(textSize.x) * cos(newTime * spd), ratio()), off.y/(textSize.y) * sin(newTime * spd));
	float dist = distance(circlePosition + circleOffset, vec2(mix(0.5, uv.x, ratio()) , uv.y ));
	return step(rad, dist);
}

void fragment()
{
	
	if (circle_visible)
	{
		float c1 = circle(UV, radius, position, offset, speed) * 0.5;
		float c2 = circle(UV, radius, position, -offset, -speed ) * 0.5;
		COLOR.a = COLOR.a * (c2 + c1);
	}
}