//
//  GameScene.swift
//  FlappyBird
//
//  Created by 白井淳 on 2021/02/03.
//

import SpriteKit //SKSceneクラスを使用するために、UIKit→SpriteKitに置換
import AudioToolbox

//衝突とスコア判定を設けるためにデリゲートプロトコルを設置
class GameScene: SKScene,SKPhysicsContactDelegate {
    
//プロパティ
    var scrollNode: SKNode! //地面、雲用
    var wallNode: SKNode!   //壁用
    var bird: SKSpriteNode! // 鳥用
    var appleNode: SKNode!  //りんご用
    
    //衝突判定カテゴリ
    let birdCategory: UInt32 = 1 << 0  //0...00001
    let groudCategory: UInt32 = 1 << 1  //0...00010
    let wallCategory: UInt32 = 1 << 2  //0...00100
    let scoreCategory: UInt32 = 1 << 3  //0...01000
    let appleCategory: UInt32 = 1 << 4  //りんご用にIDを付加
    
    var score = 0  //スコア用（現状のもの。常に変化するからvar）
    var scoreLabelNode: SKLabelNode!  //画面表示用
    var bestScoreLabelNode: SKLabelNode!  //画面表示用
    
    
    let userDefaults: UserDefaults = UserDefaults.standard //スコア保存用。簡単に値を保存する仕組み。大規模なデータではないからこれで十分
    
    var appleScore = 0  //アイテムスコア用
    var appleScoreLabelNode: SKLabelNode!  //画面表示用
    
    
//SKView上のシーンが表示さらたときに呼び出されるメソッド
    override func didMove(to view: SKView) {
        
        //鳥に対して重力を設定　＊このphysicsWorldプロパティがSKPhysicsWorldクラスになる。
        physicsWorld.gravity = CGVector(dx: 0, dy: -4)
        
        //デリゲート指定（衝突したときのメソッドを使用するために）
        physicsWorld.contactDelegate = self
        
        //背景色を設定
        backgroundColor = UIColor(red: 0.15, green: 0.75, blue: 0.90, alpha: 1)
        
        //スクロールするスプライトの親ノードを作成。＊ゲームオーバー時にスクロールを停止できるように
        //このノードは画面に表示されることはないため、SKSpriteNodeクラスではなく、下記クラスを使用
        scrollNode = SKNode()
        addChild(scrollNode)
        
        //壁のノード作成
        wallNode = SKNode()
        scrollNode.addChild(wallNode)
        
        //りんごのノード作成
        appleNode = SKNode()
        scrollNode.addChild(appleNode)
        
        //各種スプライトを生成する処理をメソッド毎に分割　（＊じゃないとdidMove内が大きくなりすぎて、後々の修正がしにくくなるため。また確認したときどの箇所に何が記述されているのか把握しづらくなるため。）
        setupGround() //地面
        setupCloud()  //雲
        setupWall()   //壁
        setupBird()   //鳥
        setupApple()  //りんご
        
        setupScoreLabel()  //スコアの初期化を行うメソッド
        setupAppleScoreLabel() //アイテムスコアの初期化を行うメソッド
    }
    
