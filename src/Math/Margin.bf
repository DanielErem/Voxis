using System;

namespace Voxis
{
	public struct Margin
	{
		public float Left;
		public float Top;
		public float Right;
		public float Bottom;

		public this(float left, float top, float right, float bottom)
		{
			Left = left;
			Top = top;
			Right = right;
			Bottom = bottom;
		}

		public static Margin Parse(StringView string)
		{
			// TODO: Figure out how to do this in a cleaner way

			if (string.IsEmpty || string.IsWhiteSpace)
			{
				return Margin(0, 0, 0, 0);
			}

			Margin result = Margin(0, 0, 0, 0);
			int count = 0;
			for (let part in string.Split(' ', 4))
			{
				if (count == 0) result.Left = float.Parse(part);
				if (count == 1) result.Top = float.Parse(part);
				if (count == 2) result.Right = float.Parse(part);
				if (count == 3) result.Bottom = float.Parse(part);

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
