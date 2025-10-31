using System;
using System.Collections;
using Voxis.Graphics;

namespace Voxis
{
	public class World
	{
		public String Name { get; }
		public String Seed { get; }
		public TerrainGenerator TerrainGenerator { get; };

		public double FixedUpdateRate { get; set; }
		public double TickRate { get; set; }
		public int MaxTickUpdate { get; set; }
		public int16 ViewRange { get; set; } = 16;

		public double FixedUpdateDeltaTime { get { return 1.0 / FixedUpdateRate; } }
		public double TickDeltaTime { get { return 1.0 / TickRate; } }

		private List<Entity> entityList = new List<Entity>() ~ DeleteContainerAndItems!(_);
		private Dictionary<ChunckIndex, Chunck> loadedChuncks = new Dictionary<ChunckIndex, Chunck>() ~ DeleteDictionaryAndValues!(_);
		private EnvironmentSettings environmentSettings = .(Vector3(0.5f, -1f, 0.5f).Normalize(), .(1f, 1f, 1f), .FromBytes(0, 51, 102, 255), .FromBytes(214, 249,255, 255), .FromBytes(156, 240, 255, 255), Chunck.SIZE * ViewRange);

		private bool isStarted = false;
		private double tickTimer = 0;
		private double fixedUpdateTimer = 0;

		private Entity trackedLoader;

		private Framebuffer framebuffer;

		private int _oldFramebufferHeight;
		private int _oldFramebufferWidth;

		public this(String name, String seed)
		{
			TerrainGenerator = new VoxisTerrainGenerator();

			Name = name;
			Seed = seed;

			FixedUpdateRate = 50.0;
			TickRate = 20.0;
			MaxTickUpdate = 10;

			framebuffer = GraphicsServer.CreateFrameBuffer(WindowServer.Width, WindowServer.Height);
		}

		public ~this()
		{
			while(entityList.Count > 0)
			{
				DestroyEntity(entityList.Front);
			}

			delete Name;
			delete Seed;

			delete TerrainGenerator;

			delete framebuffer;
		}

		public void SpawnEntity(Entity entity)
		{
			entityList.Add(entity);
			entity.World = this;
		}
		public void DestroyEntity(Entity entity)
		{
			entity.OnDestroy();
			entityList.Remove(entity);

			delete entity;
		}
		public void Destroy()
		{
			while (entityList.Count > 0)
			{
				DestroyEntity(entityList[0]);
			}

			List<ChunckIndex> indices = scope List<ChunckIndex>();
			indices.AddRange(loadedChuncks.Keys);
			for (ChunckIndex index in indices)
			{
				ForceUnloadChunck(index);
			}
		}

		public BlockState GetBlockState(BlockPos pos)
		{
			ChunckIndex index = pos.GetChunckIndex();
			let localPos = pos.GetChunckLocalPosition();

			if (IsChunckLoaded(index))
			{
				if (localPos.y < 0 || localPos.y >= Chunck.HEIGHT) return AirBlock.DEFAULT_AIR.BlockStateContainer.DefaultState;
				return loadedChuncks[index].GetBlockState(localPos.x, localPos.y, localPos.z);
			}

			return AirBlock.DEFAULT_AIR.BlockStateContainer.DefaultState;
		}
		public void SetBlockState(BlockPos pos, BlockState blockstate)
		{
			ChunckIndex index = pos.GetChunckIndex();
			let localPos = pos.GetChunckLocalPosition();
			if (IsChunckLoaded(index))
			{
				if (localPos.y < 0 || localPos.y >= Chunck.HEIGHT) return;
				loadedChuncks[index].SetBlockState
					(localPos.x, localPos.y, localPos.z, blockstate, BlockstatUpdateFlags.All);
			}
		}

		// Return true if the chunk exists in the world
		// Note: Doesn't mean blocks are populated or anything!
		public bool IsChunckLoaded(ChunckIndex index)
		{
			return loadedChuncks.ContainsKey(index);
		}

		// Returns true if player or others can walk/use the block data
		// Prevent endless falling
		public bool IsChunckGameplayReady(ChunckIndex index)
		{
			return IsChunckLoaded(index) && loadedChuncks[index].CurrentState.HasFlag(.TerrainGenerated);
		}

		// Returns true if the chunk is usable in other generation stages
		// Note: Only the base terrain is generated!
		public bool IsChunckReadable(ChunckIndex index)
		{
			return IsChunckLoaded(index) && loadedChuncks[index].CurrentState.HasFlag(.TerrainGenerated) && loadedChuncks[index].Locked == false;
		}

		// Returns true if the chunk can be used in meshing
		// Note: All stages were completed so can read and write
		public bool IsChunckFinished(ChunckIndex index)
		{
			return IsChunckLoaded(index) && loadedChuncks[index].CurrentState == .Finished;
		}

