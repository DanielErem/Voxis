using System;
using System.IO;

namespace Voxis.Data;

public class TextDataTreeWriter
{
	public enum TextFlags
	{
		None = 0,
		Pretty = 1
	}

	private StringStream _stringStream;
	private TextFlags _flags = .Pretty;

	public void WriteData(DataTree tree, String buffer)
	{
		_stringStream = scope StringStream();

		WriteNode(tree.Root);

		buffer.Append(_stringStream.Content);
	}

	public void WriteNode(TreeNode node, int indentation = 0)
	{
		switch(node)
		{
		case .Object(let map):
			_stringStream.Write(TextTag.ObjectStart);

			if (_flags == .Pretty) _stringStream.Write("\n");

			int currentIndex = 0;
			for (let pair in map)
			{
				if (_flags == .Pretty)
				{
					_stringStream.Write(scope String('\t', indentation + 1));
				}

				_stringStream.Write(TextTag.Text);
				_stringStream.Write(pair.key);
				_stringStream.Write(TextTag.Text);

				_stringStream.Write(TextTag.KeyValueSeparator);

				if (_flags == .Pretty) _stringStream.Write(TextTag.Space);

				WriteNode(pair.value, indentation + 1);

				if (currentIndex < map.Count - 1)
				{
					_stringStream.Write(TextTag.Separator);

					if (_flags == .Pretty) _stringStream.Write('\n');
				}

				currentIndex += 1;
			}

			if (_flags == .Pretty)
			{
				_stringStream.Write('\n');
				_stringStream.Write(scope String('\t', indentation));
			}

			_stringStream.Write(TextTag.ObjectEnd);
			break;
		case .Boolean(let n):
			if (n) _stringStream.Write("true");
			else _stringStream.Write("false");
			break;
		case .Number(let n):
			String temp = scope String();
			n.ToString(temp);
			_stringStream.Write(temp);
			break;
		case .Decimal(let n):
			String temp = scope String();
			n.ToString(temp);
			_stringStream.Write(temp);
			break;
		case .List(let list):
			_stringStream.Write(TextTag.ListStart);

			if (_flags == .Pretty) _stringStream.Write('\n');

			int currentIndex = 0;
			for (TreeNode element in list)
			{
				if (_flags == .Pretty)
				{
					_stringStream.Write(scope String('\t', indentation + 1));
				}

				WriteNode(element, indentation + 1);

				if (currentIndex < list.Count - 1)
				{
					_stringStream.Write(TextTag.Separator);

					if (_flags == .Pretty) _stringStream.Write('\n');
				}

				currentIndex += 1;
			}

			if (_flags == .Pretty)
			{
				_stringStream.Write('\n');
				_stringStream.Write(scope String('\t', indentation));
			}

			_stringStream.Write(TextTag.ListEnd);
			break;
		case .Null:
			_stringStream.Write("Null");
			break;
		case .Text(let s):
			_stringStream.Write(TextTag.Text);
			_stringStream.Write(s);
			_stringStream.Write(TextTag.Text);
			break;
		}
	}
}