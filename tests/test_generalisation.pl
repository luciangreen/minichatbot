:- begin_tests(generalisation).

:- use_module('/home/runner/work/minichatbot/minichatbot/src/generalise.pl').
:- use_module('/home/runner/work/minichatbot/minichatbot/src/chatbot.pl').
:- use_module('/home/runner/work/minichatbot/minichatbot/src/concepts.pl').


test(generalises_varying_dimensions) :-
    generalise_observations([
        [actor-robot, action-finds, object-father],
        [actor-robot, action-finds, object-mother],
        [actor-robot, action-finds, object-child]
    ], observation(Generalised)),
    memberchk(actor-robot, Generalised),
    memberchk(action-finds, Generalised),
    memberchk(object-one_of([child, father, mother]), Generalised).

test(compresses_repeated_structure_into_concept, [setup(bootstrap)]) :-
    learn_observation([actor-father, action-teaches, object-child], _),
    learn_observation([actor-father, action-teaches, object-child], _),
    learn_observation([actor-father, action-teaches, object-child], _),
    concept_candidates(Concepts),
    member(concept(_, and([action-teaches, actor-father, object-child]), _, _), Concepts).

:- end_tests(generalisation).
