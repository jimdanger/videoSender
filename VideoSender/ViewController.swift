//
//  ViewController.swift
//  VideoSender
//
//  Created by James Wilson on 7/22/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }



    @IBAction func startClicked(_ sender: Any) {
        start()
    }

    @IBAction func stopClicked(_ sender: Any) {
        stop()
    }

    func start() {
        print("start clicked")
    }

    func stop() {
        print("stop clicked")
    }
}

