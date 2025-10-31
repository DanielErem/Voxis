#version 450

#define MAX_TEXTURES 16

in vec4 v_color;
in vec2 v_texcoord;

out vec4 FRAGMENT;

uniform sampler2D TEXTURE;

void main()
{
	FRAGMENT = texture(TEXTURE, v_texcoord) * v_color;
}