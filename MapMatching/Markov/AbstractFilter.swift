//
//  AbstractFilter.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/13.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

/// Hidden Markov Model (HMM) filter for online and offline inference of states in a stochastic
/// process.
/// <typeparam name="TCandidate">Candidate implements <see cref="IStateCandidate{TCandidate, TTransition, TSample}"/>.</typeparam>
/// <typeparam name="TTransition">Transition inherits from {@link Transition}.</typeparam>
/// <typeparam name="TSample">Sample implements <see cref="ISample"/>.</typeparam>
open class AbstractFilter<Candidate: StateCandidate, TTransition, TSample>: Filter where Candidate == Candidate.TCandidate, Candidate == Candidate.TCandidate.TCandidate, TTransition == Candidate.TTransition, TSample == Candidate.TSample {
    public typealias TCandidate = Candidate.TCandidate
    public typealias TTransition = Candidate.TCandidate.TTransition
    public typealias TSample = Candidate.TCandidate.TSample
    
    public struct SampleCandidates {
        public private(set) var sample: TSample
        public private(set) var candidates: [TCandidate]
    }
    
    public struct SampleCandidate {
        public private(set) var sample: TSample
        public private(set) var candidate: TCandidate
    }
    
    public struct CandidateProbability {
        public private(set) var candidate: TCandidate
        public private(set) var probability: Double
    }
    
    public struct TransitionProbability {
        public private(set) var transition: TTransition
        public private(set) var probability: Double
    }
    
    /// Gets state vector, which is a set of {@link StateCandidate} objects and with its emission
    /// probability.
    /// - parameter predecessors: Predecessor state candidate <i>s<sub>t-1</sub></i>.
    /// - parameter sample: Measurement sample.
    /// - returns: Set of tuples consisting of a {@link StateCandidate} and its emission probability.
    open func candidates(predecessors: [TCandidate], sample: TSample) -> [CandidateProbability] {
        fatalError("called function in abstract class")
    }
    
    
    /// Gets transition and its transition probability for a pair of {@link StateCandidate}s, which
    /// is a candidate <i>s<sub>t</sub></i> and its predecessor <i>s<sub>t</sub></i>
    /// - parameter predecessor: Tuple of predecessor state candidate <i>s<sub>t-1</sub></i> and its
    /// respective measurement sample
    /// - parameter candidate: Tuple of state candidate <i>s<sub>t</sub></i> and its respective measurement
    /// sample
    /// - returns:
    /// Tuple consisting of the transition from <i>s<sub>t-1</sub></i> to
    /// <i>s<sub>t</sub></i> and its transition probability, or null if there is no
    /// transition.
    open func transition(predecessor: SampleCandidate, candidate: SampleCandidate) -> TransitionProbability {
        fatalError("called function in abstract class")
    }
    
    /// Gets transitions and its transition probabilities for each pair of state candidates
    /// <i>s<sub>t</sub></i> and <i>s<sub>t-1</sub></i>.
    ///
    /// <b>Note:</b> This method may be overridden for better performance, otherwise it defaults to
    /// the method {@link Filter#transition} for each single pair of state candidate and its possible
    /// predecessor.
    ///
    /// - parameter predecessors: Tuple of a set of predecessor state candidate <i>s<sub>t-1</sub></i> and
    /// its respective measurement sample.
    /// - parameter candidates: Tuple of a set of state candidate <i>s<sub>t</sub></i> and its respective
    /// measurement sample.
    /// - returns:
    /// Maps each predecessor state candidate <i>s<sub>t-1</sub> &#8712; S<sub>t-1</sub></i>
    /// to a map of state candidates <i>s<sub>t</sub> &#8712; S<sub>t</sub></i> containing
    /// all transitions from <i>s<sub>t-1</sub></i> to <i>s<sub>t</sub></i> and its
    /// transition probability, or null if there no transition.
    open func transitions(predecessors: SampleCandidates, candidates: SampleCandidates) -> [TCandidate: [TCandidate : TransitionProbability]] {
        let sample = candidates.sample
        let previous = predecessors.sample
        
        var map = [TCandidate : [TCandidate : TransitionProbability]]()
        for predecessor in predecessors.candidates {
            for candidate in candidates.candidates {
                map[predecessor, default: [TCandidate : TransitionProbability]()][candidate] =  transition(predecessor: SampleCandidate(sample: previous, candidate: predecessor), candidate: SampleCandidate(sample: sample, candidate: candidate))
            }
        }
        
        return map
    }
    
