//
//  StaticVideoViewController.swift
//  CoreImageVideo
//
//  Created by Chris Eidhof on 03/04/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit
import AVFoundation

extension CGRect {
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}


class StaticVideoViewController: UIViewController {
    var source: SampleBufferSource?
    var coreImageView: CoreImageView?
    var videoSource: VideoSampleBufferSource?
    
    var angleForCurrentTime: Float {
        return Float(NSDate.timeIntervalSinceReferenceDate() % M_PI*2)
    }
    
    override func loadView() {
        coreImageView = CoreImageView(frame: CGRect())
        self.view = coreImageView
    }
    
    override func viewDidAppear(animated: Bool) {
        let url = NSBundle.mainBundle().URLForResource("Cat", withExtension: "mp4")!
        videoSource = VideoSampleBufferSource(url: url) { [unowned self] buffer in
            let image = CIImage(CVPixelBuffer: buffer)
            let background = kaleidoscope()(image)
            let mask = radialGradient(image.extent().center, CGFloat(self.angleForCurrentTime) * 100)
            let output = blendWithMask(image, mask)(background)
            self.coreImageView?.image = output
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        source?.running = false
    }
    
    func setupCameraSource() {
        source = SampleBufferSource(position: AVCaptureDevicePosition.Front) { [unowned self] (buffer, transform) in
            let input = ciImage(buffer).imageByApplyingTransform(transform)
            let filter = hueAdjust(self.angleForCurrentTime)
//            self.coreImageView?.image = filter(input)
        }
        source?.running = true
    }
}