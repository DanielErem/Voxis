namespace Voxis.Items;

public class BlockItem : Item
{
	public Block TargetBlock { get; private set; }

	public this(Block targetBlock)
	{
		TargetBlock = targetBlock;
	}
}