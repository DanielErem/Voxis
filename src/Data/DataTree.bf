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

	public void BinaryWriteToFile(StringView path)
	{
		BinaryDataTreeWriter writer = scope BinaryDataTreeWriter();

		writer.WriteData(this, path);
	}
}