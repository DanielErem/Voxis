#version 450

uniform sampler2D SCREEN_COLOR;
uniform sampler2D SCREEN_DEPTH_STENCIL;

layout(std140) uniform Camera
{
    uniform mat4 PROJECTION;
    uniform mat4 VIEW;
};

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

// Required for Fog calculation
in vec4 V_POS_EYESPACE;

out vec4 FRAG;

vec3 apply_vignette(vec3 color, vec2 uv, float intensity)
{
    uv = uv * 2.0 - 1.0; // Transform UV to range [-1, 1]
    float vignette = 1.0 - smoothstep(0.5, 1.0, length(uv));
    vignette = mix(1.0, vignette, intensity);
    return color * vignette;
}

vec3 pixelize(vec2 uv, float pixelSize)
{
    vec2 resolution = textureSize(SCREEN_COLOR, 0);
    float p_x = pixelSize / resolution.x;
    float p_y = pixelSize / resolution.y;
    
    // Koordinaten auf das Pixel-Gitter rastern
    vec2 grid_uv = vec2(
        floor(uv.x / p_x) * p_x,
        floor(uv.y / p_y) * p_y
    );
    
    return texture(SCREEN_COLOR, grid_uv).rgb;
}

vec3 box_blur(vec2 uv, int radius)
{
    vec2 resolution = textureSize(SCREEN_COLOR, 0);
    vec2 offset = 1.0 / resolution;
    vec3 result = vec3(0.0);

    // 3x3 Kernel
    for (int x = -radius; x <= radius; x++) 
    {
        for (int y = -radius; y <= radius; y++) 
        {
            vec2 samplePos = uv + vec2(x, y) * offset;
            result += texture(SCREEN_COLOR, samplePos).rgb;
        }
    }

    int distance = radius * 2 + 1;
    int samples = distance * distance;

    result /= samples; // Durchschnitt bilden

    return result;
}

void main()
{
    //vec3 color = pixelize(V_TEXCOORD, 8.0);
    vec3 color = texture(SCREEN_COLOR, V_TEXCOORD).rgb;
    //vec3 color = box_blur(V_TEXCOORD, 4);

    color = apply_vignette(color, V_TEXCOORD, 0.2);
    
    FRAG = vec4(color, 1.0);
}