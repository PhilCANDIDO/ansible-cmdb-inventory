#!/bin/bash
# flatten_directory.sh - Flatten directory structure for AI context sharing
# Version: 1.1.0
#
# Changelog:
# 1.0.0 - Initial version
# 1.1.0 - Added README_FOR_AI.md generation to help AI systems understand the file structure

# Exit on error
set -e

# Default values
SOURCE_FOLDER=""
DEST_FOLDER=""
PREFIX=""
VERBOSE=false
DRY_RUN=false
INCLUDE_PATTERN=""
EXCLUDE_PATTERN=""

# Function to display help
display_help() {
    echo "flatten_directory.sh - Flatten directory structure for AI context sharing"
    echo "Version: 1.1.0"
    echo
    echo "Description:"
    echo "  This script flattens a directory structure, copying all files to a single"
    echo "  destination folder while renaming them to preserve the path information."
    echo "  It's designed to prepare files for sharing with AI tools like Claude, ChatGPT, etc."
    echo "  A README_FOR_AI.md file is automatically generated to help AI systems"
    echo "  understand the file structure and how to interpret the flattened files."
    echo
    echo "Usage: $0 --folder-source <source_dir> --folder-dest <dest_dir> [options]"
    echo
    echo "Required arguments:"
    echo "  --folder-source, -s <dir>  Source directory to flatten"
    echo "  --folder-dest, -d <dir>    Destination directory for flattened files"
    echo
    echo "Options:"
    echo "  --help, -h                 Display this help message and exit"
    echo "  --prefix, -p <prefix>      Add a prefix to all destination filenames"
    echo "  --verbose, -v              Enable verbose output"
    echo "  --dry-run, -n              Show what would be done without actually copying files"
    echo "  --include, -i <pattern>    Only include files matching the pattern (grep extended regex)"
    echo "  --exclude, -e <pattern>    Exclude files matching the pattern (grep extended regex)"
    echo
    echo "Examples:"
    echo "  # Basic usage"
    echo "  $0 --folder-source /srv/ansible/roles/cmdb_inventory --folder-dest /tmp/claude_files"
    echo
    echo "  # Using a prefix for all files"
    echo "  $0 -s /srv/ansible/roles/cmdb_inventory -d /tmp/claude_files -p cmdb_"
    echo
    echo "  # Dry run with verbose output"
    echo "  $0 -s /srv/ansible/roles/cmdb_inventory -d /tmp/claude_files -v -n"
    echo
    echo "  # Only include YAML files"
    echo "  $0 -s /srv/ansible/roles/cmdb_inventory -d /tmp/claude_files -i '\.ya?ml$'"
    echo
    echo "  # Exclude test files"
    echo "  $0 -s /srv/ansible/roles/cmdb_inventory -d /tmp/claude_files -e '/tests/'"
    echo
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --folder-source|-s)
            SOURCE_FOLDER="$2"
            shift 2
            ;;
        --folder-dest|-d)
            DEST_FOLDER="$2"
            shift 2
            ;;
        --prefix|-p)
            PREFIX="$2"
            shift 2
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --dry-run|-n)
            DRY_RUN=true
            shift
            ;;
        --include|-i)
            INCLUDE_PATTERN="$2"
            shift 2
            ;;
        --exclude|-e)
            EXCLUDE_PATTERN="$2"
            shift 2
            ;;
        --help|-h)
            display_help
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Use --help or -h for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [[ -z "$SOURCE_FOLDER" ]]; then
    echo "Error: Source folder is required (--folder-source or -s)"
    echo "Use --help or -h for usage information"
    exit 1
fi

if [[ -z "$DEST_FOLDER" ]]; then
    echo "Error: Destination folder is required (--folder-dest or -d)"
    echo "Use --help or -h for usage information"
    exit 1
fi

# Validate source folder exists
if [[ ! -d "$SOURCE_FOLDER" ]]; then
    echo "Error: Source folder does not exist: $SOURCE_FOLDER"
    exit 1
fi

# Create destination folder if it doesn't exist
if [[ ! -d "$DEST_FOLDER" && "$DRY_RUN" == "false" ]]; then
    if [[ "$VERBOSE" == "true" ]]; then
        echo "Creating destination folder: $DEST_FOLDER"
    fi
    mkdir -p "$DEST_FOLDER"
elif [[ "$DRY_RUN" == "true" && ! -d "$DEST_FOLDER" ]]; then
    echo "[DRY RUN] Would create destination folder: $DEST_FOLDER"
fi

# Process files
process_files() {
    # Use find to locate all files recursively
    find "$SOURCE_FOLDER" -type f | while read -r file; do
        # Calculate relative path from source folder
        rel_path="${file#$SOURCE_FOLDER/}"
        
        # Apply include/exclude filters if specified
        if [[ -n "$INCLUDE_PATTERN" ]] && ! echo "$rel_path" | grep -E "$INCLUDE_PATTERN" > /dev/null; then
            if [[ "$VERBOSE" == "true" ]]; then
                echo "Skipping (not matching include pattern): $rel_path"
            fi
            continue
        fi
        
        if [[ -n "$EXCLUDE_PATTERN" ]] && echo "$rel_path" | grep -E "$EXCLUDE_PATTERN" > /dev/null; then
            if [[ "$VERBOSE" == "true" ]]; then
                echo "Skipping (matching exclude pattern): $rel_path"
            fi
            continue
        fi
        
        # Create new filename with path separators replaced by double underscores
        new_filename="${PREFIX}${rel_path//\//__}"
        dest_path="$DEST_FOLDER/$new_filename"
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Processing: $rel_path → $new_filename"
        fi
        
        if [[ "$DRY_RUN" == "true" ]]; then
            echo "[DRY RUN] Would copy: $file → $dest_path"
        else
            # Copy the file
            cp "$file" "$dest_path"
            
            # Add a header comment to text files indicating the original path
            if file -b --mime-type "$file" | grep -E "text/" > /dev/null; then
                # Create a temporary file to avoid sed issues with different OS variations
                temp_file=$(mktemp)
                original_path="$SOURCE_FOLDER/$rel_path"
                echo "# Original path: $original_path" > "$temp_file"
                cat "$dest_path" >> "$temp_file"
                mv "$temp_file" "$dest_path"
            fi
        fi
    done
}

