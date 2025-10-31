using System;
using System.Collections;
using Voxis.Data;
using Voxis.Graphics;

namespace Voxis;

public class Material
{
	public const int UBO_CAMERA_DATA = 0;
	public const int UBO_ENVIRONMENT_DATA = 1;

	public ShaderProgram Shader { get; }
	public RasterizerState RasterizerState { get; }
	public BlendState BlendState { get; }
	public DepthState DepthState { get; }
	public RenderLayer RenderLayer { get; }

	private Dictionary<String, IMaterialProperty> properties = new Dictionary<String, IMaterialProperty>() ~ DeleteDictionaryAndKeysAndValues!(_);

	public this(ShaderProgram shader, RasterizerState rast, BlendState blend, DepthState depth, RenderLayer layer)
	{
		Shader = shader;
		RasterizerState = rast;
		BlendState = blend;
		DepthState = depth;
		RenderLayer = layer;

		// Set default uniform buffer objects
		GraphicsServer.SetUniformBufferBinding(shader, "Camera", UBO_CAMERA_DATA, RenderPipeline3D.CameraUBO);
		GraphicsServer.SetUniformBufferBinding(shader, "Environment", UBO_ENVIRONMENT_DATA, RenderPipeline3D.EnvironmentUBO);
	}

	public ~this()
	{
		GraphicsServer.DestroyResource(Shader);
	}

	public static Material ParseFromData(DataTree data)
	{
		// TODO: type unused, later create specific material subclass
		// StringView type = data.Root.GetOrDefault("type", .Text("Undefined")).AsText();
		StringView fragmentPath = data.Root.Get("shaders").Get("fragment").AsText();
		StringView vertexPath = data.Root.Get("shaders").Get("vertex").AsText();

		String fragmentText = ResourceServer.LoadTextFile(fragmentPath);
		String vertexText = ResourceServer.LoadTextFile(vertexPath);

		// Compile and Link shader programm
		ShaderProgram programm = GraphicsServer.CreateShaderProgram(vertexText, fragmentText);

		// Create material
		Material mat = new Material(programm, ParseRasterizerState(data.Root.Get("rasterizer_state")), ParseBlendState(data.Root.Get("blend_state")), ParseDepthState(data.Root.Get("depth_state")), ParseRenderLayer(data.Root.Get("render_layer")));

		// Apply uniform blocks
		List<TreeNode> uniformBlocks = data.Root.Get("uniform_blocks").AsList();
		for (int i = 0; i < uniformBlocks.Count; i++)
		{
			StringView blockName = uniformBlocks[i].AsText();

			// TODO: Really ugly mapping...
			if (blockName == "camera")
			{
				mat.ConnectUniformBufferBlock("Camera", uint(i), RenderPipeline3D.CameraUBO);
			}
			else if (blockName == "environment")
			{
				mat.ConnectUniformBufferBlock("Environment", uint(i), RenderPipeline3D.EnvironmentUBO);
			}
		}

		return mat;
	}

	public void ConnectUniformBufferBlock(StringView uboName, uint bindingPoint, UniformBuffer buffer)
	{
		GraphicsServer.SetUniformBufferBinding(Shader, uboName, bindingPoint, buffer);
	}

	public void SetMaterialProperty(StringView name, Color color)
	{
		String tempString = new String(name);
		if (properties.ContainsKey(tempString))
		{
			MaterialParameterColor existing = properties[tempString] as MaterialParameterColor;
			existing.SetColor(color);
			delete tempString;
		}
		else
		{
			properties[tempString] = new MaterialParameterColor(color);
		}
	}

	public void SetMaterialProperty(StringView name, IMaterialProperty value)
	{
		String tempSting = new String(name);
		if(properties.ContainsKey(tempSting))
		{
			delete properties[tempSting];

			properties[tempSting] = value;
			delete tempSting;
		}
		else properties[tempSting] = value;

	}

	public void Apply()
	{
		for((String key, IMaterialProperty value) pair in properties)
		{
			pair.value.Apply(this, pair.key);
		}
	}

	private static RasterizerState ParseRasterizerState(TreeNode definition)
	{
		StringView cullText = definition.GetOrDefault("cull", .Text("back")).AsText();
		StringView frontText = definition.GetOrDefault("front", .Text("clockwise")).AsText();
		bool wireframe = definition.GetOrDefault("wireframe", .Boolean(false)).AsbBoolean();
		bool scissor = definition.GetOrDefault("scissor", .Boolean(false)).AsbBoolean();

		CullFace cull;
		switch (cullText)
		{
		case "front":
			cull = .Front;
			break;
		case "back":
			cull = .Back;
			break;
		case "none":
			cull = .None;
		default:
			Runtime.FatalError("Invalid cull type text");
		}

		FrontFace front;
		switch (frontText)
		{
		case "clockwise":
			front = .Clockwise;
			break;
		case "counterclockwise":
			front = .CounterClockwise;
			break;
		default:
			Runtime.FatalError("Invalid font face text");
		}

		return RasterizerState(cull, front, wireframe, scissor);
	}

	private static DepthState ParseDepthState(TreeNode definition)
	{
		bool read = definition.GetOrDefault("read", .Boolean(true)).AsbBoolean();
		bool write = definition.GetOrDefault("write", .Boolean(true)).AsbBoolean();
		StringView functionText = definition.GetOrDefault("function", .Text("less_equal")).AsText();

		DepthTestFunction f;
		switch (functionText)
		{
		case "less_equal":
			f = .LessEqual;
			break;
		case "equal":
			f = .Equal;
			break;
		case "always":
			f = .Always;
			break;
		case "greater_equal":
			f = .GreaterEqual;
			break;
		case "greater":
			f = .Greater;
			break;
		case "less":
			f = .Less;
			break;
		case "never":
			f = .Never;
			break;
		case "not_equal":
			f = .NotEqual;
			break;
		default:
			Runtime.FatalError("Invalid depth test function text");
		}

		return DepthState(read, write, f);
	}

	private static RenderLayer ParseRenderLayer(TreeNode data)
	{
		StringView asText = data.AsText();

		switch (asText)
		{
		case "opaque":
			return RenderLayer.Opaque;
		case "transparent":
			return RenderLayer.Transparent;
		}

		Runtime.FatalError("Invalid render layer");
	}

	private static BlendState ParseBlendState(TreeNode data)
	{
		return BlendState(data.GetOrDefault("enabled", .Boolean(false)).AsbBoolean());
	}
}