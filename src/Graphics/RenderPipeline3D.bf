using System;
using Voxis.Graphics;

/* TODO:
	- Implement Batching of DrawCalls
	- Implement better culling algorithm
	- Implement render material definition based on json
		- Need more advanced handling of uniforms and similar stuff
	- Move the element type from function parameter to field in mesh
*/

namespace Voxis
{
	public static class RenderPipeline3D
	{
		// Basic Shader Programs for rendering
		public static ShaderProgram DefaultChunckShader { get; private set; }
		public static ShaderProgram DefaultSkyboxShader { get; private set; }

		// Default 3D vertex layout
		public static VertexLayout DefaultVertexLayout { get; private set; }

		// Builtin template materials
		public static Material DefaultOpaqueMaterial { get; private set; }
		public static Material DefaultCutoutMaterial { get; private set; }
		public static Material DefaultTransparentMaterial { get; private set; }
		public static Material ChunckRenderMaterial { get; private set; }
		public static Material DefaultSkyboxMaterial { get; private set; }
		public static Material DebugMaterial { get; private set; }
		public static Material PostProcessMaterial { get; private set; }

		// Shared uniform buffers
		public static UniformBuffer CameraUBO { get; private set; }
		public static UniformBuffer EnvironmentUBO { get; private set; }

		public static EnvironmentSettings Environment { get; set; }

		// Utility Meshes
		public static Mesh CubeMesh { get; private set; }
		public static Mesh FullscreenQuad { get; private set; }
		public static Mesh ImmediateMesh { get; private set; }

		// State caching to improve performance
		private static Material activeMaterial;

