namespace Voxis
{
	public class Panel : GUIElement
	{
		public override void OnDraw(int currentDepth)
		{
			GUICanvas.Theme.PanelStyle.OnDraw(ScreenRect, currentDepth);

			base.OnDraw(currentDepth);
		}

		public override Vector2 GetMinSize()
		{
			// Just gets the max size of the child elements
			Vector2 childSizes = Vector2.Zero;

			for (GUIElement child in childElements)
			{
				Vector2 childSize = child.GetMinSize();

				childSizes = Vector2.Max(childSizes, childSize);
			}

			return childSizes;
		}
	}
}
