//
//  ViewController.swift
//  VideoSender
//
//  Created by James Wilson on 7/22/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    var screenCapturer: ScreenRecorderService?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }



    @IBAction func startClicked(_ sender: Any) {
        startMakingCGDisplayStream()
    }

    @IBAction func stopClicked(_ sender: Any) {
        stopMakingCGDisplayStream()
    }



    // MARK: - ScreenRecorderService
    func startMakingCGDisplayStream(){
        screenCapturer = ScreenRecorderService()
        screenCapturer?.start()
    }

    func stopMakingCGDisplayStream(){
        screenCapturer?.stop()
    }

}
