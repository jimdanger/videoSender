//
//  ViewController.swift
//  VideoReceiver
//
//  Created by James Wilson on 8/1/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Cocoa

class ReceiverViewController: NSViewController, PTManagerDelegate {


    override func viewDidLoad() {
        super.viewDidLoad()

        PTManagerReceiver.instance.delegate = self
        PTManagerReceiver.instance.connect(portNumber: PORT_NUMBER)
        print("")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    @IBAction func asdf(_ sender: Any) {

        print("asdf")
    }

    // MARK: - PTManagerDelegate methods:
    func peertalk(shouldAcceptDataOfType type: UInt32) -> Bool {
        return true
    }


    func peertalk(didReceiveData data: Data, ofType type: UInt32){
        print("receivedData")
    }



    func peertalk(didChangeConnection connected: Bool) {
        print("didChangeConnection")

    }


    
}

