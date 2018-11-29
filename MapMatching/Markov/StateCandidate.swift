//
//  StateCandidate.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/13.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public protocol StateCandidate: class, Hashable {
    associatedtype TCandidate: StateCandidate
    associatedtype TTransition
    associatedtype TSample

    var seqprob: Double { get set }
    var filtprob: Double { get set }
    var predecessor: TCandidate? { get set }
    var transition: TTransition? { get set }
}

public extension StateCandidate {
    
    var hasTransition: Bool {
        return self.transition != nil
    }
}
