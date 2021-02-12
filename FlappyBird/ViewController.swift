//
//  ViewController.swift
//  FlappyBird
//
//  Created by 白井淳 on 2021/02/03.
//

import UIKit
import SpriteKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //SKViewに型を変換する
        let skView = self.view as! SKView
        
        //FPSを表示する
        skView.showsFPS = true
        
        //ノードの数を表示する
        skView.showsNodeCount = true
        
        //ビューと同じサイズでシーンを作成する
        let scene = GameScene(size: skView.frame.size)
        //↑GameSceneクラスを使用するために、修正
        
        //ビューにシーンを表示する
        skView.presentScene(scene)
    }
    
    
    //画面上部のステータスバーを消す
    override var prefersStatusBarHidden: Bool {
        get {
            return true
        }
    }

}

