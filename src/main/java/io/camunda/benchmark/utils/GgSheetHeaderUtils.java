package io.camunda.benchmark.utils;

import org.apache.commons.text.CaseUtils;

public class GgSheetHeaderUtils {

	private GgSheetHeaderUtils() {}
	
	public static String toCamelCase(String header) {
		String withoutBrackets = header.replaceAll("\\(.*\\)", "").trim();
		return CaseUtils.toCamelCase(withoutBrackets, false, ' ');
	}
	
}
