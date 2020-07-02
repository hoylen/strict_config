# Makefile

.PHONY: dartfmt doc test

DOC_DIR=doc/api

#----------------------------------------------------------------

help:
	@echo "Targets for ${APP_NAME} (version ${APP_VERSION}):"
	@echo "  dartfmt  - formats Dart code consistantly for check-in"
	@echo "  doc      - generate code documentation"
	@echo "  test     - run tests"
	@echo
	@echo "  clean    - deletes the ${DOC_DIR} directory"

#----------------------------------------------------------------
# Development targets

dartfmt:
	@dartfmt -w lib example test | grep -v ^Unchanged

#----------------------------------------------------------------
# Tests

test:
	pub run test

#----------------------------------------------------------------
# Documentation

doc:
	@dartdoc --output "${DOC_DIR}"
	@echo "View Dart documentation by opening: ${DOC_DIR}/index.html"

#----------------------------------------------------------------

clean:
	@rm -f -r "${DOC_DIR}" *~

#EOF
