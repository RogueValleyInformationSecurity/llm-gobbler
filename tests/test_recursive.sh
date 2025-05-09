#!/bin/bash

# Test recursive directory processing of LLM Globber
# This test checks if the tool correctly processes directories recursively

# Create output directory
mkdir -p test_output

# Test case: Recursive directory processing
echo "Test case: Recursive directory processing"

# Directory to test
TEST_DIR="test_files"

# Expected output: manually find and concatenate all .c files recursively
EXPECTED_OUTPUT="test_output/expected_recursive.txt"
echo "" > $EXPECTED_OUTPUT

# Find all .c files in the test directory
C_FILES=$(find $TEST_DIR -name "*.c" | sort)

# Add each file to the expected output
for file in $C_FILES; do
    # Use the full path instead of just the filename
    echo "" >> $EXPECTED_OUTPUT
    echo "'''--- $(pwd)/$file ---" >> $EXPECTED_OUTPUT
    cat "$file" >> $EXPECTED_OUTPUT
    echo "" >> $EXPECTED_OUTPUT
    echo "'''" >> $EXPECTED_OUTPUT
done

# Run llm_globber with recursive option and absolute path
OUTPUT_DIR="$(pwd)/test_output"
echo "Using output directory: $OUTPUT_DIR"
# Ensure the directory exists
mkdir -p "$OUTPUT_DIR"
# Run with absolute path to test directory
# Use -r flag for recursive mode
echo "Running: ../target/release/llm_globber -o $OUTPUT_DIR -n recursive_test -t .c -r $(pwd)/$TEST_DIR"
../target/release/llm_globber -o "$OUTPUT_DIR" -n recursive_test -t .c -r "$(pwd)/$TEST_DIR"

# Find the generated output file (most recent in the directory)
ACTUAL_OUTPUT=$(ls -t test_output/recursive_test_*.txt | head -1)

if [ -z "$ACTUAL_OUTPUT" ]; then
    echo "Error: No output file was generated"
    exit 1
fi

# Count the number of file headers in the output
EXPECTED_FILE_COUNT=$(grep -c "^'''\-\-\-" $EXPECTED_OUTPUT)
ACTUAL_FILE_COUNT=$(grep -c "^'''\-\-\-" $ACTUAL_OUTPUT)

# Check if the output file exists and has content
if [ ! -s "$ACTUAL_OUTPUT" ]; then
    echo "Error: Output file is empty or doesn't exist: $ACTUAL_OUTPUT"
    exit 1
fi

if [ "$EXPECTED_FILE_COUNT" = "$ACTUAL_FILE_COUNT" ]; then
    echo "Recursive test passed: Found $ACTUAL_FILE_COUNT files as expected"
    exit 0
else
    echo "FAILED: Recursive test - Expected $EXPECTED_FILE_COUNT files, but found $ACTUAL_FILE_COUNT"
    echo "Expected files:"
    grep "^'''\-\-\-" $EXPECTED_OUTPUT
    echo "Actual files:"
    grep "^'''\-\-\-" $ACTUAL_OUTPUT
    
    # Print the error message if it exists in the output
    ERROR_MSG=$(grep "Error:" "$ACTUAL_OUTPUT" 2>/dev/null)
    if [ -n "$ERROR_MSG" ]; then
        echo "Error found in output: $ERROR_MSG"
    fi
    
    exit 1
fi
