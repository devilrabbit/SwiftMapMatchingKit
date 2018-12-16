//
//  KState.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/13.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public class KState<Candidate: StateCandidate, TTransition, TSample: Sample> : StateMemory where Candidate == Candidate.TCandidate, TTransition == Candidate.TCandidate.TTransition, TSample == Candidate.TSample, TSample == Candidate.TCandidate.TSample {
    public typealias TCandidate = Candidate.TCandidate
    public typealias TTransition = Candidate.TTransition
    public typealias TSample = Candidate.TSample
    
    private struct SequenceEntry {
        public var candidates: [TCandidate]
        public var sample: TSample
        public var estimatedCandidate: TCandidate?
    }
    
    private var _sequence: [SequenceEntry]
    private var _counters: [TCandidate : Int]
    
    public var sequenceSizeBound: Int = -1
    public var sequenceIntervalBound: TimeInterval = -TimeInterval.greatestFiniteMagnitude
    
    /// Creates empty <see cref="KState{TCandidate, TTransition, TSample}"/> object with default parameters, i.e. capacity is unbounded.
    public convenience init() {
        self.init(k: -1, t: -TimeInterval.greatestFiniteMagnitude)
    }
    
    public convenience init(k: Int) {
        self.init(k: k, t: -TimeInterval.greatestFiniteMagnitude)
    }
    
    public convenience init(t: TimeInterval) {
        self.init(k: -1, t: t)
    }
    
    /// Creates an empty <see cref="KState{TCandidate, TTransition, TSample}"/> object and sets <i>&kappa;</i> and <i>&tau;</i> parameters.
    /// - parameter k: <i>&kappa;</i> parameter bounds the length of the state sequence to at most <i>&kappa;+1</i> states, if <i>&kappa; &ge; 0</i>.
    /// - parameter t: <i>&tau;</i> parameter bounds length of the state sequence to contain only states for the past <i>&tau;</i> milliseconds.
    public init(k: Int, t: TimeInterval) {
        self.sequenceSizeBound = k
        self.sequenceIntervalBound = t
        self._sequence = [SequenceEntry]()
        self._counters = [TCandidate : Int]()
    }
    
    public var isEmpty: Bool {
        return _counters.isEmpty
    }
    
    public var count: Int {
        return _counters.count
    }
    
    public var sample: TSample? {
        if _sequence.count == 0 {
            return nil
        }
        return _sequence.last?.sample
    }
                
    public var time: Date {
        precondition(_sequence.count > 0)
        return self.sample?.time ?? Date.distantPast
    }
            
    /// Gets the sequence of measurements <i>z<sub>0</sub>, z<sub>1</sub>, ..., z<sub>t</sub></i>.
    /// - returns: List with the sequence of measurements.
    public var samples: [TSample] {
        return _sequence.map { $0.sample }
    }
                
    public func update(vector: [TCandidate], sample: TSample) {
        if vector.isEmpty {
            return
        }
                
        if _sequence.count > 0 && (_sequence.last?.sample.time ?? Date.distantPast) > sample.time {
            preconditionFailure("out-of-order state update is prohibited")
        }
        
        var kestimate: TCandidate?
        for candidate in vector {
            _counters[candidate] = 0
            if let predecessor = candidate.predecessor {
                if !_counters.keys.contains(predecessor) ||
                    !(_sequence.last?.candidates.contains(predecessor) ?? true) {
                    preconditionFailure("Inconsistent update vector.")
                }
                _counters[predecessor, default: 0] += 1
            }
            
            if kestimate == nil || candidate.seqprob > kestimate!.seqprob {
                kestimate = candidate
            }
        }
                
        if let last = _sequence.last {
            var deletes = [TCandidate]()
            for candidate in last.candidates {
                if _counters[candidate] == 0 {
                    deletes.append(candidate)
                }
            }
                
            let size = last.candidates.count
            for candidate in deletes {
                if deletes.count != size || candidate != last.estimatedCandidate {
                    self.remove(candidate: candidate, at: _sequence.count - 1)
                }
            }
        }
        
        _sequence.append(SequenceEntry(candidates: vector, sample: sample, estimatedCandidate: kestimate))
        
        while true {
            let interval = sample.time.timeIntervalSince1970 - (_sequence.first?.sample.time.timeIntervalSince1970 ?? 0.0)
            if (sequenceSizeBound < 0 || _sequence.count <= sequenceSizeBound + 1) &&
                (sequenceIntervalBound < 0 || round(interval * 1000) / 1000 <= sequenceIntervalBound) {
                break
            }
            
            guard let deletes = _sequence.first?.candidates else { break }
            _sequence.remove(at: 0)
            
            for candidate in deletes {
                _counters.removeValue(forKey: candidate)
            }
            
            for candidate in _sequence.first?.candidates ?? [] {
                candidate.predecessor = nil
            }
        }
        
        assert(sequenceSizeBound < 0 || _sequence.count <= sequenceSizeBound + 1, "invalid operation")
    }
                
    private func remove(candidate: TCandidate, at index: Int) {
        if _sequence[index].estimatedCandidate == candidate {
            return
        }
        
        _counters.removeValue(forKey: candidate)
        _sequence[index].candidates.remove(value: candidate)
    
        if let predecessor = candidate.predecessor {
            _counters[predecessor, default: 0] -= 1
            if _counters[predecessor] ?? 0 <= 0 {
                self.remove(candidate: predecessor, at: index - 1)
            }
        }
    }
                
    public func vector() -> [TCandidate] {
        if _sequence.count == 0 {
            return []
        }
        return Array(Set(_sequence.last?.candidates ?? []))
    }
                
    public func estimate() -> TCandidate? {
        if _sequence.count == 0 {
            return nil
        }
        
        var estimate: TCandidate?
        for candidate in _sequence.last?.candidates ?? [] {
            if estimate == nil || candidate.filtprob > estimate!.filtprob {
                estimate = candidate
            }
        }
        return estimate
    }

    /// Gets the most likely sequence of state candidates <i>s<sub>0</sub>, s<sub>1</sub>, ...,
    /// s<sub>t</sub></i>.
    /// - returns: List of the most likely sequence of state candidates.
    public func sequence() -> [TCandidate] {
        if _sequence.count == 0 {
            return []
        }
        
        var results = [TCandidate]()
        var kestimate = _sequence.last?.estimatedCandidate
        
        for entry in _sequence.reversed() {
            if let estimate = kestimate ?? entry.estimatedCandidate {
                results.append(estimate)
                kestimate = estimate.predecessor
            }
        }
        
        if _sequence.count > 0 {
            return results.reversed()
        }
        
        return results
    }
                
}

extension Array where Element: Equatable {
    mutating func remove(value: Element) {
        if let index = self.index(of: value) {
            self.remove(at: index)
        }
    }
}
