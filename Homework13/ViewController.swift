import UIKit
import AVFoundation

class ViewController: UIViewController {

    let store = AssetStore.test()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        store.rect = self.view.frame
        createSaveButton()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        let (asset, videoComposition) = store.compose()
        startPlaying(asset: asset, videoComposition: videoComposition)
        createSaveButton()
    }
    
    func startPlaying(asset: AVAsset, videoComposition: AVVideoComposition) {
        self.view.layer.sublayers?.forEach({ (layer) in
            layer.removeFromSuperlayer()
        })
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = videoComposition
        let player = AVPlayer(playerItem: playerItem)
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.frame = self.view.bounds
//        playerLayer.anchorPoint = self.view.center
        self.view.layer.addSublayer(playerLayer)
        player.playImmediately(atRate: 2)
    }
    
    func createSaveButton() {
        let button = UIButton(frame: CGRect(x: self.view.bounds.width / 2 - 75, y: self.view.bounds.height - 200 , width: 150, height: 75))
        button.setTitle("Save", for: .normal)
        button.backgroundColor = .darkGray
        button.layer.cornerRadius = 25
        button.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        
        self.view.addSubview(button)
    }
    
    @objc func saveButtonPressed() {
        store.export(asset: store.compose().0) { (complete) in

            switch complete.status {
            case .completed :
                let alert = UIAlertController(title: "Saved successfully", message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true)
            default :
                let alert = UIAlertController(title: "Error", message: "\(String(describing: complete.error?.localizedDescription))", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
                    self.dismiss(animated: true, completion: nil)
                }))
                self.present(alert, animated: true)
            }
        }
    }


}

