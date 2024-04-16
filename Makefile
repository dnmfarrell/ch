lint:
	shellcheck ch
	shellcheck -x tests/tap.sh -x ./ch tests/run.sh
	shfmt -w ch **/*.sh

test:
	./tests/run.sh

.PHONY: lint test
