using Voxis.Data;
using System;

namespace Voxis.GUI;

public class ParsedGUIScreen : GUIScreen
{
	// Creates a gui screen by parsing the elements from a document tree
	// This tree is usually read from a json file
	public this(DataTree documentTree)
	{
		ParseFromDatatree(documentTree);
	}

	public this()
	{

	}

	protected void ParseFromDatatree(DataTree document)
	{
		TreeNode root = document.Root;

		root.GetOrDefault("id", ID, "");

		CloseOnEscape = root.GetOrDefault("close_on_escape", true);
		IsHud = root.GetOrDefault("is_hud", false);
		ReuseInstance = root.GetOrDefault("reuse_instance", false);

		TreeNode children = root.Get("children");

		if (children case .List(let list))
		{
			for (int childIndex = 0; childIndex < list.Count; childIndex++)
			{
				TreeNode childDefinition = list[childIndex];

				GUIElement createdElement = ParseSingleElement(childDefinition);

				AddChild(createdElement);
			}
		}
	}

	// Parses a GUIElement recursively
	private GUIElement ParseSingleElement(TreeNode elementNode)
	{
		GUIElement newElement = null;

		StringView type = elementNode.Get("type").AsText();

		// TODO: Figure out a better way to do this
		switch (type)
		{
		case "label":
			newElement = new Label();
			break;
		case "button":
			newElement = new Button();
			break;
		case "panel":
			newElement = new Panel();
			break;
		case "vertical_box":
			newElement = new VerticalBox();
			break;
		case "texture_rect":
			// TODO: Add this element
			newElement = new TextureRect();
			break;
		}

		// Type of element is a must
		if (newElement == null) Runtime.FatalError("No or invalid element type specified");

		newElement.Parse(elementNode);

		TreeNode children = elementNode.Get("children");

		if (children case .List(let list))
		{
			for (int i = 0; i < list.Count; i++)
			{
				newElement.AddChild(ParseSingleElement(list[i]));
			}
		}

		return newElement;
	}
}