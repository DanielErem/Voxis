namespace Voxis.Data;

using System;
using System.IO;

public class BinaryDataTreeReaderWriter : DataTreeReaderWriter
{
	public override void Write(DataTree tree, Stream stream)
	{
		WriteNode(tree.Root, stream);
	}
	public override Result<DataTree> Read(Stream stream)
	{
		TreeNode root = ReadNode(stream);

		return new DataTree(root);
	}

	private void WriteNode(TreeNode node, Stream stream)
	{
		switch(node)
		{
		case .Object(let map):
			stream.Write(BinaryTag.ObjectStart);
			for (let pair in map)
			{
				stream.Write(BinaryTag.MapKey);
				stream.WriteStrSized32(pair.key);

				WriteNode(pair.value, stream);
			}
			stream.Write(BinaryTag.ObjectEnd);
			break;
		case .Boolean(let n):
			stream.Write(BinaryTag.Boolean);
			stream.Write(n);
			break;
		case .Number(let n):
			stream.Write(BinaryTag.Number);
			stream.Write(n);
			break;
		case .Decimal(let n):
			stream.Write(BinaryTag.Decimal);
			stream.Write(n);
			break;
		case .List(let list):
			stream.Write(BinaryTag.ListStart);
			stream.Write<int64>((int64)list.Count);
			for (TreeNode element in list)
			{
				WriteNode(element, stream);
			}
			break;
		case .Null:
			stream.Write(BinaryTag.Null);
			break;
		case .Text(let s):
			stream.Write(BinaryTag.Text);
			stream.WriteStrSized32(s);
			break;
		}
	}

	private TreeNode ReadNode(Stream stream)
	{
		BinaryTag tag = stream.Read<BinaryTag>();

		switch (tag)
		{
		case .Boolean: return .Boolean(stream.Read<bool>());
		case .Number: return .Number(stream.Read<int64>());
		case .Decimal: return .Decimal(stream.Read<double>());
		case .Null: return .Null;

		case .Text:
			String result = new String();
			stream.ReadStrSized32(result);
			return .Text(result);

		case .ObjectStart:
			TreeNodeMap map = new TreeNodeMap();

			while (true)
			{
				BinaryTag subTag = stream.Read<BinaryTag>();

				if (subTag == .ObjectEnd) break;

				if (subTag == .MapKey)
				{
					String newKey = new String();

					stream.ReadStrSized32(newKey);

					TreeNode read = ReadNode(stream);

					map.Add(newKey, read);
				}
			}

			return .Object(map);
		case .ListStart:
			System.Collections.List<TreeNode> list = new System.Collections.List<TreeNode>();
			int64 listSize = stream.Read<int64>();

			for (int i = 0; i < listSize; i++)
			{
				TreeNode result = ReadNode(stream);

				list.Add(result);
			}

			return .List(list);

		case .MapKey:
		case .ObjectEnd:
			Runtime.FatalError();
		}

		// Should not happen
		Runtime.FatalError();
	}
}