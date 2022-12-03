#!/usr/bin/env -S awk -f

/BUILD FAILED: Error while trying to load definition for system/ { print("load-definition-for-system"); next }
/BUILD FAILED: Filesystem error with pathname/ { print("filesystem-error-with-pathname"); next }
/BUILD FAILED: Implementation not supported./ { print("implementation-not-supported"); next }
/BUILD FAILED: Java exception/ { print("java-exception"); next }
/BUILD FAILED: No specification defined for current paltform/ { print("no-specification"); next }
/BUILD FAILED: Permission denied/ { print("permission-denied"); next }
/BUILD FAILED: Subprocess/ { print("subprocess"); next }
/BUILD FAILED: Unable to determine Python include directory/ { print("python"); next }
/BUILD FAILED: Unable to load any of the alternatives/ { print("unable-to-load-any-of-the-alternatives"); next }
/BUILD FAILED: Unable to load foreign library/ { print("unable-to-load-foreign-library"); next }
/BUILD FAILED: Unable to open/ { print("unable-to-open"); next }
/BUILD FAILED: Your Lisp does not support weak value hash-tables/ { print("lisp-does-not-support-weak-hash-tables"); next }
/BUILD FAILED: Component .* not found/ { print("component-not-found"); next }
/BUILD FAILED: Failed to compile proto file/ { print("failed-to-compile-proto-file"); next }
/BUILD FAILED: The package .* can't be found/ { print("package-cant-be-found"); next }
/BUILD FAILED: Package named .* does not exist/ { print("package-does-not-exist"); next }
/BUILD FAILED: Unable to open/ { print("unable-to-open"); next }
/BUILD FAILED: Can't create directory/ { print("cant-create-directory"); next }
/BUILD FAILED: The variable .* is unbound/ { print("variable-is-unbound"); next }
/BUILD FAILED: Unrecognized character name/ { print("unrecognized-character-name"); next }
/BUILD FAILED: .* is not of type / { print("value-not-of-type"); next }
/BUILD FAILED: The symbol .* is not present/ { print("symbol-not-present"); next }
/BUILD FAILED: The symbol .* is not external/ { print("symbol-not-external"); next }
/BUILD FAILED: Error opening/ { print("error-opening"); next }
/BUILD FAILED: Cannot modify value of constant/ { print("cannot-modify-value-of-constant"); next }
/BUILD FAILED: No MAKE-LOAD-FORM method is defined/ { print("no-make-load-form-method-defined"); next }
/BUILD FAILED: No adequate specialization of MAKE-LOAD-FORM/ { print("no-adequate-specialization-of-MAKE-LOAD-FORM"); next }
/BUILD FAILED: Symbol named .* not found/ { print("symbol-not-found"); next }
/BUILD FAILED: The slot .* is unbound/ { print("slot-is-unbound"); next }
/BUILD FAILED: This architecture is unsupported/ { print("this-architecture-is-unsupported"); next }
/BUILD FAILED: This lisp implementation is not supported/ { print("this-lisp-is-not-supported"); next }
/BUILD FAILED: There is no package named/ { print("no-package-named"); next }
/BUILD FAILED: Read error between/ { print("read-error"); next }
/BUILD FAILED: Class named .* not found/ { print("class-not-found"); next }
/BUILD FAILED: Could not find the class/ { print("could-not-find-class"); next }
/BUILD FAILED: Could not find the package/ { print("could-not-find-package"); next }
/BUILD FAILED: Module .* was not provided/ { print("module-not-provided"); next }
/BUILD FAILED: The value/ { print("value-not-expected-type"); next }
/BUILD FAILED: There is no applicable method for the generic function/ { print("no-applicable-method"); next }
/BUILD FAILED: Wrong number of arguments/ { print("wrong-number-of-arguments"); next }
/BUILD FAILED: Couldn't execute/ { print("couldnt-execute"); next }
/BUILD FAILED: Unsupported implementation/ { print("unsupported-implementation"); next }

/BUILD FAILED/ { printf("OTHER: %s\n", $0); next }
