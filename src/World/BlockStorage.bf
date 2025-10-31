using System;
using System.Collections;
using System.Threading;

namespace Voxis
{
	public class BlockStorage
	{
		public int32 Size { get; }
		public int32 Height { get; }
		public bool IsEmpty
		{
			get
			{
				return _isEmpty;
			}
		}
		public bool IsAir
		{
			get
			{
				if (IsEmpty) return true;

				for (PaletteEntry entriy in _palette)
				{
					if (entriy.State != AirBlock.DEFAULT_AIR_STATE && entriy.Reference > 0) return false;
				}

				return true;
			}
		}

		private PaletteEntry[] _palette;
		private bool _isEmpty = true;
		private BitArray _data;

		public this(int32 size, int32 height)
		{
			Size = size;
			Height = height;

			_palette = new PaletteEntry[1];
			_palette[0] = PaletteEntry(AirBlock.DEFAULT_AIR_STATE, 0);

			_data = new BitArray(size * height * size, GetStorageBits(_palette.Count));

			_isEmpty = true;
		}

		public ~this()
		{
			delete _palette;
			delete _data;
		}

		public BlockState this[int32 x, int32 y, int32 z]
		{
		    get
		    {
		        uint64 index = _data.GetIndex(GetIndex(x, y, z));
		        BlockState state = index == 0 ? AirBlock.DEFAULT_AIR_STATE : _palette[int(index - 1)].State;

				return state;
		    }
		    set
		    {
		        if (value == null)
				{
					Runtime.FatalError("Cannot set block to null. Use AirBlock.DFEAULT_AIR_STATE to clear a block!");
				}

		        // Get palette index
		        uint64 index = _data.GetIndex(GetIndex(x, y, z));

		        if (index != 0)
		        {
		            // Decrement reference
		            _palette[int32(index - 1)].Reference--;
		        }

		        if (value == AirBlock.DEFAULT_AIR_STATE) _data.SetIndex(GetIndex(x, y, z), 0);
		        else
				{
					uint64 otherIndex = IndexToPalette(value) + 1;

					_data.SetIndex(GetIndex(x, y, z), otherIndex);

					_isEmpty = false;
				}
		    }
		}

		private int32 GetIndex(int32 x, int32 y, int32 z)
		{
		    return x + z * Size + y * Size * Size;
		}

		private uint32 IndexToPalette(BlockState state)
		{
		    // Existing
		    for (uint32 i = 0; i < _palette.Count; i++)
		    {
		        if (_palette[i].State == state)
		        {
		            _palette[i].Reference++;
		            return i;
		        }
		    }

		    // Not existing (in extra loop to reduce checks, this case does not happen very often)
		    for (uint32 i = 0; i < _palette.Count; i++)
		    {
				if (_palette[i].State == null || _palette[i].Reference <= 0)
				{
					_palette[i].State = state;
					_palette[i].Reference = 1;
					return i;
				}
		    }
			
		    // No room for new states, expand array
		    PaletteEntry[] temp = new PaletteEntry[_palette.Count * 2];

			// TODO: Cannot use Array.CopyTo, buggy???
			for (int i = 0; i < _palette.Count; i++)
			{
				temp[i] = _palette[i];
			}

			delete _palette;

		    _palette = temp;

		    // We now need to store more bits per element, need to resize bit array and copy data
		    if (_data.BitsPerIndex < GetStorageBits(_palette.Count))
		    {
		        BitArray oldData = _data;

		        _data = new BitArray(Size * Height * Size, GetStorageBits(_palette.Count));
		        _data.CopyFrom(oldData);

				delete oldData;
		    }

		    return IndexToPalette(state);
		}

		private int32 GetStorageBits(int count)
		{
			return (int32)(Math.Log(count, 2.0f) + 1);
		}
	}
}
