//
//  ViewController.swift
//  CoreImageVideo
//
//  Created by Chris Eidhof on 03/04/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit
import AVFoundation

class SimpleFilterViewController: UIViewController {
    var source: CaptureBufferSource?
    var coreImageView: CoreImageView?

    var angleForCurrentTime: Float {
        return Float(NSDate.timeIntervalSinceReferenceDate() % M_PI*2)
    }

    override func loadView() {
        coreImageView = CoreImageView(frame: CGRect())
        self.view = coreImageView
    }
    
    override func viewDidAppear(animated: Bool) {
        setupCameraSource()

    }

    override func viewDidDisappear(animated: Bool) {
        source?.running = false
    }
    
    func setupCameraSource() {
        source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) { [unowned self] (buffer, transform) in
            guard let input = CIImage(buffer: buffer)?.imageByApplyingTransform(transform) else {
                return
            }
            let filter = CIFilter(name: "CIHueAdjust", withInputParameters: [
                kCIInputAngleKey: self.angleForCurrentTime,
                kCIInputImageKey: input
                ])
            dispatch_sync(dispatch_get_main_queue()) {
                self.coreImageView?.image = filter?.outputImage
            }
        }
        source?.running = true
    }
}
