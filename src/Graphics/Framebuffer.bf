namespace Voxis.Graphics;

public class Framebuffer : IGraphicsResource
{
	public readonly uint BufferName { get; }
	public uint Width { get; private set; }
	public uint Height { get; private set; }

	public Texture2D DepthStencilAttachment { get; set; }
	public Texture2D ColorAttachment { get; set; }

	public this(uint bufferName, uint width, uint height)
	{
		BufferName = bufferName;
		Width = width;
		Height = height;
	}

	public ~this()
	{
		delete DepthStencilAttachment;
		delete ColorAttachment;
	}
}