namespace Voxis
{
	public struct PaletteEntry
	{
		public BlockState State { get; set mut; }
		public int Reference { get; set mut; }

		public this()
		{
			State = null;
			Reference = 0;
		}

		public this(BlockState state, int reference)
		{
			this.State = state;
			this.Reference = reference;
		}
	}
}