		public static void OnLoad()
		{
			CameraUBO = GraphicsServer.CreateUniformBuffer(sizeof(CameraData));
			EnvironmentUBO = GraphicsServer.CreateUniformBuffer(sizeof(EnvironmentData));

			DefaultVertexLayout = new VertexLayout(
				VertexLayoutElement("POSITION", .Vector3),
				VertexLayoutElement("TEXCOORD", .Vector2),
				VertexLayoutElement("COLOR", .Vector4),
				VertexLayoutElement("NORMAL", .Vector3)
				);

			DefaultOpaqueMaterial = ResourceServer.LoadMaterial("materials/default_opaque.json");
			DefaultTransparentMaterial = ResourceServer.LoadMaterial("materials/default_transparent.json");
			DefaultCutoutMaterial = ResourceServer.LoadMaterial("materials/default_cutout.json");
			DebugMaterial = ResourceServer.LoadMaterial("materials/debug.json");
			PostProcessMaterial = ResourceServer.LoadMaterial("materials/post_process.json");

			// Set default texture of material to white
			DefaultOpaqueMaterial.SetMaterialProperty("MAIN_TEX", new MaterialParameterTexture2D(GraphicsServer.WhiteTexture));

			// Create and initialize default chunck material
			String chunckVertex = ResourceServer.LoadTextFile("shaders/chunck_vertex.glsl");
			String chunckFragment = ResourceServer.LoadTextFile("shaders/chunck_fragment.glsl");
			DefaultChunckShader = GraphicsServer.CreateShaderProgram(chunckVertex, chunckFragment);
			ChunckRenderMaterial = new Material(DefaultChunckShader, RasterizerState(.Back, .CounterClockwise, false, false), BlendState(false), DepthState(true, true, .Less), Voxis.Graphics.RenderLayer.Opaque);

			// Create and initialize default skybox material
			String skyboxVertex = ResourceServer.LoadTextFile("shaders/skybox_vertex.glsl");
			String skyboxFragment = ResourceServer.LoadTextFile("shaders/skybox_fragment.glsl");
			DefaultSkyboxShader = GraphicsServer.CreateShaderProgram(skyboxVertex, skyboxFragment);
			DefaultSkyboxMaterial = new Material(DefaultSkyboxShader, RasterizerState(.None, .CounterClockwise, false, false), BlendState(false), DepthState(true, true, .Less), Voxis.Graphics.RenderLayer.Opaque);

			Vertex3D[] cubeVertices = scope Vertex3D[](
				// Back
				Vertex3D(Vector3(-1, -1, -1), Vector2(0, 0), .White, Vector3(0, 0, -1)),
				Vertex3D(Vector3(-1, 1, -1), Vector2(0, 1), .White, Vector3(0, 0, -1)),
				Vertex3D(Vector3(1, 1, -1), Vector2(1, 1), .White, Vector3(0, 0, -1)),
				Vertex3D(Vector3(1, -1, -1), Vector2(1, 0), .White, Vector3(0, 0, -1)),

				// Front
				Vertex3D(Vector3(1, -1, 1), Vector2(0, 0), .White, Vector3(0, 0, 1)),
				Vertex3D(Vector3(1, 1, 1), Vector2(0, 1), .White, Vector3(0, 0, 1)),
				Vertex3D(Vector3(-1, 1, 1), Vector2(1, 1), .White, Vector3(0, 0, 1)),
				Vertex3D(Vector3(-1, -1, 1), Vector2(1, 0), .White, Vector3(0, 0, 1)),

				// Left
				Vertex3D(Vector3(-1, -1, 1), Vector2(0, 0), .White, Vector3(-1, 0, 0)),
				Vertex3D(Vector3(-1, 1, 1), Vector2(0, 1), .White, Vector3(-1, 0, 0)),
				Vertex3D(Vector3(-1, 1, -1), Vector2(1, 1), .White, Vector3(-1, 0, 0)),
				Vertex3D(Vector3(-1, -1, -1), Vector2(1, 0), .White, Vector3(-1, 0, 0)),

				// Right
				Vertex3D(Vector3(1, -1, -1), Vector2(0, 0), .White, Vector3(1, 0, 0)),
				Vertex3D(Vector3(1, 1, -1), Vector2(0, 1), .White, Vector3(1, 0, 0)),
				Vertex3D(Vector3(1, 1, 1), Vector2(1, 1), .White, Vector3(1, 0, 0)),
				Vertex3D(Vector3(1, -1, 1), Vector2(1, 0), .White, Vector3(1, 0, 0)),

				// Bottom
				Vertex3D(Vector3(-1, -1, 1), Vector2(0, 0), .White, Vector3(0, -1, 0)),
				Vertex3D(Vector3(-1, -1, -1), Vector2(0, 1), .White, Vector3(0, -1, 0)),
				Vertex3D(Vector3(1, -1, -1), Vector2(1, 1), .White, Vector3(0, -1, 0)),
				Vertex3D(Vector3(1, -1, 1), Vector2(1, 0), .White, Vector3(0, -1, 0)),

				// Top
				Vertex3D(Vector3(-1, 1, -1), Vector2(0, 0), .White, Vector3(0, 1, 0)),
				Vertex3D(Vector3(-1, 1, 1), Vector2(0, 1), .White, Vector3(0, 1, 0)),
				Vertex3D(Vector3(1, 1, 1), Vector2(1, 1), .White, Vector3(0, 1, 0)),
				Vertex3D(Vector3(1, 1, -1), Vector2(1, 0), .White, Vector3(0, 1, 0))
				);
			uint16[] cubeIndices = scope uint16[](
				0, 1, 2,
				2, 3, 0,

				4, 5, 6,
				6, 7, 4,

				8, 9, 10,
				10, 11, 8,

				12, 13, 14,
				14, 15, 12,

				16, 17, 18,
				18, 19, 16,

				20, 21, 22,
				22, 23, 20
			);

			CubeMesh = new Mesh(false);
			CubeMesh.SetVertices(cubeVertices);
			CubeMesh.SetIndices(cubeIndices);

			Vertex3D[] quadVertices = scope Vertex3D[](
				Vertex3D(Vector3(-1, -1, 0), Vector2(0, 0), .White, Vector3(0, 0, 0)),
				Vertex3D(Vector3(1, -1, 0), Vector2(1, 0), .White, Vector3(0, 0, 0)),
				Vertex3D(Vector3(1, 1, 0), Vector2(1, 1), .White, Vector3(0, 0, 0)),
				Vertex3D(Vector3(-1, 1, 0), Vector2(0, 1), .White, Vector3(0, 0, 0))
			);

			uint16[] quadIndices = scope uint16[](
				0, 1, 2,
				2, 3, 0
			);

			FullscreenQuad = new Mesh(false);
			FullscreenQuad.SetVertices(quadVertices);
			FullscreenQuad.SetIndices(quadIndices);

			ImmediateMesh = new Mesh(true);
		}

		public static void OnShutdown()
		{
			delete CameraUBO;
			delete EnvironmentUBO;

			delete DefaultVertexLayout;

			delete ChunckRenderMaterial;

			delete DefaultSkyboxMaterial;

			delete CubeMesh;
			delete FullscreenQuad;
			delete ImmediateMesh;
		}

