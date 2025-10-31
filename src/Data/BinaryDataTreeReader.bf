using System;
using System.IO;

namespace Voxis.Data;

public class BinaryDataTreeReader
{
	public DataTree ReadFromFile(StringView path)
	{
		FileStream stream = scope FileStream();

		stream.Open(path);

		TreeNode root = ReadNode(stream);

		return new DataTree(root);
	}

	public TreeNode ReadNode(FileStream stream)
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