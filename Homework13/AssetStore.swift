import Foundation
import AVFoundation
import UIKit

class AssetStore {
    let video1: AVAsset
    let video2: AVAsset
    let video3: AVAsset
    let music1: AVAsset
    let music2: AVAsset
    
    var delegate : ViewController?
    
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

    func compose() -> (AVAsset, AVMutableVideoComposition) {
        
        //MARK: - create composition
        let composition = AVMutableComposition()
        guard let videoTrack1 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let videoTrack2 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let videoTrack3 = composition.addMutableTrack(withMediaType: .video, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let audioTrack1 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        guard let audioTrack2 = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: Int32(kCMPersistentTrackID_Invalid)) else { fatalError() }
        
        let transitionDuration1 = CMTime(seconds: 1, preferredTimescale: 600)
        let transitionDuration2 = CMTime(seconds: 1, preferredTimescale: 600)
        let transitionRange1 = CMTimeRange(start: video1.duration - transitionDuration1, duration: transitionDuration1)
        let transitionRange2 = CMTimeRange(start: video1.duration - transitionDuration1 + video2.duration - transitionDuration2, duration: transitionDuration2)
        
        //MARK: - insert video tracks
        try? videoTrack1.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video1.duration), of: video1.tracks(withMediaType: .video)[0], at: CMTime.zero)
        try? videoTrack2.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video2.duration), of: video2.tracks(withMediaType: .video)[0], at: video1.duration - transitionDuration1)
        try? videoTrack3.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video3.duration), of: video3.tracks(withMediaType: .video)[0], at: video1.duration  - transitionDuration1 + video2.duration - transitionDuration2)
        
        //MARK: - insert audio tracks
        try? audioTrack1.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video1.duration + video2.duration - transitionDuration1), of: music1.tracks(withMediaType: .audio)[0], at: CMTime.zero)
        try? audioTrack2.insertTimeRange(CMTimeRange(start: CMTime.zero, duration: video3.duration - transitionDuration2), of: music2.tracks(withMediaType: .audio)[0], at: video1.duration + video2.duration - transitionDuration1)
        
        //MARK: - create pass through 1
        let passTroughInstruction1 = AVMutableVideoCompositionInstruction()
        passTroughInstruction1.timeRange = CMTimeRange(start: CMTime.zero, duration: video1.duration - transitionDuration1)
        
        let passTroughLayerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        passTroughLayerInstruction1.setTransform(videoTrack1.preferredTransform, at: CMTime.zero)
        passTroughInstruction1.layerInstructions = [passTroughLayerInstruction1]
        
        //MARK: - reate pass through 2
        let passTroughInstruction2 = AVMutableVideoCompositionInstruction()
        passTroughInstruction2.timeRange = CMTimeRange(start: video1.duration, duration: video2.duration - transitionDuration1 - transitionDuration2)
        
        let passTroughLayerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        passTroughLayerInstruction2.setTransform(videoTrack2.preferredTransform, at: CMTime.zero)
        passTroughInstruction2.layerInstructions = [passTroughLayerInstruction2]
        
        //MARK: - create pass through 3
        let passTroughInstruction3 = AVMutableVideoCompositionInstruction()
        passTroughInstruction3.timeRange = CMTimeRange(start: video1.duration - transitionDuration1 + video2.duration, duration: video3.duration - transitionDuration2)
        
        let passTroughLayerInstruction3 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack3)
        passTroughLayerInstruction3.setTransform(videoTrack3.preferredTransform, at: CMTime.zero)
        passTroughInstruction3.layerInstructions = [passTroughLayerInstruction3]
       
        //MARK: - create instruction 1
        let instruction1 = AVMutableVideoCompositionInstruction()
        instruction1.timeRange = transitionRange1
        let fadeOutLayerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack1)
        let fadeInLayerInstruction1 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        
        //MARK: - create instruction 2
        let instruction2 = AVMutableVideoCompositionInstruction()
        instruction2.timeRange = transitionRange2
        let fadeOutLayerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack2)
        let fadeInLayerInstruction2 = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack3)
        
        //MARK: - fade out/ fade in animation settings
        fadeOutLayerInstruction1.setTransform(video1.preferredTransform, at: CMTime.zero)
        fadeInLayerInstruction1.setTransform(video2.preferredTransform, at: CMTime.zero)
        
        let video1W = videoTrack1.naturalSize.width
        
        fadeInLayerInstruction1.setTransformRamp(fromStart: CGAffineTransform(translationX: -video1W, y: 1), toEnd: CGAffineTransform(translationX: 1, y: 1), timeRange: transitionRange1)
        fadeOutLayerInstruction1.setTransformRamp(fromStart: CGAffineTransform(translationX: 1, y: 1), toEnd: CGAffineTransform(translationX: video1W, y: 1), timeRange: transitionRange1)
        
    
        fadeOutLayerInstruction2.setTransform(video2.preferredTransform, at: CMTime.zero)
        fadeInLayerInstruction2.setTransform(video3.preferredTransform, at: CMTime.zero)
        
        let video3W = videoTrack3.naturalSize.width
        let video3H = videoTrack3.naturalSize.height
    
        fadeInLayerInstruction2.setCropRectangleRamp(fromStartCropRectangle: CGRect(x: video3W / 2, y: video3H / 2, width: 0, height: 0), toEndCropRectangle: CGRect(x: 0, y: 0, width: video3W, height: video3H), timeRange: transitionRange2)
        
        //MARK: - composition compilating
        let videoComposition = AVMutableVideoComposition(propertiesOf: composition)
        
        instruction1.layerInstructions = [fadeInLayerInstruction1, fadeOutLayerInstruction1]
        instruction2.layerInstructions = [fadeInLayerInstruction2, fadeOutLayerInstruction2]
        videoComposition.instructions = [passTroughInstruction1, instruction1, passTroughInstruction2, instruction2, passTroughInstruction3]
        
        
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
            self.delegate?.dismiss(animated: true, completion: nil)
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
        self.delegate?.present(alert, animated: true)
    }
}


