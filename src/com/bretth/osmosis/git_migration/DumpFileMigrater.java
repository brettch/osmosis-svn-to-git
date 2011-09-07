package com.bretth.osmosis.git_migration;

import java.io.File;


public class DumpFileMigrater {
	
	private static LineWriter createTarget(String fileName) {
		return new LineWriter(new File(fileName));
	}
	
	
	private static void processFile(String fileName, LineSink sink) {
		new LineReader(new File(fileName), sink).run();
	}
	

	public static void main(String[] args) {
		RevisionMapper revisionMapper;
		LineSink sink;

		revisionMapper = new RevisionMapper();
		
		// Add a dummy revision to correspond to the initial repo setup commit.
		revisionMapper.addRevision("dummy", 1);

		sink = createTarget("../1-bh.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "bh");
		sink = new RenameNodePathsTask(sink, "conduit", "trunk");
		sink = new NodeRevisionRemovalTask(417, "conduit", sink);
		processFile("../1-bh.dmp", sink);

		sink = createTarget("../2-bh.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "bh");
		sink = new RenameNodePathsTask(sink, "osmosis", "trunk");
		processFile("../2-bh.dmp", sink);

		sink = createTarget("../3-bh.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "bh");
		sink = new RenameNodePathsTask(sink, "osmosis/", "");
		processFile("../3-bh.dmp", sink);

		sink = createTarget("../4-osm.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "osm");
		sink = new RenameNodePathsTask(sink, "applications/utils/osmosis", "trunk");
		processFile("../4-osm.dmp", sink);

		sink = createTarget("../5-osm.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "osm");
		sink = new RenameNodePathsTask(sink, "applications/utils/osmosis/", "");
		sink = new SetCopyfromNodeTask(12415, "applications/utils/osmosis/tags/0.29", "trunk", sink);
		sink = new SetCopyfromNodeTask(12416, "applications/utils/osmosis/tags/0.28", "trunk", sink);
		processFile("../5-osm.dmp", sink);
	}
}
