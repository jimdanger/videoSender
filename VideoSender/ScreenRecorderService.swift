//
//  ScreenRecorderService.swift
//  VideoSender
//
//  Created by James Wilson on 7/30/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Foundation
import VideoToolbox
import AVFoundation



class ScreenRecorderService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var displayStream: CGDisplayStream?
    let backgroundQueue = DispatchQueue(label: "com.jimdanger.app.queue",
                                        qos: .background,
                                        target: nil)

    var x = 0
    public override init(){
        super.init()
        let displayId: CGDirectDisplayID = CGDirectDisplayID(CGMainDisplayID())

        displayStream = CGDisplayStream(dispatchQueueDisplay: displayId, outputWidth: 100, outputHeight: 100, pixelFormat: Int32(k32BGRAPixelFormat), properties: nil, queue: backgroundQueue, handler: { (cgDisplayStreamFrameStatus, uInt64, iOSurfaceRef, cGDisplayStreamUpdate) in

            self.handleStream(cgDisplayStreamFrameStatus: cgDisplayStreamFrameStatus, uInt64: uInt64, iOSurfaceRef: iOSurfaceRef, cGDisplayStreamUpdate: cGDisplayStreamUpdate)

        })
    }

    func getCVPixleBuffersFromScreenCapture(){
        displayStream?.start()
    }

    func stop() {
        displayStream?.stop()
    }


    func handleStream(cgDisplayStreamFrameStatus: CGDisplayStreamFrameStatus, uInt64: UInt64, iOSurfaceRef: IOSurfaceRef?, cGDisplayStreamUpdate: CGDisplayStreamUpdate?){

        let pixBufferPointer = UnsafeMutablePointer<Unmanaged<CVPixelBuffer>?>.allocate(capacity: 1)
        if let  unwrappediOSurfaceRef = iOSurfaceRef {
            CVPixelBufferCreateWithIOSurface(nil, unwrappediOSurfaceRef, nil, pixBufferPointer)

        }

        if let pixelBuffer: CVPixelBuffer = pixBufferPointer.pointee?.takeRetainedValue() {
            doSomethingWithCVPixelBuffer(cVPixelBuffer: pixelBuffer)
        }

//        let _ = pixBufferPointer.pointee?.autorelease()

    }

    func doSomethingWithCVPixelBuffer(cVPixelBuffer: CVPixelBuffer) {
        print(self.x)
        self.x += 1

    }

    




}
