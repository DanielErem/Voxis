using Voxis.GUI;
using Voxis.Data;

namespace Voxis
{
	public class MainMenu : ParsedGUIScreen
	{
		private Label rotatingLabel;
		private float timeSinceStart = 0.0f;

		public this()
		{
			DataTree tree = DataTree.ReadJSONFile("assets/gui/screens/mainmenu.json");
			ParseFromDatatree(tree);
			delete tree;

			FindElement<Button>("create_world_button").OnClickEvent.Add(new => OnCreateWorldClick);

			rotatingLabel = FindElement<Label>("header");
		}

		private void OnCreateWorldClick()
		{
			GUICanvas.AddScreen(new WorldCreationMenu());

			GUICanvas.QueueDeletion(this);
		}

		public override void OnUpdate()
		{
			base.OnUpdate();

			timeSinceStart += (float)Time.DeltaTime;

			rotatingLabel.Rotation = System.Math.Sin(timeSinceStart);
		}
	}
}
