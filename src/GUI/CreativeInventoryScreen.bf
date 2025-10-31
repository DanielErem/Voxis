using Voxis.Items;

namespace Voxis.GUI;

public class CreativeInventoryScreen : GUIScreen
{
	public Player Player { get; set; }

	private VerticalBox _vbox = new VerticalBox();
	private ScrollView _scrollView = new ScrollView();

	public this()
	{
		CloseOnEscape = true;
		IsHud = false;

		_scrollView.RelAnch = .Center;
		_scrollView.RelMarg = .(-50, -50, 50, 50);

		_scrollView.AddChild(_vbox);
		AddChild(_scrollView);

		Item[] items = GameRegistry.Item.GetAllAsArray();
		for (Item item in items)
		{
			if (item is BlockItem)
			{
				ItemStack target = ItemStack(item, 1);

				CreativeItemSlot slot = new CreativeItemSlot(target);
				_vbox.AddChild(slot);
			}
		}
		delete items;
	}

	public override void OnDraw(int currentDepth)
	{
		// Draw dark background
		CanvasRenderPipeline.DrawRect(Rect(0, 0, WindowServer.Width, WindowServer.Height), Color(0, 0, 0, 0.7f), 1);

		base.OnDraw(currentDepth);
	}
}