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

    // MARK: - DetectionResults
    
    enum DetectionResults {
        case adjustMask
        case correctMedical
        case correctN95
        case correctOther
        case noMask
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let captureSession = AVCaptureSession()
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else { return }
        
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        captureSession.addInput(input)
        
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        view.layer.addSublayer(previewLayer)
//        previewLayer.add
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
        
    }
    
    
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
//                self.drawBoundingBox(color: .red, result: DetectionResults.noMask)
                return
            } else if(self.modelOneLabel == "wrong") {
                print("Adjust your mask")
                print("----------")
//                self.drawBoundingBox(color: .orange, result: DetectionResults.adjustMask)
                return
            }
            guard let results = finishedReq.results as? [VNRecognizedObjectObservation] else { return }

            guard let firstObservation = results.first else { return }
            guard let observationLabel = firstObservation.labels.first?.identifier else { return }
            
            self.modelTwoConf = String(firstObservation.confidence)
            self.modelTwoLabel = observationLabel
            
            if (self.modelTwoLabel == "other") {
                self.drawBoundingBox(color: .green, result: DetectionResults.correctOther)
            } else if (self.modelTwoLabel == "n95") {
                self.drawBoundingBox(color: .green, result: DetectionResults.correctN95)
            } else if (self.modelTwoLabel == "surgical") {
                self.drawBoundingBox(color: .green, result: DetectionResults.correctMedical)
            }
            
        }
        request1.imageCropAndScaleOption = .scaleFill
        request2.imageCropAndScaleOption = .scaleFill
        try? VNImageRequestHandler(ciImage: ciimage, options: [:]).perform([request1, request2])
        
    }
    
    func drawBoundingBox(color: UIColor, result: DetectionResults?) -> CALayer {
        print(self.modelOneLabel, self.modelOneConf)
        print(self.modelTwoLabel, self.modelTwoConf)
        print("----------")
        
        let imgLayer = CALayer()
        return imgLayer
    }

}

