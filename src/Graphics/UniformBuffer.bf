using System;

namespace Voxis;

public class UniformBuffer : IGraphicsResource
{
	public uint BufferID { get; }

	private this(uint handle)
	{
		BufferID = handle;
	}
}