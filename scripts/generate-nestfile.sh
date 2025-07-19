#!/bin/bash

# Script to generate nestfile.yaml from Mintfile
# Works on both macOS and Linux

set -e  # Exit on any error

# SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINTFILE="Mintfile"
NESTFILE="nestfile.yaml"

# Check if Mintfile exists
if [[ ! -f "$MINTFILE" ]]; then
    echo "Error: Mintfile not found at $MINTFILE"
    exit 1
fi

# Start generating the nestfile.yaml
echo "Generating nestfile.yaml from Mintfile..."

# Create the nestfile.yaml with header
cat > "$NESTFILE" << 'EOF'
nestPath: ./.nest
targets:
EOF

# Parse Mintfile and convert to nestfile.yaml format
# Use process substitution to handle files without trailing newlines
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
        continue
    fi
    
    # Parse the line format: owner/repo@version
    if [[ "$line" =~ ^([^@]+)@(.+)$ ]]; then
        reference="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        
        # Add the target to nestfile.yaml
        cat >> "$NESTFILE" << EOF
  - reference: $reference
    version: $version
EOF
    else
        echo "Warning: Skipping malformed line: $line"
    fi
done < "$MINTFILE"

echo "Successfully generated nestfile.yaml"
echo "Contents:"
echo "----------------------------------------"
cat "$NESTFILE"
echo "----------------------------------------"
