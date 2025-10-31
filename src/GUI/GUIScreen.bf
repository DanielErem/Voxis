namespace Voxis
{
	public abstract class GUIScreen : GUIElement
	{
		public override GUIScreen Root
		{
			get
			{
				return this;
			}
		}

		public override Rect ScreenRect
		{
			get
			{
				return Rect(0, 0, GUICanvas.Width, GUICanvas.Height);
			}
		}

		public bool CloseOnEscape { get; protected set; }
		public bool IsHud { get; protected set; }
		public bool ReuseInstance { get; set; } = false;

		private GUICanvas canvas;

		public this()
		{
			// This is only an invisible container, dont stop events!
			EventFlags = .Pass;
		}

		public void SetCanvas(GUICanvas canvas)
		{
			this.canvas = canvas;
		}

		public virtual void OnEnterStack(){}
		public virtual void OnExitStack(){}

		public override void OnInputEvent(InputEvent event)
		{
			if (CloseOnEscape && event is InputEventKeyboardKey)
			{
				InputEventKeyboardKey keyEvent = event as InputEventKeyboardKey;

				if (keyEvent.Key == KeyboardKey.Escapce)
				{
					GUICanvas.RemoveScreen(this);

					return;
				}
			}

			base.OnInputEvent(event);
		}
	}
}
