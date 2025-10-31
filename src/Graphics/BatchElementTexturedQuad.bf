namespace Voxis
{
	public class BatchElementTexturedQuad : BatchElement
	{
		public Vector2 StartPosition { get; set; }
		public Vector2 EndPosition { get; set; }
		public Vector2 TexRegionStart { get; set; }
		public Vector2 TexRegionEnd { get; set; }
		public Color Tint { get; set; }
		public Texture2D Texture { get; set; }
		public Matrix3x2 Transform { get; set; } = Matrix3x2.Identity;
	}
}
