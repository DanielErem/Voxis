using System;

namespace Voxis
{
	public struct Anchor
	{
		public float XMin;
		public float YMin;
		public float XMax;
		public float YMax;

		public static Anchor Center
		{
			get
			{
				return Anchor(0.5f, 0.5f, 0.5f, 0.5f);
			}
		}
		public static Anchor Zero
		{
			get
			{
				return Anchor(0, 0, 0, 0);
			}
		}

		public this(float xmin, float ymin, float xman, float ymax)
		{
			XMin = xmin;
			YMin = ymin;
			XMax = xman;
			YMax = ymax;
		}

		public static Anchor Parse(StringView string)
		{
			// TODO: Figure out how to do this in a cleaner way

			if (string == "fill")
			{
				return Anchor(0, 0, 1, 1);
			}
			switch (string)
			{
			case "fill":
				return Anchor(0, 0, 1, 1);
			case "center":
				return Anchor(0.5f, 0.5f, 0.5f, 0.5f);
			case "top":
				return Anchor(0, 0, 1, 0);
			case "bottom":
				return Anchor(0, 1, 1, 1);
			case "left":
				return Anchor(0, 0, 0, 1);
			case "right":
				return Anchor(1, 0, 1, 1);
			}

			Anchor result = Anchor(0, 0, 0, 0);
			int count = 0;
			for (let part in string.Split(' ', 4))
			{
				if (count == 0) result.XMin = float.Parse(part);
				if (count == 1) result.YMin = float.Parse(part);
				if (count == 2) result.XMax = float.Parse(part);
				if (count == 3) result.YMax = float.Parse(part);

				count++;
			}

			if (count != 4)
			{
				Runtime.FatalError("Parse error. Invalid amount of elements");
			}

			return result;
		}
	}
}
