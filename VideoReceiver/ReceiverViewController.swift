//
//  ViewController.swift
//  VideoReceiver
//
//  Created by James Wilson on 8/1/17.
//  Copyright © 2017 jimdanger. All rights reserved.
//

import Cocoa

class ReceiverViewController: NSViewController, PTManagerDelegate {

    @IBOutlet weak var displayLayer: DisplayLayer!
    

    var elementaryStreamDecoder: ElementaryStreamDecoder?



    override func viewDidLoad() {
        super.viewDidLoad()

        PTManagerReceiver.instance.delegate = self
        PTManagerReceiver.instance.connect(portNumber: PORT_NUMBER)

    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


    @IBAction func asdf(_ sender: Any) { // temporary to force a breakpoint

        print("put breakpoint here to freeze app on button press")
    }

    // MARK: - PTManagerDelegate methods:
    func peertalk(shouldAcceptDataOfType type: UInt32) -> Bool {
        return true
    }


    func peertalk(didReceiveData data: Data, ofType type: UInt32){
        switch type {
        case PTType.number.rawValue:
            print("number")
            print(data.convert())
            break
        case PTType.elementarystream.rawValue:
            decodeElementaryStream(data: data)
            break
        default:
            print("default")
            break
        }
    }



    func decodeElementaryStream(data: Data) {
        if elementaryStreamDecoder == nil {
            elementaryStreamDecoder = ElementaryStreamDecoder(displayLayer: displayLayer)
        }
        guard let decoder = elementaryStreamDecoder else {
            return
        }
        decoder.decode(data: data)
    }


    func peertalk(didChangeConnection connected: Bool) {
        print("receiver - didChangeConnection")

    }


    
}

