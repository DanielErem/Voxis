namespace Voxis
{
	public class VoxisTerrainGenerator : TerrainGenerator
	{
		private const float OceanFloorHeight = 32.0f;
		private const float TerrainHeightLimit = 128.0f;

		private OpenSimplex2S temperatureNoise = new OpenSimplex2S(69) ~ delete _;
		private OpenSimplex2S humidityNoise = new OpenSimplex2S(88) ~ delete _;

		private Biome[] allBiomes;

		private ScatteredBiomeBlender biomeBlender = new ScatteredBiomeBlender(0.1, 2.0, Chunck.SIZE);

		public this()
		{
			// Cache all biomes
			allBiomes = GameRegistry.Biome.GetAllAsArray();
		}

		public ~this()
		{
			delete allBiomes;
			delete biomeBlender;
		}

		public override void GenerateFeatures(ChunckAccess access)
		{
			access.GetWorkingChunck().SetFlag(.FeaturesGenerated);
			access.UnlockChuncks();
		}

		public override void GenerateStructures(ChunckAccess access)
		{
			access.GetWorkingChunck().SetFlag(.StructuresGenerated);
			access.UnlockChuncks();
		}

		public override void PostprocessTerrain(ChunckAccess access)
		{
			access.GetWorkingChunck().SetFlag(.Postprocessed);
			access.UnlockChuncks();
		}

		public override void GenerateBaseTerrain(Chunck chunck)
		{
			LinkedBiomeWeightMap biomeWeightMap = biomeBlender.GetBlendForChunck(1, chunck.PositionI.X, chunck.PositionI.Z, scope => GetBiomeAtPos);

			for(int x = 0; x < Chunck.SIZE; x++)
			{
				for (int z = 0; z < Chunck.SIZE; z++)
				{
					float wX = x + chunck.Position.X;
					float wZ = z + chunck.Position.Z;

					double height = 0;

					for (LinkedBiomeWeightMap entry = biomeWeightMap; entry != null; entry = entry.getNext())
					{
					    double weight = entry.getWeights() == null ? 1 : entry.getWeights()[z * Chunck.SIZE + x];
					    double thisHeight = entry.getBiome().GetHeight(wX, wZ) * weight;
					    height += thisHeight;
					}

					Biome thisBiome = GetBiomeAtPos(wX, wZ);

					chunck.SetHeightmapValue(x, z, int(height));
					chunck.SetBiomemapValue(x, z, thisBiome);

					for (int y = Chunck.HEIGHT - 1; y >= 0; y--)
					{
						float wY = y + chunck.Position.Y;

						BlockPos worldPos = BlockPos.FromVector(Vector3(wX, wY, wZ));
						BlockState targetblock = thisBiome.GetTerrainBlock(worldPos, int(height));
						chunck.SetBlockstateRaw(x, y, z, targetblock);

						if (worldPos.Y > height)
						{
							chunck.SetLightRaw(x, y, z, LightLevel(0, 0, 0, 15));
						}
					}
				}
			}

			delete biomeWeightMap;

			chunck.SetFlag(.TerrainGenerated);
			chunck.MeshDirty = true;

			chunck.Locked = false;
		}

		private Biome GetBiomeAtPos(double x, double z)
		{
			// Generate parameters
			float temperature = float(temperatureNoise.Noise2(x * 0.01f, z * 0.01f));
			float humidity =float(humidityNoise.Noise2(x * 0.01f, z * 0.01f));

			// Find the nearest Biome with corresponding values
			Biome nearest = allBiomes[0];
			float distance = Vector2.DistanceSquared(Vector2(nearest.Temperature, nearest.Humidity), Vector2(temperature, humidity));

			for (Biome biome in allBiomes)
			{
				float newDist = Vector2.DistanceSquared(Vector2(biome.Temperature, biome.Humidity), Vector2(temperature, humidity));
				if (newDist < distance)
				{
					nearest = biome;
					distance = newDist;
				}
			}

			return nearest;
		}
	}
}
