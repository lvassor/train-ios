import csv

input_file = './exercise_instructions.csv'
output_file = './exercise_instructions_combined.csv'

with open(input_file, 'r', encoding='utf-8') as infile:
    reader = csv.DictReader(infile)
    rows = list(reader)

with open(output_file, 'w', encoding='utf-8', newline='') as outfile:
    writer = csv.writer(outfile)
    writer.writerow(['display_name', 'instructions'])
    
    for row in rows:
        display_name = row['display_name']
        
        # Combine the 4 steps into a single multiline string
        instructions = (
            f"Step 1: {row['step_1_setup']}\n"
            f"Step 2: {row['step_2_starting_position']}\n"
            f"Step 3: {row['step_3_execution']}\n"
            f"Step 4: {row['step_4_return']}"
        )
        
        writer.writerow([display_name, instructions])

print(f"Created {output_file} with {len(rows)} exercises")