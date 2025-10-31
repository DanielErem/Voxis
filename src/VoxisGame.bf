using System;
using System.Diagnostics;
using Voxis.Graphics;
using System.Diagnostics;

namespace Voxis
{
	public class VoxisGame
	{
		public static VoxisGame Instance { get; private set; }

		public World World { get; private set; }

		public bool EnableDebugRendering { get; set; } = true;

		private bool performanceQueryStarted = false;

		public this()
		{
			VoxisGame.Instance = this;
		}

		public ~this()
		{
			if (World != null) delete World;
		}


		public void SetWorld(World world)
		{
			World = world;
		}

		public void Run()
		{
			// Setup other callbacks
			GraphicsServer.OnDebugMessageEvent.Add(scope => OnGraphicsDebugEvent);
			InputServer.OnInputEvent.Add(new => OnInputEvent);

			OnInitialize();
			OnLoad();

			OnGameStart();

			// Setup and start time measurement
			Time.Start();

			// Actual main loop
			while(WindowServer.WindowExists)
			{
				// Clear performance metrics
				Performance.Reset();

				OnUpdateFrame();

				GraphicsServer.StartPerformanceMeasurement();
				OnRenderFrame();
				GraphicsServer.EndPerformanceMeasurement();

				PriorityTasker.DispatchTasks();
			}

			World?.Destroy();

			OnShutdown();
		}

		private void OnInitialize()
		{
			WindowServer.OnInitialize();
			AudioServer.OnInitialize();

			ResourceServer.MountDirectory("assets/");

			InputServer.OnInitialize();
		}
		private void OnLoad()
		{
			GraphicsServer.OnLoad();

			RenderPipeline3D.OnLoad();
			CanvasRenderPipeline.OnLoad();
			GUICanvas.OnLoad();
		}
		private void OnGameStart()
		{
			VoxisGameContent.RegisterContent();

			BlockModelServer.BakeModels();
			VoxelTextureManager.BakeTextures();

			GUICanvas.AddScreen(new MainMenu());
		}
		private void OnShutdown()
		{
			GUICanvas.OnShutdown();
			CanvasRenderPipeline.OnShutdown();
			RenderPipeline3D.OnShutdown();

			InputServer.OnShutdown();

			GraphicsServer.OnShutdown();
			WindowServer.OnShutdown();

			PriorityTasker.ClearTasks();
		}
		private void OnUpdateFrame()
		{
			Time.Frame();

			WindowServer.OnUpdate();

			World?.OnUpdate();
			GUICanvas.OnUpdate();
		}
		private void OnRenderFrame()
		{
			// Prepare rendering
			GraphicsServer.ClearColorTarget(.Black);
			GraphicsServer.ClearDepthStencilTarget();

			World?.OnRender();

			if (EnableDebugRendering)
			{
				World?.OnDebugRender();
			}

			GUICanvas.OnDraw();

			WindowServer.SwapBuffers();
		}
		private void OnFixedUpdate()
		{
			World?.OnFixedUpdate();
		}
		private void OnTick()
		{
			World?.OnTick();
		}

		private void OnGraphicsDebugEvent(GraphicsDeviceDebugMessage debugMessage)
		{
			LoggingServer.LogLevel logLevel = .Debug;
			switch(debugMessage.Severity)
			{
			case .High:
				logLevel = .Fatal;
			case .Medium:
				logLevel = .Error;
			case .Low:
				logLevel = .Warning;
			case .Info:
				logLevel = .Info;
			}

			LoggingServer.LogMessage(debugMessage.Message, logLevel);
		}

		private void OnInputEvent(InputEvent event)
		{
			World?.OnInputEvent(event);
		}
	}
}
