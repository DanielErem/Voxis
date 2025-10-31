namespace Voxis
{
	public class Lamp : Block
	{
		public override LightLevel GetEmittedLight(BlockState state)
		{
			return LightLevel(15, 15, 15, 0);
		}

		public override bool EmitsLight(BlockState state)
		{
			return true;
		}
	}
}