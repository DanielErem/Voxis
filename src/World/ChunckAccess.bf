using System;

namespace Voxis
{
	// Fast Access to a working chunck with its neighbours
	// Working coordinates are in local space relative to the
	// working chunck. Center chunck is at x = 0 y = 0 z = 0
	public class ChunckAccess : IWorldAccessRead, IWorldAccessWrite
	{
		private Chunck[] chuncks;
		private ChunckIndex indexOffset;

		public bool Locked { get; private set; }
		public Chunck[] ChunckArray
		{
			get
			{
				return chuncks;
			}
		}

		public this()
		{
			this.chuncks = new Chunck[9];
			this.indexOffset = indexOffset;
		}

		public ~this()
		{
			delete chuncks;
		}

		public void LockChuncks()
		{
			if (Locked) Runtime.FatalError("Tried to lock chunck access twice");

			Locked = true;
			for (Chunck ch in chuncks)
			{
				ch.Locked = true;
			}
		}
		public void UnlockChuncks()
		{
			Locked = false;
			for (Chunck ch in chuncks)
			{
				 ch.Locked = false;
			}
		}

		public void UpdateState(Chunck[] newArray, ChunckIndex newOffset)
		{
			if (Locked) Runtime.FatalError("Tried to modify a locked chunck access");

			chuncks = newArray;
			indexOffset = newOffset;
		}

		// The chunck in the middle
		public Chunck GetWorkingChunck()
		{
			return chuncks[4];
		}

		public BlockState GetBlockState(BlockPos position)
		{
			let localPos = position.GetChunckLocalPosition();
			Chunck chunck = ChunckFromBlockPos(position);
			if (chunck == null) return AirBlock.DEFAULT_AIR_STATE;
			return chunck.GetBlockState(localPos.x, localPos.y, localPos.z);
		}
		public void SetBlockState(BlockPos position, BlockState state, BlockstatUpdateFlags flags = BlockstatUpdateFlags.All)
		{
			let localPos = position.GetChunckLocalPosition();
			ChunckFromBlockPos(position).SetBlockState(localPos.x, localPos.y, localPos.z, state, flags);
		}
		public void SetLight(BlockPos position, LightLevel lights)
		{
			let localPos = position.GetChunckLocalPosition();
			ChunckFromBlockPos(position).SetLightRaw
				(localPos.x, localPos.y, localPos.z, lights);
		}
		public void SetLightNoUpdate(BlockPos position, LightLevel lights)
		{
			let localPos = position.GetChunckLocalPosition();
			ChunckFromBlockPos(position).SetLightRaw
				(localPos.x, localPos.y, localPos.z, lights);
		}
		public LightLevel GetLight(BlockPos pos)
		{
			let localPos = pos.GetChunckLocalPosition();
			return ChunckFromBlockPos(pos).GetLight(localPos.x, localPos.y, localPos.z);
		}

		private Chunck ChunckFromBlockPos(BlockPos position)
		{
			ChunckIndex index = position.GetChunckIndex();
			index = index.Offset(-indexOffset.X, -indexOffset.Z);
			index = index.Offset(1, 1);

			int realIndex = index.Z * 3 + index.X;
			if (realIndex < 0 || realIndex >= chuncks.Count) return null;
			return chuncks[realIndex];
		}
	}
}
