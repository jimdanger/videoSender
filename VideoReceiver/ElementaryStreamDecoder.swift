//
//  ElementaryStreamDecoder.swift
//  VideoSender
//
//  Created by James Wilson on 8/2/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Foundation
import VideoToolbox
import CoreMediaIO



class ElementaryStreamDecoder {

    var displayLayer: DisplayLayer?
    var recivedData: [UInt8] = []
    var formatDesc: CMVideoFormatDescription?
    var spsSize: Int?
    var ppsSize: Int?

    var skip:Bool = false

    init(displayLayer: DisplayLayer){
        self.displayLayer = displayLayer

    }

    public func decode(data: Data) {

        recivedData.removeAll()
        recivedData.append(contentsOf: data)

        var status: OSStatus

        let startCodeIndex: Int = 0
        var secondStartCodeIndex: Int = 0
        var thirdStartCodeIndex: Int = 0
        var fourthStartCodeIndex: Int = 0

        var blockLength: Int = 0

        var formatDescriptionOut: UnsafeMutablePointer<CMFormatDescription?> = UnsafeMutablePointer<CMFormatDescription?>.allocate(capacity: 1)

        var cMBlockBufferRef: UnsafeMutablePointer<CMBlockBuffer?> = UnsafeMutablePointer<CMBlockBuffer?>.allocate(capacity: 1)
        var cMSampleBufferRef:UnsafeMutablePointer<CMSampleBuffer?> = UnsafeMutablePointer<CMSampleBuffer?>.allocate(capacity: 1)
        var memoryBlock: UnsafeMutablePointer<Int8>?


        var nalu_type: Int = (Int(recivedData[startCodeIndex + 4] & UInt8(0x1f)))

        // if we havent already set up our format description with our SPS PPS parameters, we
        // can't process any frames except type 7 that has our parameters

        if nalu_type != 7 && formatDesc == nil {
            //print(NSLog(@"Video error: Frame is not an I Frame and format description is null")
            return
        }

         // NALU type 7 is the SPS parameter NALU
        if nalu_type == 7 { // 39
            // find the second startCodeIndex

            for i in (startCodeIndex + 4)...(startCodeIndex + 40) {
                if recivedData[i] == 0 && recivedData[i + 1] == 0 && recivedData[i + 2] == 0 && recivedData[ i + 3 ] == 1{

                    secondStartCodeIndex = i
                    spsSize = secondStartCodeIndex // includes the header in the size
                    break
                }
            }
            nalu_type = (Int(recivedData[secondStartCodeIndex + 4] & UInt8(0x1f)))
        }
        //print(nalu_type)

        // type 8 is the PPS parameter NALU
        if nalu_type == 8 { // 40

            // find the third startCodeIndex

            for i in (secondStartCodeIndex + 4)...(secondStartCodeIndex + 40) {
                if recivedData[i] == 0 && recivedData[i + 1] == 0 && recivedData[i + 2] == 0 && recivedData[ i + 3 ] == 1{

                    thirdStartCodeIndex = i
                    guard let unwrappedspsSize  = spsSize else {
                        return
                    }
                    ppsSize = thirdStartCodeIndex - unwrappedspsSize
                    break
                }
            }
             nalu_type = (Int(recivedData[thirdStartCodeIndex + 4] & UInt8(0x1f)))
        }
        guard let unwrappedSpsSize  = spsSize else {
            return
        }

        let kNalUnitHeaderLength: Int32 = 4
        var spsByteArray: [UInt8] = []
        var ppsByteArray: [UInt8] = []

        // extract sps data
        spsByteArray = Array(recivedData[Int(kNalUnitHeaderLength)..<(unwrappedSpsSize)])
        // extract pps data

        if (secondStartCodeIndex + Int(kNalUnitHeaderLength)) > thirdStartCodeIndex {
            skip = true
        } else {
            skip = false
        }

        if skip {
            return 
        }

        ppsByteArray = Array(recivedData[(secondStartCodeIndex + Int(kNalUnitHeaderLength))..<thirdStartCodeIndex])

        // CMVideoFormatDescriptionCreateFromH264ParameterSets parameters
        let parameterSetCount: Int = 2

        let pointerSPS = UnsafePointer<UInt8>(spsByteArray)
        let pointerPPS = UnsafePointer<UInt8>(ppsByteArray)

        let dataParamArray = [pointerSPS, pointerPPS]
        let parameterSetPointers = UnsafePointer<UnsafePointer<UInt8>>(dataParamArray)

        let sizeParamArray = [spsByteArray.count, ppsByteArray.count]
        let parameterSetSizes = UnsafePointer<Int>(sizeParamArray)


        // CMVideoFormatDescriptionCreateFromH264ParameterSets
        status = CMVideoFormatDescriptionCreateFromH264ParameterSets(nil, parameterSetCount, parameterSetPointers, parameterSetSizes, kNalUnitHeaderLength, formatDescriptionOut)

        let error = NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil)

        if status != 0 {
            print("ERROR dropping a frame. could not create CMVideoFormatDescription vrom h246: \(error)")
            recivedData = []
            // TODO: release allocated data, if any.
            return
        }

        formatDesc = formatDescriptionOut.pointee

