package com.bretth.osmosis.git_migration;

public class RevisionRenumberTask implements LineSource {
	private LineSource source;
	private RevisionMapper revisionMapper;

	
	public RevisionRenumberTask(LineSource source, RevisionMapper revisionMapper) {
		this.source = source;
		this.revisionMapper = revisionMapper;
	}
	

	@Override
	public boolean hasNext() {
		// TODO Auto-generated method stub
		return false;
	}


	@Override
	public byte[] next() {
		// TODO Auto-generated method stub
		return null;
	}
}
