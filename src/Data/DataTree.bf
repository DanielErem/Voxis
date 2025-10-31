using System.IO;
using System;

namespace Voxis.Data;

public class DataTree
{
	public TreeNode Root { get; private set; }

	public this()
	{
		Root = TreeNode.Object(new TreeNodeMap());
	}

	public this(TreeNode node)
	{
		Root = node;
	}

	public ~this()
	{
		Root.Delete();
	}

	public static DataTree ReadJSONFile(StringView path)
	{
		FileStream stream = scope FileStream();
		stream.Open(path, .Read, .None);

		JSONDataTreeReaderWriter reader = scope JSONDataTreeReaderWriter();
		DataTree result = reader.Read(stream);

		stream.Close();

		return result;
	}

	public static DataTree ReadBinaryFile(StringView path)
	{
		FileStream stream = scope FileStream();
		stream.Open(path, .Read, .None);

		BinaryDataTreeReaderWriter reader = scope BinaryDataTreeReaderWriter();
		DataTree result = reader.Read(stream);

		stream.Close();

		return result;
	}

	public void WriteJSONFile(StringView path)
	{
		FileStream stream = scope FileStream();
		stream.Open(path, .Write, .None);

		JSONDataTreeReaderWriter writer = scope JSONDataTreeReaderWriter();
		writer.Write(this, stream);

		stream.Close();
	}

	public void WriteBinaryFile(StringView path)
	{
		FileStream stream = scope FileStream();
		stream.Open(path, .Write, .None);

		BinaryDataTreeReaderWriter writer = scope BinaryDataTreeReaderWriter();
		writer.Write(this, stream);

		stream.Close();
	}
}