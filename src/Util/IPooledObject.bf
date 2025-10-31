namespace Voxis.Util;

public interface IPooledObject
{
	public void OnPooledInstantiate();
	public void OnPooledDestroy();
}