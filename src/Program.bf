using System;
using Voxis.Data;
using System.Diagnostics;

namespace Voxis
{
	public class Program
	{
		private static int Main()
		{
			VoxisGame game = new VoxisGame();
			game.Run();
			delete game;
			return 0;
		}
	}
}
