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
		
		lineReader = new LineReader(inDumpFile);
		lineWriter = new LineWriter(outDumpFile);
		
		while (lineReader.hasNext()) {
			lineWriter.writeLine(lineReader.next());
		}
		
		lineReader.close();
		lineWriter.close();
	}
}
