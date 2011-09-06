package com.bretth.osmosis.git_migration;

import java.io.File;

public class RenumberRevisions {
	
	private static void renumberRevisions(RevisionMapper revisionMapper, String inDump, String outDump, String repository) {
		LineWriter lineWriter;
		RevisionRenumberTask renumberTask;
		LineReader lineReader;
		
		lineWriter = new LineWriter(new File(outDump));
		renumberTask = new RevisionRenumberTask(lineWriter, revisionMapper, "osm");
		lineReader = new LineReader(new File(inDump), renumberTask);
		
		lineReader.run();
		
		lineReader.close();
		lineWriter.close();
	}
	

	public static void main(String[] args) {
		RevisionMapper revisionMapper;
		
		revisionMapper = new RevisionMapper();

		renumberRevisions(revisionMapper, "../1-bh.dmp", "../1-bh.fixed.dmp", "bh");
		renumberRevisions(revisionMapper, "../2-bh.dmp", "../2-bh.fixed.dmp", "bh");
		renumberRevisions(revisionMapper, "../3-bh.dmp", "../3-bh.fixed.dmp", "bh");
		renumberRevisions(revisionMapper, "../4-osm.dmp", "../4-osm.fixed.dmp", "osm");
		renumberRevisions(revisionMapper, "../5-osm.dmp", "../5-osm.fixed.dmp", "osm");
	}
}
