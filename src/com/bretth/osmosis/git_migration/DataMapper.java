package com.bretth.osmosis.git_migration;

import java.nio.charset.Charset;


public class DataMapper {
	private Charset utf8Charset = Charset.forName("UTF-8");


	public byte[] toBytes(String data) {
		return data.getBytes(utf8Charset);
	}


	public String toString(byte[] data) {
		return new String(data, utf8Charset);
	}


	public boolean doesPrefixMatch(byte[] prefix, byte[] data) {
		if (data.length < prefix.length) {
			return false;
		}
		for (int i = 0; i < prefix.length; i++) {
			if (prefix[i] != data[i]) {
				return false;
			}
		}

		return true;
	}
	
	
	public byte[] getBytes(byte[] data, int offset, int length) {
		byte[] result;
		
		result = new byte[length];
		System.arraycopy(data, offset, result, 0, length);
		
		return result;
	}
	
	
	public byte[] getBytes(byte[] data, int offset) {
		byte[] result;
		
		result = new byte[data.length - offset];
		System.arraycopy(data, offset, result, 0, result.length);
		
		return result;
	}
	
	
	public byte[] mergeBytes(byte[] data1, byte[] data2) {
		byte[] result;
		
		result = new byte[data1.length + data2.length];
		System.arraycopy(data1, 0, result, 0, data1.length);
		System.arraycopy(data2, 0, result, data1.length, data2.length);
		
		return result;
	}
}
