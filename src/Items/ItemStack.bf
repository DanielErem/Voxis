using Voxis.Data;
using System;

namespace Voxis.Items;

public struct ItemStack : IDisposable
{
    public static ItemStack Empty = ItemStack(null, 0);

    public Item Item { get; }
    public int Count { get; }
	
    public readonly bool HasProgressBar => Item.HasProgressBar(this);
    public readonly float MaximumProgress => Item.GetMaximumProgress(this);
    public readonly float CurrentProgress => Item.GetProgress(this);

	private DataTree _metadata;

    public float GetHarvestEfficiency(BlockState forState)
    {
        return Item.GetHarvestEfficiency(this, forState);
    }
    public float GetHarvestSpeed(BlockState forState)
    {
        return Item.GetHarvestSpeed(this, forState);
    }
    public ItemUseResult OnUse(Player user)
    {
        return Item.OnUse(this, user);
    }
    public ItemUseResult OnUseOnBlock(Player user)
    {
        return Item.OnUseOnBlock(this, user);
    }
    public ItemBehaviour GetRightClickBehavior()
    {
        return Item.GetRightClickBehavior(this);
    }
    public void OnBlockBrokenWith(World world, BlockPos pos, Player player)
    {
        Item.OnBlockBrokenWith(this, world, pos, player);
    }

    public bool IsEmpty
    {
        get
        {
            return Item == null || Count <= 0;
        }
    }

    public static ItemStack FromID(StringView id, int count)
    {
        Item item = GameRegistry.Item.Get(id);

        return ItemStack(item, count);
    }

    public this(Item item, int count)
    {
        Item = item;
        Count = count;
		_metadata = null;
    }

    public bool CanStack(ItemStack other)
    {
        // Items with metadata are not stackable
        if (HasMetadata() || other.HasMetadata())
        {
            return false;
        }

        return other.Item == Item;
    }

    public ItemStack WithCount(int newCount)
    {
        return ItemStack(Item, newCount);
    }

    public ItemStack Subtract(int amount)
    {
        return ItemStack(Item, Count - amount);
    }

    public ItemStack Add(int amounts)
    {
        return ItemStack(Item, Count + amounts);
    }

    public bool Matches(ItemStack other)
    {
        return Item == other.Item;
    }

    public void Combine(ItemStack other, out ItemStack thisResult, out ItemStack otherResult)
    {
        if (!CanStack(other))
        {
            otherResult = other;
            thisResult = this;
            return;
        }

        int amount = Math.Min(other.Count, other.Item.StackLimit);

        otherResult = other.Subtract(amount);
        thisResult = Add(amount);
    }

    public bool HasMetadata()
    {
        return _metadata != null;
    }
    public void SetMetadata(StringView key, TreeNode data) mut
    {
		if (_metadata == null) _metadata = new DataTree();

		_metadata.Root.Set(key, data);
    }
    public TreeNode GetMetadata(StringView key, TreeNode defaultValue)
    {
        if (_metadata == null) return defaultValue;

		return _metadata.Root.GetOrDefault(key, defaultValue);
    }
	public void Dispose()
	{
		if (_metadata != null) delete _metadata;
	}
}