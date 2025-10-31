using System;

namespace Voxis
{
    public class BitArray
    {
        public int32 MaxIndicesPerElement { get; private set; }
        public int32 BitsPerIndex { get; private set; }
        public int32 Length { get; private set; }

        private uint64[] _data;
        private int32[] _shiftValues;

        public this(int32 numIndices, int32 bitsPerIndex)
        {
            BitsPerIndex = bitsPerIndex;
            MaxIndicesPerElement = 64 / BitsPerIndex;
            int numElements = (numIndices + MaxIndicesPerElement - 1) / MaxIndicesPerElement;
            _data = new uint64[numElements];

			// Initialize to zero
			for (int i = 0; i < _data.Count; i++)
			{
				_data[i] = 0;
			}

            _shiftValues = new int32[MaxIndicesPerElement];
            for(int32 i = 0; i < _shiftValues.Count; i++)
            {
                _shiftValues[i] = i * BitsPerIndex;
            }

            Length = numIndices;
        }

		public ~this()
		{
			delete _data;
			delete _shiftValues;
		}

        public void SetIndex(int32 index, uint64 value)
        {
            int32 elementIndex = index / MaxIndicesPerElement;
            int32 withinElementIndex = index % MaxIndicesPerElement;
            int32 leftShift = _shiftValues[withinElementIndex];

            _data[elementIndex] &= ~(0xFFFFFFFFFFFFFFFF >> (64 - BitsPerIndex) << leftShift);
            _data[elementIndex] |= (value & ((1uL << BitsPerIndex) - 1)) << leftShift;
        }

        public uint64 GetIndex(int32 index)
        {
            int32 elementIndex = index / MaxIndicesPerElement;
            int32 withingElementIndex = index % MaxIndicesPerElement;
            int32 leftShift = _shiftValues[withingElementIndex];

            return (_data[elementIndex] >> leftShift) & ((1uL << BitsPerIndex) - 1);
        }

        public void CopyFrom(BitArray bitArray)
        {
            if (bitArray.Length != Length)
			{
				Runtime.FatalError("Source and destination length does not match!");
			}

            for (int32 i = 0; i < Length; i++)
            {
                SetIndex(i, bitArray.GetIndex(i));
            }
        }
    }
}
