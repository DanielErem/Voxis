using System;

namespace Voxis
{
	public class Camera
	{
		public Vector3 Position { get; set; }
		public Quaternion Rotation { get; set; }
		public BoundingFrustum Frustrum { get; } = new BoundingFrustum(ProjectionMatrix * ViewMatrix) ~ delete _;

		public Vector3 Forward
		{
			get
			{
				return Vector3.Transform(Vector3.UnitZ, Rotation);
			}
		}
		public Vector3 Right
		{
			get
			{
				return Vector3.Transform(Vector3.UnitX, Rotation);
			}
		}
		public Vector3 Up
		{
			get
			{
				return Vector3.Cross(Forward, Right);
			}
		}
		public Matrix4x4 ViewMatrix
		{
			get
			{
				return Matrix4x4.CreateLookAt(Position, Position + Forward, Up);
			}
		}
		public Matrix4x4 ProjectionMatrix
		{
			get
			{
				float aspect = float(WindowServer.Width) / float(WindowServer.Height);
				return Matrix4x4.CreatePerspectiveFieldOfView(ToRadians(90.0f), aspect, 0.1f, 2000.0f);
			}
		}
		public Matrix4x4 TransformMatrix
		{
			get
			{
				return Matrix4x4.CreateFromQuaternion(Rotation) * Matrix4x4.CreateTranslation(Position);
			}
		}
		public CameraData Data
		{
			get
			{
				return CameraData(ProjectionMatrix, ViewMatrix);
			}
		}

		/*
		public void DrawMesh(Mesh mesh, Matrix4x4 modelMatrix, VertexLayout vertexLayout, Material material, BoundingBox worldBounds)
		{
			// Frustrum culling
			if (!Frustrum.Intersects(worldBounds)) return;

			RenderPipeline3D.DrawMesh(mesh, ProjectionMatrix, ViewMatrix, modelMatrix, vertexLayout, material);
		}

		public void DrawCube(Matrix4x4 data, Color color)
		{
			RenderPipeline3D.DrawMesh(RenderPipeline3D.CubeMesh, ProjectionMatrix, ViewMatrix, data, RenderPipeline3D.DefaultVertexLayout, RenderPipeline3D.DefaultOpaqueMaterial);
		}

		public void DrawCube(Vector3 center, Vector3 extents, Color color)
		{
			Matrix4x4 modelMatrix = Matrix4x4.CreateScale(extents) * Matrix4x4.CreateTranslation(center);

			RenderPipeline3D.DrawMesh(RenderPipeline3D.CubeMesh, ProjectionMatrix, ViewMatrix, modelMatrix, RenderPipeline3D.DefaultVertexLayout, RenderPipeline3D.DefaultOpaqueMaterial);
		}
		*/

		public void Update()
		{
			Frustrum.Matrix = ViewMatrix * ProjectionMatrix;
		}

		public bool IntersectFrustrum(BoundingBox bb)
		{
			return Frustrum.Intersects(bb);
		}

		private float ToRadians(float value)
		{
			return value * Math.PI_f / 180.0f;
		}
	}
}
