using System;

namespace Voxis.GUI;

public class TextureRect : GUIElement
{
	public Texture2D Texture { get; set; }
	public TextureDrawMode TextureDrawMode { get; set; } = .Tile;

	public override void Parse(Voxis.Data.TreeNode elementNode)
	{
		base.Parse(elementNode);

		StringView texturePath = elementNode.GetOrDefault("texture", .Text("")).AsText();

		if (!texturePath.IsEmpty && !texturePath.IsWhiteSpace)
		{
			Texture = ResourceServer.LoadTexture2D(texturePath);
		}
	}

	public override void OnDraw(int currentDepth)
	{
		switch (TextureDrawMode)
		{
		case .Tile:
			CanvasRenderPipeline.DrawTiledTexturedRect(ScreenRect, Texture, currentDepth);
			break;
		case .Stretch:
			CanvasRenderPipeline.DrawTexturedRect(ScreenRect, Texture, currentDepth);
			break;
		}

		base.OnDraw(currentDepth);
	}
}