:- module(memory,
    [ reset_memory/0,
      remember_observation/3,
      remember_context/3,
      remember_association/5,
      remember_concept/4,
      remember_prediction/5,
      remember_correction/5,
      list_observations/1,
      list_associations/1,
      list_concepts/1,
      list_predictions/1,
      list_corrections/1,
      list_context/1,
      forget_observation/1,
      forget_concept/1,
      revise_association/4,
      memory_snapshot/1,
      set_state/2,
      get_state/2,
      clear_state/1,
      next_id/2,
      memory_term/1,
      import_memory_term/1
    ]).

:- use_module(library(lists)).

:- dynamic stored_observation/3.
:- dynamic stored_association/6.
:- dynamic stored_concept/4.
:- dynamic stored_prediction/5.
:- dynamic stored_correction/5.
:- dynamic stored_context/3.
:- dynamic transient_state/2.
:- dynamic id_counter/2.

reset_memory :-
    retractall(stored_observation(_, _, _)),
    retractall(stored_association(_, _, _, _, _, _)),
    retractall(stored_concept(_, _, _, _)),
    retractall(stored_prediction(_, _, _, _, _)),
    retractall(stored_correction(_, _, _, _, _)),
    retractall(stored_context(_, _, _)),
    retractall(transient_state(_, _)),
    retractall(id_counter(_, _)).

remember_observation(Pairs, Meta, Id) :-
    next_id(observation, Id),
    assertz(stored_observation(Id, Pairs, Meta)).

remember_context(Pairs, Source, Id) :-
    next_id(context, Id),
    assertz(stored_context(Id, Pairs, Source)).

remember_association(Known, Key, Value, EvidenceId, AssociationId) :-
    normalize_evidence([EvidenceId], Evidence),
    (   retract(stored_association(AssociationId, Known, Key, Value, Weight0, Evidence0))
    ->  Weight is Weight0 + 1,
        append(Evidence0, Evidence, Evidence1),
        normalize_evidence(Evidence1, Evidence2),
        assertz(stored_association(AssociationId, Known, Key, Value, Weight, Evidence2))
    ;   next_id(association, AssociationId),
        assertz(stored_association(AssociationId, Known, Key, Value, 1, Evidence))
    ).

remember_concept(Name, Structure, EvidenceIds, Meta) :-
    normalize_evidence(EvidenceIds, Evidence),
    retractall(stored_concept(Name, _, _, _)),
    assertz(stored_concept(Name, Structure, Evidence, Meta)).

remember_prediction(Known, Candidates, Selected, Explanation, Id) :-
    next_id(prediction, Id),
    assertz(stored_prediction(Id, Known, Candidates, Selected, Explanation)).

remember_correction(Known, Rejected, Corrected, Evidence, Id) :-
    next_id(correction, Id),
    assertz(stored_correction(Id, Known, Rejected, Corrected, Evidence)).

list_observations(Observations) :-
    findall(observation(Id, Pairs, Meta), stored_observation(Id, Pairs, Meta), Observations).

list_associations(Associations) :-
    findall(association(Id, Known, Key, Value, Weight, Evidence),
        stored_association(Id, Known, Key, Value, Weight, Evidence),
        Associations).

list_concepts(Concepts) :-
    findall(concept(Name, Structure, Evidence, Meta),
        stored_concept(Name, Structure, Evidence, Meta),
        Concepts).

list_predictions(Predictions) :-
    findall(prediction(Id, Known, Candidates, Selected, Explanation),
        stored_prediction(Id, Known, Candidates, Selected, Explanation),
        Predictions).

list_corrections(Corrections) :-
    findall(correction(Id, Known, Rejected, Corrected, Evidence),
        stored_correction(Id, Known, Rejected, Corrected, Evidence),
        Corrections).

list_context(Context) :-
    findall(context(Id, Pairs, Source), stored_context(Id, Pairs, Source), Context).

forget_observation(Id) :-
    stored_observation(Id, _, _),
    retractall(stored_observation(Id, _, _)).

forget_concept(Name) :-
    stored_concept(Name, _, _, _),
    retractall(stored_concept(Name, _, _, _)).

