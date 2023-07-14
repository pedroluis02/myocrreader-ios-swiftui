//
//  CameraUIViewController.swift
//  MyOcrReader
//
//  Created by Pedro Luis on 11/07/23.
//

import UIKit
import AVFoundation
import MLKit

class CameraUIViewController : UIViewController {
    private var permissionGranted: Bool = false
    private let devicePosition: AVCaptureDevice.Position = .back
    
    private let captureSession: AVCaptureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    
    private var previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    private var screenRect: CGRect! = nil
    
    override func viewDidLoad() {
        checkPermission()
        sessionQueue.async {
            guard self.permissionGranted else { return }
            self.setupCaptureSession()
            self.captureSession.startRunning()
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.connection?.videoOrientation = currentAVOrientation()
    }
    
    private func setupCaptureSession() {
        guard let captureDevice = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: devicePosition) else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        
        screenRect = UIScreen.main.bounds
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.connection?.videoOrientation = .portrait
        
        DispatchQueue.main.async {
            self.view.layer.addSublayer(self.previewLayer)
        }
    }
    
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            requestPermission()
            
        case .authorized:
            permissionGranted = true
            
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: .video) { permissionGranted in
            self.permissionGranted = permissionGranted
            self.sessionQueue.resume()
        }
    }
    
    private func currentAVOrientation() -> AVCaptureVideoOrientation {
        var orientation: AVCaptureVideoOrientation
        switch UIDevice.current.orientation {
        case UIDeviceOrientation.portraitUpsideDown:
            orientation = .portraitUpsideDown
            
        case UIDeviceOrientation.landscapeLeft:
            orientation = .landscapeRight
            
        case UIDeviceOrientation.landscapeRight:
            orientation = .landscapeLeft
            
        case UIDeviceOrientation.portrait:
            orientation = .portrait
            
        default:
            orientation = .portrait
        }
        
        return orientation
    }
}
