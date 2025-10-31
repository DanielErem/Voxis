using System;

namespace Voxis
{
	public struct ChunckIndex : IHashable
	{
		public int16 X;
		public int16 Z;

		public this(int16 x, int16 z)
		{
			X = x;
			Z = z;
		}

		public int GetHashCode()
		{
			return int32(X) | (int32(Z) << 16);
		}

		public ChunckIndex Offset(int16 x, int16 z)
		{
			return ChunckIndex(X + x, Z + z);
		}

		public override void ToString(String strBuffer)
		{
			strBuffer.AppendF("{{0}, {2}}", X, Z);
		}

		public static ChunckIndex FromPosition(Vector3 pos)
		{
			return ChunckIndex(int16(pos.X) >> Chunck.LOG_SIZE, int16(pos.Z) >> Chunck.LOG_SIZE);
		}

		public Vector3 ToWorldVector()
		{
			return Vector3(X, 0, Z) * Chunck.SIZE;
		}
	}
}
