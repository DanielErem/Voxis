using Voxis.Items;
namespace Voxis.GUI;

public abstract class BaseItemSlot : GUIElement
{
	public abstract ItemStack GetContainedItemStack();

	private BlockModel _modelCache;
	private Mesh _modelMesh;

	public override Vector2 GetMinSize()
	{
		return Vector2(64, 64);
	}

	public override void OnDraw(int currentDepth)
	{
		if (Hovered)
			GUICanvas.Theme.InventorySlotHoveredStyle.OnDraw(ScreenRect, currentDepth);
		else
			GUICanvas.Theme.InventorySlotStyle.OnDraw(ScreenRect, currentDepth);

		ItemStack toRender = GetContainedItemStack();

		if (toRender.IsEmpty || !(toRender.Item is BlockItem)) return;

		BlockItem blockItem = toRender.Item as BlockItem;

		BlockModel model = blockItem.TargetBlock.DefaultState.Model;

		if (model != null && _modelCache != model)
		{
			ChunckMesh chunckMesh = scope ChunckMesh();

			for (BakedQuad quad in model.Quads)
			{
				chunckMesh.InsertQuad(quad, LightLevel(0,0,0,15), Vector3.One * 0.5f);
			}
			if (_modelMesh == null) _modelMesh = new Mesh(true);
			chunckMesh.Upload(_modelMesh);

			_modelCache = model;
		}

		if (_modelMesh != null)
		{
			Quaternion rotation = Quaternion.CreateFromAxisAngle(Vector3.UnitX, ExtMath.Deg2Rad(225.0f));
			rotation *= Quaternion.CreateFromAxisAngle(Vector3.UnitY, ExtMath.Deg2Rad(45.0f));

			Vector3 pos = Vector3(this.ScreenRect.Position + Vector2(-13, 54), 0.0f);
			Matrix4x4 modelMatrix = Matrix4x4.CreateScale(32.0f) * Matrix4x4.CreateFromQuaternion(rotation) * Matrix4x4.CreateTranslation(pos);

			CanvasRenderPipeline.DrawChunckMesh(_modelMesh, modelMatrix, currentDepth + 1);
		}

		base.OnDraw(currentDepth);
	}
}