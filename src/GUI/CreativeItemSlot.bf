using Voxis.Items;
namespace Voxis.GUI;

public class CreativeItemSlot : BaseItemSlot
{
	private ItemStack _contents;

	public this(ItemStack itemStack)
	{
		_contents = itemStack;
	}

	public override Voxis.Items.ItemStack GetContainedItemStack()
	{
		return _contents;
	}
}