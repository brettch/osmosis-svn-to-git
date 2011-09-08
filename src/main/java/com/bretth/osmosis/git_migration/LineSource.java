package com.bretth.osmosis.git_migration;

public interface LineSource {

	public boolean hasNext();


	byte[] next();
}