    //↓画面が表示されたときのそれぞれの上記メソッドの機能を以下に記していく
    
//りんご
    func setupApple() {
        //画像を読み込む
        let appleTexture = SKTexture(imageNamed: "apple")
        appleTexture.filteringMode = .linear  //鳥とのあたり判定があるため、鮮明にしておく
        
        //移動する距離
        let appleMovingDistance = CGFloat(self.frame.size.width + appleTexture.size().width)
        
        //画面外まで移動するアクション
        let moveApple = SKAction.moveBy(x: -appleMovingDistance, y: 0, duration: 4)
        
        //自身を取り除く（消す）アクション
        let removeApple = SKAction.removeFromParent()
        
        //上記2つのアニメーションを順に実行していく
        let appleAnimation = SKAction.sequence([moveApple, removeApple])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //りんごの上下の振れ幅を鳥サイズの３倍にする
        let random_y_range = birdSize.height * 100
        
        //りんごの位置指定のために準備
        let groundSize = SKTexture(imageNamed: "groud").size()  //地面の画像サイズを取得
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_apple_lowest_y = center_y - appleTexture.size().height / 2 - random_y_range / 2
        
        //りんごを作成するアクション
        let createAppleAnimation = SKAction.run({
            //りんご関連のノードを乗せるノード
            let apple = SKNode()
            apple.position = CGPoint(x: self.frame.size.width + appleTexture.size().width / 2, y: center_y)  //x軸の位置がよくわからない→後で修正
            apple.zPosition = -50  //壁と同じ
            
            //りんごのサイズを修正
            apple.xScale = 0.1
            apple.yScale = 0.1
            
            //りんごの位置（y高さ）をランダムに設置する値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            //上記の値を足して、りんごのy座標を決定
            let under_apple_y = under_apple_lowest_y + random_y
            
            //りんごの作成
            let installApple = SKSpriteNode(texture: appleTexture)
            installApple.position = CGPoint(x: 0, y: under_apple_y)
            
            //衝突用にスプライトの物理演算を設定
            installApple.physicsBody = SKPhysicsBody(rectangleOf: appleTexture.size())
            //衝突用のカテゴリ設定
            installApple.physicsBody?.categoryBitMask = self.appleCategory
            //衝突した時に動かないようにする
            installApple.physicsBody?.isDynamic = false
            
            apple.addChild(installApple)
            
            apple.run(appleAnimation)
            
            self.appleNode.addChild(apple)
            
        })
        
        //次のりんご作成までの時間待ちのアクション
        let waitAppleAnimation = SKAction.wait(forDuration: 2)
        
        //りんごを作成→時間待ち→りんご作成と無限に繰り返すアクション
        let appleRepeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createAppleAnimation,waitAppleAnimation]))
        
        appleNode.run(appleRepeatForeverAnimation)
        
    }
    
//地面
    func setupGround() {
        //地面の画像を読み込む
        let groundTexture = SKTexture(imageNamed: "ground")
        groundTexture.filteringMode = .nearest
        //filteringMode：プロパティ
        //.nearest：画像が荒くなるが処理速度が速い設定　<->.liner：綺麗だけど遅い
        
        //必要な枚数を計算（+2の理由：画面の横幅より余分に取得しておくことで、スクロールさせたとき画面右端が切れないようにするため）
        let needNumber = Int(self.frame.size.width / groundTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分を5秒かけてスクロールさせるアクション
        //xの値がマイナスなのはx方向（＋の方向：右）に対して左に動くため
        let movedGround = SKAction.moveBy(x: -groundTexture.size().width, y: 0, duration: 5)
        
        //元の位置に一瞬（0秒かけて）で戻すアクション
        let resetground = SKAction.moveBy(x: groundTexture.size().width, y: 0, duration: 0)
        
        //左にスクロール→元の位置→左にスクロールと無限に繰り返すアクション
        let repeatScrollGround = SKAction.repeatForever(SKAction.sequence([movedGround,resetground]))
        
        for i in 0..<needNumber {
            //groundのスプライトを配置する
            let sprite = SKSpriteNode(texture: groundTexture)
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: groundTexture.size().width / 2 + groundTexture.size().width * CGFloat(i),
                y: groundTexture.size().height / 2)
            
            //スプライトにアクションを設定する
            sprite.run(repeatScrollGround)
            
            //スプライトに物理演算を設定
            sprite.physicsBody = SKPhysicsBody(rectangleOf: groundTexture.size())
            //衝突のカテゴリを設定
            sprite.physicsBody?.categoryBitMask = groudCategory
            //鳥が地面と衝突したとき止まるように地面が衝突時に動かないように設定
            sprite.physicsBody?.isDynamic = false
            
            //設定したスプライトを追加する
            scrollNode.addChild(sprite)
            }
    }
    
//雲
    func setupCloud() {
        //雲の画像を読み込む
        let cloudTexture = SKTexture(imageNamed: "cloud")
        cloudTexture.filteringMode = .nearest
        
        //必要な枚数を計算
        let needCloudNumber = Int(self.frame.size.width / cloudTexture.size().width) + 2
        
        //スクロールするアクションを作成
        //左方向に画像一枚分スクロールさせるアクション
        let moveCloud = SKAction.moveBy(x: -cloudTexture.size().width, y: 0, duration: 20)
        
        //元の位置に一瞬で戻すアクション
        let resetCloud = SKAction.moveBy(x: cloudTexture.size().width, y: 0, duration: 0)
        
        //左スクロール→元の位置→左スクロールと無限に繰り返すアクション
        let repeatScrollCloud = SKAction.repeatForever(SKAction.sequence([moveCloud,resetCloud]))
        
        //スプライトを配置する
        for i in 0..<needCloudNumber {
            let sprite = SKSpriteNode(texture: cloudTexture)
            sprite.zPosition = -100 //一番後ろになるようにする
            
            //スプライトの表示する位置を指定する
            sprite.position = CGPoint(
                x: cloudTexture.size().width / 2 + cloudTexture.size().width * CGFloat(i),
                y: self.size.height - cloudTexture.size().height / 2)
            
            //スプライトにアニメーションを設定する
            sprite.run(repeatScrollCloud)
            
            //設定したスプライトを追加する
            scrollNode.addChild(sprite)
        }
    }
    
