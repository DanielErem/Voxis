using System.Threading;
using Voxis.Graphics;

namespace Voxis
{
	public class Chunck
	{
		public enum StateFlags
		{
			New = 0,
			TerrainGenerated = 1,
			FeaturesGenerated = 1 << 1,
			StructuresGenerated = 1 << 2,
			Postprocessed = 1 << 3,
			Finished = TerrainGenerated | FeaturesGenerated | StructuresGenerated | Postprocessed
		}

		public const int LOG_SIZE = 5;
		public const int SIZE = 1 << LOG_SIZE;
		public const int MASK = SIZE - 1;
		public const int HEIGHT = 256;

		public World World { get; }
		public ChunckIndex Index { get; }
		public Vector3 Position { get; }
		public Vector3Int PositionI { get; }
		public StateFlags CurrentState { get; private set; }
		public bool Locked { get; set; }
		public bool MeshDirty { get; set; }
		public bool MeshNeedsApply { get; set; }
		public bool MeshDrawable { get; set; }
		public bool LightmapDirty { get; set; }
		public int CurrentLoadTime { get; private set; }
		public bool Visible { get; private set; }
		public BoundingBox Bounds { get; }
		public bool IsUnloaded { get; set; } = false;

		private BlockStorage blockStorage;
		private bool started = false;
		private ChunckMesh chunckMesh;
		private ChunckAccess localAccessCache = new ChunckAccess() ~ delete _;
		private Mesh mesh = new Mesh(true) ~ delete _;
		private Lightmap lightmap = new Lightmap() ~ delete _;
		private float[,] heightmap = new float[SIZE,SIZE];
		private Biome[,] biomemap = new Biome[SIZE,SIZE];

		private System.Collections.Queue<BlockPos> lightUpdateQueue = new System.Collections.Queue<BlockPos>() ~ delete _;
		private System.Collections.Queue<(BlockPos, LightLevel)> lightRemovalQueue = new System.Collections.Queue<(BlockPos, LightLevel)>() ~ delete _;

		public this(World world, ChunckIndex index)
		{
			World = world;
			Index = index;
			Position = Index.ToWorldVector();
			PositionI = Vector3Int(Position);
			Bounds = BoundingBox(Position, Position + Vector3(SIZE, HEIGHT, SIZE));
			blockStorage = new BlockStorage(SIZE, HEIGHT);
		}

		public ~this()
		{
			delete blockStorage;
			delete heightmap;
			delete biomemap;

			if (chunckMesh != null) delete chunckMesh;
		}

		public void SetHeightmapValue(int x, int z, int value)
		{
			heightmap[x,z] = value;
		}
		public void SetBiomemapValue(int x, int z, Biome biome)
		{
			biomemap[x,z] = biome;
		}
		public BlockState GetBlockState(int x, int y, int z)
		{
			if (y >= HEIGHT || y < 0) return AirBlock.DEFAULT_AIR_STATE;

			return blockStorage[int32(x), int32(y), int32(z)];
		}
		public void SetBlockState(int x, int y, int z, BlockState blockstate, BlockstatUpdateFlags flags = BlockstatUpdateFlags.All)
		{
			// BlockState oldState = blockStorage[(int32)x, (int32)y, (int32)z];
			blockStorage[int32(x), int32(y), int32(z)] = blockstate;

			if (flags.HasFlag(BlockstatUpdateFlags.Neighbours))
			{
				 World.CheckNeighbourUpdate(Index, x, y, z);
			}
			if (flags.HasFlag(BlockstatUpdateFlags.Lighting))
			{
				LightLevel wasLight = GetLight(x, y, z);
				lightRemovalQueue.Add((BlockPos, LightLevel)(BlockPos(x, y, z).AddChunckIndexOffset(Index), wasLight));

				lightmap.SetLight(x, y, z, LightLevel.Empty);

				if (blockstate.EmitsLight())
				{
					lightUpdateQueue.Add(BlockPos(x, y, z).AddChunckIndexOffset(Index));
				}

				LightmapDirty = true;
			}
			if (flags.HasFlag(BlockstatUpdateFlags.MeshUpdate)) MeshDirty = true;
		}

		public void MarkLightUpdate(BlockPos pos)
		{
			lightUpdateQueue.Add(pos);
			LightmapDirty = true;
		}

