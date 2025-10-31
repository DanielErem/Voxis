namespace Voxis.GUI;

public class ScrollView : GUIElement
{
	public bool ScrollVertial { get; set; } = true;

	public Vector2 Scroll { get; set; } = Vector2.Zero;

	public override void OnDraw(int currentDepth)
	{
		// Enable scissor, THEN draw children

		CanvasRenderPipeline.EnableScissor(ScreenRect);

		base.OnDraw(currentDepth);

		CanvasRenderPipeline.DisableScissor();
	}

	public override void OnUpdate()
	{
		base.OnUpdate();

		// Offset all children by scroll value
		for (GUIElement child in childElements)
		{
			child.RelAnch = .(0, 0, 0, 0);

			Vector2 childSize = child.GetMinSize();

			childSize.X = System.Math.Max(childSize.X, ScreenRect.Width);
			childSize.Y = System.Math.Max(childSize.Y, ScreenRect.Height);

			// TODO: Maybe add size flags?

			child.RelMarg = .(Scroll.X, Scroll.Y, Scroll.X + childSize.X, Scroll.Y + childSize.Y);
		}	 
	}
}