		public static void ApplyMaterial(Material material)
		{
			if (activeMaterial == material) return;

			activeMaterial = material;

			GraphicsServer.SetShaderProgram(material.Shader);

			// Apply material specific parameters
			material.Apply();

			// Apply rendering states
			GraphicsServer.SetBlendState(material.BlendState);
			GraphicsServer.SetDepthState(material.DepthState);
			GraphicsServer.SetRasterizerState(material.RasterizerState);
		}

		public static void SetCameraData(ref CameraData data)
		{
			GraphicsServer.UpdateUniformBuffer<CameraData>(CameraUBO, &data);
		}

		public static void SetEnvironmentData(ref EnvironmentData data)
		{
			GraphicsServer.UpdateUniformBuffer<EnvironmentData>(EnvironmentUBO, &data);
		}

		public static void RenderEnvironment(Camera camera, EnvironmentSettings environment)
		{
			Environment = environment;

			Material skybox = DefaultSkyboxMaterial;
			skybox.SetMaterialProperty("SKY", environment.SkyColor);
			skybox.SetMaterialProperty("HORIZON", environment.HorizonColor);

			Matrix4x4 modelMatrix = Matrix4x4.CreateScale(1000, 1000, 1000) * Matrix4x4.CreateTranslation(camera.Position);
			RenderPipeline3D.DrawMesh(RenderPipeline3D.CubeMesh, modelMatrix, RenderPipeline3D.DefaultVertexLayout, skybox);
		}

		public static void DrawMesh(Mesh mesh, Matrix4x4 modelMatrix, VertexLayout vertexLayout, Material material, MaterialInstanceProperties overrideProps = null)
		{
			ApplyMaterial(material);

			overrideProps?.Apply(material);

			DrawMeshRaw(modelMatrix, material, mesh, vertexLayout);
		}

		// Draws a mesh, invalidates old camera data!!!
		public static void DrawMesh(
			Mesh mesh,
			Matrix4x4 projectionMatrix,
			Matrix4x4 viewMatrix,
			Matrix4x4 modelMatrix,
			VertexLayout vertexLayout,
			Material material,
			MaterialInstanceProperties overrideProps = null,
			EnvironmentSettings? environment = null)
		{
			// TODO: Figure out how to set camera data temporarily
			CameraData newData = CameraData(projectionMatrix, viewMatrix);
			SetCameraData(ref newData);

			// TOFO: Figure out how to set environment data temporarily
			if (environment != null)
			{
				EnvironmentData environmentData = environment.Value.Data;
				SetEnvironmentData(ref environmentData);
			}

			ApplyMaterial(material);

			overrideProps?.Apply(material);

			DrawMeshRaw(modelMatrix, material, mesh, vertexLayout);
		}

		// Primitive drawing helper
		public static void DrawDebugCube(Vector3 center, Vector3 extents, Color color = .White)
		{
			// Create MODEL matrix
			Matrix4x4 modelMatrix = Matrix4x4.CreateScale(extents) * Matrix4x4.CreateTranslation(center);

			// Set Instance property
			MaterialInstanceProperties props = scope MaterialInstanceProperties();
			props.SetMaterialProperty("TINT", new MaterialParameterColor(color));

			// Draw the actual mesh
			DrawMesh(CubeMesh, modelMatrix, DefaultVertexLayout, DebugMaterial, props);
		}

		public static void DrawDebugOutline(Vector3 center, Vector3 extents, float width, Color color = .Red)
		{
			Vector3 min = center - extents;
			Vector3 max = center + extents;

			DrawDebugLine(Vector3(min.X, min.Y, min.Z), Vector3(min.X, max.Y, min.Z), width, color);
			DrawDebugLine(Vector3(min.X, min.Y, min.Z), Vector3(min.X, min.Y, max.Z), width, color);
			DrawDebugLine(Vector3(min.X, max.Y, min.Z), Vector3(min.X, max.Y, max.Z), width, color);
			DrawDebugLine(Vector3(min.X, min.Y, max.Z), Vector3(min.X, max.Y, max.Z), width, color);

			DrawDebugLine(Vector3(max.X, min.Y, min.Z), Vector3(max.X, max.Y, min.Z), width, color);
			DrawDebugLine(Vector3(max.X, min.Y, min.Z), Vector3(max.X, min.Y, max.Z), width, color);
			DrawDebugLine(Vector3(max.X, max.Y, min.Z), Vector3(max.X, max.Y, max.Z), width, color);
			DrawDebugLine(Vector3(max.X, min.Y, max.Z), Vector3(max.X, max.Y, max.Z), width, color);

			DrawDebugLine(Vector3(min.X, max.Y, min.Z), Vector3(max.X, max.Y, min.Z), width, color);
			DrawDebugLine(Vector3(min.X, max.Y, max.Z), Vector3(max.X, max.Y, max.Z), width, color);
			DrawDebugLine(Vector3(min.X, min.Y, min.Z), Vector3(max.X, min.Y, min.Z), width, color);
			DrawDebugLine(Vector3(min.X, min.Y, max.Z), Vector3(max.X, min.Y, max.Z), width, color);
		}

