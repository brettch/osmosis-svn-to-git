package com.bretth.osmosis.git_migration;

import java.io.File;

public class RenumberRevisions {

	public static void main(String[] args) {
		File inDumpFile;
		File outDumpFile;
		RevisionMapper revisionMapper;
		LineWriter lineWriter;
		RevisionRenumberTask renumberTask;
		LineReader lineReader;
		
		inDumpFile = new File("../osmosis.dmp");
		outDumpFile = new File("../test.dmp");
		
		revisionMapper = new RevisionMapper();
		
		lineWriter = new LineWriter(outDumpFile);
		renumberTask = new RevisionRenumberTask(lineWriter, revisionMapper, "osm");
		lineReader = new LineReader(inDumpFile, renumberTask);
		
		lineReader.run();
		
		lineReader.close();
		lineWriter.close();
	}
}
