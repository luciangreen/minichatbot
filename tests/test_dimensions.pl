:- begin_tests(dimensions).

:- use_module('../src/dimensions.pl').

test(infer_dimensions_from_text) :-
    infer_dimensions("robot finds father", observation(Pairs)),
    memberchk(actor-robot, Pairs),
    memberchk(action-finds, Pairs),
    memberchk(object-father, Pairs).

test(discover_dimension_difference) :-
    discover_dimension(observation([actor-robot, object-father, action-finds]), observation([actor-robot, object-father, action-protects]), discovery(action, finds, protects)).

:- end_tests(dimensions).
