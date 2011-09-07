package com.bretth.osmosis.git_migration;

public class RenameNodePathsTask implements LineSink {
	private LineSink sink;
	private DataMapper dataMapper;
	private byte[] nodePathPrefix;
	private byte[] nodeCopyfromPathPrefix;
	private byte[] sourcePathPrefix;
	private byte[] targetPathPrefix;


	public RenameNodePathsTask(LineSink sink, String sourcePathPrefix, String targetPathPrefix) {
		this.sink = sink;

		dataMapper = new DataMapper();

		nodePathPrefix = dataMapper.toBytes("Node-path: ");
		nodeCopyfromPathPrefix = dataMapper.toBytes("Node-copyfrom-path: ");
		this.sourcePathPrefix = dataMapper.toBytes(sourcePathPrefix);
		this.targetPathPrefix = dataMapper.toBytes(targetPathPrefix);
	}


	private boolean replaceFieldDataPrefix(byte[] data, byte[] fieldNamePrefix, byte[] sourceDataPrefix,
			byte[] targetDataPrefix) {
		// If this row contains data for the specified field.
		if (dataMapper.doesPrefixMatch(fieldNamePrefix, data)) {
			byte[] fieldData = dataMapper.getBytes(data, fieldNamePrefix.length, data.length - fieldNamePrefix.length);

			// If this field contains a value that needs a prefix replacement.
			if (dataMapper.doesPrefixMatch(sourceDataPrefix, fieldData)) {
				byte[] result;

				// Get the dynamic suffix.
				result = dataMapper.getBytes(fieldData, sourceDataPrefix.length);
				// Add the replacement prefix to the start.
				result = dataMapper.mergeBytes(targetDataPrefix, result);
				// Add the field name to the start.
				result = dataMapper.mergeBytes(fieldNamePrefix, result);

				sink.processLine(result);

				return true;
			}
		}

		return false;
	}


	@Override
	public void processLine(byte[] data) {
		// Invoke the various prefix replacements. If neither finds a match,
		// send the original unmodified data to the sink.
		if (!replaceFieldDataPrefix(data, nodePathPrefix, sourcePathPrefix, targetPathPrefix)
				&& !replaceFieldDataPrefix(data, nodeCopyfromPathPrefix, sourcePathPrefix, targetPathPrefix)) {
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
