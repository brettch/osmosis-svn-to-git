package com.bretth.osmosis.git_migration;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;


public class LineReader {

	private BufferedInputStream is;
	private byte[] lineBuffer;
	private int lineLength;
	private boolean linePopulated;
	private byte[] readBuffer;
	private int readIndex;
	private int readMax;
	private boolean eof;
	private LineSink sink;


	public LineReader(File dumpFile, LineSink sink) {
		this.sink = sink;
		
		try {
			is = new BufferedInputStream(new FileInputStream(dumpFile));
		} catch (FileNotFoundException e) {
			throw new MigrationException("Unable to open dump file " + dumpFile, e);
		}

		lineBuffer = new byte[0];
		readBuffer = new byte[4096];
	}
	
	
	public void run() {
		try {
			while (hasNext()) {
				sink.processLine(next());
			}
			sink.complete();
		} finally {
			close();
			sink.close();
		}
	}


	private void extendLineBuffer() {
		int newLength;
		byte[] newLineBuffer;

		newLength = lineBuffer.length * 2;
		if (newLength == 0) {
			newLength += 1;
		}

		newLineBuffer = new byte[newLength];
		System.arraycopy(lineBuffer, 0, newLineBuffer, 0, lineLength);
		lineBuffer = newLineBuffer;
	}


	private boolean hasNext() {
		if (!linePopulated) {
			lineLength = 0;
			while (!eof && !linePopulated) {
				byte b;
				
				if (readIndex >= readMax) {
					readIndex = 0;
					
					try {
						readMax = is.read(readBuffer);
					} catch (IOException e) {
						throw new MigrationException("Unable to read from the dump file", e);
					}
					
					if (readMax < 0) {
						eof = true;
						break;
					}
				}

				b = readBuffer[readIndex++];

				if (b == '\n') {
					linePopulated = true;
				} else {
					if (lineLength == lineBuffer.length) {
						extendLineBuffer();
					}

					lineBuffer[lineLength++] = b;
				}
			}
			
			if (lineLength > 0) {
				linePopulated = true;
			}
		}

		return linePopulated;
	}


	private byte[] next() {
		byte[] result;

		if (!hasNext()) {
			throw new MigrationException("No more lines are available in the dump file.");
		}

		result = new byte[lineLength];
		System.arraycopy(lineBuffer, 0, result, 0, lineLength);
		linePopulated = false;

		return result;
	}


	private void close() {
		try {
			is.close();
		} catch (IOException e) {
		}
	}
}
