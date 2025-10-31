using System;

namespace Voxis
{
	[Ordered]
	public struct Vertex3D
	{
		public Vector3 Position;
		public Vector2 TexCoord;
		public Color Color;
		public Vector3 Normal;

		public this(Vector3 pos, Vector2 texcoord, Color color, Vector3 normal)
		{
			Position = pos;
			TexCoord = texcoord;
			Color = color;
			Normal = normal;
		}

		public this(Vector3 pos)
		{
			Position = pos;
			TexCoord = Vector2.Zero;
			Color = Color(1.0f, 1.0f, 1.0f, 1.0f);
			Normal = Vector3.Zero;
		}
	}
}