		// Set blockstate without any updates, not even meshing
		public void SetBlockstateRaw(int x, int y, int z, BlockState stat)
		{
			blockStorage[(int32)x, (int32)y, (int32)z] = stat;
		}

		// Set blockstate without updating lightmap
		public void SetLightRaw(int x, int y, int z, LightLevel light)
		{
			lightmap.SetLight(x, y, z, light);

			LightmapDirty = true;
		}

		public LightLevel GetLight(int x, int y, int z)
		{
			return lightmap.GetLight(x, y, z);	
		}

		public void SetFlag(StateFlags flag)
		{
			CurrentState = CurrentState | flag;
		}
		public bool HasFlag(StateFlags flag)
		{
			return CurrentState.HasFlag(flag);
		}

		public void OnUpdate()
		{
			if (!started)
			{
				started = true;
				OnStart();
				return;
			}

			OnUpdateState();
		}
		public void OnRender(Camera camera, CommandList commandList)
		{
			Visible = camera.Frustrum.Intersects(Bounds);

			if (!MeshDrawable) return;

			if (Visible)
			{
				Matrix4x4 modelMatrix = Matrix4x4.CreateTranslation(Position);
				commandList.DrawMesh(mesh, modelMatrix, ChunckVertex.Layout, RenderPipeline3D.ChunckRenderMaterial);
			}
		}
		public void OnDebugRender(Camera camera, CommandList commandList)
		{
		}
		public void OnTick()
		{

		}
		public void OnFixedUpdate(){

		}

		public void KeepLoaded(int ticks)
		{
			CurrentLoadTime = System.Math.Max(ticks, CurrentLoadTime);
		}

		private void OnStart()
		{

		}
		private void OnUpdateState()
		{
			// Chunck is being worked on or used by others
			if (Locked) return;

			// Check if chunk should be unloaded
			CurrentLoadTime -= 1;
			if(CurrentLoadTime < 0)
			{
				World.UnloadChunck(Index);
				return;
			}

			if (CurrentState != .Finished)
			{
				if(!HasFlag(.TerrainGenerated))
				{
					Locked = true;
					PriorityTasker.AddPOITask(new () => { World.TerrainGenerator.GenerateBaseTerrain(this); }, .Normal, Position);
					return;
				}

				if (!World.GetChunckAccess(Index, ref localAccessCache))
				{
					return;
				}

				if(!HasFlag(.FeaturesGenerated))
				{
					localAccessCache.LockChuncks();
					PriorityTasker.AddPOITask(new () => { World.TerrainGenerator.GenerateFeatures(localAccessCache); }, .Normal, Position);
				}
				else if(!HasFlag(.StructuresGenerated))
				{
					localAccessCache.LockChuncks();
					PriorityTasker.AddPOITask(new () => { World.TerrainGenerator.GenerateStructures(localAccessCache); }, .Normal, Position);
				}
				else if(!HasFlag(.Postprocessed))
				{
					localAccessCache.LockChuncks();
					PriorityTasker.AddPOITask(new () => { World.TerrainGenerator.PostprocessTerrain(localAccessCache); }, .Normal, Position);
				}
			}
			else if (LightmapDirty)
			{
				if (World.GetChunckAccess(Index, ref localAccessCache))
				{
					localAccessCache.LockChuncks();

					LightmapDirty = false;

					PriorityTasker.AddPOITask(new () => { Lightmap.UpdateLightmap(localAccessCache); }, .Low, Position);
				}
			}
			else if(MeshDirty && Visible)
			{
				// Dont mesh if we dont have anything to mesh
				if (blockStorage.IsAir)
				{
					// Save on RAM usage
					if (chunckMesh != null)
					{
						DeleteAndNullify!(chunckMesh);
					}

					MeshDirty = false;
				}
				else if (World.GetChunckAccess(Index, ref localAccessCache))
				{
					localAccessCache.LockChuncks();

					MeshDirty = false;

					PriorityTasker.AddPOITask(new () => { ChunckMesher.CreateMesh(localAccessCache); }, .High, Position);
				}
			}
			else if(MeshNeedsApply)
			{
				chunckMesh.Upload(mesh);
				MeshDrawable = true;
				MeshNeedsApply = false;
			}
		}
	}
}
