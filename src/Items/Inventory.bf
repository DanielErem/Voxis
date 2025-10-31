using System;

namespace Voxis.Items;

public class Inventory
{
    public delegate void ContentsChangedDelegate(int slotIndex, ItemStack oldStack, ItemStack newStack);

	public Event<ContentsChangedDelegate> OnContentsChanged = default;

    public int Size
    {
        get
        {
            return itemStacks.Count;
        }
    }

    private ItemStack[] itemStacks;

    public this(int capacity)
    {
        itemStacks = new ItemStack[capacity];

		for (int i = 0; i < itemStacks.Count; i++)
		{
			itemStacks[i] = ItemStack.Empty;
		}
    }

    public ItemStack GetItemStackInSlot(int slot)
    {
        return itemStacks[slot];
    }

    public void SetItemStackInSlot(int slot, ItemStack itemStack)
    {
        ItemStack oldItemStack = itemStacks[slot];

        itemStacks[slot] = itemStack;

        OnContentsChanged(slot, oldItemStack, itemStack);
    }

    public bool HasItems(ItemStack itemStack)
    {
        int count = itemStack.Count;
        for (ItemStack inInventory in itemStacks)
        {
            if (inInventory.Matches(itemStack))
            {
                count -= inInventory.Count;

                if (count <= 0) return true;
            }
        }

        return false;
    }

    public ItemStack InsertItemStack(ItemStack itemStack)
    {
		// Mutable copy
		var itemStack;

        // First try stacking
        if (!itemStack.IsEmpty)
        {
            for (int i = 0; i < itemStacks.Count; i++)
            {
                ItemStack existing = itemStacks[i];

                if (existing.CanStack(itemStack))
                {
                    int amount = Math.Min(itemStack.Count, itemStack.Item.StackLimit - existing.Count);

                    itemStack = itemStack.Subtract(amount);

                    SetItemStackInSlot(i, existing.Add(amount));
                }
            }
        }

        if (!itemStack.IsEmpty)
        {
            for (int i = 0; i < itemStacks.Count; i++)
            {
                if (itemStacks[i].IsEmpty)
                {
                    SetItemStackInSlot(i, itemStack);

                    return ItemStack.Empty;
                }
            }
        }

        return itemStack;
    }

    public ItemStack ExtractItemStack()
    {
        for (int i = 0; i < Size; i++)
        {
            if (!itemStacks[i].IsEmpty)
            {
                ItemStack copy = itemStacks[i];
                SetItemStackInSlot(i, copy);
                return copy;
            }
        }

        return ItemStack.Empty;
    }
}