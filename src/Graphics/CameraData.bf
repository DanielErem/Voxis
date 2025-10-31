namespace Voxis;

public struct CameraData
{
	public Matrix4x4 Projection;
	public Matrix4x4 View;

	public this(Matrix4x4 projection, Matrix4x4 view)
	{
		Projection = projection;
		View = view;
	}
}