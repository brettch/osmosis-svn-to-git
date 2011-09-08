package com.bretth.osmosis.git_migration;

public class RevisionMonitor implements LineSink {

	private DataMapper dataMapper = new DataMapper();
	private byte[] revisionNumberPrefix = dataMapper.toBytes("Revision-number: ");
	private int revision;


	public void processLine(byte[] data) {
		if (dataMapper.doesPrefixMatch(revisionNumberPrefix, data)) {
			byte[] revisionData = dataMapper.getBytes(data, revisionNumberPrefix.length);
			String revisionStr = dataMapper.toString(revisionData);
			revision = Integer.parseInt(revisionStr);
		}
	}
	
	
	public int getRevision() {
		return revision;
	}


	@Override
	public void complete() {

	}


	@Override
	public void close() {

	}
}
