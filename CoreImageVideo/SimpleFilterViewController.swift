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
    var filter: CIFilter?
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

        filter = CIFilter(name: "CIHueAdjust", withInputParameters: [:])
    }

    override func viewDidDisappear(animated: Bool) {
        source?.running = false
    }
    
    func setupCameraSource() {
        source = CaptureBufferSource(position: AVCaptureDevicePosition.Front) { [unowned self] (buffer, transform) in
            if let input = CIImage(buffer: buffer)?.imageByApplyingTransform(transform) {
                self.filter?.setValue(self.angleForCurrentTime, forKey: kCIInputAngleKey)
                self.filter?.setValue(input, forKey: kCIInputImageKey)
                self.coreImageView?.image = self.filter?.outputImage //filter(input)
            }
        }
        source?.running = true
    }
}
