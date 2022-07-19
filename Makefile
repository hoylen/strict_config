# Makefile

.PHONY: format doc test

DOC_DIR=doc/api

PKG_NAME=`awk '/^name:/ { print $$2 }' pubspec.yaml`
PKG_VERSION=`awk '/^version:/ { print $$2 }' pubspec.yaml`

#----------------------------------------------------------------

help:
	@echo "Targets for ${PKG_NAME} (version ${PKG_VERSION}):"
	@echo "  format   - formats Dart code consistantly for check-in"
	@echo "  doc      - generate code documentation"
	@echo "  test     - run tests"
	@echo
	@echo "  clean    - deletes the ${DOC_DIR} directory"

#----------------------------------------------------------------
# Development targets

format:
	@dart format  lib example test

#----------------------------------------------------------------
# Tests

test:
	pub run test

#----------------------------------------------------------------
# Documentation

doc:
	@dart doc --output-dir "${DOC_DIR}" `pwd`
	@echo "View Dart documentation by opening: ${DOC_DIR}/index.html"

#----------------------------------------------------------------

clean:
	@rm -f -r "${DOC_DIR}" *~

#EOF
