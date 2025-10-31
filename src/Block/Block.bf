using System;

namespace Voxis
{
	public class Block : RegistryObject
	{
		public BlockStateContainer BlockStateContainer { get; };
		public BlockModelBaker ModelBaker { get; set; }

		public BlockState DefaultState
		{
			get
			{
				return BlockStateContainer.DefaultState;
			}
		}

		public this()
		{
			BlockStateContainer = new BlockStateContainer(this);

			AppendProperties(BlockStateContainer);

			BlockStateContainer.Build();
		}

		public ~this()
		{
			delete BlockStateContainer;
			if (ModelBaker != null) delete ModelBaker;
		}

		public virtual float GetHardness(BlockState state)
		{
			return 1.0f;
		}

		public virtual bool GeneratesCollision(BlockState state)
		{
			return true;

		}
		public virtual bool DoesRender(BlockState state)
		{
			return true;
		}
		public virtual bool DoesOcclude(BlockState state, OcclusionDirection direction)
		{
			return true;
		}
		public virtual BoundingBox GetCollisionBox(BlockState state)
		{
			return BoundingBox(.Zero, .One);
		}
		public virtual bool HasCollision(BlockState state)
		{
			return true;
		}
		public virtual bool LetsLightThrough(BlockState state)
		{
			return false;
		}
		public virtual int FilterLight(BlockState state, int value, int component)
		{
			return value - 1;
		}
		public virtual bool EmitsLight(BlockState state)
		{
			return false;
		}
		public virtual LightLevel GetEmittedLight(BlockState state)
		{
			return LightLevel.Empty;
		}

		protected virtual void AppendProperties(BlockStateContainer container)
		{

		}
	}
}
