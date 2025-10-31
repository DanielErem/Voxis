using System;
using System.Diagnostics;
using System.Collections;
using Voxis.Graphics;

namespace Voxis
{
	public static class CanvasRenderPipeline
	{
		public const int MAX_VERTICES = 2048;
		public const int MAX_INDICES = 1024;

		private static VertexBuffer vertexBuffer;
		private static IndexBuffer indexBuffer;
		private static ShaderProgram shaderProgram;
		private static VertexLayout vertexLayout;

		private static ResetArray<Vertex2D> vertexArray;
 		private static ResetArray<uint16> indexArray;

		private static Rect[] ninceSliceTargetBuffer = new Rect[9] ~ delete _;
		private static Rect[] nineSliceTextureBuffer = new Rect[9] ~ delete _;

		// BATCHING STATE RELEVANT
		private static int currentOrder = 0;
		private static bool isInBatch = false;
		private static Matrix4x4 projectionMatrix;
		private static SortOrder currentSortOrder;
		private static Texture2D activeTexture;

		private static List<BatchElement> drawElements = new List<BatchElement>() ~ DeleteContainerAndItems!(_);
		private static Material blockModelMaterial;
		private static EnvironmentSettings environmentSettings;

		private static bool _scissorActive = false;

		public static void OnShutdown()
		{
			GraphicsServer.DestroyResource(vertexBuffer);
			GraphicsServer.DestroyResource(indexBuffer);
			GraphicsServer.DestroyResource(shaderProgram);
			delete vertexLayout;
			delete vertexArray;
			delete indexArray;
			delete blockModelMaterial;
		}

		public static void OnLoad()
		{
			vertexArray = new ResetArray<Vertex2D>(MAX_VERTICES);
			indexArray = new ResetArray<uint16>(MAX_INDICES);

			vertexBuffer = GraphicsServer.CreateVertexBuffer(.DynamicDraw, MAX_VERTICES * sizeof(Vertex2D));
			indexBuffer = GraphicsServer.CreateIndexBuffer(.DynamicDraw, MAX_INDICES * sizeof(uint16));

			String vertexShaderText = ResourceServer.LoadTextFile("shaders/rp2d_vertex.glsl");
			String fragmentShaderText = ResourceServer.LoadTextFile("shaders/rp2d_fragment.glsl");

			vertexLayout = new VertexLayout(
				VertexLayoutElement("POSITION", .Vector4),
				VertexLayoutElement("TEXCOORD", .Vector2),
				VertexLayoutElement("COLOR", .Vector4)
				);

			shaderProgram = GraphicsServer.CreateShaderProgram(vertexShaderText, fragmentShaderText);

			// Create and initialize default chunk material
			String chunckVertex = ResourceServer.LoadTextFile("shaders/chunck_vertex.glsl");
			String chunckFragment = ResourceServer.LoadTextFile("shaders/chunck_fragment.glsl");
			ShaderProgram blockModelShader = GraphicsServer.CreateShaderProgram(chunckVertex, chunckFragment);
			blockModelMaterial = new Material(blockModelShader, RasterizerState(.Back, .CounterClockwise, false, false), BlendState(false), DepthState(false, false, .Always), Voxis.Graphics.RenderLayer.Opaque);

			// Environment used when rendering models in gui
			environmentSettings = EnvironmentSettings(
				Vector3(0, 0, 1),
				Color.White,
				Color(0.3f, 0.3f, 0.3f, 1.0f),
				Color.Purple,
				Color.Red,
				// High fog range disables fog
				float.MaxValue
				);
		}

		public static void Begin(Matrix4x4 projection, SortOrder order = .BackToFront)
		{
			Debug.Assert(!isInBatch);

			ClearAndDeleteItems!(drawElements);
			currentSortOrder = order;
			projectionMatrix = projection;
			isInBatch = true;
		}

