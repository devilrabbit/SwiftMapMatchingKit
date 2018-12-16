//
//  MatcherCandidate.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/14.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public final class MatcherCandidate: StateCandidate {
    public typealias TSample = MatcherSample
    
    public var seqprob: Double = 0
    public var filtprob: Double = 0
    public var predecessor: MatcherCandidate?
    public var transition: MatcherTransition?

    public var hasTransition: Bool {
        return transition != nil
    }

    public var sample: MatcherSample
    public private(set) var point: RoadPoint
    
    public init(sample: MatcherSample, point: RoadPoint) {
        self.sample = sample
        self.point = point
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(point)
    }
    
    public static func == (lhs: MatcherCandidate, rhs: MatcherCandidate) -> Bool {
        return lhs === rhs
    }
}
