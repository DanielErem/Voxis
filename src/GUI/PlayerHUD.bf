using System;
using Voxis.GUI;

namespace Voxis
{
	public class PlayerHUD : GUIScreen
	{
		public Player Player { get; set; } = null;

		private LabelTextOwned performanceLabel;
		private GUIBlockModel _selectedBlockPreview;

		public this()
		{
			IsHud = true;
			CloseOnEscape = false;
		}

		public override void OnEnterStack()
		{
			base.OnEnterStack();

			Texture2D crosshairTexture = ResourceServer.LoadTexture2D("textures/gui/crosshair.png");

			ImageRect crosshair = new ImageRect(crosshairTexture);
			crosshair.RelAnch = .Center;
			crosshair.RelMarg = .(-crosshairTexture.Width * 0.5f, -crosshairTexture.Height * 0.5f, crosshairTexture.Width * 0.5f, crosshairTexture.Height * 0.5f);
			AddChild(crosshair);

			IconProgressBar healthBar = new IconProgressBar();
			healthBar.MaxValue = 10;
			healthBar.Value = 5;
			healthBar.BackgroundIcon = ResourceServer.LoadTexture2D("textures/gui/health_back.png");
			healthBar.ForegroundIcon = ResourceServer.LoadTexture2D("textures/gui/health_fore.png");
			Vector2 healthBarSize = healthBar.GetMinSize();
			healthBar.RelAnch = .(0.5f, 1.0f, 0.5f, 1.0f);
			healthBar.RelMarg = .(-healthBarSize.X * 0.5f, -healthBarSize.Y, healthBarSize.X * 0.5f, 0.0f);
			AddChild(healthBar);

			performanceLabel = new LabelTextOwned();
			performanceLabel.RelAnch = .(0, 0, 1, 1);
			performanceLabel.RelMarg = .(0, 0, 0, 0);
			performanceLabel.TextHAlign = .Left;
			performanceLabel.TextVAlign = .Top;
			AddChild(performanceLabel);

			_selectedBlockPreview = new GUIBlockModel();
			_selectedBlockPreview.RelAnch = .(0, 0, 0, 0);
			_selectedBlockPreview.RelMarg = .(100, 100, 0, 0);
			AddChild(_selectedBlockPreview);
		}

		public override void OnUpdate()
		{
			base.OnUpdate();

			String tempString = scope String();
			tempString.AppendF(
				"""
				Drawcall3D: {0}
				Canvas Drawcalls: {1}
				Primitive Drawcalls: {2}
				FPS: {3}
				GPU Elapsed time: {4}
				Primitives Generated: {5}
				""",
				Performance.LastFrame.DrawCalls3D,
				Performance.LastFrame.DrawCallsCanvas,
				Performance.LastFrame.DrawPrimitive,
				Performance.LastFrame.FPS,
				Performance.LastFrame.GPUElapsedNanos / 1000.0f / 1000.0f,
				Performance.LastFrame.PrimitivesGenerated
				);
			
			performanceLabel.SetText(tempString);
		}

		public override void OnDraw(int currentDepth)
		{
			base.OnDraw(currentDepth);

			Block selectedBlock = GameRegistry.Block.GetAtIndex(Player.SelectedBlockIndex);

			if (selectedBlock != null && selectedBlock.DefaultState.Model != null)
			{
				_selectedBlockPreview.ModelToRender = selectedBlock.DefaultState.Model;
			}
		}
	}
}
