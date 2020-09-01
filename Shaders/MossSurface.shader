shader_type spatial;
render_mode blend_mix,depth_draw_opaque,cull_back,diffuse_lambert,specular_schlick_ggx,world_vertex_coords;
uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;

uniform vec4 albedo_top : hint_color;
uniform sampler2D texture_albedo_top : hint_albedo;

uniform float specular;
uniform float metallic;
uniform float roughness : hint_range(0,1);
varying vec3 uv1_triplanar_pos;
varying vec3 uv1_top_triplanar_pos;
uniform float uv1_blend_sharpness;
varying vec3 uv1_power_normal;
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv1_top_scale;

varying float upside;
uniform float UpSideThreshold : hint_range(0.0, 0.999) = 0.8;
uniform float UpSideSharpness = 1.0;


void vertex() {
	TANGENT = vec3(0.0,0.0,-1.0) * abs(NORMAL.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(NORMAL.z);
	TANGENT = normalize(TANGENT);
	BINORMAL = vec3(0.0,-1.0,0.0) * abs(NORMAL.x);
	BINORMAL+= vec3(0.0,0.0,1.0) * abs(NORMAL.y);
	BINORMAL+= vec3(0.0,-1.0,0.0) * abs(NORMAL.z);
	BINORMAL = normalize(BINORMAL);
	uv1_power_normal=pow(abs(NORMAL),vec3(uv1_blend_sharpness));
	uv1_power_normal/=dot(uv1_power_normal,vec3(1.0));

	uv1_triplanar_pos = VERTEX * uv1_scale + uv1_offset;
	uv1_triplanar_pos *= vec3(1.0,-1.0, 1.0);

	uv1_top_triplanar_pos = VERTEX * uv1_top_scale + uv1_offset;
	uv1_top_triplanar_pos *= vec3(1.0,-1.0, 1.0);
	
	upside = NORMAL.y;
}


vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}


void fragment() {
	float upside_fac = clamp(upside - UpSideThreshold, 0.0, 1.0) / (1.0 - UpSideThreshold);
	upside_fac = clamp(upside_fac * UpSideSharpness, 0.0, 1.0);

	vec4 albedo_tex = triplanar_texture(texture_albedo,uv1_power_normal,uv1_triplanar_pos);
	vec4 albedo_tex_top = triplanar_texture(texture_albedo_top,uv1_power_normal,uv1_top_triplanar_pos);
	
	ALBEDO = mix(albedo.rgb * albedo_tex.rgb, albedo_top.rgb * albedo_tex_top.rgb, upside_fac);
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
}
