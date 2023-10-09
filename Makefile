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
	@echo "  pana     - run pana"
	@echo
	@echo "  clean    - deletes the ${DOC_DIR} directory"

#----------------------------------------------------------------
# Development targets

format:
	@dart format  lib example test

#----------------------------------------------------------------
# Tests

test:
	dart run test

#----------------------------------------------------------------
# Documentation

doc:
	@dart doc --output-dir "${DOC_DIR}" `pwd`
	@echo "View Dart documentation by opening: ${DOC_DIR}/index.html"

#----------------------------------------------------------------
# Publishing

pana:
	dart run pana

#----------------------------------------------------------------

clean:
	@rm -f -r "${DOC_DIR}" *~

#EOF
