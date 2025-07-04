.SILENT:

.PHONY: default build clean

default:
	echo
	echo "Available Makefile targets:"
	echo
	grep -P '^[\w\-]+:' Makefile|grep -v ":="|cut -f1 -d:|grep -v -E '^default'|while read target; do \
		DESC=$$( grep -B 1 -P "^$$target:" Makefile | head -1 ); \
		if  ( ! echo "$$DESC" | grep -qP '^# Do not use' ) then printf "  %-32s %s\n" "$$target" "$$DESC"; fi \
	done
	echo

# Full rebuild from scratch
build: clean nrpe-data-exporter

# Compile main executable
nrpe-data-exporter: nrpe-data-exporter.pl
	docker run --rm -it -v "$$PWD":/src --name rocky9builder rockylinux:9 bash -c "cd /src && ./build.sh"

# Clean up
clean:
	-rm -f nrpe-data-exporter

# Apply Perl formating rules
tidy:
	perltidy -pro=perltidyrc *.pl

# Do a syntax check
check:
	source ./activate && for i in *.pl; do perl -c "$$i"; done