        // type 6 is the Supplemental enhancement information (SEI) (non-VCL) - Note, I did not find anyone use this in the Stack Overflow exmaples. idk what it is. I'm skipping over it, sipmly to find the next start code index.
        if nalu_type == 6 { // 6

            // find the fourth startCodeIndex. I'm skipping over the type 6 info.

            for i in (thirdStartCodeIndex + 4)...(thirdStartCodeIndex + 40) {
                if recivedData[i] == 0 && recivedData[i + 1] == 0 && recivedData[i + 2] == 0 && recivedData[ i + 3 ] == 1{

                    fourthStartCodeIndex = i

                    break
                }
            }
            nalu_type = (Int(recivedData[fourthStartCodeIndex + 4] & UInt8(0x1f)))
        }

        print(nalu_type)


        if nalu_type == 1 { // 1
            let useWholeThing = false

            if useWholeThing {
                blockLength = recivedData.count
            } else {
                blockLength = recivedData.count - thirdStartCodeIndex - 4
            }

//            memoryBlock = malloc(blockLength)
//            if useWholeThing {
//                memoryBlock = memcpy(memoryBlock, &recivedData[0], blockLength)
//            } else {
//                if blockLength > 4000{
//                    let _ = ""
//                }
//                memoryBlock = memcpy(memoryBlock, &recivedData[thirdStartCodeIndex + 4], blockLength)
//            }

            let flags: CMBlockBufferFlags = 0




            let status = CMBlockBufferCreateWithMemoryBlock(nil, nil, blockLength, nil, nil, 0, blockLength, flags, cMBlockBufferRef)
            print(status)
//            memoryBlock?.deallocate(bytes: blockLength, alignedTo: 0)

        }

        if status != noErr {
            print("CMBlockBufferCreateWithMemoryBlock: \(NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil))")
        } else{

            // make the CMSampleBuffer


            let bl: UnsafePointer<Int>? = UnsafePointer.init(bitPattern: blockLength)
            let cMBlockBuffer = cMBlockBufferRef.pointee

            let status  = CMSampleBufferCreate(kCFAllocatorDefault, cMBlockBuffer, true, nil, nil, formatDesc, 1, 0, nil, 0, bl, cMSampleBufferRef)

            let _ = ""
            print("final status: \(status)" )

            // READ THIS TOMORROW: https://developer.apple.com/documentation/coremedia/1489723-cmsamplebuffercreate?language=objc
            // Also for tomorrow: 
                // - toggleing true/ false on the whole thing seems to neitehr cause crash. 
            // printing the unwrappedCMSampleBuffer reveals some important data.




            if status == noErr {


                // set some values of the sample buffer's attachments


                let cMSampleBuffer:CMSampleBuffer? = cMSampleBufferRef.pointee

                if let unwrappedCMSampleBuffer = cMSampleBuffer {

                    let attachements = CMSampleBufferGetSampleAttachmentsArray(unwrappedCMSampleBuffer, true) as? [[String:Bool]]
                    if let unwrappedattachements = attachements {
                        var firstDict = unwrappedattachements[0]
                        firstDict[kCMSampleAttachmentKey_DisplayImmediately as String] = true
                    }

                    displayLayer?.enqueue(cMSamplebuffer: unwrappedCMSampleBuffer)
                }
            }

        }

        // free memory to avoid a memory leak, do the same for sps, pps and blockbuffer

        formatDescriptionOut.deallocate(capacity: 1)
        cMBlockBufferRef.deallocate(capacity: 1)
        cMSampleBufferRef.deallocate(capacity: 1)


//        memoryBlock?.deallocate(bytes: blockLength, alignedTo: 0)

        memoryBlock = nil
    }



    // helper sipmly for printing to console
    let naluTypesStrings: [String] =
    [
    "0: Unspecified (non-VCL)",
    "1: Coded slice of a non-IDR picture (VCL)",    // P frame
    "2: Coded slice data partition A (VCL)",
    "3: Coded slice data partition B (VCL)",
    "4: Coded slice data partition C (VCL)",
    "5: Coded slice of an IDR picture (VCL)",      // I frame
    "6: Supplemental enhancement information (SEI) (non-VCL)",
    "7: Sequence parameter set (non-VCL)",         // SPS parameter
    "8: Picture parameter set (non-VCL)",          // PPS parameter
    "9: Access unit delimiter (non-VCL)",
    "10: End of sequence (non-VCL)",
    "11: End of stream (non-VCL)",
    "12: Filler data (non-VCL)",
    "13: Sequence parameter set extension (non-VCL)",
    "14: Prefix NAL unit (non-VCL)",
    "15: Subset sequence parameter set (non-VCL)",
    "16: Reserved (non-VCL)",
    "17: Reserved (non-VCL)",
    "18: Reserved (non-VCL)",
    "19: Coded slice of an auxiliary coded picture without partitioning (non-VCL)",
    "20: Coded slice extension (non-VCL)",
    "21: Coded slice extension for depth view components (non-VCL)",
    "22: Reserved (non-VCL)",
    "23: Reserved (non-VCL)",
    "24: STAP-A Single-time aggregation packet (non-VCL)",
    "25: STAP-B Single-time aggregation packet (non-VCL)",
    "26: MTAP16 Multi-time aggregation packet (non-VCL)",
    "27: MTAP24 Multi-time aggregation packet (non-VCL)",
    "28: FU-A Fragmentation unit (non-VCL)",
    "29: FU-B Fragmentation unit (non-VCL)",
    "30: Unspecified (non-VCL)",
    "31: Unspecified (non-VCL)"
    ]



}
