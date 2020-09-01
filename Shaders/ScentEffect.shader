shader_type spatial;
render_mode blend_mix,depth_draw_alpha_prepass,cull_back,diffuse_lambert,specular_schlick_ggx, world_vertex_coords;
uniform sampler2D texture_mask : hint_albedo;
uniform vec4 emission : hint_color;
uniform float emission_energy;
uniform vec3 uv1_scale;

uniform float modulate_effect = 1.0;

void vertex() {
	VERTEX.x += sin((TIME-VERTEX.y*10.0)*1.2)*0.05;
	VERTEX.z += sin((TIME-VERTEX.y*10.0)*1.6)*0.05;
}




void fragment() {
	vec2 base_uv = UV*uv1_scale.xy + vec2(0.0, TIME*0.03);
	vec4 mask_tex = texture(texture_mask, base_uv);
	ALBEDO = vec3(0.0);
	METALLIC = 0.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	EMISSION = emission.rgb * emission_energy;
	ALPHA = modulate_effect * mask_tex.a;
}
