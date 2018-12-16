//
//  DownloaderManager.swift
//  MapMatching
//
//  Created by devilrabbit on 2018/12/16.
//  Copyright (c) 2018 devilrabbit. All rights reserved.
//

import Foundation

public class ProgressManager {
    
    public var autoRun: Bool = true
    public var isConcurrently: Bool = false
    
    private var tasks: [AnyHashable : ProgressReporting]
    private var observers: [AnyHashable : NSKeyValueObservation]
    
    public init() {
        self.tasks = [:]
        self.observers = [:]
    }
    
    public func task(for key: AnyHashable) -> ProgressReporting? {
        return tasks[key]
    }
    
    public func add(_ task: ProgressReporting, for key: AnyHashable) {
        if let observer = self.observers[key] {
            observer.invalidate()
        }
        self.tasks.removeValue(forKey: key)
        
        self.tasks[key] = task
        self.observers[key] = task.progress.observe(\.fractionCompleted, options: .new) { progress, _ in
            if progress.isFinished {
                if let observer = self.observers.removeValue(forKey: key) {
                    observer.invalidate()
                }
            }
            self.execute()
        }
        
        if autoRun {
            self.execute()
        }
    }
    
    @discardableResult
    public func remove(forKey key: AnyHashable) -> ProgressReporting? {
        if let observer = self.observers[key] {
            observer.invalidate()
        }
        return self.tasks.removeValue(forKey: key)
    }
    
    public func execute() {
        if isConcurrently {
            for task in tasks.values {
                if task.progress.isPaused && !task.progress.isFinished {
                    task.progress.resume()
                }
            }
        } else {
            tasks.values.first(where: { $0.progress.isPaused && !$0.progress.isFinished })?.progress.resume()
        }
    }
}

public class DownloadTask: NSObject, ProgressReporting {
    
    public var progress: Progress
    public var files: [URL]
    
    private var queue: OperationQueue
    
    public init(queue: OperationQueue) {
        self.progress = Progress()
        self.files = [URL]()
        self.queue = queue
        
        super.init()
        
        self.progress.pausingHandler = {
            self.suspend()
        }
        self.progress.resumingHandler = {
            self.resume()
        }
        self.progress.pause()
    }

    public func execute() {
        for file in files {
            queue.addOperation {
                // download sync.
                print("download \(file)")
            }
        }
        queue.isSuspended = false
    }
    
    public func resume() {
        queue.isSuspended = false
    }
    
    public func suspend() {
       queue.isSuspended = true
    }
    
}
