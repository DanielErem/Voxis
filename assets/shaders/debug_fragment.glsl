#version 450

in vec2 V_TEXCOORD;
in vec4 V_COLOR;
in vec3 V_NORMAL;

out vec4 FRAG;

uniform vec4 TINT = vec4(1.0, 1.0, 1.0, 1.0);

void main()
{
    FRAG = V_COLOR * TINT;
}