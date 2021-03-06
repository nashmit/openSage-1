using OpenSage.Support;
using Vapi.W3D.Chunk;
using Vapi.W3D.HLod;

namespace OpenSage.Resources.W3D.ChunkVisitors {
	public class HLodVisitor : ChunkVisitor {
		public HLodHeaderStruct *header;
		public HLodArrayVisitor lod_array;

		public HLodVisitor(StreamCursor cursor){
			base(cursor);
			base.setup(isKnown, visit);
		}

		public bool isKnown(ChunkType type){
			switch(type){
				case ChunkType.HLOD_HEADER:
				case ChunkType.HLOD_LOD_ARRAY:
					return true;
				default:
					return false;
			}
		}

		public VisitorResult visit(ChunkHeader hdr, StreamCursor cursor){
			switch(hdr.ChunkType){
				case ChunkType.HLOD_HEADER:
					stdout.printf("[HLOD] => Header\n");
					header = (HLodHeaderStruct *)(cursor.ptr);
					cursor.skip((long)sizeof(HLodHeaderStruct));
					return VisitorResult.OK;
				case ChunkType.HLOD_LOD_ARRAY:
					stdout.printf("[HLOD] => Lod Array\n");
					lod_array = new HLodArrayVisitor(cursor);
					return lod_array.run();
			}
			return VisitorResult.UNKNOWN_DATA;
		}
	}
}