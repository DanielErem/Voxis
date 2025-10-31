namespace Voxis.Graphics;

public class DrawCommand
{
	public Mesh MeshToDraw { get; set; }
	public Matrix4x4 ModelMatrix { get; set; }
	public VertexLayout Layout { get; set; }
	public Material Material { get; set; }
	public MaterialInstanceProperties Properties { get; set; }

	public Vector3 SortPivot { get; set; }
}