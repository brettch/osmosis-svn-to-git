package com.bretth.osmosis.git_migration;

import java.io.BufferedInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;


public class LineReader implements LineSource {

	private BufferedInputStream is;
	private byte[] lineBuffer;
	private int lineLength;
	private boolean linePopulated;
	private byte[] readBuffer;
	private int readIndex;
	private int readMax;
	private boolean eof;


	public LineReader(File dumpFile) {
		try {
			is = new BufferedInputStream(new FileInputStream(dumpFile));
		} catch (FileNotFoundException e) {
			throw new MigrationException("Unable to open dump file " + dumpFile, e);
		}

		lineBuffer = new byte[0];
		readBuffer = new byte[4096];
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


	public boolean hasNext() {
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


	public byte[] next() {
		byte[] result;

		if (!hasNext()) {
			throw new MigrationException("No more lines are available in the dump file.");
		}

		result = new byte[lineLength];
		System.arraycopy(lineBuffer, 0, result, 0, lineLength);
		linePopulated = false;

		return result;
	}


	public void close() {
		try {
			is.close();
		} catch (IOException e) {
		}
	}
}
