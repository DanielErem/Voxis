using System;
using System.IO;

namespace Voxis.Data;

public abstract class DataTreeReaderWriter
{
	public abstract void Write(DataTree tree, Stream stream);
	public abstract Result<DataTree> Read(Stream stream);
}