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
    
    
    var modelOneLabel: String = ""
    var modelOneConf: String = ""
    var modelTwoLabel: String = ""
    var modelTwoConf: String = ""
    let maskReq = LowestMaskReq.cloth
    
    @IBOutlet weak var image: UIImageView?
    let detectingImg = UIImage(named: "detecting")
    let noMaskImg = UIImage(named: "nomask")
    let adjustMaskImg = UIImage(named: "adjust")
    var correctClothImg = UIImage(named: "correctCloth")
    var correctSurgImg = UIImage(named: "correctSurg")
    let correctN95Img = UIImage(named: "correctN95")
    
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
        
        loadImages(maskReq: maskReq)
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }

        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)

        captureSession.startRunning()

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        view.layer.addSublayer(previewLayer)
        drawBoundingBox(result: .detecting)
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
//    func showCameraFeed() {
//        boundingLayer.frame = CGRect(x: 0,
//                                     y: self.view.frame.height/2 - self.view.frame.width/2,
//                                     width: self.view.frame.width,
//                                     height: self.view.frame.width)
//
//        boundingLayer.transform = CATransform3DMakeRotation(270.0 / 180.0 * .pi, 0.0, 0.0, 1.0)
//        previewLayer!.frame = view.frame
//        previewLayer!.setNeedsDisplay()
//        view.layer.addSublayer(previewLayer!)
//        view.setNeedsDisplay()
//
//
//    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciimage = CIImage(cvPixelBuffer: pixelBuffer)
        guard let model1 = try? VNCoreMLModel(for: UMaskedold().model ) else { return }
        guard let model2 = try? VNCoreMLModel(for: MaskType_new().model) else { return }
        
        let request1 = VNCoreMLRequest(model: model1) { finishedReq, err in
            guard let results = finishedReq.results as? [VNRecognizedObjectObservation] else { return }

            guard let firstObservation = results.first else { return }
            guard let observationLabel = firstObservation.labels.first?.identifier else { return }
            self.modelOneLabel = observationLabel
            self.modelOneConf = String(firstObservation.confidence)
        }
        
        let request2 = VNCoreMLRequest(model: model2) { finishedReq, err in
            
            if(self.modelOneLabel == "nomask") {
                print("Put on a mask")
                print("----------")
                self.drawBoundingBox(result: .noMask)
                return
            } else if(self.modelOneLabel == "wrong") {
                print("Adjust your mask")
                print("----------")
                self.drawBoundingBox(result: .adjustMask)
                return
            }
            guard let results = finishedReq.results as? [VNRecognizedObjectObservation] else { return }

            guard let firstObservation = results.first else { return }
            guard let observationLabel = firstObservation.labels.first?.identifier else { return }
            
            self.modelTwoConf = String(firstObservation.confidence)
            self.modelTwoLabel = observationLabel
            
            if (self.modelTwoLabel == "other") {
                self.drawBoundingBox(result: .correctOther)
            } else if (self.modelTwoLabel == "n95") {
                self.drawBoundingBox(result: .correctN95)
            } else if (self.modelTwoLabel == "surgical") {
                self.drawBoundingBox(result: .correctSurg)
            } else {
                self.drawBoundingBox(result: .detecting)
            }

        }
        request1.imageCropAndScaleOption = .scaleFill
        request2.imageCropAndScaleOption = .scaleFill
        try? VNImageRequestHandler(ciImage: ciimage, options: [:]).perform([request1, request2])
        
    }
    
    func drawBoundingBox(result: DetectionResults) {
        print(self.modelOneLabel, self.modelOneConf)
        print(self.modelTwoLabel, self.modelTwoConf)
        print("----------")
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
            
            self.image?.transform = CGAffineTransform(rotationAngle: CGFloat(3 * Double.pi/2))
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
    
    func updateBoundingBox(img: CGImage) {
//        let boundingLayer = CALayer()
//        boundingLayer.contents = img
//
//        boundingLayer.frame = CGRect(x: 0,
//                                     y: self.view.frame.height/2 - self.view.frame.width/2,
//                                     width: self.view.frame.width,
//                                     height: self.view.frame.width)
//
//        boundingLayer.transform = CATransform3DMakeRotation(270.0 / 180.0 * .pi, 0.0, 0.0, 1.0)
//        return boundingLayer
    }

}

