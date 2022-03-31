package io.camunda.benchmark.utils;

import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

public class GgSheetHeaderUtilsTests {
	@Test
	void toCamelCaseTest() {
		String result = GgSheetHeaderUtils.toCamelCase("Max payload size (KiB)");
		assertThat(result).isEqualTo("maxPayloadSize");
	}
}