    /// Executes Hidden Markov Model (HMM) filter iteration that determines for a given measurement
    /// sample <i>z<sub>t</sub></i>, which is a {@link Sample} object, and of a predecessor state
    /// vector <i>S<sub>t-1</sub></i>, which is a set of {@link StateCandidate} objects, a state
    /// vector <i>S<sub>t</sub></i> with filter and sequence probabilities set.
    ///
    /// <b>Note:</b> The set of state candidates <i>S<sub>t-1</sub></i> is allowed to be empty. This
    /// is either the initial case or an HMM break occured, which is no state candidates representing
    /// the measurement sample could be found.
    ///
    /// - parameter predecessors: State vector <i>S<sub>t-1</sub></i>, which may be empty.
    /// - parameter previous: Previous measurement sample <i>z<sub>t-1</sub></i>.
    /// - parameter sample: Measurement sample <i>z<sub>t</sub></i>.
    /// - returns: State vector <i>S<sub>t</sub></i>, which may be empty if an HMM break occured.
    public func execute(predecessors: [TCandidate], previous: TSample?, sample: TSample) -> [TCandidate] {
        var result = Set<TCandidate>()
        let candidates = self.candidates(predecessors: predecessors, sample: sample)
        //Logger.verbose("{} state candidates", candidates.size())
        
        var normsum = 0.0
        
        if let previous = previous, predecessors.count > 0 {
            let states = Array(Set(candidates.map { $0.candidate }))
            var transitions = self.transitions(
                predecessors: SampleCandidates(sample: previous, candidates: predecessors),
                candidates: SampleCandidates(sample: sample, candidates: states)
            )
            
            for c in candidates {
                let candidate = c.candidate
                candidate.seqprob = -Double.infinity
                
                for predecessor in predecessors {
                    if let transition = transitions[predecessor]?[candidate] {
                        if transition.probability == 0 {
                            continue
                        }
                        
                        candidate.filtprob += transition.probability * predecessor.filtprob
                        
                        let seqprob = predecessor.seqprob + log10(transition.probability) + log10(c.probability)
                        
                        if seqprob > candidate.seqprob {
                            candidate.predecessor = predecessor
                            candidate.transition = transition.transition
                            candidate.seqprob = seqprob
                        }
                    }
                }
                
                if candidate.filtprob == 0 {
                    continue
                }
                
                candidate.filtprob = candidate.filtprob * c.probability
                result.insert(candidate)
                
                normsum += candidate.filtprob
            }
        }
        
        if candidates.count > 0 && result.count == 0 && predecessors.count > 0 {
            //Logger.debug("HMM break - no state transitions")
        }
        
        if result.count == 0 || predecessors.count == 0 {
            for candidate in candidates {
                if candidate.probability == 0 {
                    continue
                }
                let candidate_ = candidate.candidate
                normsum += candidate.probability
                candidate_.filtprob = candidate.probability
                candidate_.seqprob = log10(candidate.probability)
                result.insert(candidate_)
            }
        }
        
        if result.count == 0 {
            //Logger.debug("HMM break - no state emissions");
        }
        
        for candidate in result {
            candidate.filtprob = candidate.filtprob / normsum
        }
        
        //Logger.verbose("{0} state candidates for state update", result.count)
        
        return Array(result)
    }
}
