//
//  ViewController.swift
//  UMasked?
//
//  Created by Alex Yeh on 2021-07-29.
//

import AVKit
import UIKit
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    typealias Info = OwnerInfo
    
    var ownerInfo = Info(name: "", email: "", maskReq: .cloth)
        
    var modelOneLabel: String = ""
    var modelOneConf: String = ""
    var modelTwoLabel: String = ""
    var modelTwoConf: String = ""
    
    @IBOutlet weak var image: UIImageView?
    let detectingImg = UIImage(named: "detecting")
    let noMaskImg = UIImage(named: "nomask")
    let adjustMaskImg = UIImage(named: "adjust")
    var correctClothImg = UIImage(named: "correctCloth")
    var correctSurgImg = UIImage(named: "correctSurg")
    let correctN95Img = UIImage(named: "correctN95")
    
    var totalCorrectFrames = 0
    
    let captureSession = AVCaptureSession()
    
    
    // MARK: - LowestMaskReq
    
    enum LowestMaskReq {
        case cloth
        case surgical
        case n95
    }
    
    // MARK: - DetectionResults
    
    enum DetectionResults {
        case adjustMask
        case correctSurg
        case correctN95
        case correctOther
        case detecting
        case noMask
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadImages(maskReq: ownerInfo.maskReq)
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }

        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)

        captureSession.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        drawBoundingBox(result: .detecting)
        view.bringSubviewToFront(image!)
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciimage = CIImage(cvPixelBuffer: pixelBuffer).oriented(forExifOrientation: 6)
        
        guard let model1 = try? VNCoreMLModel(for: UMaskedold().model ) else { return }
        guard let model2 = try? VNCoreMLModel(for: MaskType_new().model) else { return }
        
        let request1 = VNCoreMLRequest(model: model1) { finishedReq, err in
            guard let results = finishedReq.results as? [VNRecognizedObjectObservation] else { return }

            guard let firstObservation = results.first else {
                self.modelOneLabel = "detecting"
                return
            }
            guard let observationLabel = firstObservation.labels.first?.identifier else { return }
            
            self.modelOneLabel = observationLabel
            self.modelOneConf = String(firstObservation.confidence)
        }
        
        let request2 = VNCoreMLRequest(model: model2) { finishedReq, err in
            if (self.modelOneLabel == "detecting") {
                self.drawBoundingBox(result: .detecting)
                self.mutateFrames(result: .detecting)
                return
            } else if(self.modelOneLabel == "nomask") {
                self.drawBoundingBox(result: .noMask)
                self.mutateFrames(result: .noMask)
                return
            } else if(self.modelOneLabel == "wrong") {
                self.drawBoundingBox(result: .adjustMask)
                self.mutateFrames(result: .adjustMask)
                return
            }
            guard let results = finishedReq.results as? [VNRecognizedObjectObservation] else { return }

            guard let firstObservation = results.first else { return }
            guard let observationLabel = firstObservation.labels.first?.identifier else { return }
            
            self.modelTwoConf = String(firstObservation.confidence)
            self.modelTwoLabel = observationLabel
            
            if (self.modelTwoLabel == "other") {
                self.drawBoundingBox(result: .correctOther)
                self.mutateFrames(result: .correctOther)
            } else if (self.modelTwoLabel == "n95") {
                self.drawBoundingBox(result: .correctN95)
                self.mutateFrames(result: .correctN95)
            } else if (self.modelTwoLabel == "surgical") {
                self.drawBoundingBox(result: .correctSurg)
                self.mutateFrames(result: .correctSurg)
            } else {
                self.drawBoundingBox(result: .detecting)
                self.mutateFrames(result: .detecting)
            }

        }
        request1.imageCropAndScaleOption = .scaleFill
        request2.imageCropAndScaleOption = .scaleFill
        try? VNImageRequestHandler(ciImage: ciimage, options: [:]).perform([request1, request2])
        
    }
    
    func drawBoundingBox(result: DetectionResults) {
        let newImage: UIImage?
        switch result {
        case .noMask:
            newImage = noMaskImg
        case .adjustMask:
            newImage = adjustMaskImg
        case .correctN95:
            newImage = correctN95Img
        case .correctOther:
            newImage = correctClothImg
        case .correctSurg:
            newImage = correctSurgImg
        case .detecting:
            newImage = detectingImg
        }
        DispatchQueue.main.async {
            self.image?.image = newImage
            self.image?.frame = CGRect(x: 0,
                                       y: self.view.frame.height/2 - self.view.frame.width/2,
                                         width: self.view.frame.width,
                                         height: self.view.frame.width)
        }
    }
    
    func loadImages(maskReq: LowestMaskReq) {
        switch maskReq {
        case .n95:
            correctClothImg = UIImage(named: "n95req")
            correctSurgImg = UIImage(named: "n95req")
        case .surgical:
            correctClothImg = UIImage(named: "surgreq")
        case .cloth:
            break
        }
    }
    
    func mutateFrames(result: DetectionResults) {
        switch ownerInfo.maskReq {
        case .cloth:
            if (result == .adjustMask || result == .noMask) {
                totalCorrectFrames = 0
            } else if (result != .detecting) {
                totalCorrectFrames = totalCorrectFrames + 1
            }
        case .n95:
            if (result == .correctN95) {
                totalCorrectFrames = totalCorrectFrames + 1
            } else if (result != .detecting){
                totalCorrectFrames = 0
            }
        case .surgical:
            if (result == .correctN95 || result == .correctSurg) {
                totalCorrectFrames = totalCorrectFrames + 1
            } else if (result != .detecting) {
                totalCorrectFrames = 0
            }
        }
        if (totalCorrectFrames > 5) {
            // TODO: Segue
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "goToFinal", sender: self)
                self.captureSession.stopRunning()

                if let inputs = self.captureSession.inputs as? [AVCaptureDeviceInput] {
                    for input in inputs {
                        self.captureSession.removeInput(input)
                    }
                }
            }
            
        }
    }
    
    func stopCaptureSession() {
        DispatchQueue.main.async {

//            self.view.layer.sublayers?.forEach { $0.removeFromSuperlayer() }
////            self.view.layer.removeFromSuperlayer()
//            self.performSegue(withIdentifier: "goToFinal", sender: self)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToFinal"{
//            let destinationVC = segue.destination as! CompleteViewController
//            destinationVC.ownerInfo = ownerInfo ?? Info(name: "", email: "", maskReq: .cloth)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
}

