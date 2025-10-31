using System;
using System.IO;

namespace Voxis.Data;

public class TextDataTreeReader
{
	private String _string;
	private int _position = 0;

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

	public DataTree ReadFromFile(StringView path)
	{
		_string = scope String();
		File.ReadAllText(path, _string);

		SkipWhitespace();

		// There should be only one root object
		TreeNode root = ReadNode();

		return new DataTree(root);
	}

	public DataTree ReadFromText(StringView text)
	{
		_string = scope String(text);
		_position = 0;

		SkipWhitespace();

		TreeNode root = ReadNode();

		return new DataTree(root);
	}

	public TreeNode ReadNode()
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