using System;
using System.Collections;

namespace Voxis.Util;

public class ObjectPool<T> where T : new, delete, IPooledObject
{
	public int ObjectLimit { get; } = 1024;
	public int Capacity { get; private set; } = 0;

	private List<T> _pool;

	public this(int limit, int capacity)
	{
		ObjectLimit = limit;
		Capacity = capacity;

		_pool = new List<T>(Capacity);

		Runtime.FatalError("NYI");
	}
}