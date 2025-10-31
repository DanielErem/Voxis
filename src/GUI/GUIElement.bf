using System;
using Voxis.Data;
using System.Collections;
using Voxis.GUI;

namespace Voxis;

public abstract class GUIElement
{
	// Shared parsed properties
	public Anchor RelAnch { get; set; }
	public Margin RelMarg { get; set; }
	public bool Enabled { get; set; }
	public bool Visible { get; set; }
	public LayoutFlags VLayoutFlags { get; set; }
	public LayoutFlags HLayoutFlags { get; set; }
	public String Tag { get; set; } =  new String() ~ delete _;
	public String ID { get; set; } = new String() ~ delete _;
	public GrowFlags VGrowFlags { get; set; } = .Both;
	public GrowFlags HGrowFlags { get; set; } = .Both;
	public int CustomDepth { get; set; } = 0;

	public float Rotation { get; set; } = 0.0f;
	public Vector2 Scale { get; set; } = Vector2.One;

	// Each Elements sets these flags itself
	public MouseFlags EventFlags { get; protected set; }

	// Internal state update
	public bool Hovered { get; private set; }
	public bool IsFocused { get; private set; }

	public Matrix3x2 Transform
	{
		get
		{
			return Matrix3x2.CreateScale(Scale, ScreenRect.Center) * Matrix3x2.CreateRotation(Rotation, ScreenRect.Center);
		}
	}

	public GUIElement Parent { get; private set; }
	public virtual GUIScreen Root
	{
		get
		{
			return Parent.Root;
		}
	}
	public virtual Rect ScreenRect
	{
		get
		{
			if (Parent == null) return Rect(RelMarg.Left, RelMarg.Top, RelMarg.Right, RelMarg.Bottom);

			Rect parentRect = Parent.ScreenRect;
			Rect thisRect = Rect.FromMinMax(
				Vector2(parentRect.X + parentRect.Width * RelAnch.XMin + RelMarg.Left, parentRect.Y + parentRect.Height * RelAnch.YMin + RelMarg.Top),
				Vector2(parentRect.X + parentRect.Width * RelAnch.XMax + RelMarg.Right, parentRect.Y + parentRect.Height * RelAnch.YMax + RelMarg.Bottom)
			);

			Vector2 minSize = GetMinSize();

			if (thisRect.Size.X < minSize.X)
			{
				float missingSize = minSize.X - thisRect.Size.X;

				thisRect.X += missingSize;

				switch (HGrowFlags)
				{
				case .Both:
					thisRect.X -= missingSize / 2;
					break;
				case .Negative:
					thisRect.X -= missingSize;
					break;
				case .Positive:
					break;
				}
			}

			if (thisRect.Size.Y < minSize.Y)
			{
				float missingSize = minSize.Y - thisRect.Size.Y;

				thisRect.Height += missingSize;

				switch (VGrowFlags)
				{
				case .Both:
					thisRect.Y -= missingSize / 2;
					break;
				case .Negative:
					thisRect.Y -= missingSize;
					break;
				case .Positive:
					break;
				}
			}

			return thisRect;
		}
	}

	protected List<GUIElement> childElements = new List<GUIElement>() ~ DeleteContainerAndItems!(_);

	protected this()
	{
		Enabled = true;
		Visible = true;
		EventFlags = .Stop;
	}

	public void FillParent()
	{
		RelAnch = Anchor(0, 0, 1, 1);
		RelMarg = Margin(0, 0, 0, 0);
	}

	public bool CompareTag(System.StringView tagTest)
	{
		if (Tag == null) return false;

		return Tag == tagTest;
	}

	public T SearchTaggedElement<T>(System.StringView tag) where T : GUIElement
	{
		if (CompareTag(tag)) return (T)this;

		for (GUIElement child in childElements)
		{
			T temp = child.SearchTaggedElement<T>(tag);

			if (temp != null) return temp;
		}

		return null;
	}

