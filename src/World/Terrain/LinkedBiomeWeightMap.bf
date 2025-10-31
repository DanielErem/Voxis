namespace Voxis;

public class LinkedBiomeWeightMap
{
    private Biome biome;
    private double[] weights;
    private LinkedBiomeWeightMap next;

    public this(Biome biome, LinkedBiomeWeightMap next)
    {
        this.biome = biome;
        this.next = next;
    }

    public this(Biome biome, int chunkColumnCount, LinkedBiomeWeightMap next)
    {
        this.biome = biome;
        this.weights = new double[chunkColumnCount];
        this.next = next;
    }

	public ~this()
	{
		delete weights;
		if (next != null) delete next;
	}

    public Biome getBiome()
    {
        return biome;
    }

    public double[] getWeights()
    {
        return weights;
    }

    public void setWeights(double[] weights)
    {
		if (this.weights != null) delete this.weights;
        this.weights = weights;
    }

    public LinkedBiomeWeightMap getNext()
    {
        return next;
    }
}