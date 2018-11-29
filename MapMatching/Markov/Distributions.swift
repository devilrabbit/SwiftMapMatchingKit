//
//  Distributions.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/10/13.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

/**
 * Copyright (C) 2015-2016, BMW Car IT GmbH and BMW AG
 * Author: Stefan Holder (stefan.holder@bmw.de)
 *
 * Copyright (C) 2017 Wei "oldrev" Li (oldrev@gmail.com)
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation

/// Implements various probability distributions.
public final class Distributions {
    
    public static func normalDistribution(sigma: Double, x: Double) -> Double {
        return 1.0 / (sqrt(2.0 * .pi) * sigma) * exp(-0.5 * pow(x / sigma, 2))
    }
    
    /// Use this function instead of Math.log(normalDistribution(sigma, x)) to avoid an
    /// arithmetic underflow for very small probabilities.
    /// - parameter sigma:
    /// - parameter x:
    /// - returns:
    public static func logNormalDistribution(sigma: Double, x: Double) -> Double {
        return log(1.0 / (sqrt(2.0 * .pi) * sigma)) + (-0.5 * pow(x / sigma, 2))
    }
    
    ///
    /// - parameter beta: beta =1/lambda with lambda being the standard exponential distribution rate parameter
    /// - parameter x:
    /// - returns:
    public static func exponentialDistribution(beta: Double, x: Double) -> Double {
        return 1.0 / beta * exp(-x / beta)
    }
    
    /// Use this function instead of Math.log(exponentialDistribution(beta, x)) to avoid an
    /// arithmetic underflow for very small probabilities.
    /// - parameter beta: beta = 1 / lambda with lambda being the standard exponential distribution rate parameter
    /// - parameter x:
    /// - returns:
    public static func logExponentialDistribution(beta: Double, x: Double) -> Double {
        return log(1.0 / beta) - (x / beta)
    }
}