//壁
    func setupWall() {
        //壁の画像を読み込む
        let wallTexture = SKTexture(imageNamed: "wall")
        wallTexture.filteringMode = .linear  //壁は鳥との当たり判定があるため、画像を鮮明niする
        
        //移動する距離を計算
        let movingDistance = CGFloat(self.frame.size.width + wallTexture.size().width)
        
        //画面外まで移動するアクションを作成
        let moveWall = SKAction.moveBy(x: -movingDistance, y: 0, duration: 4)
        
        //自身を取り除くアクションを作成
        let removeWall = SKAction.removeFromParent()
        
        //2つのアニメーションを順に実行するアクションを作成
        let wallAnimation = SKAction.sequence([moveWall,removeWall])
        
        //鳥の画像サイズを取得
        let birdSize = SKTexture(imageNamed: "bird_a").size()
        
        //鳥が通り抜ける隙間の長さを鳥のサイズの３倍とする→４倍に変更
        let slit_length = birdSize.height * 4
        
        //隙間位置の上下の振れ幅を鳥のサイズの2.5倍とする　（＊今回の振れ幅は高さだから”y”が該当する）→３倍に変更
        let random_y_range = birdSize.height * 3
        
        //下の壁のY軸下限位置（中央位置から下方向の最大振れ幅で下の壁を表示する位置）を計算
        //これを設定しておかないと、y軸の下限値を超えて下に行ってしまったとき、画面外になってしまう
        //壁の位置をあとで計算するために使用
        let groundSize = SKTexture(imageNamed: "ground").size()
        let center_y = groundSize.height + (self.frame.size.height - groundSize.height) / 2
        let under_wall_lownest_y = center_y - slit_length / 2 - wallTexture.size().height / 2 - random_y_range / 2
        //↑この下限値の計算がなぜこのような式になるのかというと、「最低でもこの高さはないと鳥が通り抜けるスペースと壁の確保ができないよね」の値を出している。そして、壁の高さと隙間、振れ幅が「半分」の長さで引くの理由は、引かれる対象がcenter_y、つまり地面を省いた（枠の）高さの中央＝「半分」の位置のため。/2しないで計算すると、下限値はマイナスの値になってしまう。
        //壁を生成するアクションを作成
        let createWallAnimation = SKAction.run({
            //壁関連のノードを載せるノードを作成
            let wall = SKNode()
            wall.position = CGPoint(x: self.frame.size.width + wallTexture.size().width / 2, y: 0)
            wall.zPosition = -50 //雲より手前、地面より奥
            
            //0~random_y_rangeまでのランダム値を生成
            let random_y = CGFloat.random(in: 0..<random_y_range)
            let under_wall_y = under_wall_lownest_y + random_y
            
        //下側の壁を作成
            let under = SKSpriteNode(texture: wallTexture)
            under.position = CGPoint(x: 0, y: under_wall_y)
            
            //スプライトに物理演算を設定
            under.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //衝突用のカテゴリ設定
            under.physicsBody?.categoryBitMask = self.wallCategory
            //鳥が衝突したときに止まるよう、壁が衝突時に動かないようにする
            under.physicsBody?.isDynamic = false
            
            
            wall.addChild(under)
            
        //上側の壁を作成
            let upper = SKSpriteNode(texture: wallTexture)
            upper.position = CGPoint(x: 0, y: under_wall_y + wallTexture.size().height + slit_length)
            
            //スプライトに物理演算を設定
            upper.physicsBody = SKPhysicsBody(rectangleOf: wallTexture.size())
            //衝突用のカテゴリ設定
            upper.physicsBody?.categoryBitMask = self.wallCategory
            //衝突時にうごかないよう設定
            upper.physicsBody?.isDynamic = false
            
            
            wall.addChild(upper)
            
            //スコアアップ用のノード
            let scoreNode = SKNode()
            scoreNode.position = CGPoint(x: upper.size.width + birdSize.width / 2, y: self.frame.size.height / 2)
            scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: upper.size.width, height: self.frame.size.height))
            scoreNode.physicsBody?.isDynamic = false
            scoreNode.physicsBody?.categoryBitMask = self.scoreCategory
            scoreNode.physicsBody?.contactTestBitMask = self.birdCategory
            
            wall.addChild(scoreNode)
            
            wall.run(wallAnimation)
            
            self.wallNode.addChild(wall)
        })
        
        //次の壁作成までの時間待ちのアクションを作成
        let waitAnimation = SKAction.wait(forDuration: 2)
        
        //壁を作成→時間待ち→壁を作成を無限に繰り返すアクションを作成
        let repeatForeverAnimation = SKAction.repeatForever(SKAction.sequence([createWallAnimation,waitAnimation]))
        
        wallNode.run(repeatForeverAnimation)
    }
    
