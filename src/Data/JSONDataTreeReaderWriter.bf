namespace Voxis.Data;

using System.IO;
using System;

public class JSONDataTreeReaderWriter : DataTreeReaderWriter
{
	private String _string;
	private int _position;

	public override void Write(DataTree tree, Stream stream)
	{
		StringStream stringStream = scope StringStream();
		WriteNode(tree.Root, stringStream, false, 0);
		String buffer = scope String();
		stringStream.ToString(buffer);

		stream.Write(buffer);
	}
	public override Result<DataTree> Read(Stream stream)
	{
		_string = new String();
		_position = 0;

		// TODO: This is so stupid, why do i need to do this?
		while (stream.CanRead)
		{
			String temp = scope String();
			stream.ReadStrSized32(128, temp);

			if (temp.IsEmpty) break;

			_string.Append(temp);
		}
		SkipWhitespace();

		// Now we can read
		TreeNode root = ReadNode();

		// Reset state
		delete _string;
		_position = 0;

		return new DataTree(root);
	}

	private void WriteNode(TreeNode node, StringStream stream, bool pretty, int indentation)
	{
		switch(node)
		{
		case .Object(let map):
			stream.Write(TextTag.ObjectStart);

			if (pretty) stream.Write("\n");

			int currentIndex = 0;
			for (let pair in map)
			{
				if (pretty)
				{
					stream.Write(scope String('\t', indentation + 1));
				}

				stream.Write(TextTag.Text);
				stream.Write(pair.key);
				stream.Write(TextTag.Text);

				stream.Write(TextTag.KeyValueSeparator);

				if (pretty) stream.Write(TextTag.Space);

				WriteNode(pair.value, stream, pretty, indentation + 1);

				if (currentIndex < map.Count - 1)
				{
					stream.Write(TextTag.Separator);

					if (pretty) stream.Write('\n');
				}

				currentIndex += 1;
			}

			if (pretty)
			{
				stream.Write('\n');
				stream.Write(scope String('\t', indentation));
			}

			stream.Write(TextTag.ObjectEnd);
			break;
		case .Boolean(let n):
			if (n) stream.Write("true");
			else stream.Write("false");
			break;
		case .Number(let n):
			String temp = scope String();
			n.ToString(temp);
			stream.Write(temp);
			break;
		case .Decimal(let n):
			String temp = scope String();
			n.ToString(temp);
			stream.Write(temp);
			break;
		case .List(let list):
			stream.Write(TextTag.ListStart);

			if (pretty) stream.Write('\n');

			int currentIndex = 0;
			for (TreeNode element in list)
			{
				if (pretty)
				{
					stream.Write(scope String('\t', indentation + 1));
				}

				WriteNode(element, stream, pretty, indentation + 1);

				if (currentIndex < list.Count - 1)
				{
					stream.Write(TextTag.Separator);

					if (pretty) stream.Write('\n');
				}

				currentIndex += 1;
			}

			if (pretty)
			{
				stream.Write('\n');
				stream.Write(scope String('\t', indentation));
			}

			stream.Write(TextTag.ListEnd);
			break;
		case .Null:
			stream.Write("Null");
			break;
		case .Text(let s):
			stream.Write(TextTag.Text);
			stream.Write(s);
			stream.Write(TextTag.Text);
			break;
		}
	}

	private char8 CurrentCharacter
	{
		get
		{
			if (_position >= _string.Length) return '0';
			return _string[_position];
		}
	}
	private char8 NextCharacter
	{
		get
		{
			if (_position + 1 >= _string.Length) return '0';
			return _string[_position + 1];
		}
	}

	private void Advance()
	{
		_position++;
	}

	private bool Match(StringView toMatch)
	{
		for (int i = 0; i < toMatch.Length; i++)
		{
			if (_position + i >= _string.Length) return false;

			if (_string[_position + i] != toMatch[i]) return false;
		}

		_position += toMatch.Length;

		return true;
	}

	private void ReadString(String buffer)
	{
		Advance();
		while (CurrentCharacter != '\0' && CurrentCharacter != '"')
		{
			buffer.Append(CurrentCharacter);
			Advance();
		}
		Advance();
	}

	private void SkipWhitespace()
	{
		while (CurrentCharacter != '\0' && CurrentCharacter.IsWhiteSpace) Advance();
	}

	private TreeNode ReadObject()
	{
		Advance();
		SkipWhitespace();

		TreeNodeMap map = new TreeNodeMap();

		while (CurrentCharacter != TextTag.ObjectEnd.Underlying)
		{
			if (CurrentCharacter == '\0') Runtime.FatalError();

			String key = new String();
			ReadString(key);

			SkipWhitespace();

			if (CurrentCharacter != TextTag.KeyValueSeparator.Underlying) Runtime.FatalError();

			Advance();
			SkipWhitespace();

			TreeNode childNode = ReadNode();

			SkipWhitespace();

			map[key] = childNode;

			if (CurrentCharacter == ',')
			{
				Advance();
				SkipWhitespace();
			}
		}

		if (CurrentCharacter == TextTag.ObjectEnd.Underlying)
		{
			Advance();
			SkipWhitespace();
		}

		return TreeNode.Object(map);
	}

	private TreeNode ReadBoolean()
	{
		if (Match("true")) return TreeNode.Boolean(true);
		else if (Match("false")) return TreeNode.Boolean(false);

		Runtime.FatalError();
	}

	private TreeNode ReadNumber()
	{
		String asText = scope String();
		bool isFloat = false;
		bool isNegative = false;

		while (CurrentCharacter.IsNumber || CurrentCharacter == '.' || CurrentCharacter == '-')
		{
			if (CurrentCharacter == '.')
			{
				if (isFloat) Runtime.FatalError();
				isFloat = true;
			}
			else if (CurrentCharacter == '-')
			{
				if (isNegative) Runtime.FatalError();
				isNegative = true;
			}

			asText.Append(CurrentCharacter);

			Advance();
		}

		SkipWhitespace();

		if (isFloat) return TreeNode.Decimal(double.Parse(asText));
		else return TreeNode.Number(int64.Parse(asText));
	}

	private TreeNode ReadList()
	{
		// Consume list start tag
		Advance();
		SkipWhitespace();

		System.Collections.List<TreeNode> list = new System.Collections.List<TreeNode>();

		while (true)
		{
			if (CurrentCharacter == '\0') Runtime.FatalError();

			if (CurrentCharacter == TextTag.ListEnd.Underlying) break;

			TreeNode child = ReadNode();

			SkipWhitespace();

			if (CurrentCharacter == TextTag.Separator.Underlying)
			{
				// Just ignore that for now
				Advance();
				SkipWhitespace();
			}

			list.Add(child);
		}

		if (CurrentCharacter == TextTag.ListEnd.Underlying)
		{
			Advance();
			SkipWhitespace();
		}

		return TreeNode.List(list);
	}

	private TreeNode ReadNode()
	{
		switch (CurrentCharacter)
		{
		case TextTag.ObjectStart.Underlying:
			return ReadObject();
		case TextTag.ListStart.Underlying:
			return ReadList();
		case TextTag.Text.Underlying:
			String result = new String();
			ReadString(result);
			return TreeNode.Text(result);
		default:
			if (CurrentCharacter.IsLetter) return ReadBoolean();
			else if (CurrentCharacter.IsNumber || CurrentCharacter == '-') return ReadNumber();
			Runtime.FatalError();
		}
	}
}