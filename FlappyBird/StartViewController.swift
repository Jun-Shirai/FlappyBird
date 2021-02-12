//
//  StartViewController.swift
//  FlappyBird
//
//  Created by 白井淳 on 2021/02/12.
//

import UIKit

class StartViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imageArray: UIImage = UIImage(named: "bird_a")!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageView.image = imageArray
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