		public static void End()
		{
			Debug.Assert(isInBatch);

			drawElements.Sort(scope => Sort_BackToFront);

			/*
			switch(currentSortOrder)
			{
			case .BackToFront:
				drawElements.Sort(scope => Sort_BackToFront);
				break;
			case .FrontToBack:
				drawElements.Sort(scope => Sort_FrontToBack);
				break;
			}*/

			for(BatchElement element in drawElements)
			{
				// TODO: Move functionality to classes itself
				if(element is BatchElementTexturedQuad)
				{
					BatchElementTexturedQuad quad = element as BatchElementTexturedQuad;

					Validate(4, 6);

					Texture2D targetTexture = quad.Texture;
					if (activeTexture != null && activeTexture != targetTexture)
					{
						FlushBatch();
					}
					activeTexture = targetTexture;

					uint16 currentIndex = (uint16)vertexArray.Length;

					//quad.StartPosition.

					/*
					vertexArray.Add(Vertex2D(Vector2(quad.StartPosition.X, quad.StartPosition.Y), 0, 0, quad.TexRegionStart, quad.Tint));
					vertexArray.Add(Vertex2D(Vector2(quad.EndPosition.X, quad.StartPosition.Y), 0, 0, Vector2(quad.TexRegionEnd.X, quad.TexRegionStart.Y), quad.Tint));
					vertexArray.Add(Vertex2D(Vector2(quad.EndPosition.X, quad.EndPosition.Y), 0, 0, quad.TexRegionEnd, quad.Tint));
					vertexArray.Add(Vertex2D(Vector2(quad.StartPosition.X, quad.EndPosition.Y), 0, 0, Vector2(quad.TexRegionStart.X, quad.TexRegionEnd.Y), quad.Tint));
					*/
					
					vertexArray.Add(Vertex2D(Vector2.Transform(Vector2(quad.StartPosition.X, quad.StartPosition.Y), quad.Transform), quad.Depth, 0, quad.TexRegionStart, quad.Tint));
					vertexArray.Add(Vertex2D(Vector2.Transform(Vector2(quad.EndPosition.X, quad.StartPosition.Y), quad.Transform), quad.Depth, 0, Vector2(quad.TexRegionEnd.X, quad.TexRegionStart.Y), quad.Tint));
					vertexArray.Add(Vertex2D(Vector2.Transform(Vector2(quad.EndPosition.X, quad.EndPosition.Y), quad.Transform), quad.Depth, 0, quad.TexRegionEnd, quad.Tint));
					vertexArray.Add(Vertex2D(Vector2.Transform(Vector2(quad.StartPosition.X, quad.EndPosition.Y), quad.Transform), quad.Depth, 0, Vector2(quad.TexRegionStart.X, quad.TexRegionEnd.Y), quad.Tint));
					

					indexArray.Add(currentIndex);
					indexArray.Add(currentIndex + 1);
					indexArray.Add(currentIndex + 2);
					indexArray.Add(currentIndex + 2);
					indexArray.Add(currentIndex + 3);
					indexArray.Add(currentIndex);
				}
				else if (element is BatchElement3DModel)
				{
					BatchElement3DModel model = element as BatchElement3DModel;

					FlushBatch();

					// TODO: Bro change that, that is terrible
					MaterialParameterTextureArray2D param = new MaterialParameterTextureArray2D(VoxelTextureManager.VoxelTextures);
					model.MaterialToUse.SetMaterialProperty("MAIN_TEX", param);

					RenderPipeline3D.DrawMesh(model.MeshToRender, projectionMatrix, Matrix4x4.Identity, model.ModelMatrix, model.Layout, model.MaterialToUse, null, environmentSettings);
				}
			}

			FlushBatch();

			isInBatch = false;
		}

		private static void Validate(int vertexCap, int indexCap)
		{
			Debug.Assert(isInBatch);
			if(vertexArray.CapLeft < vertexCap) FlushBatch();
			else if(indexArray.CapLeft < indexCap) FlushBatch();
		}

		public static void FlushBatch()
		{
			// Dont draw anything with no data
			if (vertexArray.Length == 0 || indexArray.Length == 0) return;

			// Upload vertex and index data
			GraphicsServer.UpdateVertexBuffer(vertexBuffer, 0, uint32(vertexArray.Length), vertexArray.Array);
			GraphicsServer.UpdateIndexBuffer(indexBuffer, 0, uint32(indexArray.Length), indexArray.Array);

			GraphicsServer.SetDepthState(DepthState(false, false, .LessEqual));
			GraphicsServer.SetRasterizerState(RasterizerState(.None, .Clockwise, false, false));
			GraphicsServer.SetBlendState(BlendState(true));

			GraphicsServer.SetVertexBuffer(vertexBuffer);
			GraphicsServer.SetIndexBuffer(indexBuffer);
			GraphicsServer.SetShaderProgram(shaderProgram);
			GraphicsServer.SetVertexLayout(vertexLayout);

			GraphicsServer.SetProgramParameter(shaderProgram, "PROJECTION", projectionMatrix);

			GraphicsServer.SetProgramTexture(shaderProgram, "TEXTURE", activeTexture, 0);

			GraphicsServer.DrawIndexedPrimitives(indexArray.Length, PrimitiveType.Triangles);

			vertexArray.Clear();
			indexArray.Clear();

			activeTexture = null;

			Performance.CurrentFrame.DrawCallsCanvas++;
		}

