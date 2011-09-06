package com.bretth.osmosis.git_migration;

public class MappedRevision {
	private int sourceRevision;
	private int targetRevision;


	public MappedRevision(int sourceRevision, int targetRevision) {
		this.sourceRevision = sourceRevision;
		this.targetRevision = targetRevision;
	}


	public int getSourceRevision() {
		return sourceRevision;
	}


	public int getTargetRevision() {
		return targetRevision;
	}
}
