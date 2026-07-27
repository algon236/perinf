EMACS ?= emacs
VERSION := 0.1.0
PACKAGE := perinf-$(VERSION)
DIST_DIR := dist

.PHONY: test compile package clean

test:
	$(EMACS) -Q --batch -L . -L lisp -L schema -L locales \
	  -l test/perinf-test.el -f ert-run-tests-batch-and-exit

compile:
	$(EMACS) -Q --batch -L . -L lisp -L schema -L locales \
	  -f batch-byte-compile perinf.el lisp/*.el schema/*.el locales/*.el

package: test compile
	find . -name '*.elc' -delete
	rm -rf $(DIST_DIR)/$(PACKAGE)
	mkdir -p $(DIST_DIR)/$(PACKAGE)
	cp perinf.el perinf-pkg.el README.md LICENSE $(DIST_DIR)/$(PACKAGE)/
	cp lisp/*.el locales/*.el schema/*.el $(DIST_DIR)/$(PACKAGE)/
	COPYFILE_DISABLE=1 tar -C $(DIST_DIR) -cf $(DIST_DIR)/$(PACKAGE).tar $(PACKAGE)
	rm -rf $(DIST_DIR)/$(PACKAGE)

clean:
	find . -name '*.elc' -delete
	rm -rf $(DIST_DIR)
