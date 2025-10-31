namespace Voxis.Data;

public enum BinaryTag : uint8
{
	Null,
	ObjectStart,
	ObjectEnd,
	ListStart,
	Boolean,
	Number,
	Decimal,
	Text,
	MapKey,
}