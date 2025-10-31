#version 450

uniform sampler2D MAIN_TEX;

uniform vec4 TINT = vec4(1.0, 1.0, 1.0, 1.0);

layout(std140) uniform Environment
{
    uniform vec4 SUN_DIR;
    uniform vec4 SUN_COLOR;
    uniform vec4 AMBIENT_COLOR;
    uniform vec4 FOG;
};

in vec2 V_TEXCOORD;
in vec4 V_COLOR;
in vec3 V_NORMAL;
in vec4 V_POS_EYESPACE;

out vec4 FRAG;

float get_fog_factor(float fog_coord)
{
    float factor = 1.0 - clamp(exp(-pow(FOG.a * fog_coord, 2.0)), 0.0, 1.0);
    return factor;
}

vec4 apply_lighting(vec4 base_color, vec3 normal)
{
    vec3 light_dir = normalize(-SUN_DIR.xyz);
    float diff = max(dot(V_NORMAL, light_dir), 0.0);

    return base_color * AMBIENT_COLOR + base_color * SUN_COLOR * diff;
}

void main()
{
    // Get texture color
    vec4 tex_color = texture(MAIN_TEX, V_TEXCOORD);

    if (tex_color.a < 0.5) discard;

    // Apply lighting
    tex_color = apply_lighting(tex_color, V_NORMAL);

    // Apply fog
    float fog_coord = length(V_POS_EYESPACE);
    float fog_factor = clamp(fog_coord / FOG.a, 0.0, 1.0);
    // float fog_factor = get_fog_factor(fog_coord);

    FRAG = vec4(mix(tex_color.rgb, FOG.rgb, fog_factor), 1.0);
}