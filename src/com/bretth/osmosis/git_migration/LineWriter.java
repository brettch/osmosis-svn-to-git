package com.bretth.osmosis.git_migration;

import java.io.BufferedOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;

public class LineWriter {

	private BufferedOutputStream os;


	public LineWriter(File dumpFile) {
		try {
			os = new BufferedOutputStream(new FileOutputStream(dumpFile));
		} catch (FileNotFoundException e) {
			throw new MigrationException("Unable to open dump file " + dumpFile, e);
		}
	}
	
	
	public void writeLine(byte[] data) {
		try {
			os.write(data);
			os.write('\n');
			
		} catch (IOException e) {
			throw new MigrationException("Unable to write to dump file", e);
		}
	}


	public void close() {
		try {
			os.close();
		} catch (IOException e) {
		}
	}
}
