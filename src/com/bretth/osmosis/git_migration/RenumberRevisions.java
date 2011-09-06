package com.bretth.osmosis.git_migration;

import java.io.File;

public class RenumberRevisions {

	public static void main(String[] args) {
		File inDumpFile;
		File outDumpFile;
		LineReader lineReader;
		LineWriter lineWriter;
		
		inDumpFile = new File("../osmosis.dmp");
		outDumpFile = new File("../test.dmp");
		
		lineWriter = new LineWriter(outDumpFile);
		lineReader = new LineReader(inDumpFile, lineWriter);
		
		lineReader.run();
		
		lineReader.close();
		lineWriter.close();
	}
}
