package com.bretth.osmosis.git_migration;

public class RevisionRemovalTask implements LineSink {

	private LineSink sink;
	private int revision;
	private RevisionMonitor revisionMonitor;


	public RevisionRemovalTask(int revision, LineSink sink) {
		this.revision = revision;
		this.sink = sink;

		revisionMonitor = new RevisionMonitor();
	}


	@Override
	public void processLine(byte[] data) {
		revisionMonitor.processLine(data);

		if (revisionMonitor.getRevision() != revision) {
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
