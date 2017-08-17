using OpenSage.Loaders;
using OpenSage.Support;
using OpenSage.Resources.W3D.ChunkVisitors;

using Vapi.W3D;
using Vapi.W3D.Chunk;

using GL;
using ValaGL.Core;

namespace OpenSage.Resources.W3D.Renderer {

private struct BufferItem {
	Vector3 position;
	Vector3 normal;
	TextureCoordinates texcoords;
}

public class MeshRenderer {
	public MeshVisitor mesh;
	private GLProgram viewer;
	
	private VBO mesh_vbo;
	private IBO mesh_ibo;
	private ImageLoader ildr = new ImageLoader();
	private ValaGL.Core.Texture texture;

	public MeshRenderer(GLProgram viewer, MeshVisitor mv){
		this.viewer = viewer;
		this.mesh = mv;
		this.init_renderer();
	}

	public void render(){
		// Mark the shape's VBO and IBO as current
		mesh_vbo.make_current();
		mesh_ibo.make_current();

		
		glActiveTexture(GL_TEXTURE0);
		texture.make_current();
		glUniform1i((GLint)viewer.uniforms["diffuse"], 0);

		// Then render their contents
		glDrawElements(
			GL_TRIANGLES,
			(GLsizei)(mesh.header.NumTris * 3), // number of indices
			GL_UNSIGNED_SHORT, // format of each index
			null
		);
	}

	private void init_renderer(){
		if(!ildr.load(EngineSettings.RootDir + "/avpaladin.dds")){
			stderr.printf("Texture load failed\n");
			return;
		}
		texture = ildr.get_frame();

		// VBO (vertices)
		BufferItem[] items = new BufferItem[mesh.header.NumVertices];
		//Memory.set(items, 0x00, sizeof(BufferItem) * items.length);

		for(uint i=0; i<mesh.header.NumVertices; i++){
			items[i].position = mesh.vertices[i];
			items[i].normal = mesh.vertices_normals[i];
			items[i].texcoords = mesh.material_pass.texture_stage.texcoords[i];
		}

		stdout.printf("We have %u vertices\n", mesh.header.NumVertices);

		try {
			// Make a VBO and load data into it
			mesh_vbo = new VBO((void *)items, sizeof(BufferItem) * items.length);
		} catch(CoreError err){
			stderr.printf("Failed to create VBO\n");
		}
		mesh_vbo.make_current();

		//for offset calculation
		BufferItem dummy = BufferItem();

		/*
		* Specify the components we are passing through the buffer
		*/
		mesh_vbo.add_attribute(
			0, //index
			3, //number of vector components
			GL_FLOAT, //type of elements
			GL_FALSE, //values should not be normalized
			sizeof(BufferItem), //distance to the next element
			(uintptr)&dummy.position - (uintptr)&dummy //offset of the item
		);

		// Index 1 -> vertex normals
		mesh_vbo.add_attribute(
			1,
			3,
			GL_FLOAT,
			GL_FALSE,
			sizeof(BufferItem),
			(uintptr)&dummy.normal - (uintptr)&dummy
		);

		// Index 2 -> vertex texture coords
		mesh_vbo.add_attribute(
			2,
			2,
			GL_FLOAT,
			GL_FALSE,
			sizeof(BufferItem),
			(uintptr)&dummy.texcoords - (uintptr)&dummy
		);

		// IBO (indices)
		// Load triangles indices: each triangle has 3
		GLushort[] indices = new GLushort[mesh.header.NumTris * 3];
		uint i_tris = 0;
		uint i_idx = 0;
		
		for(; i_idx<mesh.header.NumTris * 3; i_tris++){
			// Process this triangle's indices
			for(uint tris_idx=0; tris_idx<3; tris_idx++, i_idx++){
				indices[i_idx] = (GLushort)mesh.triangles[i_tris].Vindex[tris_idx];
			}
		}

		try {
			mesh_ibo = new IBO((void *)indices, sizeof(GLushort) * indices.length * 3);
		} catch(CoreError err){
			stderr.printf("IBO creation failed\n");
		}

		mesh_ibo.make_current();
	}
}

}