	public T FindElement<T>(StringView id, bool recursive = true) where T : GUIElement
	{
		if (ID == id) return this as T;

		if (recursive)
		{
			T result = null;
			for (GUIElement child in childElements)
			{
				result = child.FindElement<T>(id);

				if (result != null) return result;
			}
		}
		else
		{
			for (GUIElement child in childElements)
			{
				if (child.ID == id) return child as T;
			}
		}

		return null;
	}

	public void AddChild(GUIElement element)
	{
		childElements.Add(element);
		element.Parent = this;
	}

	public virtual void OnUpdate()
	{
		if (!Enabled || !Visible) return;

		for(GUIElement childElement in childElements)
		{
			childElement.OnUpdate();
		}
	}
	public virtual void OnDraw(int currentDepth)
	{
		if (!Visible) return;

		for(GUIElement childElement in childElements)
		{
			childElement.OnDraw(currentDepth + 1);
		}
	}
	public virtual void OnInputEvent(InputEvent event)
	{
		if (!Enabled || !Visible) return;

		// Reverse event order! (Lower GUI Element in the Hierarchy are usually in front of others)
		for (int i = childElements.Count - 1; i >= 0 && !event.Consumed; i--)
		{
			childElements[i].OnInputEvent(event);
		}

		if (event.Consumed) return;

		if (event is InputEventMouseMovement)
		{
			InputEventMouseMovement movement = event as InputEventMouseMovement;

			if (ScreenRect.ContainsPoint(movement.Position))
			{
				if (EventFlags == .Stop) event.Consume();

				if(!Hovered)
				{
					Hovered = true;
					OnMouseEnter();
				}
			}
			else
			{
				if (Hovered)
				{
					Hovered = false;
					OnMouseExit();
				}
			}
		}
		else if(event is InputEventMouseButton)
		{
			InputEventMouseButton mbe = event as InputEventMouseButton;

			if(Hovered && mbe.Button == .Left && mbe.Action == .Press)
			{
				if (!event.Consumed) GUICanvas.SetFocused(this);
				OnMouseClick();
				if (EventFlags == .Stop) event.Consume();
			}
		}
	}

	public virtual Vector2 GetMinSize()
	{
		return Vector2(0, 0);
	}

	public virtual void Parse(TreeNode elementNode)
	{
		elementNode.GetOrDefault("id", ID, "");

		String anchorValues = scope String();
		String marginValues = scope String();

		elementNode.GetOrDefault("anchor", anchorValues, "fill");
		elementNode.GetOrDefault("margin", marginValues, "");

		RelAnch = Anchor.Parse(anchorValues);
		RelMarg = Margin.Parse(marginValues);

		Enabled = elementNode.GetOrDefault("enabled", Enabled);
		Visible = elementNode.GetOrDefault("visible", Visible);

		Rotation = (float)elementNode.GetOrDefault("rotation", Rotation);

		CustomDepth = (int)elementNode.GetOrDefault("depth", CustomDepth);

		if (elementNode.Contains("v_layout"))
		{
			VLayoutFlags = Enum.Parse<LayoutFlags>(elementNode.Get("v_layout").AsText());
		}
		if (elementNode.Contains("h_layout"))
		{
			VLayoutFlags = Enum.Parse<LayoutFlags>(elementNode.Get("h_layout").AsText());
		}
		if (elementNode.Contains("v_grow"))
		{
			VGrowFlags = Enum.Parse<GrowFlags>(elementNode.Get("v_grow").AsText());
		}
		if (elementNode.Contains("h_grow"))
		{
			HGrowFlags = Enum.Parse<GrowFlags>(elementNode.Get("h_grow").AsText());
		}
		if (elementNode.Contains("scale"))
		{
			String tempString = scope String();
			elementNode.GetOrDefault("scale", tempString, "1 1");
			Scale = Vector2.Parse(tempString);
		}
	}

	protected virtual void OnMouseEnter()
	{

	}
	protected virtual void OnMouseExit()
	{

	}
	protected virtual void OnMouseClick()
	{

	}
	protected virtual void OnFocusEnter()
	{

	}
	protected virtual void OnFocusExit()
	{

	}
}
