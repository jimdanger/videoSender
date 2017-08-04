
//
//  File.swift
//  VideoSender
//
//  Created by James Wilson on 7/31/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Foundation
import AVFoundation
import AVKit


class DisplayLayer: NSView {
    var aVSampleBufferDisplay: AVSampleBufferDisplayLayer = AVSampleBufferDisplayLayer()


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }

    func sizeWillChange(size: NSSize) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        aVSampleBufferDisplay.frame.size = size
        CATransaction.commit()
    }

    func setup() {
        aVSampleBufferDisplay.removeFromSuperlayer()
        self.wantsLayer = true
        self.isHidden = false
        layer!.addSublayer(aVSampleBufferDisplay)
        layer?.isHidden = false
        aVSampleBufferDisplay.videoGravity = AVLayerVideoGravityResizeAspectFill
        aVSampleBufferDisplay.frame = layer!.bounds
    }

    func enqueue(cMSamplebuffer: CMSampleBuffer){
        aVSampleBufferDisplay.enqueue(cMSamplebuffer)
    }

}


