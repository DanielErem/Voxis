using System;
using System.Collections;

namespace Voxis.Items;

public class Item : RegistryObject
{
    public int StackLimit { get; } = 64;

    public virtual bool CanHarvest(ItemStack itemStack, BlockState state)
    {
		return false;
    }
    public virtual bool IsEffectiveOn(ItemStack itemStack, BlockState state)
    {
		return false;
    }
    public virtual float GetHarvestEfficiency(ItemStack itemStack, BlockState state)
    {
		return 0.0f;
    }
    public virtual bool HasProgressBar(ItemStack itemStack)
    {
		return false;
    }
    public virtual float GetMaximumProgress(ItemStack itemStack)
    {
		return 1.0f;
    }
    public virtual float GetProgress(ItemStack itemStack)
    {
		return 0.0f;
    }
    public virtual ItemUseResult OnUse(ItemStack itemStack, Player user)
    {
        return ItemUseResult.Failure;
    }
    public virtual ItemUseResult OnUseOnBlock(ItemStack itemStack, Player user)
    {
        return ItemUseResult.Failure;
    }
    public virtual ItemBehaviour GetRightClickBehavior(ItemStack itemStack)
    {
        return ItemBehaviour.Default;
    }
    public virtual void OnBlockBrokenWith(ItemStack itemStack, World world, BlockPos targetPos, Player player)
    {

    }

    public float GetHarvestSpeed(ItemStack itemStack, BlockState state)
    {
        float harvestTime = state.Hardness;

        // If we cant harvest it, double the time and thats it
        if (!CanHarvest(itemStack, state))
        {
            return harvestTime * 2.0f;
        }
        // If any item component reports it as beeing efective, add mining efficiency to time
        if (IsEffectiveOn(itemStack, state))
        {
            return harvestTime - itemStack.GetHarvestEfficiency(state);
        }

        return harvestTime;
    }

    public virtual Mesh GetRenderMesh(ItemStack itemStack)
    {
		return null;
        //return ModelCache.GetItemMesh(this);
    }
}
