using System;
using System.Collections;

namespace Voxis;

public class ScatteredBiomeBlender
{
    public delegate int GetBiomeDelegate(double x, double z);
	public delegate Biome DetermineBiomeDelegate(double x, double z);

    private readonly int chunkColumnCount;
    private readonly int blendRadiusBoundArrayCenter;
    private readonly double chunkWidthMinusOne;
    private readonly double blendRadius, blendRadiusSq;
    private readonly double[] blendRadiusBound;
    private readonly ChunkPointGatherer<LinkedBiomeWeightMap> gatherer;

    // chunkWidth should be a power of two.
    public this(double samplingFrequency, double blendRadiusPadding, int chunkWidth)
    {
        this.chunkWidthMinusOne = chunkWidth - 1;
        this.chunkColumnCount = chunkWidth * chunkWidth;
        this.blendRadius = blendRadiusPadding + getInternalMinBlendRadiusForFrequency(samplingFrequency);
        this.blendRadiusSq = blendRadius * blendRadius;
        this.gatherer = new ChunkPointGatherer<LinkedBiomeWeightMap>(samplingFrequency, blendRadius, chunkWidth);

        blendRadiusBoundArrayCenter = (int)Math.Ceiling(blendRadius) - 1;
        blendRadiusBound = new double[blendRadiusBoundArrayCenter * 2 + 1];
        for (int i = 0; i < blendRadiusBound.Count; i++)
        {
            int dx = i - blendRadiusBoundArrayCenter;
            int maxDxBeforeTruncate = Math.Abs(dx) + 1;
            blendRadiusBound[i] = Math.Sqrt(blendRadiusSq - maxDxBeforeTruncate);
        }

    }

	public ~this()
	{
		delete gatherer;
		delete blendRadiusBound;
	}

    public LinkedBiomeWeightMap GetBlendForChunck(int64 seed, int chunkBaseWorldX, int chunkBaseWorldZ, DetermineBiomeDelegate callback)
    {

        // Get the list of data points in range.
        List<GatheredPoint<LinkedBiomeWeightMap>> points = gatherer.getPointsFromChunkBase(seed, chunkBaseWorldX, chunkBaseWorldZ);

        // Evaluate and aggregate all biomes to be blended in this chunk.
        LinkedBiomeWeightMap linkedBiomeMapStartEntry = null;
        for (GatheredPoint<LinkedBiomeWeightMap> point in points)
        {

            // Get the biome for this data point from the callback.
            Biome biome = callback(point.getX(), point.getZ());

            // Find or create the chunk biome blend weight layer entry for this biome.
            LinkedBiomeWeightMap entry = linkedBiomeMapStartEntry;
            while (entry != null)
            {
                if (entry.getBiome() == biome) break;
                entry = entry.getNext();
            }
            if (entry == null)
            {
                entry = linkedBiomeMapStartEntry =
                    new LinkedBiomeWeightMap(biome, linkedBiomeMapStartEntry);
            }

            point.setTag(entry);
        }

        // If there is only one biome in range here, we can skip the actual blending step.
        if (linkedBiomeMapStartEntry != null && linkedBiomeMapStartEntry.getNext() == null)
        {
            /*double[] weights = new double[chunkColumnCount];
            linkedBiomeMapStartEntry.setWeights(weights);
            for (int i = 0; i < chunkColumnCount; i++) {
                weights[i] = 1.0;
            }*/

			DeleteContainerAndItems!(points);
            return linkedBiomeMapStartEntry;
        }

        for (LinkedBiomeWeightMap entry = linkedBiomeMapStartEntry; entry != null; entry = entry.getNext())
        {
            entry.setWeights(new double[chunkColumnCount]);
        }

        double z = chunkBaseWorldZ, x = chunkBaseWorldX;
        double xStart = x;
        double xEnd = xStart + chunkWidthMinusOne;
        for (int i = 0; i < chunkColumnCount; i++)
        {

            // Consider each data point to see if it's inside the radius for this column.
            double columnTotalWeight = 0.0;
            for (GatheredPoint<LinkedBiomeWeightMap> point in points)
            {
                double dx = x - point.getX();
                double dz = z - point.getZ();

                double distSq = dx * dx + dz * dz;

                // If it's inside the radius...
                if (distSq < blendRadiusSq)
                {

                    // Relative weight = [r^2 - (x^2 + z^2)]^2
                    double weight = blendRadiusSq - distSq;
                    weight *= weight;

                    point.getTag().getWeights()[i] += weight;
                    columnTotalWeight += weight;
                }
            }

            // Normalize so all weights in a column add up to 1.
            double inverseTotalWeight = 1.0 / columnTotalWeight;
            for (LinkedBiomeWeightMap entry = linkedBiomeMapStartEntry; entry != null; entry = entry.getNext())
            {
                entry.getWeights()[i] *= inverseTotalWeight;
            }

            // A double can fully represent an int, so no precision loss to worry about here.
            if (x == xEnd)
            {
                x = xStart;
                z++;
            }
            else x++;
        }

		DeleteContainerAndItems!(points);

        return linkedBiomeMapStartEntry;
    }

    public static double getInternalMinBlendRadiusForFrequency(double samplingFrequency)
    {
        return UnfilteredPointGatherer<ScatteredBiomeBlender>.MAX_GRIDSCALE_DISTANCE_TO_CLOSEST_POINT / samplingFrequency;
    }

    public double getInternalBlendRadius()
    {
        return blendRadius;
    }

    private class BiomeEvaluation
    {
        int biome;

        public this(int biome)
        {
            this.biome = biome;
        }
    }

}