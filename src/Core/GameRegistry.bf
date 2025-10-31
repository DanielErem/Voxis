using Voxis.Items;

namespace Voxis
{
	public static class GameRegistry
	{
		public static Registry<Block> Block = new Registry<Block>();
		public static Registry<Biome> Biome = new Registry<Biome>();
		public static Registry<Item> Item = new Registry<Item>();

		static ~this()
		{
			delete Block;
			delete Biome;
			delete Item;
		}
	}
}