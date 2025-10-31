using System;
using System.IO;

namespace Voxis.Data;

public class BinaryDataTreeWriter
{
	private FileStream _fileStream;

	public void WriteData(DataTree tree, StringView path)
	{
		_fileStream = scope FileStream();
		_fileStream.Create(path);

		WriteNode(tree.Root);

		_fileStream.Close();
	}

	public void WriteNode(TreeNode node)
	{
		switch(node)
		{
		case .Object(let map):
			_fileStream.Write(BinaryTag.ObjectStart);
			for (let pair in map)
			{
				_fileStream.Write(BinaryTag.MapKey);
				_fileStream.WriteStrSized32(pair.key);

				WriteNode(pair.value);
			}
			_fileStream.Write(BinaryTag.ObjectEnd);
			break;
		case .Boolean(let n):
			_fileStream.Write(BinaryTag.Boolean);
			_fileStream.Write(n);
			break;
		case .Number(let n):
			_fileStream.Write(BinaryTag.Number);
			_fileStream.Write(n);
			break;
		case .Decimal(let n):
			_fileStream.Write(BinaryTag.Decimal);
			_fileStream.Write(n);
			break;
		case .List(let list):
			_fileStream.Write(BinaryTag.ListStart);
			_fileStream.Write<int64>((int64)list.Count);
			for (TreeNode element in list)
			{
				WriteNode(element);
			}
			break;
		case .Null:
			_fileStream.Write(BinaryTag.Null);
			break;
		case .Text(let s):
			_fileStream.Write(BinaryTag.Text);
			_fileStream.WriteStrSized32(s);
			break;
		}
	}
}