//鳥
    func setupBird() {
        //鳥の画像を２種類読み込む　＊壁との当たり判定があるため、画像を鮮明にする
        let birdTextureA = SKTexture(imageNamed: "bird_a")
        birdTextureA.filteringMode = .linear
        let birdTextureB = SKTexture(imageNamed: "bird_b")
        birdTextureB.filteringMode = .linear
        
        //２種類のテクスチャを交互に変更するアニメーションを作成→無限に繰り返す
        let texturesAnimation = SKAction.animate(with: [birdTextureA,birdTextureB], timePerFrame: 0.2)
        let flap = SKAction.repeatForever(texturesAnimation)
        
        //スプライトを生成
        bird = SKSpriteNode(texture: birdTextureA)
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        
        //物理演算を設定（鳥に重力をかける）
        bird.physicsBody = SKPhysicsBody(circleOfRadius: bird.size.height / 2)
        
        //衝突したときに回転させない
        bird.physicsBody?.allowsRotation = false
        
        //衝突のカテゴリの設定　＊りんごも追加
        bird.physicsBody?.categoryBitMask = birdCategory
        bird.physicsBody?.collisionBitMask = groudCategory | wallCategory | appleCategory
        bird.physicsBody?.contactTestBitMask = groudCategory | wallCategory | appleCategory
        
        //アニメーションを設定
        bird.run(flap)
        
        //スプライトを追加する
        addChild(bird)
    }
    
//画面をタップしたときに呼ばれる動作
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if scrollNode .speed > 0 {
        //鳥が衝突せず動いている（スピードがある）ときにタップすると次の動作になるよう設定
        //鳥の速度を0にする
        bird.physicsBody?.velocity = CGVector.zero
        
        //鳥に縦方向の力を与える
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 15))
        }else if bird.speed == 0 {
            //鳥が壁や地面に衝突してスピードが0になり停止したとき（ゲームオーバー時）リスタートを設定
            restart()
        }
        
    }
    
