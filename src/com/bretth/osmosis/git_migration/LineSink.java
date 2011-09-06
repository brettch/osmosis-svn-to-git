package com.bretth.osmosis.git_migration;

public interface LineSink {
	void processLine(byte[] data);


	void complete();
}
