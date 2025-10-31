namespace Voxis
{
	public class MaterialParameterTexture2D : IMaterialProperty
	{
		private Texture2D texture;
		private uint _slot;

		public this(Texture2D tex, uint slot = 0)
		{
			texture = tex;
			_slot = slot;
		}

		public void Apply(Material material, System.String key)
		{
			GraphicsServer.SetProgramTexture(material.Shader, key, texture, _slot);
		}
	}
}
