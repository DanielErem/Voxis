using System;
using System.Collections;

namespace Voxis
{
	public static class Performance
	{
		public struct Metrics
		{
			public int DrawCalls3D = 0;
			public int DrawCallsCanvas = 0;
			public int DrawPrimitive = 0;
			public int FPS = 0;
			public uint64 GPUElapsedNanos = 0;
			public uint64 PrimitivesGenerated = 0;
		}

		public static Metrics CurrentFrame;
		public static Metrics LastFrame;

		private static int _lastFPSMeasurement = 0;
		private static int _frameCount = 0;
		private static System.Diagnostics.Stopwatch _sw = new System.Diagnostics.Stopwatch() ~ delete _;

		public static void Reset()
		{
			LastFrame = CurrentFrame;
			LastFrame.FPS = _lastFPSMeasurement;

			// Reset some metrics
			CurrentFrame.DrawCalls3D = 0;
			CurrentFrame.DrawCallsCanvas = 0;
			CurrentFrame.DrawPrimitive = 0;
			CurrentFrame.FPS = 0;

			if (!_sw.IsRunning)
			{
				_sw.Restart();
			}
			else
			{
				_frameCount++;

				if (_sw.ElapsedMilliseconds >= 1000)
				{
					_lastFPSMeasurement = _frameCount;
					_frameCount = 0;
					_sw.Reset();
				}
			}
		}
	}
}