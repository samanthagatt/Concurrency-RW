/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import Foundation

/// You should never directly use this class. Always subclass it.
class AsyncOperation: Operation {
  
  private var _state: State = .isReady
  private let stateQueue = DispatchQueue(label: "com.SamanthaGatt.Concurrency.ConcurrentOperationStateQueue")
  
  // Creates thread safe state management
  var state: State {
    get {
      var result: State?
      stateQueue.sync { result = _state }
      // Should never be nil but I don't like force unwrapping
      return result ?? .isFinished
    }
    set {
      let oldValue = state
      willChangeValue(forKey: newValue.rawValue)
      willChangeValue(forKey: oldValue.rawValue)
      
      stateQueue.sync { _state = newValue }
      
      didChangeValue(forKey: oldValue.rawValue)
      didChangeValue(forKey: newValue.rawValue)
    }
  }

  // Make sure to check the base class isReady since it handles scheduling for you
  override var isReady: Bool {
    return super.isReady && state == .isReady
  }
  override var isExecuting: Bool {
    return state == .isExecuting
  }
  override var isFinished: Bool {
    return state == .isFinished
  }
  
  override var isAsynchronous: Bool {
    return true
  }

  // Must not call super.start()
  override func start() {
    if isCancelled {
      state = .isFinished
      return
    }
    main()
    state = .isExecuting
  }
}

extension AsyncOperation {
  enum State: String {
    case isReady, isExecuting, isFinished
  }
}
