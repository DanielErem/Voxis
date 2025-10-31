using System.Collections;
using System;

namespace Voxis
{
	public static class GUICanvas
	{
		public static int Width { get; set; }
		public static int Height { get; set; }
		public static GUITheme Theme { get; set; }

		public static GUIElement FocusedElement { get; private set; }

		public static GUIScreen ExclusiveScreen { get; private set; }

		public static Matrix3x2 CurrentTransform { get; private set; } = Matrix3x2.Identity;

		private static List<GUIScreen> screens = new List<GUIScreen>() ~ DeleteContainerAndItems!(_);
		private static Queue<GUIScreen> deletionQueue = new Queue<GUIScreen>();

		private static List<Matrix3x2> transformStack = new List<Matrix3x2>() ~ delete _;

		public static bool IsBlockingInput()
		{
			if (ExclusiveScreen != null) return true;

			for (GUIScreen screen in screens)
			{
				if (!screen.IsHud) return true;
			}

			return false;
		}

		public static void PushTransform(Matrix3x2 matrix)
		{
			transformStack.Add(matrix);

			CurrentTransform *= matrix;
		}

		public static void PopTransform()
		{
			transformStack.PopBack();

			// Need to recalculate everything
			Matrix3x2 result = Matrix3x2.Identity;

			for (Matrix3x2 mat in transformStack)
			{
				result *= mat;
			}

			CurrentTransform = result;
		}

		public static void AddScreen(GUIScreen screen)
		{
			screens.Add(screen);
			screen.OnEnterStack();

			SetFocused(null);
		}
		public static void RemoveScreen(GUIScreen screen)
		{
			if (ExclusiveScreen == screen)
			{
				ExclusiveScreen = null;
			}

			screens.Remove(screen);
			screen.OnExitStack();

			SetFocused(null);
		}
		public static void QueueDeletion(GUIScreen screen)
		{
			deletionQueue.Add(screen);
		}
		public static void ShowExclusive(GUIScreen screen)
		{
			// Remove all other active screens
			List<GUIScreen> toRemove = scope List<GUIScreen>();
			for (GUIScreen screene in screens)
			{
				if (!screene.IsHud)
				{
					toRemove.Add(screene);
				}
			}
			for (GUIScreen r in toRemove)
			{
				RemoveScreen(r);
			}

			AddScreen(screen);
			ExclusiveScreen = screen;
		}

		public static void SetFocused(GUIElement newFocus)
		{
			if (FocusedElement != null)
			{
				FocusedElement.[Friend]IsFocused = false;
				FocusedElement.[Friend]OnFocusExit();
			}

			FocusedElement = newFocus;

			if (FocusedElement != null)
			{
				FocusedElement.[Friend]IsFocused = true;
				FocusedElement.[Friend]OnFocusEnter();
			}
		 }

		public static T SearchTaggedElement<T>(StringView tag) where T : GUIElement
		{
			for(GUIScreen screen in screens)
			{
				T temp = screen.SearchTaggedElement<T>(tag);

				if (temp != null) return temp;
			}

			return null;
		}

		public static void OnLoad()
		{
			Theme = new GUITheme();
			Theme.OnLoad();

			InputServer.OnInputEvent.Add(new => OnInputEvent);
		}

		public static void OnShutdown()
		{
			delete Theme;
			ProcessDeletionQueue();
			delete deletionQueue;
		}

		public static void OnUpdate()
		{
			ProcessDeletionQueue();

			for(GUIScreen screen in screens){
				screen.OnUpdate();
			}
		}
		public static void OnDraw()
		{
			Width = WindowServer.Width;
			Height = WindowServer.Height;

			GraphicsServer.SetViewport(0, 0, 0, uint32(Width), uint32(Height));

			Matrix4x4 projectionMatrix = Matrix4x4.CreateOrthographicOffCenter(0, Width, Height, 0, 0.0f, 1000.0f);
			CanvasRenderPipeline.Begin(projectionMatrix);

			int currentCanvasDepth = 0;

			// Only draw the exclusive screen if its set
			// Otherwise draw all the other screens
			if (ExclusiveScreen != null)
			{
				ExclusiveScreen.OnDraw(currentCanvasDepth);
			}
			else
			{
				for(GUIScreen screen in screens)
				{
					screen.OnDraw(currentCanvasDepth);
	
					currentCanvasDepth += 128;
				}
			}
			CanvasRenderPipeline.End();
		}

		private static void OnInputEvent(InputEvent event)
		{
			// Event order is reversed (deeper childs are on top the screen so they should be evaluated first)
			for (int i = screens.Count - 1; i >= 0; i--)
			{
				screens[i].OnInputEvent(event);
			}
		}

		private static void ProcessDeletionQueue()
		{
			while(deletionQueue.Count > 0)
			{
				GUIScreen sc = deletionQueue.PopFront();
				sc.OnExitStack();
				screens.Remove(sc);
				delete sc;
			}
		}
	}
}
