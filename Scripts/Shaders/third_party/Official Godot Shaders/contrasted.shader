shader_type canvas_item;

// Source - https://godotengine.org/asset-library/asset/122

void fragment() {

	vec3 c = textureLod(SCREEN_TEXTURE,SCREEN_UV,0.0).rgb;
	c=mod(c+vec3(0.5),vec3(1.0));
	COLOR.rgb=c;
}
