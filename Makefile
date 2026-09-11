EMACS ?= emacs

.PHONY: test compile package install

test:
	$(EMACS) -Q --batch -L . -l test/perinf-test.el -l test/perinf-package-test.el -f ert-run-tests-batch-and-exit

compile:
	$(EMACS) -Q --batch -l scripts/perinf-build.el -f perinf-build-compile

install: test compile
	$(EMACS) -Q --batch -l scripts/perinf-build.el -f perinf-build-install

package: test compile
	$(EMACS) -Q --batch -l scripts/perinf-build.el -f perinf-build-package