		public static void DrawRealDebugOutline(Vector3 min, Vector3 max, Color color = .Red)
		{
			DrawRealLine(Vector3(min.X, min.Y, min.Z), Vector3(min.X, max.Y, min.Z), color);
			DrawRealLine(Vector3(min.X, min.Y, min.Z), Vector3(min.X, min.Y, max.Z), color);
			DrawRealLine(Vector3(min.X, max.Y, min.Z), Vector3(min.X, max.Y, max.Z), color);
			DrawRealLine(Vector3(min.X, min.Y, max.Z), Vector3(min.X, max.Y, max.Z), color);

			DrawRealLine(Vector3(max.X, min.Y, min.Z), Vector3(max.X, max.Y, min.Z), color);
			DrawRealLine(Vector3(max.X, min.Y, min.Z), Vector3(max.X, min.Y, max.Z), color);
			DrawRealLine(Vector3(max.X, max.Y, min.Z), Vector3(max.X, max.Y, max.Z), color);
			DrawRealLine(Vector3(max.X, min.Y, max.Z), Vector3(max.X, max.Y, max.Z), color);

			DrawRealLine(Vector3(min.X, max.Y, min.Z), Vector3(max.X, max.Y, min.Z), color);
			DrawRealLine(Vector3(min.X, max.Y, max.Z), Vector3(max.X, max.Y, max.Z), color);
			DrawRealLine(Vector3(min.X, min.Y, min.Z), Vector3(max.X, min.Y, min.Z), color);
			DrawRealLine(Vector3(min.X, min.Y, max.Z), Vector3(max.X, min.Y, max.Z), color);
		}

		// TODO: Add support for non axis aligned lines
		public static void DrawDebugLine(Vector3 start, Vector3 end, float width, Color color = .Red)
		{
			Vector3 extents = (end - start) * 0.5;
			Vector3 center = start + extents;

			extents.X = Math.Max(extents.X, width);
			extents.Y = Math.Max(extents.Y, width);
			extents.Z = Math.Max(extents.Z, width);

			DrawDebugCube(center, extents, color);
		}

		// Method to actually draw real lines
		public static void DrawRealLine(Vector3 start, Vector3 end, Color color = .Red)
		{
			Vertex3D[] verts = scope Vertex3D[](Vertex3D(start), Vertex3D(end));
			uint16[] indices = scope uint16[](0, 1);

			ImmediateMesh.SetVertices(verts);
			ImmediateMesh.SetIndices(indices);

			Matrix4x4 modelMatrix = Matrix4x4.Identity;

			MaterialInstanceProperties props = scope MaterialInstanceProperties();
			props.SetMaterialProperty("TINT", new MaterialParameterColor(color));

			DrawMesh(ImmediateMesh, modelMatrix, DefaultVertexLayout, DebugMaterial, props);
		}

		// Used by other methods
		public static void DrawMeshRaw(Matrix4x4 modelMatrix, Material material, Mesh mesh, VertexLayout vertexLayout)
		{
			GraphicsServer.SetProgramParameter(material.Shader, "MODEL", modelMatrix);

			GraphicsServer.SetVertexLayout(vertexLayout);

			GraphicsServer.SetVertexBuffer(mesh.[Friend]vertexBuffer);
			GraphicsServer.SetIndexBuffer(mesh.[Friend]indexBuffer);

			GraphicsServer.DrawIndexedPrimitives(mesh.IndexCount, mesh.PrimitiveType);

			Performance.CurrentFrame.DrawCalls3D++;
		}
	}
}
