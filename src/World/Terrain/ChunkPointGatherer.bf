using System;
using System.Collections;

namespace Voxis;

public class ChunkPointGatherer<TTag>
{

    private static readonly double CHUNK_RADIUS_RATIO = Math.Sqrt(1.0 / 2.0);

    int halfChunkWidth;
    double maxPointContributionRadius;
    double maxPointContributionRadiusSq;
    double radiusPlusHalfChunkWidth;
    UnfilteredPointGatherer<TTag> unfilteredPointGatherer;

    public this(double frequency, double maxPointContributionRadius, int chunkWidth)
    {
        this.halfChunkWidth = chunkWidth / 2;
        this.maxPointContributionRadius = maxPointContributionRadius;
        this.maxPointContributionRadiusSq = maxPointContributionRadius * maxPointContributionRadius;
        this.radiusPlusHalfChunkWidth = maxPointContributionRadius + halfChunkWidth;
        unfilteredPointGatherer = new UnfilteredPointGatherer<TTag>(frequency,
                maxPointContributionRadius + chunkWidth * CHUNK_RADIUS_RATIO);
    }

	public ~this()
	{
		delete unfilteredPointGatherer;
	}

    public List<GatheredPoint<TTag>> getPointsFromChunkBase(int64 seed, int chunkBaseWorldX, int chunkBaseWorldZ)
    {
        // Technically, the true minimum is between coordinates. But tests showed it was more efficient to add before converting to doubles.
        return getPointsFromChunkCenter(seed, chunkBaseWorldX + halfChunkWidth, chunkBaseWorldZ + halfChunkWidth);
    }

    public List<GatheredPoint<TTag>> getPointsFromChunkCenter(int64 seed, int chunkCenterWorldX, int chunkCenterWorldZ)
    { 
        List<GatheredPoint<TTag>> worldPoints = unfilteredPointGatherer.getPoints(seed, chunkCenterWorldX, chunkCenterWorldZ);
        for (int i = 0; i < worldPoints.Count; i++)
        {
            GatheredPoint<TTag> point = worldPoints[i];

            // Check if point contribution radius lies outside any coordinate in the chunk
            double axisCheckValueX = Math.Abs(point.getX() - chunkCenterWorldX) - halfChunkWidth;
            double axisCheckValueZ = Math.Abs(point.getZ() - chunkCenterWorldZ) - halfChunkWidth;
            if (axisCheckValueX >= maxPointContributionRadius || axisCheckValueZ >= maxPointContributionRadius
                    || (axisCheckValueX > 0 && axisCheckValueZ > 0
                        && axisCheckValueX * axisCheckValueX + axisCheckValueZ * axisCheckValueZ >= maxPointContributionRadiusSq))
            {

                // If so, remove it.
                // Copy the last value to this value, and remove the last,
                // to avoid shifting because order doesn't matter.
                int lastIndex = worldPoints.Count - 1;
				var temp = worldPoints[i];
                worldPoints[i] = worldPoints[lastIndex];
                worldPoints.RemoveAt(lastIndex);
				delete temp;
                i--;
            }
        }

        return worldPoints;
    }

}