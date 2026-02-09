import pandas as pd
import csv

# Read the exercise database file
db_file = '/Users/lukevassor/Documents/trAIn-ios/database-management/train_exercise_database_prod.csv'
mapping_wip_file = '/Users/lukevassor/Documents/trAIn-ios/database-management/exercise_video_mapping_WIP.csv'
mapping_prod_file = '/Users/lukevassor/Documents/trAIn-ios/database-management/exercise_video_mapping_prod.csv'

# Read database file
db_df = pd.read_csv(db_file)

# Read both mapping files
mapping_wip_df = pd.read_csv(mapping_wip_file)
mapping_prod_df = pd.read_csv(mapping_prod_file)

# Rename columns for clarity
mapping_wip_df = mapping_wip_df.rename(columns={
    'supplier_id': 'bunny_id_wip',
    'notes': 'notes_wip'
})

mapping_prod_df = mapping_prod_df.rename(columns={
    'supplier_id': 'bunny_id_prod',
    'note': 'notes_prod'
})

# Merge with WIP mapping first
merged_df = pd.merge(db_df, mapping_wip_df[['exercise_id', 'bunny_id_wip', 'notes_wip']],
                     on='exercise_id', how='left')

# Merge with production mapping
merged_df = pd.merge(merged_df, mapping_prod_df[['exercise_id', 'bunny_id_prod', 'notes_prod']],
                     on='exercise_id', how='left')

# Create combined bunny_id column - use WIP if available, otherwise use production
merged_df['bunny_id_combined'] = merged_df['bunny_id_wip'].fillna(merged_df['bunny_id_prod'])

# Create combined notes column
merged_df['notes_combined'] = merged_df['notes_wip'].fillna('') + ' | ' + merged_df['notes_prod'].fillna('')
merged_df['notes_combined'] = merged_df['notes_combined'].str.replace(r'^\s*\|\s*|\s*\|\s*$', '', regex=True)
merged_df['notes_combined'] = merged_df['notes_combined'].replace('', None)

# Create final output with selected columns
output_df = merged_df[[
    'exercise_id',
    'display_name',
    'equipment_category',
    'attachment_specific',
    'bunny_id_combined',
    'notes',
    'notes_combined'
]].copy()

# Rename columns for clarity
output_df.columns = [
    'exercise_id',
    'display_name',
    'equipment',
    'attachment',
    'bunny_id',
    'notes_database',
    'notes_mapping'
]

# Sort by exercise_id
output_df = output_df.sort_values('exercise_id')

# Save to CSV
output_file = '/Users/lukevassor/Documents/trAIn-ios/complete_exercise_data.csv'
output_df.to_csv(output_file, index=False)

print(f"Complete exercise data saved to: {output_file}")
print(f"Total exercises: {len(output_df)}")
print(f"Exercises with bunny ID: {len(output_df[output_df['bunny_id'].notna()])}")
print(f"Exercises without bunny ID: {len(output_df[output_df['bunny_id'].isna()])}")

# Show breakdown by data source
wip_count = len(merged_df[merged_df['bunny_id_wip'].notna()])
prod_only_count = len(merged_df[(merged_df['bunny_id_wip'].isna()) & (merged_df['bunny_id_prod'].notna())])
print(f"Bunny IDs from WIP file: {wip_count}")
print(f"Bunny IDs from PROD file only: {prod_only_count}")