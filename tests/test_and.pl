:- begin_tests(and_kernel).

:- use_module('/home/runner/work/minichatbot/minichatbot/src/and.pl').

test(normalize_nested_and) :-
    normalize_and(and(red, and(ball, round)), and([red, ball, round])).

test(and_contains) :-
    and_contains(and([robot, remembers, father]), remembers).

:- end_tests(and_kernel).
