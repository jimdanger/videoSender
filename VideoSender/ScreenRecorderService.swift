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



class ScreenRecorderService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, PTManagerDelegate {

    var x = 0
    var timeStampValue: Int64 = 0
    var dumpFramesInCompressionQueueTimer: Timer?
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
//        VTSessionSetProperty(vtCompressionSession, kVTVideoEncoderSpecification_EnableHardwareAcceleratedVideoEncoder, kCFBooleanTrue)
//        VTSessionSetProperty(vtCompressionSession, kVTCompressionPropertyKey_MaxFrameDelayCount, NSNumber(value: 3))

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
        PTManager.instance.delegate = self
        PTManager.instance.connect(portNumber: PORT_NUMBER)
    }

    func stop() {
        displayStream?.stop()
        dumpFramesInQueue()
    }

    func dumpFramesInQueue(){
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
        convertCMSampleBuffersToElemtaryStream(frame: cMSampleBuffer)
        dumpQueuePrecheck()
        checkIfHanging()
    }

    func previewSampleBuffersInThisAppBeforeSendingToOtherApp(cMSampleBuffer: CMSampleBuffer) {
        guard let previewVc = self.sendPreviewViewController else {
            return
        }
        previewVc.enqueue(cMSamplebuffer: cMSampleBuffer)
        self.checkIfHanging()
    }

    public func convertCMSampleBuffersToElemtaryStream(frame: CMSampleBuffer)
    {
        print ("Received encoded frame in delegate...")

        //----AVCC to Elem stream-----//
        let elementaryStream = NSMutableData()

        //1. check if CMBuffer had I-frame
        var isIFrame: Bool = false

        guard let attachmentsArray: CFArray = CMSampleBufferGetSampleAttachmentsArray(frame, false) else {
            print("attachmentsArray null")
            return

        }
        //check how many attachments
        if ( CFArrayGetCount(attachmentsArray) > 0 ) {
            let dict = CFArrayGetValueAtIndex(attachmentsArray, 0)
            let dictRef: CFDictionary = unsafeBitCast(dict, to: CFDictionary.self)
            //get value
            let value = CFDictionaryGetValue(dictRef, unsafeBitCast(kCMSampleAttachmentKey_NotSync, to: UnsafeRawPointer.self))
            if ( value != nil ){
                print ("IFrame found...")
                isIFrame = true
            }
        }

        //2. define the start code
        let nStartCodeLength:size_t = 4
        let nStartCode:[UInt8] = [0x00, 0x00, 0x00, 0x01]

        //3. write the SPS and PPS before I-frame
        if ( isIFrame == true ){
            let description:CMFormatDescription = CMSampleBufferGetFormatDescription(frame)!
            //how many params
            var numParams:size_t = 0
            CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, 0, nil, nil, &numParams, nil)

            //write each param-set to elementary stream
            print("Write param to elementaryStream ", numParams)
            for i in 0..<numParams {
                var parameterSetPointer:UnsafePointer<UInt8>? = nil
                var parameterSetLength:size_t = 0
                CMVideoFormatDescriptionGetH264ParameterSetAtIndex(description, i, &parameterSetPointer, &parameterSetLength, nil, nil)
                elementaryStream.append(nStartCode, length: nStartCodeLength)
                elementaryStream.append(parameterSetPointer!, length: parameterSetLength)
            }
        }

        //4. Get a pointer to the raw AVCC NAL unit data in the sample buffer
        var blockBufferLength:size_t = 0
        var bufferDataPointer: UnsafeMutablePointer<Int8>? = nil
        CMBlockBufferGetDataPointer(CMSampleBufferGetDataBuffer(frame)!, 0, nil, &blockBufferLength, &bufferDataPointer)
        print ("Block length = ", blockBufferLength)

        //5. Loop through all the NAL units in the block buffer
        var bufferOffset:size_t = 0
        let AVCCHeaderLength:Int = 4
        while (bufferOffset < (blockBufferLength - AVCCHeaderLength) ) {
            // Read the NAL unit length
            var NALUnitLength:UInt32 =  0
            memcpy(&NALUnitLength, bufferDataPointer! + bufferOffset, AVCCHeaderLength)
            //Big-Endian to Little-Endian
            NALUnitLength = CFSwapInt32(NALUnitLength)
            if ( NALUnitLength > 0 ){
                print ( "NALUnitLen = ", NALUnitLength)
                // Write start code to the elementary stream
                elementaryStream.append(nStartCode, length: nStartCodeLength)
                // Write the NAL unit without the AVCC length header to the elementary stream
                elementaryStream.append(bufferDataPointer! + bufferOffset + AVCCHeaderLength, length: Int(NALUnitLength))
                // Move to the next NAL unit in the block buffer
                bufferOffset += AVCCHeaderLength + size_t(NALUnitLength);
                print("Moving to next NALU...")
            }
        }
        print("Read completed...")
        sendElementarySteam(elementaryStream: elementaryStream)
    }

    func sendElementarySteam(elementaryStream: NSMutableData) {
        let elementaryStreamData = elementaryStream as Data
        PTManager.instance.sendData(data: elementaryStreamData, type: PTType.elementarystream.rawValue)
    }


    func peertalk(shouldAcceptDataOfType type: UInt32) -> Bool {
        return true
    }


    func peertalk(didReceiveData data: Data, ofType type: UInt32) {
        print("sender- didReceiveData")
    }


    func peertalk(didChangeConnection connected: Bool) {
        print("sender- didChangeConnection")
    }

    func dumpQueuePrecheck() { // if the main display stops moving for a moment, we want to release the frames in the compression queue.

        DispatchQueue.main.async {
            self.dumpFramesInCompressionQueueTimer?.invalidate()
            self.dumpFramesInCompressionQueueTimer = Timer.scheduledTimer(timeInterval: 0.02, target: self,
                                                                     selector: #selector(self.dumpFramesInQueue),
                                                                     userInfo: nil, repeats: false)
        }
    }


    func checkIfHanging(){

        print(self.x) // should dump numbers to console when mousing around main display. If hangs, we have a problem.
        self.x += 1
    }



}
