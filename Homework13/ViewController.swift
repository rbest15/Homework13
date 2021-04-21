import UIKit
import AVFoundation

class ViewController: UIViewController {

    let store = AssetStore.test()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        store.vc = self
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
        self.view.layer.addSublayer(playerLayer)
        player.play()
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

class AssetStore {
    let video1: AVAsset
    let video2: AVAsset
    let video3: AVAsset
    let music1: AVAsset
    let music2: AVAsset
    
    var vc : ViewController?
    
    init(video1: AVAsset, video2: AVAsset, video3: AVAsset, music1: AVAsset, music2: AVAsset) {
        self.video1 = video1
        self.video2 = video2
        self.video3 = video3
        self.music1 = music1
        self.music2 = music2
    }
    
    static func asset(_ res: String, _ type: String) -> AVAsset {
        guard let path = Bundle.main.path(forResource: res, ofType: type) else {
            print("error")
            fatalError()
        }
        let url = URL(fileURLWithPath: path)
        return AVAsset(url: url)
    }
    
    static func test() -> AssetStore {
        return AssetStore(video1: asset("video1", "mp4"), video2: asset("video2", "mp4"), video3: asset("video3", "mp4"), music1: asset("music1", "mp3"), music2: asset("music2", "mp3"))
    }
    

    
    func compose() -> (AVAsset, AVVideoComposition) {
        let composition = AVMutableComposition()
        guard let videoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let videoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let audioTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        
        let transition1Duration = CMTime(seconds: 1, preferredTimescale: 600)
        
        try? videoTrack1.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video1.duration), of: video1.tracks(withMediaType: .video)[0], at: CMTime.zero)
        try? videoTrack2.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video2.duration), of: video2.tracks(withMediaType: .video)[0], at: video1.duration - transition1Duration)
        try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video1.duration + video2.duration - transition1Duration), of: music1.tracks(withMediaType: .audio)[0], at: CMTime.zero)
        
        let passTroughInstruction1 = AVMutableVideoCompositionInstruction()
        passTroughInstruction1.timeRange = CMTimeRange(start: CMTime.zero, duration: video1.duration - transition1Duration)
        
        let passTroughLayerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        passTroughLayerInstruction1.setTransform(videoTrack1.preferredTransform, at: CMTime.zero)
        passTroughInstruction1.layerInstructions = [passTroughLayerInstruction1]
        
        let passTroughInstruction2 = AVMutableVideoCompositionInstruction()
        passTroughInstruction2.timeRange = CMTimeRange(start: video1.duration, duration: video2.duration - transition1Duration)
        
        let passTroughLayerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        passTroughLayerInstruction2.setTransform(videoTrack2.preferredTransform, at: CMTime.zero)
        passTroughInstruction2.layerInstructions = [passTroughLayerInstruction2]
       
        let transition1Range = CMTimeRange(start: video1.duration - transition1Duration, end: transition1Duration)
        
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        let instruction1 = AVMutableVideoCompositionInstruction()
        instruction1.timeRange = transition1Range
        let fadeOutLayerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        let fadeInLayerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        
        fadeOutLayerInstruction1.setTransform(video1.preferredTransform, at: CMTime.zero)
        fadeOutLayerInstruction1.setOpacityRamp(fromStartOpacity: 1, toEndOpacity: 0, timeRange: transition1Range)
        fadeInLayerInstruction1.setTransform(video2.preferredTransform, at: CMTime.zero)
        fadeInLayerInstruction1.setOpacityRamp(fromStartOpacity: 0, toEndOpacity: 1, timeRange: transition1Range)
        
        instruction1.layerInstructions = [fadeOutLayerInstruction1, fadeInLayerInstruction1]
        videoComposition.instructions = [passTroughInstruction1, instruction1, passTroughInstruction2]
        
//        func insertVideo(asset: AVAsset, at: CMTime) {
//            try? videoTrack1.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: asset.duration), of: asset.tracks(withMediaType: .video)[0], at: at)
//        }
//        func insertAudio(asset: AVAsset, duration: CMTime ,at: CMTime) {
//            try? audioTrack.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: duration), of: asset.tracks(withMediaType: .audio)[0], at: at)
//        }
//        insertVideo(asset: video1, at: CMTime.zero)
//        insertVideo(asset: video2, at: video1.duration)
//        insertVideo(asset: video3, at: video1.duration + video2.duration)
//        insertAudio(asset: music1, duration: video1.duration + video2.duration - transition1Duration ,at: CMTime.zero)
//        insertAudio(asset: music2, duration: CMTime(seconds: 15, preferredTimescale: .max) ,at: CMTime(seconds: 30, preferredTimescale: .max))

        return (composition, videoComposition)
    }
    
    func export(asset: AVAsset, completiton: @escaping (AVAssetExportSession) -> Void) {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError()
        }
        var fileName = ""
        
        let alert = UIAlertController(title: "Name", message: "Provide a name for file:", preferredStyle: .alert)
        alert.addTextField { (textfield) in
            return
        }
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action) in
            self.vc?.dismiss(animated: true, completion: nil)
            fileName = alert.textFields![0].text ?? "defaultName"
            let url = documentsDirectory.appendingPathComponent(fileName)
            guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720) else {
                fatalError()
            }
            exporter.outputURL = url
            exporter.outputFileType = .mp4
            exporter.exportAsynchronously {
                DispatchQueue.main.async {
                    completiton(exporter)
                }
            }
        }))
        self.vc?.present(alert, animated: true)
    }
}
