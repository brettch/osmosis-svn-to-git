package com.bretth.osmosis.git_migration;

import java.util.Arrays;

public class SetCopyfromNodeTask implements LineSink {
	
	private LineSink sink;
	private int revision;
	private RevisionMonitor revisionMonitor;
	private DataMapper dataMapper;
	private byte[] nodePathPrefix;
	private byte[] nodeLine;
	private byte[] copyFromNodePathPrefix;
	private byte[] copyFromNodePathLine;
	private boolean fieldSearchActive;
	
	
	public SetCopyfromNodeTask(int revision, String nodeName, String copyFrom, LineSink sink) {
		this.revision = revision;
		this.sink = sink;
		
		revisionMonitor = new RevisionMonitor();
		dataMapper = new DataMapper();
		
		nodePathPrefix = dataMapper.toBytes("Node-path: ");
		nodeLine = dataMapper.mergeBytes(nodePathPrefix, dataMapper.toBytes(nodeName));
		copyFromNodePathPrefix = dataMapper.toBytes("Node-copyfrom-path: ");
		copyFromNodePathLine = dataMapper.mergeBytes(copyFromNodePathPrefix, dataMapper.toBytes(copyFrom));
		
		fieldSearchActive = false;
	}
	

	@Override
	public void processLine(byte[] data) {
		revisionMonitor.processLine(data);
		
		// Only take notice of data in the specified revision.
		if (revisionMonitor.getRevision() == revision) {
			// Are we actively searching for the field within the correct node.
			if (fieldSearchActive) {
				// Is this the field we're interested in.
				if (dataMapper.doesPrefixMatch(copyFromNodePathPrefix, data)) {
					// Send the updated line to the sink and stop searching.
					sink.processLine(copyFromNodePathLine);
					fieldSearchActive = false;
				} else {
					// Have we reached the next node without finding the field.
					if (dataMapper.doesPrefixMatch(nodePathPrefix, data)) {
						throw new MigrationException("We reached the next node without finding the copyfrom field in revision " + revision);
					}
					sink.processLine(data);
				}
			} else {
				// Have we reached the node we're interested in.
				fieldSearchActive = Arrays.equals(nodeLine, data);
				sink.processLine(data);
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
