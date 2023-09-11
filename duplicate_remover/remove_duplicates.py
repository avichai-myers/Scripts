#!/usr/bin/env python3

def remove_duplicates(input_file):
    try:
        with open(input_file, 'r') as f:
            lines = f.readlines()

        unique_lines = sorted(set(line.strip() for line in lines))

        with open(input_file, 'w') as f:
            f.write("\n".join(unique_lines))

        total_lines = len(lines)
        unique_lines_count = len(unique_lines)
        duplicates_removed = total_lines - unique_lines_count

        print("Duplicates removed:", duplicates_removed)
        print("Lines left:", unique_lines_count)
        print("Unique emails saved to '{}'.".format(input_file))

    except FileNotFoundError:
        print("Error: Input file '{}' not found.".format(input_file))


if __name__ == "__main__":
    input_file = "emails.txt"
    remove_duplicates(input_file)
