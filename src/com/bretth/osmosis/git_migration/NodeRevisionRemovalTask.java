package com.bretth.osmosis.git_migration;

import java.util.Arrays;

public class NodeRevisionRemovalTask implements LineSink {
	
	private LineSink sink;
	private int revision;
	private RevisionMonitor revisionMonitor;
	private DataMapper dataMapper;
	private byte[] nodeLine;
	private byte[] nodePathPrefix;
	private boolean outputActive;
	
	
	public NodeRevisionRemovalTask(int revision, String nodeName, LineSink sink) {
		this.revision = revision;
		this.sink = sink;
		
		revisionMonitor = new RevisionMonitor();
		dataMapper = new DataMapper();
		
		nodeLine = dataMapper.mergeBytes(dataMapper.toBytes("Node-path: "), dataMapper.toBytes(nodeName));
		nodePathPrefix = dataMapper.toBytes("Node-path: ");
		
		outputActive = true;
	}
	

	@Override
	public void processLine(byte[] data) {
		revisionMonitor.processLine(data);
		
		if (revisionMonitor.getRevision() == revision) {
			if (outputActive) {
				if (Arrays.equals(nodeLine, data)) {
					outputActive = false;
				} else {
					sink.processLine(data);
				}
			} else {
				if (dataMapper.doesPrefixMatch(nodePathPrefix, data)) {
					outputActive = true;
					sink.processLine(data);
				}
			}
		} else {
			sink.processLine(data);
		}
	}

	@Override
	public void complete() {
		sink.complete();
	}

	@Override
	public void close() {
		sink.close();
	}
}
