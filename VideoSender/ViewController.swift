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
    var previewWindow: NSWindow?

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
        openPreviewWindow()

    }

    @IBAction func stopClicked(_ sender: Any) {
        stopMakingCGDisplayStream()
    }


    func openPreviewWindow() {

        let storyboard: NSStoryboard = NSStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateController(withIdentifier: "SendPreviewViewController") as? SendPreviewViewController {
            previewWindow = NSWindow(contentViewController: vc)
            if let window = previewWindow {
                window.makeKeyAndOrderFront(self)
                let controller = NSWindowController(window: window)
                controller.showWindow(self)
                setPreviewWindowDelegate(sendPreviewViewController: vc)
            }
        }
    }
    func setPreviewWindowDelegate(sendPreviewViewController: SendPreviewViewController){
        guard let sc = screenCapturer else {
            return
        }
        sc.setDelegate(sendPreviewViewController: sendPreviewViewController)
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