		public void LoadChunck(ChunckIndex index)
		{
			Chunck newChunck = new Chunck(this, index);
			loadedChuncks.Add(index, newChunck);
			newChunck.KeepLoaded(30);

			SetNeighboursDirty(index);
		}

		public void ForceUnloadChunck(ChunckIndex index)
		{
			if (!loadedChuncks.ContainsKey(index)) return;

			Chunck ch = loadedChuncks[index];

			ch.IsUnloaded = true;

			// Wait until chunk is unlocked, unlocked means no thread is working on it anymore
			while (ch.Locked)
			{

			}

			loadedChuncks.Remove(index);

			delete ch;

			SetNeighboursDirty(index);
		}

		public void UnloadChunck(ChunckIndex index)
		{
			if (!loadedChuncks.ContainsKey(index)) return;

			Chunck ch = loadedChuncks[index];
			loadedChuncks.Remove(index);

			delete ch;

			SetNeighboursDirty(index);
		}

		public bool GetChunckMeshingAccess(ChunckIndex index, ref ChunckAccess access)
		{
			Chunck[] chuncks = access.[Friend]chuncks;

			for(int16 x = 0; x < 3; x++)
			{
				for(int16 z = 0; z < 3; z++)
				{
					ChunckIndex withOffset = index.Offset(x - 1, z - 1);

					if (!IsChunckFinished(withOffset))
					{
						return false;
					}
					else
					{
						chuncks[z * 3 + x] = loadedChuncks[withOffset];
					}
				}
			}

			access.[Friend]chuncks = chuncks;
			access.[Friend]indexOffset = index;
			return true;
		}

		public bool GetChunckAccess(ChunckIndex index, ref ChunckAccess access)
		{
			Chunck[] chuncks = access.ChunckArray;

			for(int16 x = 0; x < 3; x++)
			{
				for(int16 z = 0; z < 3; z++)
				{
					ChunckIndex withOffset = index.Offset(x - 1, z - 1);
					if (!IsChunckReadable(withOffset))
					{
						return false;
					}
					else
					{
						chuncks[z * 3 + x] = loadedChuncks[withOffset];
					}
				}
			}

			access.UpdateState(chuncks, index);

			return true;
		}

		public void SetNeighboursDirty(ChunckIndex index)
		{
			for(int16 x = -1; x <= 1; x++)
			{
				for (int16 z = -1; z <= 1; z++)
				{
					ChunckIndex offseted = index.Offset(x, z);
					Chunck chunck;
					if (loadedChuncks.TryGetValue(offseted, out chunck))
					{
						chunck.MeshDirty = true;
					}
				}
			}
		}

		public void CheckNeighbourUpdate(ChunckIndex index, int x, int y, int z)
		{
			if (x == 0) MarkChunckDirty(index.Offset(-1, 0));
			else if (x == Chunck.SIZE - 1) MarkChunckDirty(index.Offset(1, 0));

			if (z == 0) MarkChunckDirty(index.Offset(0, -1));
			else if (z == Chunck.SIZE - 1) MarkChunckDirty(index.Offset(0, 1));
		}

		public void PropagateNeighbourLighting(BlockPos position)
		{
			for (BlockDirection dir in BlockDirection.All)
			{
				BlockPos offseted = position.Offset(dir);
				BlockState nb = GetBlockState(offseted);
				if (nb.LetsLightThrough())
				{
					MarkLightUpdate(offseted);
				}
			}
		}

		public void MarkLightUpdate(BlockPos pos)
		{
			if (IsChunckLoaded(pos.GetChunckIndex()))
			{
				loadedChuncks[pos.GetChunckIndex()].MarkLightUpdate(pos);
			}
		}

		public void MarkChunckDirty(ChunckIndex index)
		{
			if (loadedChuncks.ContainsKey(index)) loadedChuncks[index].MeshDirty = true;
		}

