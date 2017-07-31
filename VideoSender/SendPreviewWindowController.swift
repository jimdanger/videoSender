//
//  SendPreviewViewController.swift
//  VideoSender
//
//  Created by James Wilson on 7/31/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Cocoa
import AVFoundation
import AVKit

class SendPreviewViewController: NSViewController {


    @IBOutlet weak var previewLayer: PreviewLayer!

//    var previewLayer: PreviewLayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
//        previewLayer = PreviewLayer()
        if let pl = previewLayer {
            pl.setup()
            pl.wantsLayer = true 
        }
    }
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    func enqueue(cMSamplebuffer: CMSampleBuffer){
        if let unwrappedPreviewLayer = previewLayer{
            unwrappedPreviewLayer.enqueue(cMSamplebuffer: cMSamplebuffer)
        }
    }

    
}