# Generate metadata file
generate_metadata() {
    metadata_file="$DEST_FOLDER/${PREFIX}file_mapping.txt"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would create metadata file: $metadata_file"
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Generating metadata file: $metadata_file"
        fi
        
        echo "# Flattened directory mapping" > "$metadata_file"
        echo "# Generated on $(date)" >> "$metadata_file"
        echo "# Source: $SOURCE_FOLDER" >> "$metadata_file"
        echo "# " >> "$metadata_file"
        echo "# Format: flattened_filename -> original_path" >> "$metadata_file"
        echo "# " >> "$metadata_file"
        
        find "$SOURCE_FOLDER" -type f | while read -r file; do
            rel_path="${file#$SOURCE_FOLDER/}"
            
            # Apply include/exclude filters if specified
            if [[ -n "$INCLUDE_PATTERN" ]] && ! echo "$rel_path" | grep -E "$INCLUDE_PATTERN" > /dev/null; then
                continue
            fi
            
            if [[ -n "$EXCLUDE_PATTERN" ]] && echo "$rel_path" | grep -E "$EXCLUDE_PATTERN" > /dev/null; then
                continue
            fi
            
            new_filename="${PREFIX}${rel_path//\//__}"
            echo "$new_filename -> $rel_path" >> "$metadata_file"
        done
    fi
}

# Generate directory structure file
generate_structure() {
    structure_file="$DEST_FOLDER/${PREFIX}directory_structure.txt"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would create directory structure file: $structure_file"
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Generating directory structure file: $structure_file"
        fi
        
        echo "# Directory structure of $SOURCE_FOLDER" > "$structure_file"
        echo "# Generated on $(date)" >> "$structure_file"
        echo "# " >> "$structure_file"
        
        (
            cd "$SOURCE_FOLDER" && find . -type f -o -type d | sort | while read -r line; do
                indent=$(echo "$line" | sed 's/[^\/]//g' | sed 's/\//  /g')
                name=$(basename "$line")
                echo "$indent$name" >> "$structure_file"
            done
        )
    fi
}

# Generate README for AI
generate_ai_readme() {
    readme_file="$DEST_FOLDER/${PREFIX}README_FOR_AI.md"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY RUN] Would create README for AI: $readme_file"
    else
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Generating README for AI: $readme_file"
        fi
        
        cat > "$readme_file" << EOF
# Important Information for AI Analysis

## File Structure Context

This is a flattened directory structure of an Ansible role. The original hierarchy has been converted to flat files where:

- Original path separators (/) have been replaced with double underscores (__)
- Example: \`tasks__hardware__main.yml\` was originally \`tasks/hardware/main.yml\`

## Important Files to Review First

1. **${PREFIX}directory_structure.txt**: Contains the visual representation of the original directory structure
2. **${PREFIX}file_mapping.txt**: Maps each flattened filename back to its original path

## Understanding the Ansible Role Structure

This is an Ansible role with a standard directory structure that includes:
- \`tasks/\`: Contains the main playbook tasks, organized in subdirectories by function
- \`templates/\`: Contains Jinja2 templates
- \`defaults/\`: Contains default variables
- \`handlers/\`: Contains handlers that can be notified by tasks
- \`vars/\`: Contains role variables
- \`meta/\`: Contains role metadata
- \`files/\`: Contains static files

When analyzing these files, please reconstruct the original hierarchy mentally to understand the role's organization and functionality.

## Original Directory Source

These files were flattened from: \`$SOURCE_FOLDER\`
EOF
    fi
}

# Main execution
echo "Flattening directory structure"
echo "Source: $SOURCE_FOLDER"
echo "Destination: $DEST_FOLDER"
if [[ -n "$PREFIX" ]]; then
    echo "Using prefix: $PREFIX"
fi
if [[ -n "$INCLUDE_PATTERN" ]]; then
    echo "Including files matching: $INCLUDE_PATTERN"
fi
if [[ -n "$EXCLUDE_PATTERN" ]]; then
    echo "Excluding files matching: $EXCLUDE_PATTERN"
fi
if [[ "$DRY_RUN" == "true" ]]; then
    echo "*** DRY RUN - No files will be copied ***"
fi
echo ""

# Process files
process_files

# Generate metadata
generate_metadata

# Generate directory structure
generate_structure

# Generate README for AI
generate_ai_readme

if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY RUN] Operation completed - no files were actually copied"
else
    echo "Operation completed successfully"
    echo "Flattened files are available at: $DEST_FOLDER"
    
    # Report file count
    file_count=$(find "$DEST_FOLDER" -type f | wc -l)
    echo "Total files processed: $file_count"
fi

exit 0