		// TODO: Does not work like this, need to apply the scissor rect when rendering the batches
		public static void EnableScissor(Rect rect)
		{
			Debug.Assert(!_scissorActive);
			Debug.Assert(isInBatch);
			if (_scissorActive) Runtime.FatalError("Scissor already active, nested scissor test not supported!");

			_scissorActive = true;

			// Need to draw old geometry
			FlushBatch();

			// All new geometry draws should have scissor test enabled
			GraphicsServer.SetScissorRect((uint32)rect.X, (uint32)rect.Y, (uint32)rect.Width, (uint32)rect.Height);

			GraphicsServer.SetScissorEnabled(true);
		}

		public static void DisableScissor()
		{
			Debug.Assert(_scissorActive);

			_scissorActive = false;

			// Draw drawcalls with scissor testing enabled
			FlushBatch();

			GraphicsServer.SetScissorEnabled(false);
		}

		// DRAWING METHODS

		// Draw a mesh created from voxel data or even a single block model in the canvas
		// This requires to flush the current batch
		public static void DrawChunckMesh(Mesh mesh, Matrix4x4 modelMatrix, int depth)
		{
			BatchElement3DModel model = new BatchElement3DModel(){
				MeshToRender = mesh,
				ModelMatrix = modelMatrix,
				Layout = ChunckVertex.Layout,
				MaterialToUse = blockModelMaterial,
				Depth = depth
			};

			drawElements.Add(model);
		}

		public static void DrawTexturedRect(Rect targetRect, Texture2D texture, Rect textureRegion, int depth, Color tint = Color.White)
		{
			BatchElementTexturedQuad quad = new BatchElementTexturedQuad();
			quad.Depth = depth;
			quad.SubmitOrder = currentOrder++;
			quad.StartPosition = targetRect.Position;
			quad.EndPosition = targetRect.Position + targetRect.Size;
			quad.TexRegionStart = textureRegion.Position * texture.TexelSize;
			quad.TexRegionEnd = textureRegion.End * texture.TexelSize;
			quad.Texture = texture;
			quad.Tint = tint;

			//quad.Transform = Matrix3x2.Identity;
			quad.Transform = GUICanvas.CurrentTransform;

			drawElements.Add(quad);
		}

		public static void DrawTiledTexturedRect(Rect targetRect, Texture2D texture, int depth, Color tint = Color.White)
		{
			BatchElementTexturedQuad quad = new BatchElementTexturedQuad();
			quad.Depth = depth;
			quad.SubmitOrder = currentOrder++;
			quad.StartPosition = targetRect.Position;
			quad.EndPosition = targetRect.Position + targetRect.Size;

			quad.TexRegionEnd = Vector2.Zero;
			quad.TexRegionEnd = Vector2(targetRect.Width / texture.Width, targetRect.Height / texture.Height);

			quad.Texture = texture;
			quad.Tint = tint;

			quad.Transform = Matrix3x2.Identity;
			//quad.Transform = GUICanvas.CurrentTransform;

			drawElements.Add(quad);
		}

		public static void DrawTexturedRect(Rect targetRect, Texture2D texture, int depth, Color tint = Color.White)
		{
			DrawTexturedRect(targetRect, texture, Rect(0, 0, texture.Width, texture.Height), depth, tint);
		}

		public static void DrawNineSlice(Rect targetRect, Texture2D texture, Margin sliceBorder, int depth, Color tint)
		{
			Utilities.CreatePatches(targetRect, ninceSliceTargetBuffer, sliceBorder);
			Utilities.CreatePatches(Rect(0, 0, texture.Width, texture.Height), nineSliceTextureBuffer, sliceBorder);

			for(int i = 0; i < ninceSliceTargetBuffer.Count; i++)
			{
				DrawTexturedRect(ninceSliceTargetBuffer[i], texture, nineSliceTextureBuffer[i], depth, tint);
			}
		}

		public static void DrawRect(Rect target, Color tint = Color.White, int depth = 1)
		{
			DrawTexturedRect(target, GraphicsServer.WhiteTexture, depth, tint);
		}

		// END DRAWING METHODS

		// SORTING METHODS

		private static int Sort_BackToFront(BatchElement left, BatchElement right)
		{
			if (left.Depth > right.Depth) return 1;
			else if(left.Depth < right.Depth) return -1;
			else return Sort_SubmitOrder(left, right);
		}
		private static int Sort_FrontToBack(BatchElement left, BatchElement right)
		{
			if (left.Depth > right.Depth) return -1;
			else if(left.Depth < right.Depth) return 1;
			else return Sort_SubmitOrder(left, right);
		}
		private static int Sort_SubmitOrder(BatchElement left, BatchElement right)
		{
			if (left.SubmitOrder < right.SubmitOrder) return -1;
			else if (right.SubmitOrder > right.SubmitOrder) return 1;
			else return 0;
		}

		// END SORTING METHODS
	}
}
