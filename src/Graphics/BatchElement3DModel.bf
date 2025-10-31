namespace Voxis.Graphics;

public class BatchElement3DModel : BatchElement
{
	public Mesh MeshToRender { get; set; }
	public Matrix4x4 ModelMatrix { get; set; }
	public Material MaterialToUse { get; set; }
	public VertexLayout Layout { get; set; }
}