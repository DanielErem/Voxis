using System.Collections;
using System;

namespace Voxis.Data;

typealias TreeNodeMap = Dictionary<String, TreeNode>;

public enum TreeNode
{
	case Null;
	case Text(String string);
	case Number(int64 integer);
	case Decimal(double floating);
	case List(List<TreeNode> array);
	case Object(TreeNodeMap map);
	case Boolean(bool b);

	public TreeNode AddChild(StringView childName, TreeNode nodeToAdd)
	{
		if (this case .Object(let map))
		{
			map.Add(new String(childName), nodeToAdd);
			return nodeToAdd;
		}

		if (this case .List(let list))
		{
			list.Add(nodeToAdd);
			return nodeToAdd;
		}

		Runtime.FatalError();
	}

	public TreeNode CreateChildObject(StringView childName)
	{
		if (this case .Object || this case .List)
		{
			return AddChild(childName, .Object(new TreeNodeMap()));
		}

		Runtime.FatalError();
	}

	public TreeNode CreateChildList(StringView name)
	{
		if (this case .Object || this case .List)
		{
			return AddChild(name, .List(new List<TreeNode>()));
		}

		Runtime.FatalError();
	}

	public TreeNode FindChild(StringView name, bool recursive = false)
	{
		if (this case .Object(let map))
		{
			for (let enumerator in map)
			{
				if (enumerator.key == name) return enumerator.value;

				if (recursive && enumerator.value case .Object)
				{
					TreeNode found = enumerator.value.FindChild(name, recursive);

					if (found != .Null) return found;
				}
			}
		}

		return .Null;
	}

	public int GetChildCount()
	{
		if (this case .Object(let map)) return map.Count;
		else if (this case .List(let list)) return list.Count;

		Runtime.FatalError();
	}

	public TreeNode GetChildAtIndex(int index)
	{
		if (this case .List(let list)) return list[index];

		Runtime.FatalError();
	}

	public void Set(StringView name, TreeNode value)
	{
		if (this case .Object(let map))
		{
			String tempString = new String(name);

			// Key is already owned
			if (map.ContainsKey(tempString))
			{
				map[tempString]  = value;
				delete tempString;
			}
			else
			{
				map[tempString] = value;
			}

			return;
		}

		Runtime.FatalError();
	}

	public void Set(StringView name, int64 value)
	{
		Set(name, .Number(value));
	}
	public void Set(StringView name, double value)
	{
		Set(name, .Decimal(value));
	}
	public void Set(StringView name, StringView value)
	{
		Set(name, .Text(new String(value)));
	}
	public void Set(StringView name, bool value)
	{
		Set(name, .Boolean(value));
	}

	public TreeNode Get(StringView name)
	{
		if (this case .Object(let map))
		{
			String temp = scope String(name);

			if (map.ContainsKey(temp)) return map[temp];
		}

		return .Null;
	}

	public bool Contains(StringView name)
	{
		if (this case .Object(let map))
		{
			return map.ContainsKeyAlt(name);
		}

		return false;
	}

	public TreeNode GetOrDefault(StringView name, TreeNode defaultValue)
	{
		if (Contains(name)) return Get(name);

		return defaultValue;
	}

	public bool GetOrDefault(StringView name, bool defaultValue)
	{
		if (!Contains(name)) return defaultValue;

		return Get(name).AsbBoolean();
	}

	public double GetOrDefault(StringView name, double defaultValue)
	{
		if (!Contains(name)) return defaultValue;

		return Get(name).AsDecimal();
	}

	public int64 GetOrDefault(StringView name, int64 defaultValue)
	{
		if (!Contains(name)) return defaultValue;

		return Get(name).AsNumber();
	}

	// Helper methods
	public void GetOrDefault(StringView name, String outString, StringView defaultValue)
	{
		if (!Contains(name))
		{
			outString.Append(defaultValue);
			return;
		}

		outString.Append(Get(name).AsText());
	}

	public List<TreeNode> AsList()
	{
		if (this case .List(let l)) return l;

		Runtime.FatalError();
	}
	public bool AsbBoolean()
	{
		if (this case .Boolean(let b)) return b;

		Runtime.FatalError();
	}
	public int64 AsNumber()
	{
		if (this case .Number(let n)) return n;
		else if (this case .Decimal(let d)) return int64(d);

		Runtime.FatalError();
	}
	public double AsDecimal()
	{
		if (this case .Decimal(let d)) return d;
		else if (this case .Number(let n)) return double(n);

		Runtime.FatalError();
	}
	public StringView AsText()
	{
		if (this case .Text(let s)) return s;

		Runtime.FatalError();
	}
	public Variant AsVariant()
	{
		switch (this)
		{
		case .Boolean(let b):
			return Variant.Create(b);
		case .Text(let t):
			return Variant.Create(t);
		case .Number(let n):
			return Variant.Create(n);
		case .Decimal(let d):
			return Variant.Create(d);
		default:
			Runtime.FatalError("Unsupported type");
		}
	}

	public void Delete()
	{
		switch (this)
		{
		case .List(let list):
			for (TreeNode child in list)
			{
				child.Delete();
			}
			delete list;
			break;
		case .Object(let map):
			for (let pair in map)
			{
				delete pair.key;
				pair.value.Delete();
			}
			delete map;
			break;
		case .Text(let s):
			delete s;
			break;
		default:
			// Nothing to delete
		}
	}
}