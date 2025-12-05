You're an expert is database design for swift ios. you're looking at the codebase for my fitness app. use pandas xls to take a look at project root/exercises_shared_database.xlsx (only this excel file in the root, explicitly, do not look at any other csv or xls* files in subfolders). analyse the structure and contents thoroughly.

Then look at these questions in our onboarding questionnaire:
- 3 (Experience Step View) 
- 4 (Equipment Step View)
- 5 (Injuries Step View)

functional requirements of these questions:
- Q3: Collect user's subjective experience assessment (links to an experience mapping table in database-management/exercises.db (SQLlite3))
- Q4: Collect user's available equipment - this is where we have gaps, you'll notice we have an equipment name column in the xlsx and an accessory equipment column. you'll see from the lookup tables (other sheets in the xlsx) that equipment name is basic equipment, for example the Barbell Bench Press exercise (EX071) has "Barbell" listed. logic being that in question 4 if the user deselects "Barbell" from equipment then all equipment with barbell as the equipment would be filtered out of the baseline dataset for that user from which to generate a programme. however, as you can see we now wish to expand the Barbell options and down one level in the hierarchy list all types of barbell equipment "Barbell Bench Press" for example. we don't actually list that explicitly in the exercises database so this makes it hard to filter out, for example the user could have X/10 pieces of barbell equipment in their gym just not Barbell Bench Press so that would be the only one that needs filtering out. originally i'd desinged the accessory equipment column to include a low level breakdown of components, of the exericse, so for example Cable Squat would be exercise_name cable and accessory equipment "Cable Attachment" but this still does not lend itself to the filtering mechanism we want to introduce. give me your analysis and feedback here, do you think we should introduce specific equipment names so that we can filter them out? How should we design the columns so that we have a more abstract (broader) Type column (e.g. barbell, meaning all barbell exercises can be filtered out if Barbell is deselected in question 4 at the top level) and what else? 
- Q5: Collect user's injuries, if any (links to an experience mapping table in database-management/exercises.db (SQLlite3)) but do we need that mapping table? does it create bloat?

xls file columns and reasoning:
Columns:
exercise_id             object - unique identifier for exercise
canonical_name          object - abstract name common to different exercises of the same types - allows us to offer close alternative exercises in the case of a swap (see workout logger view)
display_name            object - how the exercise name is displayed in the app
equipment_name          object - explained above
equipment_type          object - broad filtering on machines e.g. pin-loaded (question 4)
accessory_equipment     object - explained above
complexity_level        object - maps to question 3 explained above
primary_muscle          object - maps to question 2 MuscleGroupsStepView
secondary_muscle        object 
instructions            object - displayed on screen during Logger
programme_inclusion    float64 - boolean flag that allows us to switch on whether we include the exercise in the users programme. crucially, all exercises (true or false) will be shown in the exercise library (Models/ExerciseDatabase.swift), so a false exercise would not be generated in a programme but would be shown in the exercisedatabase. this is essentially for niche (specialist) exercises, and since we're targetting general population, often beginners, we would not programme them these. a later feature may be that they can manually add these exercises to their programme if they so wish.

I'm happy to be challenged on these. we want to operate most efficiently and you're the expert on database design. give me your feedback on the exercise database design in the xlsx then the current designs we have in exercises.db, including columns and dtypes. do you think we need to change things? do we have redundant columns? do we need new columns?

generate the analysis and save your output in a markdown report. be succinct and systematic in your analysis approach.
