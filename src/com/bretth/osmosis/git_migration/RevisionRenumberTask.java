package com.bretth.osmosis.git_migration;


public class RevisionRenumberTask implements LineSink {
	private LineSink sink;
	private RevisionMapper revisionMapper;
	private String repository;
	private DataMapper dataMapper;


	public RevisionRenumberTask(LineSink sink, RevisionMapper revisionMapper, String repository) {
		this.sink = sink;
		this.revisionMapper = revisionMapper;
		this.repository = repository;
		
		dataMapper = new DataMapper();
	}


	@Override
	public void processLine(byte[] data) {
		String revisionPrefix = "Revision-number: ";
		String copyfromRevisionPrefix = "Node-copyfrom-rev: ";

		if (dataMapper.doesPrefixMatch(dataMapper.toBytes(revisionPrefix), data)) {
			String revisionStr = dataMapper.toString(data).substring(revisionPrefix.length());
			int sourceRevision = Integer.parseInt(revisionStr);
			int targetRevision = revisionMapper.addRevision(repository, sourceRevision);

			sink.processLine(dataMapper.toBytes(revisionPrefix + targetRevision));

		} else if (dataMapper.doesPrefixMatch(dataMapper.toBytes(copyfromRevisionPrefix), data)) {
			String revisionStr = dataMapper.toString(data).substring(copyfromRevisionPrefix.length());
			int sourceRevision = Integer.parseInt(revisionStr);
			int targetRevision = revisionMapper.getTargetRevision(repository, sourceRevision);

			sink.processLine(dataMapper.toBytes(copyfromRevisionPrefix + targetRevision));
			
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
