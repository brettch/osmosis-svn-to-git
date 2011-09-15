package com.bretth.osmosis.git_migration;

import java.util.ArrayList;
import java.util.List;


public class RepositoryRevisionMapper {
	private String repository;
	private List<MappedRevision> revisions;


	public RepositoryRevisionMapper(String repository) {
		this.repository = repository;

		revisions = new ArrayList<MappedRevision>();
	}


	public String getRepository() {
		return repository;
	}


	public void addRevision(MappedRevision revision) {
		revisions.add(revision);
	}


	public MappedRevision getRevisionBySource(int sourceRevision) {
		MappedRevision mappedRevision;

		// Check if we have a suitable revision.
		if (revisions.size() == 0) {
			throw new MigrationException("No revisions are available for repository " + repository);
		}
		mappedRevision = revisions.get(0);
		if (mappedRevision.getSourceRevision() > sourceRevision) {
			throw new MigrationException("Cannot find source revision " + sourceRevision + " for repository "
					+ repository + ", first revision is " + mappedRevision.getSourceRevision());
		}
		for (int i = 1; i < revisions.size(); i++) {
			if (revisions.get(i).getSourceRevision() <= sourceRevision) {
				mappedRevision = revisions.get(i);
			}
		}

		return mappedRevision;
	}


	public int getTargetRevision(int sourceRevision) {
		return getRevisionBySource(sourceRevision).getTargetRevision();
	}
}
