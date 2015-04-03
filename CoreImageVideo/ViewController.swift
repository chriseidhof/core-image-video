//
//  ViewController.swift
//  CoreImageVideo
//
//  Created by Chris Eidhof on 03/04/15.
//  Copyright (c) 2015 objc.io. All rights reserved.
//

import UIKit
import AVFoundation
import GLKit


extension CGAffineTransform {
    
    init(angle: CGFloat) {
        let t = CGAffineTransformMakeRotation(angle)
        self.init(a: t.a, b: t.b, c: t.c, d: t.d, tx: t.tx, ty: t.ty)

    }
    
    func scale(sx: CGFloat, sy: CGFloat) -> CGAffineTransform {
        return CGAffineTransformScale(self, sx, sy)
    }
}




struct SampleBufferSource {
    
    typealias BufferConsumer = (CMSampleBuffer, CGAffineTransform) -> ()
    
    class SampleBufferDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        let callback: CMSampleBuffer -> ()
        
        init(_ callback: CMSampleBuffer -> ()) {
            self.callback = callback
        }
        
        func captureOutput(captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, fromConnection connection: AVCaptureConnection!) {
            callback(sampleBuffer)
        }
    }
    
    
    let captureSession: AVCaptureSession
    let delegate: SampleBufferDelegate
    var running: Bool = false {
        didSet {
            if running {
                captureSession.startRunning()
            } else {
                captureSession.stopRunning()
            }
        }
    }
    
    init?(device: AVCaptureDevice, transform: CGAffineTransform, callback: BufferConsumer) {
        captureSession = AVCaptureSession()
        if let deviceInput = AVCaptureDeviceInput(device: device, error: nil) {
            if captureSession.canAddInput(deviceInput) {
                captureSession.addInput(deviceInput)
                let dataOutput = AVCaptureVideoDataOutput()
                dataOutput.alwaysDiscardsLateVideoFrames = true
                dataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
                delegate = SampleBufferDelegate { buffer in
                    callback(buffer, transform)
                }
                dataOutput.setSampleBufferDelegate(delegate, queue: dispatch_get_main_queue())
                captureSession.addOutput(dataOutput)
                captureSession.commitConfiguration()
                return
            }
        }
        return nil
    }
    
    static func frontFacingCamera() -> (AVCaptureDevice, CGAffineTransform)? {
        if let camera = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo).filter({
            $0.position == AVCaptureDevicePosition.Front
        }).first as? AVCaptureDevice {
            let transform = CGAffineTransform(angle: -CGFloat(M_PI_2)).scale(1, sy: -1)
            return (camera, transform)
        }
        return nil
    }
    
   
    static func frontFacingCameraSource(callback: BufferConsumer) -> SampleBufferSource? {
        if let (camera, transform) = frontFacingCamera() {
            return SampleBufferSource(device: camera, transform: transform, callback: callback)
        }
        return nil
    }
    
}

func ciImage(buffer: CMSampleBuffer) -> CIImage {
    let imageBuffer = CMSampleBufferGetImageBuffer(buffer)
    return CIImage(CVPixelBuffer: imageBuffer)
}

class CoreImageView: GLKView {
    var image: CIImage? {
        didSet {
            // Calling display() triggers drawRect() to be called
            display()
        }
    }
    let coreImageContext: CIContext
    
    override convenience init(frame: CGRect) {
        let eaglContext = EAGLContext(API: EAGLRenderingAPI.OpenGLES2)
        self.init(frame: frame, context: eaglContext)
    }
    
    override init(frame: CGRect, context eaglContext: EAGLContext!) {
        coreImageContext = CIContext(EAGLContext: eaglContext)
        super.init(frame: frame, context: eaglContext)
        // We will be calling display() directly, hence this needs to be false
        enableSetNeedsDisplay = false
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   
    override func drawRect(rect: CGRect) {
        if let img = image {
            let r = bounds
            let scale = self.window?.screen.scale ?? 1.0
            let destRect = CGRectApplyAffineTransform(r, CGAffineTransformMakeScale(scale, scale))
            coreImageContext.drawImage(img, inRect: destRect, fromRect: img.extent())
        }
    }
}


class ViewController: UIViewController {
    var source: SampleBufferSource?
    var coreImageView: CoreImageView?
    
    override func loadView() {
        coreImageView = CoreImageView(frame: CGRect())
        self.view = coreImageView
        if coreImageView == nil { fatalError("No image view") }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        coreImageView?.frame = CGRect(origin: CGPoint(), size: size)
    }
    
   
    override func viewDidAppear(animated: Bool) {
        source = SampleBufferSource.frontFacingCameraSource { [unowned self] (buffer, transform) in
            let image = ciImage(buffer)
            let blurred = hueAdjust(Float(M_PI))(image)
            self.coreImageView?.image = blurred.imageByApplyingTransform(transform)
        }
        source?.running = true
        if source == nil {
            fatalError("No front facing camera")
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        source?.running = false
    }

}

