using System.Collections;

namespace Voxis
{
	public static class PriorityTasker
	{
		public enum TaskPriority : int32
		{
			Low = 0,
			Normal = 10000,
			High = 100000
		}

		public const bool DISABLE_THREADING = false;

		private struct WorkItem
		{
			public System.Threading.WorkDelegate WorkToDo;
			public int Priority;

			public this(System.Threading.WorkDelegate del, int prio)
			{
				WorkToDo = del;
				Priority = prio;
			}

			public void Dispose()
			{
				delete WorkToDo;
			}
		}

		public static int MaxDispatch = 8;
		public static Vector3 PointOfInterest = Vector3.Zero;

		private static List<WorkItem> actions = new List<WorkItem>();

		public static void ClearTasks()
		{
			DeleteContainerAndDisposeItems!(actions);
		}

		public static void DispatchTasks()
		{
			actions.Sort(scope (a, b) => {
				if (a.Priority < b.Priority) return -1;
				else if (a.Priority > b.Priority) return 1;
				return 0;
				});

			for (int i = 0; i < MaxDispatch && !actions.IsEmpty; i++)
			{
				if (!DISABLE_THREADING) System.Threading.ThreadPool.QueueUserWorkItem(actions.PopFront().WorkToDo);
				else
				{
					WorkItem item = actions.PopFront();

					item.WorkToDo.Invoke();

					item.Dispose();
				}
			}
		}

		public static void AddTask(System.Threading.WorkDelegate work, TaskPriority priority)
		{
			actions.Add(WorkItem(work, priority.Underlying));
		}

		public static void AddPOITask(System.Threading.WorkDelegate work, TaskPriority priority, Vector3 position)
		{
			actions.Add(WorkItem(work, priority.Underlying + int32(Vector3.Distance(position, PointOfInterest))));
		}
	}
}