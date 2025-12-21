"""
templates.py - Session templates matching Swift DynamicProgramGenerator
"""

from typing import List, Tuple, Dict


# Session template: {'name': str, 'muscle_groups': [(muscle, count), ...]}
SessionTemplate = Dict[str, any]


def get_session_templates(days_per_week: int, session_duration: str) -> List[SessionTemplate]:
    """
    Get session templates based on days per week and duration.
    Matches Swift DynamicProgramGenerator logic.

    session_duration: '30-45 min', '45-60 min', '60-90 min'
    """
    # Map duration strings to internal keys
    duration_map = {
        '30-45 min': 'short',
        '45-60 min': 'medium',
        '60-90 min': 'long'
    }
    duration = duration_map.get(session_duration, 'medium')

    if days_per_week == 1:
        return get_1_day_templates(duration)
    elif days_per_week == 2:
        return get_2_day_templates(duration)
    elif days_per_week == 3:
        return get_3_day_templates(duration)
    elif days_per_week == 4:
        return get_4_day_templates(duration)
    elif days_per_week == 5:
        return get_5_day_templates(duration)
    elif days_per_week == 6:
        return get_6_day_templates(duration)
    else:
        return get_3_day_templates(duration)  # Default fallback


def get_1_day_templates(duration: str) -> List[SessionTemplate]:
    """1-day Full Body templates"""
    if duration == 'short':
        return [{
            'name': 'Full Body',
            'muscle_groups': [
                ('Chest', 1), ('Shoulders', 1), ('Back', 1),
                ('Quads', 1), ('Hamstrings', 1), ('Core', 1)
            ]
        }]
    elif duration == 'medium':
        return [{
            'name': 'Full Body',
            'muscle_groups': [
                ('Chest', 1), ('Shoulders', 1), ('Back', 1),
                ('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)
            ]
        }]
    else:  # long
        return [{
            'name': 'Full Body',
            'muscle_groups': [
                ('Chest', 1), ('Shoulders', 1), ('Back', 1),
                ('Biceps', 1), ('Triceps', 1),
                ('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)
            ]
        }]


def get_2_day_templates(duration: str) -> List[SessionTemplate]:
    """2-day Upper/Lower or Full Body templates"""
    if duration == 'short':
        # Upper/Lower split
        return [
            {
                'name': 'Upper',
                'muscle_groups': [('Chest', 1), ('Shoulders', 1), ('Back', 1)]
            },
            {
                'name': 'Lower',
                'muscle_groups': [('Quads', 2), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)]
            }
        ]
    else:  # medium or long - Full Body
        if duration == 'medium':
            return [
                {
                    'name': 'Full Body',
                    'muscle_groups': [
                        ('Chest', 1), ('Shoulders', 1), ('Back', 1),
                        ('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)
                    ]
                },
                {
                    'name': 'Full Body',
                    'muscle_groups': [
                        ('Chest', 1), ('Shoulders', 1), ('Back', 1),
                        ('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)
                    ]
                }
            ]
        else:  # long
            return [
                {
                    'name': 'Full Body',
                    'muscle_groups': [
                        ('Chest', 1), ('Shoulders', 1), ('Back', 1),
                        ('Biceps', 1), ('Triceps', 1),
                        ('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)
                    ]
                },
                {
                    'name': 'Full Body',
                    'muscle_groups': [
                        ('Chest', 1), ('Shoulders', 1), ('Back', 1),
                        ('Biceps', 1), ('Triceps', 1),
                        ('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)
                    ]
                }
            ]


def get_3_day_templates(duration: str) -> List[SessionTemplate]:
    """3-day Push/Pull/Legs templates"""
    if duration == 'short':
        return [
            {
                'name': 'Push',
                'muscle_groups': [('Chest', 1), ('Shoulders', 2), ('Triceps', 1)]
            },
            {
                'name': 'Pull',
                'muscle_groups': [('Back', 2), ('Biceps', 2)]
            },
            {
                'name': 'Legs',
                'muscle_groups': [('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)]
            }
        ]
    elif duration == 'medium':
        return [
            {
                'name': 'Push',
                'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Triceps', 1)]
            },
            {
                'name': 'Pull',
                'muscle_groups': [('Back', 3), ('Biceps', 2)]
            },
            {
                'name': 'Legs',
                'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]
            }
        ]
    else:  # long
        return [
            {
                'name': 'Push',
                'muscle_groups': [('Chest', 3), ('Shoulders', 3), ('Triceps', 2)]
            },
            {
                'name': 'Pull',
                'muscle_groups': [('Back', 3), ('Biceps', 3)]
            },
            {
                'name': 'Legs',
                'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]
            }
        ]


def get_4_day_templates(duration: str) -> List[SessionTemplate]:
    """4-day Upper/Lower split templates"""
    if duration == 'short':
        return [
            {'name': 'Upper', 'muscle_groups': [('Chest', 1), ('Shoulders', 1), ('Back', 1)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)]},
            {'name': 'Upper', 'muscle_groups': [('Chest', 1), ('Shoulders', 1), ('Back', 1)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)]}
        ]
    elif duration == 'medium':
        return [
            {'name': 'Upper', 'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Back', 2)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]},
            {'name': 'Upper', 'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Back', 2)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]}
        ]
    else:  # long
        return [
            {'name': 'Upper', 'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Back', 2), ('Triceps', 1), ('Biceps', 1)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]},
            {'name': 'Upper', 'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Back', 2), ('Triceps', 1), ('Biceps', 1)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]}
        ]


def get_5_day_templates(duration: str) -> List[SessionTemplate]:
    """5-day Hybrid split (PPL + Upper/Lower)"""
    if duration == 'short':
        return [
            {'name': 'Push', 'muscle_groups': [('Chest', 1), ('Shoulders', 2), ('Triceps', 1)]},
            {'name': 'Pull', 'muscle_groups': [('Back', 2), ('Biceps', 2)]},
            {'name': 'Legs', 'muscle_groups': [('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)]},
            {'name': 'Upper', 'muscle_groups': [('Chest', 1), ('Shoulders', 1), ('Back', 1)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 1), ('Hamstrings', 1), ('Glutes', 1), ('Core', 1)]}
        ]
    elif duration == 'medium':
        return [
            {'name': 'Push', 'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Triceps', 1)]},
            {'name': 'Pull', 'muscle_groups': [('Back', 3), ('Biceps', 2)]},
            {'name': 'Legs', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]},
            {'name': 'Upper', 'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Back', 2)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]}
        ]
    else:  # long
        return [
            {'name': 'Push', 'muscle_groups': [('Chest', 3), ('Shoulders', 3), ('Triceps', 2)]},
            {'name': 'Pull', 'muscle_groups': [('Back', 3), ('Biceps', 3)]},
            {'name': 'Legs', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]},
            {'name': 'Upper', 'muscle_groups': [('Chest', 2), ('Shoulders', 2), ('Back', 2), ('Triceps', 1), ('Biceps', 1)]},
            {'name': 'Lower', 'muscle_groups': [('Quads', 2), ('Hamstrings', 2), ('Glutes', 1), ('Core', 1)]}
        ]


def get_6_day_templates(duration: str) -> List[SessionTemplate]:
    """6-day Push/Pull/Legs x2"""
    base_ppl = get_3_day_templates(duration)
    # Duplicate the PPL split
    return base_ppl + [
        {'name': f"{t['name']} B", 'muscle_groups': t['muscle_groups']}
        for t in base_ppl
    ]
