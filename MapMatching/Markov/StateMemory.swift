//
//  StateMemory.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/13.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol StateMemory {
    associatedtype TCandidate: StateCandidate where TCandidate.TSample: Sample
    associatedtype TTransition
    associatedtype TSample
    
    /// Indicates if the state is empty.
    /// Boolean indicating if the state is empty.
    var isEmpty: Bool { get }
    
    /// Gets the size of the state, which is the number of state candidates organized in the data structure.
    /// Size of the state, which is the number of state candidates.
    var count: Int { get }
    
    /// Sample object of the most recent update.
    /// Sample object of the most recent update or null if there hasn't been any update yet.
    var sample: TSample? { get }
    
    /// Time of the last state update in milliseconds epoch time.
    var time: Date { get }
    
    /// Updates the state with a state vector which is a set of {@link StateCandidate} objects with
    /// its respective measurement, which is a sample object.
    /// - parameter vector: vector State vector for update of the state.
    /// - parameter sample: sample Sample measurement of the state vector.
    func update(vector: [TCandidate], sample: TSample)
    
    /// Gets state vector of the last update.
    /// - returns: State vector of the last update, or an empty set if there hasn't been any update yet.
    func vector() -> [TCandidate]
    
    /// Gets a state estimate which is the most likely state candidate of the last update, with
    /// respect to state candidate's filter probability (<see cref="AbstractStateCandidate{TCandidate, TTransition, TSample}.Filtprob"/>).
    /// - returns: State estimate, which is most likely state candidate.
    func estimate() -> TCandidate?
}
