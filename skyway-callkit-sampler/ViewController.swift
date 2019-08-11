//
//  ViewController.swift
//  skyway-callkit-sampler
//
//  Created by yorifuji on 2019/08/06.
//  Copyright © 2019 yorifuji. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if AppDelegate.shared.skywayAPIKey == nil || AppDelegate.shared.skywayDomain == nil {
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let alert = UIAlertController(title: "エラー", message: "APIKEYかDOMAINが設定されていません", preferredStyle: .alert)
        let ok = UIAlertAction(title: "OK", style: .default)
        alert.addAction(ok)
        self.present(alert, animated: true, completion: nil)
    }
}

