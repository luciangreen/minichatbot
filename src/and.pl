:- module(and_kernel,
    [ compose_and/2,
      normalize_and/2,
      and_components/2,
      and_contains/2
    ]).

compose_and(Components, And) :-
    normalize_and(and(Components), And).

normalize_and(Term, and(Normalized)) :-
    and_components(Term, Components),
    maplist(normalize_component, Components, Normalized).

and_components(and(Components), Flattened) :-
    is_list(Components),
    !,
    foldl(append_components, Components, [], Flattened0),
    exclude(==(none), Flattened0, Flattened).
and_components(and(A, B), Flattened) :-
    !,
    and_components(A, Left),
    and_components(B, Right),
    append(Left, Right, Flattened).
and_components([], []) :-
    !.
and_components(Component, [Component]).

and_contains(And, Component) :-
    and_components(And, Components),
    memberchk(Component, Components).

append_components(Component, Acc, Flattened) :-
    and_components(Component, Nested),
    append(Acc, Nested, Flattened).

normalize_component(Component, Normalized) :-
    (   Component = and(_, _)
    ;   Component = and(_)
    ),
    !,
    normalize_and(Component, Normalized).
normalize_component(Component, Component).
