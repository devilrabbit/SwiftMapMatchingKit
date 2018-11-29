//
//  Filter.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/13.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol Filter {
    associatedtype TCandidate: StateCandidate
    associatedtype TTransition where TCandidate.TTransition == TTransition
    associatedtype TSample where TCandidate.TSample == TSample
    
    func execute(predecessors: [TCandidate], previous: TSample, sample: TSample) -> [TCandidate]
}
