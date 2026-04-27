#!/usr/bin/env bash

# ==============================================================================
# JSON IMPORT UTILITIES - WITH INCREMENTAL PROJECTION
# ==============================================================================
# Compatible Windows (Git Bash) et VPS
# Utilise \COPY FROM STDIN pour importer JSON depuis fichier côté client
# ==============================================================================
# Usage:
#   source json-import-utils.sh
#   import_json_to_raw_table "file.json" "table_raw" "projection_callback"
# ==============================================================================

# ==============================================================================
# FILE SIZE CHECK
# ==============================================================================
should_split_json() {
    local file=$1
    local max_size_mb=${2:-$MAX_JSON_SIZE_MB}

    if [ ! -f "$file" ]; then
        echo "❌ File not found: $file" >&2
        return 1
    fi

    local file_size_mb=$(du -m "$file" | cut -f1)
    [ "$file_size_mb" -gt "$max_size_mb" ]
}

# ==============================================================================
# SPLIT JSON WITH TYPESCRIPT
# ==============================================================================
split_json_with_ts() {
    local input_file=$1
    local max_size_mb=$2

    if ! command -v ts-node &> /dev/null; then
        echo "❌ Error: ts-node not found" >&2
        echo "Please install: npm install -g ts-node typescript @types/node" >&2
        return 1
    fi

    if [ ! -f "$JSON_SPLITTER_TS" ]; then
        echo "❌ Error: json-splitter.ts not found at $JSON_SPLITTER_TS" >&2
        return 1
    fi

    ts-node "$JSON_SPLITTER_TS" "$input_file" "$max_size_mb"
}

# ==============================================================================
# CLEANUP SPLIT FILES
# ==============================================================================
cleanup_split_files() {
    local original_file=$1
    local base_name=$(basename "$original_file" .json)
    local dir_name=$(dirname "$original_file")

    # ✅ Attendre que les handles soient relâchés (Windows)
    sleep 2

    # ✅ Suppression avec retry
    local max_attempts=3
    local attempt=1

    while [ $attempt -le $max_attempts ]; do
        if rm -f "$dir_name/${base_name}_part"*.json 2>/dev/null; then
            echo "🧹 Cleaned up split files for $(basename "$original_file")"
            return 0
        fi

        echo "⏳ Cleanup attempt $attempt/$max_attempts failed, retrying..."
        sleep 2
        attempt=$((attempt + 1))
    done

    echo "⚠️  Could not remove all split files (may be locked). Manual cleanup needed:"
    echo "    rm -f \"$dir_name/${base_name}_part\"*.json"
}
# ==============================================================================
# IMPORT JSON TO RAW TABLE (MAIN FUNCTION)
# ==============================================================================
import_json_to_raw_table() {
    local json_file=$1
    local raw_table=$2
    local projection_callback=$3
    local max_size_mb=${4:-$MAX_JSON_SIZE_MB}

    if [ -z "$json_file" ] || [ -z "$raw_table" ]; then
        echo "❌ Missing required parameters" >&2
        return 1
    fi

    if [ -z "$DB_CONTAINER" ] || [ -z "$DB_USER_WRITER" ] || [ -z "$DB_NAME" ]; then
        echo "❌ Missing environment variables: DB_CONTAINER, DB_USER_WRITER, DB_NAME" >&2
        return 1
    fi

    echo "Checking file size..."
    if should_split_json "$json_file" "$max_size_mb"; then
        _import_large_json_incremental "$json_file" "$raw_table" "$projection_callback" "$max_size_mb"
    else
        _import_small_json "$json_file" "$raw_table" "$projection_callback"
    fi
}

# ==============================================================================
# INTERNAL: IMPORT LARGE JSON WITH INCREMENTAL PROJECTION
# ==============================================================================
_import_large_json_incremental() {
    local json_file=$1
    local raw_table=$2
    local projection_callback=$3
    local max_size_mb=$4

    echo "⚠️ File exceeds ${max_size_mb}MB - splitting..."
    local part_files=$(split_json_with_ts "$json_file" "$max_size_mb")
    if [ $? -ne 0 ]; then
        echo "❌ Split failed" >&2
        return 1
    fi

    local total_parts=$(echo "$part_files" | wc -l)
    echo "📊 Total parts to process: $total_parts"

    local part_num=0
    while IFS= read -r part_file <&3; do
        [ -z "$part_file" ] && continue
        [ ! -f "$part_file" ] && echo "⚠️ Part file not found: $part_file" && continue
        part_num=$((part_num + 1))
        echo "=============================================="
        echo "Processing part $part_num/$total_parts"
        echo "=============================================="

        _import_part_file "$part_file" "$raw_table" || return 1

        if [ -n "$projection_callback" ] && [ "$(type -t "$projection_callback")" = "function" ]; then
            echo "Projecting..."
            $projection_callback
        fi

        echo "Cleaning raw table..."
        docker exec "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c "TRUNCATE TABLE $raw_table;"

        echo "✓ Part $part_num processed"
    done 3<<< "$part_files"

    cleanup_split_files "$json_file"
    echo "✅ All parts imported and projected"
}

# ==============================================================================
# INTERNAL: IMPORT SMALL JSON (DIRECT)
# ==============================================================================
_import_small_json() {
    local json_file=$1
    local raw_table=$2
    local projection_callback=$3

    echo "ℹ️ File under ${MAX_JSON_SIZE_MB}MB - direct import"
    _import_part_file "$json_file" "$raw_table"

    if [ -n "$projection_callback" ] && [ "$(type -t "$projection_callback")" = "function" ]; then
        $projection_callback "$raw_table"
    fi
}

# ==============================================================================
# INTERNAL: IMPORT SINGLE PART FILE
# ==============================================================================
_import_part_file() {
    local part_file=$1
    local raw_table=$2

    echo "📦 Importing $(basename "$part_file")..."
    docker exec -i "$DB_CONTAINER" psql -U "$DB_USER_WRITER" -d "$DB_NAME" -c \
      "\\COPY $raw_table(data) FROM STDIN WITH (FORMAT csv, QUOTE e'\\x01', DELIMITER e'\\x02')" < "$part_file"

    echo "✓ Imported into raw"
}

# ==============================================================================
# SQL EXECUTION
# ==============================================================================
run_sql_file() {
    local file=$1
    docker exec -i "$DB_CONTAINER" \
        psql -U "$DB_USER_WRITER" -d "$DB_NAME" \
        -f "$file"
}

# ==============================================================================
# EXPORT FUNCTIONS
# ==============================================================================
export -f should_split_json
export -f split_json_with_ts
export -f cleanup_split_files
export -f import_json_to_raw_table
export -f _import_large_json_incremental
export -f _import_small_json
export -f _import_part_file
export -f run_sql_file
