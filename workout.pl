% ==============================================================================
% 1. FACTS: MULTIPLE WORKOUT OPTIONS & INTENSITIES PER DAY
% ==============================================================================

workout_option(monday, upper_push, high).
workout_option(monday, full_body_beginner, moderate).
workout_option(monday, rest, low).

workout_option(tuesday, lower_squat, high).
workout_option(tuesday, upper_pull, moderate).
workout_option(tuesday, rest, low).

workout_option(wednesday, full_body_beginner, high).
workout_option(wednesday, active_recovery, low).
workout_option(wednesday, rest, low).

workout_option(thursday, lower_hinge, high).
workout_option(thursday, upper_push, moderate).
workout_option(thursday, rest, low).

workout_option(friday, full_body_cardio, moderate).
workout_option(friday, upper_pull, high).
workout_option(friday, rest, low).

% EXERCISE DATABASE & SPLIT EXECUTION VALIDATOR
% Mapping specific beginner-friendly exercises to each workout split
exercise_for_split(upper_push, bench_press).
exercise_for_split(upper_push, overhead_press).
exercise_for_split(upper_push, tricep_extension).

exercise_for_split(lower_squat, barbell_squat).
exercise_for_split(lower_squat, leg_press).
exercise_for_split(lower_squat, calf_raises).

exercise_for_split(upper_pull, pull_up).
exercise_for_split(upper_pull, barbell_row).
exercise_for_split(upper_pull, bicep_curl).

exercise_for_split(lower_hinge, romanian_deadlift).
exercise_for_split(lower_hinge, hamstring_curl).
exercise_for_split(lower_hinge, plank).

exercise_for_split(full_body_beginner, goblet_squat).
exercise_for_split(full_body_beginner, push_up).
exercise_for_split(full_body_beginner, dumbbell_row).

exercise_for_split(full_body_cardio, stationary_bike).
exercise_for_split(full_body_cardio, jump_rope).

exercise_for_split(active_recovery, light_walking).
exercise_for_split(active_recovery, mobility_stretching).

exercise_for_split(rest, complete_rest).

% ==============================================================================
% 2. REAL-WORLD PHYSIOLOGICAL RULES & CONSTRAINTS
% ==============================================================================

% Rolling 3-Day Overtraining Guardrail
no_rolling_overtraining(high, high, high) :- !, fail.
no_rolling_overtraining(_, _, _).

% Muscle Group Spacing (Lower Body Conflict Check)
safe_muscle_spacing(lower_squat, lower_hinge) :- !, fail.
safe_muscle_spacing(lower_hinge, lower_squat) :- !, fail.
safe_muscle_spacing(_, _).

% Wednesday Specific Recovery Rule
valid_wednesday(lower_squat, MonWorkout, MonIntensity, TueWorkout, _) :-
    ( MonWorkout \= upper_push 
    ; MonIntensity \= high 
    ; TueWorkout = rest ).
valid_wednesday(Workout, _, _, _, _) :-
    Workout \= lower_squat.

% Helper: Count active workout days (excluding rest)
count_workouts([], 0).
count_workouts([day(_, rest, _) | Rest], Count) :-
    count_workouts(Rest, Count).
count_workouts([day(_, Workout, _) | Rest], Count) :-
    Workout \= rest,
    count_workouts(Rest, SubCount),
    Count is SubCount + 1.


% ==============================================================================
% 3. FULL-WEEK BACKGROUND VALIDATOR (valid_plan_full)
% ==============================================================================

valid_plan_full(Schedule, TargetDays) :-
    Schedule = [
        day(monday, MonW, MonI),
        day(tuesday, TueW, TueI),
        day(wednesday, WedW, WedI),
        day(thursday, ThuW, ThuI),
        day(friday, FriW, FriI)
    ],
    % Validate choices against facts
    workout_option(monday, MonW, MonI),
    workout_option(tuesday, TueW, TueI),
    workout_option(wednesday, WedW, WedI),
    workout_option(thursday, ThuW, ThuI),
    workout_option(friday, FriW, FriI),
    
    % Wednesday conditional recovery rule
    valid_wednesday(WedW, MonW, MonI, TueW, TueI),
    
    % Rolling safety checks
    no_rolling_overtraining(MonI, TueI, WedI),
    no_rolling_overtraining(TueI, WedI, ThuI),
    no_rolling_overtraining(WedI, ThuI, FriI),
    
    safe_muscle_spacing(MonW, TueW),
    safe_muscle_spacing(TueW, WedW),
    safe_muscle_spacing(WedW, ThuW),
    safe_muscle_spacing(ThuW, FriW),
    
    % Match target frequency split
    count_workouts(Schedule, TargetDays).


% ==============================================================================
% 4. USER-FACING WRAPPER WITH COMPACT OUTPUT FILTER
% ==============================================================================

filter_active_days([], []).
filter_active_days([day(_, rest, _) | Rest], Filtered) :-
    filter_active_days(Rest, Filtered).
filter_active_days([day(Day, Workout, Intensity) | Rest], [day(Day, Workout, Intensity) | Filtered]) :-
    Workout \= rest,
    filter_active_days(Rest, Filtered).

valid_plan(CompactSchedule, TargetDays) :-
    valid_plan_full(FullSchedule, TargetDays),
    filter_active_days(FullSchedule, CompactSchedule).


% Rule A: Query individual exercises belonging to a split
split_exercise(Split, Exercise) :-
    exercise_for_split(Split, Exercise).


% Rule B: Validate if a list of performed exercises matches a specific split
% (Checks that every exercise in the student's list is legally part of that split)
valid_split_execution(_, []).
valid_split_execution(Split, [Exercise | RestOfExercises]) :-
    exercise_for_split(Split, Exercise),
    valid_split_execution(Split, RestOfExercises).
