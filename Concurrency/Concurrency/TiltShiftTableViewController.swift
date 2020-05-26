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

import UIKit

class TiltShiftTableViewController: UITableViewController {
  private let queue = OperationQueue()
  private var urls: [URL] = []
  private var operations: [IndexPath: (downloadOp: NetworkImageOperation, tiltShiftOp: TiltShiftOperation)] = [:]
  private var images: [IndexPath: UIImage] = [:]
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    guard let plist = Bundle.main.url(forResource: "Photos", withExtension: "plist"),
      let contents = try? Data(contentsOf: plist),
      let serial = try? PropertyListSerialization.propertyList(from: contents, format: nil),
      let serialURLs = serial as? [String] else { return }
    
    urls = serialURLs.compactMap(URL.init)
  }

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 10
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "normal", for: indexPath) as! PhotoCell
    cell.display(image: nil)
    
    // If image has already been fetched
    if let image = images[indexPath] {
      cell.display(image: image)
      return cell
    }
    
    // Create new ops
    let downloadOp = NetworkImageOperation(url: urls[indexPath.row])
    let tiltShiftOp = TiltShiftOperation()
    tiltShiftOp.addDependency(downloadOp)
    tiltShiftOp.onImageProcessed = { image in
      // Store image in cache
      self.images[indexPath] = image
      guard let cell = tableView.cellForRow(at: indexPath) as? PhotoCell else { return }
      cell.isLoading = false
      cell.display(image: image)
    }
     queue.addOperations([downloadOp, tiltShiftOp], waitUntilFinished: false)
    
    // If old ops have already been started make sure they get cancelled
    if let oldOps = operations[indexPath] {
      oldOps.downloadOp.cancel()
      oldOps.tiltShiftOp.cancel()
    }
    // Store the new ops in cache
    operations[indexPath] = (downloadOp: downloadOp, tiltShiftOp: tiltShiftOp)
    return cell
  }
  
  override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    
    guard let ops = operations[indexPath] else { return }
    ops.downloadOp.cancel()
    ops.tiltShiftOp.cancel()
  }
}

// TODO: Look into prefetching for table views and collection views introduced in iOS 10
