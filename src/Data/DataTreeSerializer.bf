using System;
using System.Collections;
namespace Voxis.Data;

public static class DataTreeSerializer
{
	public static DataTree SerializeObject(Object obj)
	{
		TreeNode serialized = SerializeNestedObject(obj);

		return new DataTree(serialized);
	}

	public static T DeserializeObject<T>(DataTree tree)
	{
		Object created = DeserializeNestedObject(typeof(T), tree.Root);

		if (typeof(T).IsValueType)
		{
			T result = (T)created;

			delete created;

			return result;
		}
		else
		{
			return (T)created;
		}
	}

	public static Object DeserializeNestedObject(Type targetType, TreeNode node)
	{
		Object createdObject = null;

		if (targetType.IsStruct)
		{
			if (targetType == typeof(Vector3))
			{
				createdObject = new box Vector3();
			}
			else
			{
				Runtime.FatalError("Cannot deserialize struct");
			}
		}
		else
		{
			createdObject = targetType.CreateObject();
		}

		// Deserialize all fields of the created object
		for (var fieldInfo in targetType.GetFields())
		{
			if (fieldInfo.IsReadOnly) continue;

			TreeNode subNode = node.Get(fieldInfo.Name);

			if (fieldInfo.FieldType == typeof(float))
			{
				fieldInfo.SetValue(createdObject, (float)subNode.AsDecimal());
			}
			else if (fieldInfo.FieldType == typeof(double))
			{
				fieldInfo.SetValue(createdObject, subNode.AsDecimal());
			}
			else if (fieldInfo.FieldType == typeof(int))
			{
				fieldInfo.SetValue(createdObject, (int)subNode.AsNumber());
			}
			else
			{
				Runtime.FatalError("Unhandled type");
			}
		}

		return createdObject;
	}

	public static TreeNode SerializeNestedObject(Object value)
	{
		Type type = value.GetType();

		Dictionary<String, TreeNode> children = new Dictionary<String, TreeNode>();

		for (var fieldInfo in type.GetFields())
		{
			if (fieldInfo.IsReadOnly) continue;

			StringView fieldName = fieldInfo.Name;
			Variant val = fieldInfo.GetValue(value).Value;
			Type fieldType = fieldInfo.FieldType;
			bool primitive = fieldType.IsPrimitive;

			TreeNode leafNode = TreeNode.Null;
			if (primitive)
			{
				leafNode = SerializePrimitive(val);
			}

			children.Add(new String(fieldName), leafNode);

			Console.WriteLine(fieldInfo.Name);
		}

		return TreeNode.Object(children);
	}

	public static TreeNode SerializePrimitive(Variant value)
	{
		if (value.VariantType == typeof(int))
		{
			int i = value.Get<int>();

			return TreeNode.Number(i);
		}
		else if (value.VariantType == typeof(float))
		{
			float f = value.Get<float>();

			return TreeNode.Decimal(f);
		}

		return TreeNode.Null;
	}
}