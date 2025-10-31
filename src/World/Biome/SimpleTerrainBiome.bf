namespace Voxis;

namespace Voxis
{
	public class SimpleTerrainBiome : Biome
	{
		private BlockState coverBlock, shallowBlock, deepBlock;

		private float baseHeight, heightAmplitude, noiseScale;

		private OpenSimplex2S heightNoise = new OpenSimplex2S(1132) ~ delete _;

		public this(BlockState cover, BlockState shallow, BlockState deep, float temp, float hum, float baseHeight, float heightAmplitude, float noiseScale)
		{
			coverBlock = cover;
			shallowBlock = shallow;
			deepBlock = deep;

			this.baseHeight = baseHeight;
			this.heightAmplitude = heightAmplitude;
			this.noiseScale = noiseScale;

			Temperature = temp;
			Humidity = hum;
		}

		public override BlockState GetTerrainBlock(BlockPos pos, int height)
		{
			if (pos.Y > height) return AirBlock.DEFAULT_AIR_STATE;
			else if (pos.Y == height) return coverBlock;
			else if (pos.Y > height - 5) return shallowBlock;
			else return deepBlock;
		}

		public override int GetHeight(double x, double z)
		{
			return int(baseHeight + heightNoise.Noise2(x * noiseScale, z * noiseScale) * heightAmplitude);
		}
	}
}
