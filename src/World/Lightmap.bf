using System;
using System.Collections;

namespace Voxis
{
	public class Lightmap
	{
		private LightLevel[,,] lightValues = new LightLevel[Chunck.SIZE, Chunck.HEIGHT, Chunck.SIZE]() ~ delete _;

		public void SetLight(int x, int y, int z, LightLevel val)
		{
			lightValues[x, y, z] = val;
		}
		public LightLevel GetLight(int x, int y, int z)
		{
			if (y < 0 || y >= Chunck.HEIGHT) return LightLevel.Empty;

			return lightValues[x, y, z];
		}

		public static void UpdateLightmap(ChunckAccess access)
		{
			Chunck workingChunck = access.GetWorkingChunck();

			Queue<BlockPos> lightQueue = workingChunck.[Friend]lightUpdateQueue;
			Queue<(BlockPos, LightLevel)> removalQueue = workingChunck.[Friend]lightRemovalQueue;

			// Remove lights
			while (removalQueue.Count > 0)
			{
				(BlockPos, LightLevel) entry;
				entry = removalQueue.PopFront();

				LightLevel wasLight = entry.1;

				for (BlockDirection dir in BlockDirection.All)
				{
					BlockPos offsetPos = entry.0.Offset(dir);
					LightLevel neighbourLight = access.GetLight(offsetPos);

					bool removal = false;
					bool propagation = false;

					LightLevel newLightLevel = neighbourLight;

					// RGB
					for (int ci = 0; ci < 4; ci++)
					{
						if (neighbourLight[ci] != 0 && neighbourLight[ci] < wasLight[ci])
						{
							newLightLevel[ci] = 0;
							removal = true;
						}
						else if (dir == BlockDirection.DOWN && ci == 3 && wasLight[ci] == 15)
						{
							newLightLevel[ci] = 0;
							removal = true;
						}
						else if (neighbourLight[ci] >= wasLight[ci])
						{
							propagation = true;
						}
					}

					access.SetLight(offsetPos, newLightLevel);

					if (removal)
					{
						removalQueue.Add((BlockPos, LightLevel)(offsetPos, neighbourLight));
					}
					if (propagation)
					{
						lightQueue.Add(offsetPos);
					}
				}
			}

			// Spreading new light values
			while (lightQueue.Count > 0)
			{
				BlockPos worldPos = lightQueue.PopFront();
				
				//BlockState thisState = access.GetBlockState(worldPos);

				LightLevel thisLightlevel = access.GetLight(worldPos);

				// TODO: Implement
				/*
				if (thisState.EmitsLight())
				{
					thisLightlevel = thisLightlevel.Max(thisState.GetEmittedLight());
				}
				*/

				for (BlockDirection dir in BlockDirection.All)
				{
					BlockPos neighbourPos = worldPos.Offset(dir);

					BlockState neighbourBlockstate = access.GetBlockState(neighbourPos);

					if (!neighbourBlockstate.LetsLightThrough()) continue;

					LightLevel neighbourLightlevel = access.GetLight(neighbourPos);

					// Add to update queue if a light component changed
					bool enqueue = false;

					LightLevel newLight = neighbourLightlevel;

					// RGB Lights
					for (int ci = 0; ci < 3; ci++)
					{
						int wantLight = neighbourBlockstate.FilterLight(thisLightlevel[ci], ci);

						if (neighbourLightlevel[ci] >= wantLight)
							continue;

						newLight[ci] = wantLight;
						
						enqueue = true;
					}

					// Skylights
					// Infinite downwards light propagation in air blocks
					int wantSkylight = neighbourBlockstate.FilterLight(thisLightlevel[3], 3);
					if (dir == BlockDirection.DOWN && thisLightlevel.S == 15 && neighbourLightlevel.S != 15 && neighbourBlockstate == AirBlock.DEFAULT_AIR_STATE)
					{
						newLight[3] = 15;
						enqueue = true;
					}
					// Normal skylight propagation
					else if (neighbourLightlevel[3] < wantSkylight)
					{
						newLight[3] = wantSkylight;

						enqueue = true;
					}
					else
					{
						// Dont modify sky light level
						newLight[3] = neighbourLightlevel[3];
					}

					if (enqueue)
					{
						access.SetLight(neighbourPos, newLight);
						lightQueue.Add(neighbourPos);
					}
				}
			}

			workingChunck.LightmapDirty = false;
			workingChunck.MeshDirty = true;
			access.UnlockChuncks();
		}
	}
}