//衝突したときに呼ばれるSKPhysicsContactDelegateのメソッド。
    func didBegin(_ contact: SKPhysicsContact) {
        //ゲームオーバーの時は何もしない
        if scrollNode.speed  <= 0 {
            return
        }
        
        //鳥とスコア物体が衝突したときの記述。なぜスコアは記述されていて、鳥の記述はないのかというと、スコアが衝突する相手は鳥しか設定していないため。
        //また下記に鳥を記述すると、鳥の衝突相手の通りは、壁、地面、スコアの３通りになり衝突相手を絞れない。だからスコア物体を記述。
        //スコアと衝突
        if (contact.bodyA.categoryBitMask & scoreCategory) == scoreCategory || (contact.bodyB.categoryBitMask & scoreCategory) == scoreCategory {
            //スコア用の物体と衝突したときスコアアップ
            print("ScoreUp")
            score += 1
            scoreLabelNode.text = "Score:\(score)"  //スコアを表示
            
            //ベストスコアかどうかを確認する。このベストスコア値は変化するためvar
            var bestScore = userDefaults.integer(forKey: "BEST")
            if score > bestScore {
                bestScore = score
                bestScoreLabelNode.text = "Best Score:\(bestScore)"  //ベストスコアを表示・kousinn
                userDefaults.set(bestScore, forKey: "BEST")
                userDefaults.synchronize()  //即座に更新・保存する
            }
        //りんごと衝突
        }else if (contact.bodyA.categoryBitMask & appleCategory) == appleCategory || (contact.bodyB.categoryBitMask & appleCategory) == appleCategory {
            //アイテムスコアアップの記述
            print("AppleScoreUp")
            appleScore += 1
            appleScoreLabelNode.text = "AppleScore:\(appleScore)"  //アイテムスコアを表示
            
            //効果音
            var soundIdRing: SystemSoundID = 1109
            if let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), nil, nil, nil) {
                AudioServicesCreateSystemSoundID(soundUrl, &soundIdRing)
                AudioServicesPlaySystemSound(soundIdRing)
            }
            
            //りんごの消滅→bodyA,Bそれぞれがりんごだった時の場合分けで記述していく
            if (contact.bodyA.categoryBitMask == appleCategory) {
                
                contact.bodyA.node?.removeFromParent()  //衝突したアイテムだけ削除
                
            }else if (contact.bodyB.categoryBitMask == appleCategory) {
                
                contact.bodyB.node?.removeFromParent()  //衝突したアイテムだけ削除
                
            }
        //上記以外と衝突したとき
        }else {
            //壁か地面と衝突したときゲームオーバー
            print("GameOver")
            //スクロールを停止させる＝鳥も速度０になる
            scrollNode.speed = 0
            
            //壁と衝突した際に、地面まで落下する。このとき再度壁と衝突することがないよう、鳥の衝突相手を一時的に地面のみに設定している。
            bird.physicsBody?.collisionBitMask = groudCategory
            
            let roll = SKAction.rotate(byAngle: CGFloat(Double.pi) * CGFloat(bird.position.y) * 0.01, duration: 1)
            bird.run(roll, completion: {
                self.bird.speed = 0
            })
            
        }
    }
//リスタートの設定（スコアを０に、鳥を初期位置に、壁を一旦取り除く、スクロール・鳥の速度を1に戻す）
    
    func restart() {
        score = 0
        scoreLabelNode.text = "Score:\(score)"  //スコア表示をリセット
        
        appleScore = 0
        appleScoreLabelNode.text = "AppleScore:\(appleScore)"  //アイテムスコア表示をリセット
        
        bird.position = CGPoint(x: self.frame.size.width * 0.2, y: self.frame.size.height * 0.7)
        bird.physicsBody?.velocity = CGVector.zero
        bird.physicsBody?.collisionBitMask = groudCategory | wallCategory                        //りんごも追加?
        bird.zPosition = 0
        wallNode.removeAllChildren()                                                              //りんごも追加？
        bird.zRotation = 0  //鳥の向きを元に戻す（角度を0に指定することで初期の角度（向き）になる）
        
        bird.speed = 1
        scrollNode.speed = 1
        
    }
//スコアの初期化を行うメソッドを設定
    func setupScoreLabel() {
        //スコアの表示設定
        score = 0
        scoreLabelNode = SKLabelNode()
        scoreLabelNode.fontColor = UIColor.black  //色を設定
        scoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 60)
        scoreLabelNode.zPosition = 100  //一番手前に表示
        scoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left  //表示位置
        scoreLabelNode.text = "Score:\(score)"  //表示
        self.addChild(scoreLabelNode)  //画面に追加
        
        //ベストスコアの表示設定
        bestScoreLabelNode = SKLabelNode()
        bestScoreLabelNode.fontColor = UIColor.black
        bestScoreLabelNode.position = CGPoint(x: 10, y: self.frame.size.height - 90)
        bestScoreLabelNode.zPosition = 100
        bestScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        let bestScore = userDefaults.integer(forKey: "BEST")  //このベストスコアは表示中の間、値の変化はないからlet
        bestScoreLabelNode.text = "BestScore:\(bestScore)"
        self.addChild(bestScoreLabelNode)  //画面に追加
        
    }
    
//アイテムスコアの初期化を行うメソッドの設定
    func setupAppleScoreLabel() {
        //アイテムスコアの表示設定       位置設定間違えているから直す
        appleScore = 0
        appleScoreLabelNode = SKLabelNode()
        appleScoreLabelNode.fontColor = UIColor.red
        appleScoreLabelNode.position = CGPoint(x: 200, y: self.frame.size.height - 60)
        appleScoreLabelNode.zPosition = 100
        appleScoreLabelNode.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        appleScoreLabelNode.text = "AppleScore:\(appleScore)"
        self.addChild(appleScoreLabelNode)
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
