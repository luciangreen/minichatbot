:- module(prediction,
    [ predict_known_dimensions/2,
      best_candidate/2,
      candidate_explanation/3
    ]).

:- use_module(library(lists)).
:- use_module(dimensions).
:- use_module(memory).
:- use_module(similarity).

predict_known_dimensions(Known0, candidates(Candidates)) :-
    observation_pairs(Known0, Known),
    findall(candidate(Key-Value, Score, observation(Id)),
        observation_candidate(Known, Key, Value, Score, Id),
        ObservationCandidates),
    findall(candidate(Key-Value, Score, association(Id)),
        association_candidate(Known, Key, Value, Score, Id),
        AssociationCandidates),
    append(ObservationCandidates, AssociationCandidates, RawCandidates),
    consolidate_candidates(Known, RawCandidates, Consolidated),
    sort_candidates(Consolidated, Candidates).

best_candidate(candidates([candidate(Pair, Score, Evidence)|_]), best(Pair, Score, Evidence)).

candidate_explanation(Known0, Pair, explanation{
    known:Known,
    candidate:Pair,
    observations:ObservationEvidence,
    associations:AssociationEvidence,
    corrections:Corrections
}) :-
    observation_pairs(Known0, Known),
    list_observations(Observations),
    include(observation_supports(Known, Pair), Observations, ObservationEvidence),
    list_associations(Associations),
    include(association_supports(Known, Pair), Associations, AssociationEvidence),
    list_corrections(AllCorrections),
    include(correction_relevant(Known, Pair), AllCorrections, Corrections).

observation_candidate(Known, Key, Value, Score, Id) :-
    list_observations(Observations),
    member(observation(Id, Pairs, _), Observations),
    subset_pairs(Known, Pairs),
    member(Key-Value, Pairs),
    \+ memberchk(Key-_, Known),
    similarity(Known, Pairs, SimilarityScore),
    Score is 1.0 + SimilarityScore.

association_candidate(Known, Key, Value, Score, Id) :-
    list_associations(Associations),
    member(association(Id, Pattern, Key, Value, Weight, _Evidence), Associations),
    similarity(Known, Pattern, SimilarityScore),
    SimilarityScore > 0,
    \+ memberchk(Key-_, Known),
    Score is Weight + SimilarityScore.

consolidate_candidates(Known, RawCandidates, Candidates) :-
    findall(Key-Value,
        member(candidate(Key-Value, _, _), RawCandidates),
        Keys0),
    sort(Keys0, Keys),
    findall(candidate(Key-Value, Score, Evidence),
        ( member(Key-Value, Keys),
          findall(Candidate,
              member(Candidate, RawCandidates),
              Matching),
          include(matches_pair(Key-Value), Matching, PairMatches),
          PairMatches \= [],
          score_candidates(Known, Key-Value, PairMatches, Score, Evidence)
        ),
        Candidates).

matches_pair(Pair, candidate(Pair, _, _)).

score_candidates(Known, Pair, Candidates, Score, evidence(Reasons)) :-
    findall(Value,
        member(candidate(_, Value, _), Candidates),
        Scores),
    sum_list(Scores, RawScore),
    findall(Evidence,
        member(candidate(_, _, Evidence), Candidates),
        Reasons0),
    sort(Reasons0, Reasons1),
    correction_adjustment(Known, Pair, Adjustment, CorrectionReasons),
    append(Reasons1, CorrectionReasons, Reasons),
    Score is RawScore + Adjustment.

correction_adjustment(Known, Pair, Adjustment, Reasons) :-
    list_corrections(Corrections),
    findall(Change-Id,
        ( member(correction(Id, CorrectionKnown, Rejected, Corrected, _), Corrections),
          similarity(Known, CorrectionKnown, SimilarityScore),
          SimilarityScore > 0,
          ( Pair == Corrected -> Change is 2.0 * SimilarityScore
          ; Pair == Rejected -> Change is -3.0 * SimilarityScore
          )
        ),
        Changes),
    findall(Id, member(_-Id, Changes), Reasons),
    findall(Change, member(Change-_, Changes), Deltas),
    sum_list(Deltas, Adjustment).

sort_candidates(Candidates0, Candidates) :-
    include(positive_candidate, Candidates0, Candidates1),
    predsort(compare_candidates, Candidates1, Candidates).

positive_candidate(candidate(_, Score, _)) :-
    Score > 0.

compare_candidates(Order, candidate(_, ScoreA, _), candidate(_, ScoreB, _)) :-
    compare(Order0, ScoreB, ScoreA),
    ( Order0 = (=) -> Order = (<) ; Order = Order0 ).

subset_pairs([], _).
subset_pairs([Pair|Rest], Pairs) :-
    memberchk(Pair, Pairs),
    subset_pairs(Rest, Pairs).

observation_supports(Known, Pair, observation(_Id, Pairs, _Meta)) :-
    subset_pairs(Known, Pairs),
    memberchk(Pair, Pairs).

association_supports(Known, Pair, association(_Id, Pattern, Key, Value, _Weight, _Evidence)) :-
    Pair = Key-Value,
    similarity(Known, Pattern, Score),
    Score > 0.

correction_relevant(Known, Pair, correction(_Id, CorrectionKnown, Rejected, Corrected, _)) :-
    similarity(Known, CorrectionKnown, Score),
    Score > 0,
    (Pair == Rejected ; Pair == Corrected).
