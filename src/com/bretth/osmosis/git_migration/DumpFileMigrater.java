package com.bretth.osmosis.git_migration;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.IOException;


public class DumpFileMigrater {
	
	private static LineWriter createTarget(String fileName) {
		return new LineWriter(new File(fileName));
	}
	
	
	private static void processFile(String fileName, LineSink sink) {
		new LineReader(new File(fileName), sink).run();
	}
	
	
	private static void execute(String command) {
		try {
			Process process;
			BufferedInputStream is;
			byte[] buffer;
			int bytesRead;
			int exitCode;
			
			process = new ProcessBuilder(command).redirectErrorStream(true).start();
			
			is = new BufferedInputStream(process.getInputStream());
			bytesRead = 0;
			buffer = new byte[4096];
			while(true) {
				bytesRead = is.read(buffer);
				if (bytesRead < 0) {
					break;
				}
				System.out.write(buffer, 0, bytesRead);
			}
			
			exitCode = process.waitFor();
			if (exitCode != 0) {
				throw new MigrationException("Command " + command + " exited with code " + exitCode);
			}
			
		} catch (IOException e) {
			throw new MigrationException("Unable to invoke command " + command, e);
		} catch (InterruptedException e) {
			throw new MigrationException("Unable to invoke command " + command, e);
		}
	}
	

	public static void main(String[] args) {
		RevisionMapper revisionMapper;
		LineSink sink;
		
		execute("./dump_repository.sh");
		
		revisionMapper = new RevisionMapper();
		
		// Add a dummy revision to correspond to the initial repo setup commit.
		revisionMapper.addRevision("dummy", 1);

		sink = createTarget("data/1-bh.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "bh");
		sink = new RenameNodePathsTask(sink, "conduit", "trunk");
		sink = new NodeRevisionRemovalTask(417, "conduit", sink);
		processFile("data/1-bh.dmp", sink);

		sink = createTarget("data/2-bh.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "bh");
		sink = new RenameNodePathsTask(sink, "osmosis", "trunk");
		processFile("data/2-bh.dmp", sink);

		sink = createTarget("data/3-bh.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "bh");
		sink = new RenameNodePathsTask(sink, "osmosis/", "");
		processFile("data/3-bh.dmp", sink);

		sink = createTarget("data/4-osm.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "osm");
		sink = new RenameNodePathsTask(sink, "applications/utils/osmosis", "trunk");
		processFile("data/4-osm.dmp", sink);

		sink = createTarget("data/5-osm.fixed.dmp");
		sink = new RevisionRenumberTask(sink, revisionMapper, "osm");
		sink = new RenameNodePathsTask(sink, "applications/utils/osmosis/", "");
		sink = new SetCopyfromNodeTask(12415, "applications/utils/osmosis/tags/0.29", "trunk", sink);
		sink = new SetCopyfromNodeTask(12416, "applications/utils/osmosis/tags/0.28", "trunk", sink);
		processFile("data/5-osm.dmp", sink);
	}
}