revise_association(Known, Key, Value, Delta) :-
    (   retract(stored_association(Id, Known, Key, Value, Weight0, Evidence))
    ->  Weight is max(0, Weight0 + Delta),
        (   Weight =:= 0
        ->  true
        ;   assertz(stored_association(Id, Known, Key, Value, Weight, Evidence))
        )
    ;   true
    ).

set_state(Key, Value) :-
    retractall(transient_state(Key, _)),
    assertz(transient_state(Key, Value)).

get_state(Key, Value) :-
    transient_state(Key, Value).

clear_state(Key) :-
    retractall(transient_state(Key, _)).

memory_snapshot(snapshot{
    observations:Observations,
    associations:Associations,
    concepts:Concepts,
    predictions:Predictions,
    corrections:Corrections,
    context:Context,
    counts:Counts
}) :-
    list_observations(Observations),
    list_associations(Associations),
    list_concepts(Concepts),
    list_predictions(Predictions),
    list_corrections(Corrections),
    list_context(Context),
    length(Observations, ObservationCount),
    length(Associations, AssociationCount),
    length(Concepts, ConceptCount),
    length(Predictions, PredictionCount),
    length(Corrections, CorrectionCount),
    Counts = counts{
        observations:ObservationCount,
        associations:AssociationCount,
        concepts:ConceptCount,
        predictions:PredictionCount,
        corrections:CorrectionCount
    }.

next_id(Type, Id) :-
    (   retract(id_counter(Type, Current))
    ->  Next is Current + 1
    ;   Next = 1
    ),
    assertz(id_counter(Type, Next)),
    atomic_list_concat([Type, Next], '_', Id).

memory_term(stored_observation(Id, Pairs, Meta)) :-
    stored_observation(Id, Pairs, Meta).
memory_term(stored_association(Id, Known, Key, Value, Weight, Evidence)) :-
    stored_association(Id, Known, Key, Value, Weight, Evidence).
memory_term(stored_concept(Name, Structure, Evidence, Meta)) :-
    stored_concept(Name, Structure, Evidence, Meta).
memory_term(stored_prediction(Id, Known, Candidates, Selected, Explanation)) :-
    stored_prediction(Id, Known, Candidates, Selected, Explanation).
memory_term(stored_correction(Id, Known, Rejected, Corrected, Evidence)) :-
    stored_correction(Id, Known, Rejected, Corrected, Evidence).
memory_term(stored_context(Id, Pairs, Source)) :-
    stored_context(Id, Pairs, Source).
memory_term(id_counter(Type, Value)) :-
    id_counter(Type, Value).

import_memory_term(Term) :-
    valid_memory_term(Term),
    assertz(Term),
    !.
import_memory_term(Term) :-
    throw(error(domain_error(memory_term, Term), import_memory_term/1)).

valid_term_list(Value) :- is_list(Value).
valid_meta(_).
valid_atomic_or_term(Value) :- nonvar(Value).

valid_memory_term(stored_observation(Id, Pairs, Meta)) :-
    atom(Id), valid_term_list(Pairs), valid_meta(Meta).
valid_memory_term(stored_association(Id, Known, Key, Value, Weight, Evidence)) :-
    atom(Id), valid_term_list(Known), nonvar(Key), nonvar(Value), integer(Weight), valid_term_list(Evidence).
valid_memory_term(stored_concept(Name, Structure, Evidence, Meta)) :-
    atom(Name), valid_atomic_or_term(Structure), valid_term_list(Evidence), valid_meta(Meta).
valid_memory_term(stored_prediction(Id, Known, Candidates, Selected, Explanation)) :-
    atom(Id), valid_term_list(Known), valid_term_list(Candidates), valid_atomic_or_term(Selected), valid_atomic_or_term(Explanation).
valid_memory_term(stored_correction(Id, Known, Rejected, Corrected, Evidence)) :-
    atom(Id), valid_term_list(Known), valid_atomic_or_term(Rejected), valid_atomic_or_term(Corrected), valid_atomic_or_term(Evidence).
valid_memory_term(stored_context(Id, Pairs, Source)) :-
    atom(Id), valid_term_list(Pairs), valid_atomic_or_term(Source).
valid_memory_term(id_counter(Type, Value)) :-
    atom(Type), integer(Value), Value >= 0.

normalize_evidence(Evidence0, Evidence) :-
    exclude(var, Evidence0, Evidence1),
    sort(Evidence1, Evidence).
