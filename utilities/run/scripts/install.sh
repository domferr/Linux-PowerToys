#!/bin/bash
# installs all plugin gsettings schemas

run_utility_base_path="$(dirname "$(pwd)/$0/")/.."

# install gsettings schemas
shopt -s globstar
for schema_path in $run_utility_base_path/lib/plugins/**/*.gschema.xml ; do
    echo installing $(basename $schema_path)
    cp $schema_path /usr/share/glib-2.0/schemas/
done
glib-compile-schemas /usr/share/glib-2.0/schemas/