		public void OnUpdate()
		{
			if (!isStarted)
			{
				OnStart();
				isStarted = true;
			}

			// Chunk-loading
			ChunckIndex center = ChunckIndex(0, 0);

			if (trackedLoader != null)
			{
				Vector3 pos = trackedLoader.LocalPosition;
				center = ChunckIndex(int16(pos.X) >> Chunck.LOG_SIZE, int16(pos.Z) >> Chunck.LOG_SIZE);

				// Set Priority Queue POI to loader position
				PriorityTasker.PointOfInterest = pos;
			}

			for(int16 x = -ViewRange; x <= ViewRange; x++)
			{
				for(int16 z = -ViewRange; z <= ViewRange; z++)
				{
					ChunckIndex offseted = ChunckIndex(center.X + x, center.Z + z);
					if (!IsChunckLoaded(offseted))
					{
						 LoadChunck(offseted);
					}
					else
					{
						loadedChuncks[offseted].KeepLoaded(30);
					}
				}
			}

			// Update called every frame
			for (Chunck c in loadedChuncks.Values)
			{
				c.OnUpdate();
			}
			for(Entity e in entityList)
			{
				e.OnUpdate();
			}

			// Fixed Update called a fixed rate per second
			fixedUpdateTimer += Time.DeltaTime;
			while (fixedUpdateTimer >= FixedUpdateDeltaTime)
			{
				fixedUpdateTimer -= FixedUpdateDeltaTime;
				OnFixedUpdate();
			}

			// Tick called a fixed rate per second but can lag behind!
			tickTimer += Time.DeltaTime;
			int currentUpdatedTicks = 0;
			while (tickTimer >= TickDeltaTime && currentUpdatedTicks < MaxTickUpdate)
			{
				tickTimer -= TickDeltaTime;
				OnTick();
			}
		}
		public void OnFixedUpdate()
		{
			for (Chunck c in loadedChuncks.Values) c.OnFixedUpdate();
			for (Entity e in entityList) e.OnFixedUpdate();
		}
		public void OnTick()
		{
			for (Chunck c in loadedChuncks.Values) c.OnTick();
			for (Entity e in entityList) e.OnTick();
		}
		public void OnDebugRender()
		{
			// Search all cameras in the world
			List<Camera> cameras = scope List<Camera>();
			for (Entity e in entityList)
			{
				e.OnCollectCameras(cameras);
			}

			// Prepare command list
			CommandList commandList = new CommandList();
			defer delete commandList;


			// Render all cameras but in debug
			for (Camera camera in cameras)
			{
				commandList.Begin();

				CameraData cameraData = camera.Data;
				RenderPipeline3D.SetCameraData(ref cameraData);

				for (Chunck c in loadedChuncks.Values)
				{
					c.OnDebugRender(camera, commandList);
				}

				for(Entity e in entityList)
				{
					e.OnDebugRender(camera, commandList);
				}

				commandList.End();

				commandList.Flush(camera.Position);
			}
		}
		public void OnRender()
		{
			// Recreate framebuffer if changed
			if (_oldFramebufferWidth != WindowServer.Width || _oldFramebufferHeight != WindowServer.Height)
			{
				delete framebuffer;
				
				framebuffer = GraphicsServer.CreateFrameBuffer(WindowServer.Width, WindowServer.Height);

				_oldFramebufferWidth = WindowServer.Width;
				_oldFramebufferHeight = WindowServer.Height;
			}

			GraphicsServer.BindFramebuffer(framebuffer);

			GraphicsServer.SetViewport(0, 0, 0, uint32(framebuffer.Width), uint32(framebuffer.Height));

			GraphicsServer.ClearColorTarget(Color.Red);
			GraphicsServer.ClearDepthStencilTarget();

			// Apply world environment
			EnvironmentData environmentData = environmentSettings.Data;
			RenderPipeline3D.SetEnvironmentData(ref environmentData);

			// Search all cameras in the world
			List<Camera> cameras = scope List<Camera>();
			for (Entity e in entityList)
			{
				e.OnCollectCameras(cameras);
			}

			// Prepare command list
			CommandList commandList = new CommandList();
			defer delete commandList;

			// Render all cameras
			for (Camera camera in cameras)
			{
				commandList.Begin();

				CameraData cameraData = camera.Data;
				RenderPipeline3D.SetCameraData(ref cameraData);
				RenderPipeline3D.RenderEnvironment(camera, environmentSettings);

				for (Chunck c in loadedChuncks.Values)
				{
					c.OnRender(camera, commandList);
				}

				for(Entity e in entityList)
				{
					e.OnRender(camera, commandList);
				}

				commandList.End();

				commandList.Flush(camera.Position);
			}

			// Sets framebuffer to internal one (Draw to screen)
			GraphicsServer.BindFramebuffer(null);

			GraphicsServer.SetViewport(0, 0, 0, WindowServer.Width, WindowServer.Height);

			// Clear screen buffer
			GraphicsServer.ClearColorTarget(Color.Black);
			GraphicsServer.ClearDepthStencilTarget();

			// Draw the framebuffer to the screen with shaders
			RenderPipeline3D.PostProcessMaterial.SetMaterialProperty("SCREEN_COLOR", new MaterialParameterTexture2D(framebuffer.ColorAttachment, 0));
			RenderPipeline3D.PostProcessMaterial.SetMaterialProperty("SCREEN_DEPTH_STENCIL", new MaterialParameterTexture2D(framebuffer.DepthStencilAttachment, 1));

			RenderPipeline3D.DrawMesh(RenderPipeline3D.FullscreenQuad, Matrix4x4.Identity, RenderPipeline3D.DefaultVertexLayout, RenderPipeline3D.PostProcessMaterial);
		}
		public void OnInputEvent(InputEvent event)
		{
			for (Entity e in entityList)
			{
				e.OnInputEvent(event);
			}
		}

		private void OnStart()
		{
			Player mainPlayer = new Player();
			SpawnEntity(mainPlayer);

			trackedLoader = mainPlayer;
		}
	}
}
