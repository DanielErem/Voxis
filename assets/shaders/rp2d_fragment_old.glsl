#version 450

#define MAX_TEXTURES 16

in vec4 v_color;
in vec2 v_texcoord;
in flat int v_texindex;

out vec4 FRAGMENT;

uniform sampler2D TEXTURES[MAX_TEXTURES];

void main()
{
	int index;
	switch(v_texindex)
	{
		case 0:
			index = 0;
			break;
		case 1:
			index = 1;
			break;
		case 2:
			index = 2;
			break;
		case 3:
			index = 3;
			break;
		case 4:
			index = 4;
			break;
		case 5:
			index = 5;
			break;
		case 6:
			index = 6;
			break;
		case 7:
			index = 7;
			break;
		case 8:
			index = 8;
			break;
		case 9:
			index = 9;
			break;
		case 10:
			index = 10;
			break;
		case 11:
			index = 11;
			break;
		case 12:
			index = 12;
			break;
		case 13:
			index = 13;
			break;
		case 14:
			index = 14;
			break;
		case 15:
			index = 15;
			break;
	}

	FRAGMENT = texture(TEXTURES[index], v_texcoord) * v_color;
}