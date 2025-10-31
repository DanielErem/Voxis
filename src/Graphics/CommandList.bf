using System.Collections;
using System;

namespace Voxis.Graphics;

public class CommandList
{
	public bool IsCollecting { get; private set; } = false;
	public bool Flushed { get; private set; } = true;

	private List<DrawCommand> _commands = new List<DrawCommand>() ~ DeleteContainerAndItems!(_);
	private Vector3 _sortPivot;

	public void Begin()
	{
		if (IsCollecting) Runtime.FatalError("Command collection already started.");
		if (!Flushed) Runtime.FatalError("Commands not flushed.");

		IsCollecting = true;
		Flushed = false;

		_commands.ClearAndDeleteItems();
	}

	public void End()
	{
		IsCollecting = false;
		Flushed = false;
	}

	public void Flush(Vector3 sortPivot)
	{
		_sortPivot = sortPivot;
		_commands.Sort(scope => CompareDrawCommand);

		Material activeMaterial = null;

		for (int i = 0; i < _commands.Count; i++)
		{
			DrawCommand command = _commands[i];

			// Minimize shader changes
			if (activeMaterial == null || activeMaterial != command.Material)
			{
				activeMaterial = command.Material;

				RenderPipeline3D.ApplyMaterial(activeMaterial);
			}

			command.Properties?.Apply(command.Material);

			RenderPipeline3D.DrawMeshRaw(command.ModelMatrix, command.Material, command.MeshToDraw, command.Layout);
		}

		Flushed = true;
	}

	public void DrawMesh(Mesh mesh, Matrix4x4 modelMatrix, VertexLayout layout, Material material, MaterialInstanceProperties props = null)
	{
		_commands.Add(new DrawCommand(){
			SortPivot = modelMatrix.Translation,
			MeshToDraw = mesh,
			Material = material,
			ModelMatrix = modelMatrix,
			Layout = layout,
			Properties = props
		});
	}

	private int CompareDrawCommand(DrawCommand a, DrawCommand b)
	{
		// Lower priority draws first
		int priorityA = a.Material.RenderLayer.Underlying;
		int priorityB = b.Material.RenderLayer.Underlying;

		// Sort based on priority
		if (priorityA != priorityB) return priorityA <=> priorityB;

		// If opaque, increase priority by distance meaning they draw later by distance (Reduce overdraw)
		if (a.Material.RenderLayer == RenderLayer.Opaque){
			priorityA += int(Vector3.Distance(a.SortPivot, _sortPivot));
			priorityB += int(Vector3.Distance(b.SortPivot, _sortPivot));
		}
		// When transparent, draw distant objects first (better transparency blending)
		else if (a.Material.RenderLayer == RenderLayer.Transparent)
		{
			priorityA -= int(Vector3.Distance(a.SortPivot, _sortPivot));
			priorityB -= int(Vector3.Distance(b.SortPivot, _sortPivot));
		}

		return priorityA <=> priorityB;
	}
}