namespace Voxis.GUI;

public class GUIBlockModel : GUIElement
{
	public BlockModel ModelToRender { get { return _modelToRender; } set { if (_modelToRender == value) { return; } _modelToRender = value; UpdateMesh(); }}

	public Vector3 ModelScale{ get; set; } = Vector3.One * 100.0f;
	public Quaternion ModelRotation { get; set; }

	private BlockModel _modelToRender;
	private Mesh _modelMesh;

	public this()
	{
		ModelRotation = Quaternion.CreateFromAxisAngle(Vector3.UnitX, ExtMath.Deg2Rad(225.0f));
		ModelRotation *= Quaternion.CreateFromAxisAngle(Vector3.UnitY, ExtMath.Deg2Rad(45.0f));
	}

	public void UpdateMesh()
	{
		if (_modelToRender == null) return;

		if (_modelMesh == null) _modelMesh = new Mesh(false);

		ChunckMesh chunckMesh = new ChunckMesh();

		for (BakedQuad quad in _modelToRender.Quads)
		{
			chunckMesh.InsertQuad(quad, LightLevel(0,0,0,15), Vector3.Zero);
		}
		chunckMesh.Upload(_modelMesh);

		delete chunckMesh;
	}

	public override void OnDraw(int currentDepth)
	{
		base.OnDraw(currentDepth);

		if (_modelToRender == null) return;

		Vector3 pos = Vector3(this.ScreenRect.Position, 0.0f);
		Matrix4x4 modelMatrix = Matrix4x4.CreateScale(ModelScale) * Matrix4x4.CreateFromQuaternion(ModelRotation) * Matrix4x4.CreateTranslation(pos);

		CanvasRenderPipeline.DrawChunckMesh(_modelMesh, modelMatrix, currentDepth);
	}
}