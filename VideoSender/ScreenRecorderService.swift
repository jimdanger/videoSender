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
import CoreMedia



class ScreenRecorderService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {

    var x = 0
    var timeStampValue: Int64 = 0
    var displayStream: CGDisplayStream?
    let backgroundQueue = DispatchQueue(label: "com.jimdanger.app.queue", qos: .background, target: nil)


    var compressionSesionOut: UnsafeMutablePointer<VTCompressionSession?>
    var vtCompressionSession: VTCompressionSession
    var sendPreviewViewController: SendPreviewViewController?

    public override init(){

        let displayId: CGDirectDisplayID = CGDirectDisplayID(CGMainDisplayID())


        compressionSesionOut = UnsafeMutablePointer<VTCompressionSession?>.allocate(capacity: 1)

        let bounds: CGRect = CGDisplayBounds(displayId)
        let width: Int32 = Int32(bounds.width)
        let height: Int32 = Int32(bounds.height)



        VTCompressionSessionCreate(nil, width, height, kCMVideoCodecType_H264, nil, nil, nil, nil, nil, compressionSesionOut)
        vtCompressionSession = compressionSesionOut.pointee.unsafelyUnwrapped
        VTSessionSetProperty(vtCompressionSession, kVTCompressionPropertyKey_RealTime, kCFBooleanTrue)
        // TODO: play with these properties ^^ to possibly improve performance.

        super.init()

        displayStream = CGDisplayStream(dispatchQueueDisplay: displayId, outputWidth: Int(width), outputHeight: Int(height), pixelFormat: Int32(k32BGRAPixelFormat), properties: nil, queue: backgroundQueue, handler: { (cgDisplayStreamFrameStatus, uInt64, iOSurfaceRef, cGDisplayStreamUpdate) in

            self.handleStream(cgDisplayStreamFrameStatus: cgDisplayStreamFrameStatus, uInt64: uInt64, iOSurfaceRef: iOSurfaceRef, cGDisplayStreamUpdate: cGDisplayStreamUpdate)
        })
    }

    func setDelegate(sendPreviewViewController: SendPreviewViewController){
        self.sendPreviewViewController = sendPreviewViewController
    }

    func initVTCompressionSession(){

    }

    func start(){
        displayStream?.start()
    }

    func stop() {
        displayStream?.stop()
        VTCompressionSessionCompleteFrames(self.vtCompressionSession, CMTimeMake(self.timeStampValue, 1))
    }

    func handleStream(cgDisplayStreamFrameStatus: CGDisplayStreamFrameStatus, uInt64: UInt64, iOSurfaceRef: IOSurfaceRef?, cGDisplayStreamUpdate: CGDisplayStreamUpdate?){

        let pixBufferPointer = UnsafeMutablePointer<Unmanaged<CVPixelBuffer>?>.allocate(capacity: 1)
        if let  unwrappediOSurfaceRef = iOSurfaceRef {
            CVPixelBufferCreateWithIOSurface(nil, unwrappediOSurfaceRef, nil, pixBufferPointer)
        }

        if let pixelBuffer: CVPixelBuffer = pixBufferPointer.pointee?.takeRetainedValue() {
            doSomethingWithCVPixelBuffer(cVPixelBuffer: pixelBuffer)
        }

        // let _ = pixBufferPointer.pointee?.autorelease() // this may come in handy.

    }

    func doSomethingWithCVPixelBuffer(cVPixelBuffer: CVPixelBuffer) {
        compressCVPixelBufferIntoCMSampleBuffers(cVPixelBuffer: cVPixelBuffer)
    }

    func compressCVPixelBufferIntoCMSampleBuffers(cVPixelBuffer: CVPixelBuffer) {

        
        let nowTimeStamp: CMTime = CMTimeMake(self.timeStampValue, 1)
        self.timeStampValue += 1
        let err = VTCompressionSessionEncodeFrameWithOutputHandler(vtCompressionSession, cVPixelBuffer, nowTimeStamp, kCMTimeInvalid, nil, nil, { (osstatus,  vTEncodeInfoFlags, cMSampleBuffer) in

            if let unwrappedCMSampleBuffer  = cMSampleBuffer {
                self.doSomethingWithCMSampleBuffers(cMSampleBuffer: unwrappedCMSampleBuffer)
            }
        })
        if err != 0 {
            print(err)
        }
    }

    func doSomethingWithCMSampleBuffers(cMSampleBuffer: CMSampleBuffer){
        previewSampleBuffersInThisAppBeforeSendingToOtherApp(cMSampleBuffer: cMSampleBuffer)
//        convertCMSampleBuffersToElemtaryStream(cMSampleBuffer: cMSampleBuffer)
    }

    func previewSampleBuffersInThisAppBeforeSendingToOtherApp(cMSampleBuffer: CMSampleBuffer) {
        guard let previewVc = self.sendPreviewViewController else {
            return
        }
        previewVc.enqueue(cMSamplebuffer: cMSampleBuffer)
        self.checkIfHanging()

    }

    func convertCMSampleBuffersToElemtaryStream(cMSampleBuffer: CMSampleBuffer) {

        let formatDescription: CMVideoFormatDescription? =  CMSampleBufferGetFormatDescription(cMSampleBuffer)


        if let unwrappedFormatDescription = formatDescription {
            let h264ParameterSetAtIndex = CMVideoFormatDescriptionGetH264ParameterSetAtIndex(unwrappedFormatDescription, 0, nil, nil, nil, nil)
            print(h264ParameterSetAtIndex)

        }


    }





    func checkIfHanging(){

        print(self.x) // should dump numbers to console when mousing around main display. If hangs, we have a problem.
        self.x += 1
    }



}
