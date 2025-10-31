using System;

namespace Voxis
{
	public class Label : GUIElement
	{
		public String Text { get; set; }
		public HAlign TextHAlign { get; set; }
		public VAlign TextVAlign { get; set; }

		public this(StringView text = "Label")
		{
			Text = new String(text);

			TextHAlign = .Left;
			TextVAlign = .Center;

			HLayoutFlags = .None;
			VLayoutFlags = .None;
		}

		public ~this()
		{
			delete Text;
		}

		public override void OnDraw(int currentDepth)
		{
			GUICanvas.PushTransform(Transform);

			Vector2 textStart = GUICanvas.Theme.MainFont.AlignTextStart(Text, ScreenRect, TextVAlign, TextHAlign);

			GUICanvas.Theme.MainFont.RenderText(textStart, Text, currentDepth + CustomDepth);

			base.OnDraw(currentDepth);

			GUICanvas.PopTransform();
		}

		public override Vector2 GetMinSize()
		{
			return Vector2(GUICanvas.Theme.MainFont.MeasureText(Text), GUICanvas.Theme.MainFont.LineHeight);
		}

		public override void Parse(Voxis.Data.TreeNode elementNode)
		{
			base.Parse(elementNode);

			if (elementNode.Contains("text"))
			{
				Text.Clear();
				elementNode.GetOrDefault("text", Text, "Label");
			}
		}
	}
}
