namespace Voxis.Data;

public enum TextTag : char8
{
	Space = ' ',
	ObjectStart = '{',
	ObjectEnd = '}',
	ListStart = '[',
	ListEnd = ']',
	KeyValueSeparator = ':',
	Text = '"',
	Separator = ',',
	Indentation = '\t'
}