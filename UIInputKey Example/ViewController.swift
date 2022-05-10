//
//  ViewController.swift
//  UIInputKey Example
//
//  Created by Jayachandra Agraharam on 10/05/22.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var inputTextField: JAInputTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }

    @IBAction func tap(_ sender: Any) {
        inputTextField.becomeFirstResponder()
    }
}

