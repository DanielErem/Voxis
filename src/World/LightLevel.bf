namespace Voxis;

public struct LightLevel
{
    const int MASK = (1 << 4) - 1;

    private uint16 Channels {get; set mut; };

    public int R => Channels & MASK;
    public int G => (Channels >> 4) & MASK;
    public int B => (Channels >> 8) & MASK;
    public int S => (Channels >> 12) & MASK;

    public static LightLevel Empty => Self(0);

	public this(uint16 channels)
	{
		Channels = channels;
	}

    public this(int r, int g, int b, int s = 0)
    {
        Channels = (uint16)((s << 12) | (b << 8) | (g << 4) | (r));
    }

    public int this[int key]
    {
        get
        {
            return (Channels >> (key * 4)) & MASK;
        }
        set mut
        {
            // Zero out previous
            Channels = (uint16)(Channels & ~(0xFF << (key * 4)));

            // Prepare shifted value
            int temp = value << (key * 4);

            Channels = (uint16)(Channels | temp);
        }
    }

    public Color32 ToColor32()
    {
		return Color32(
			(uint8)R * 16,
			(uint8)G * 16,
			(uint8)B * 16,
			(uint8)S * 16
			);
    }

    public LightLevel Max(LightLevel other)
    {
        return LightLevel(
            System.Math.Max(R, other.R),
            System.Math.Max(G, other.G),
            System.Math.Max(B, other.B),
            System.Math.Max(S, other.S)
            );
    }
}