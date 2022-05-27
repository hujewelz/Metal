//
//  CameraViewController.swift
//  Video
//
//  Created by huluobo on 2021/11/22.
//

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    private let session = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput!
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private var previewerView: PreviewerView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        previewerView = PreviewerView()
        previewerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewerView)
        
        NSLayoutConstraint.activate([
            previewerView.leftAnchor.constraint(equalTo: view.leftAnchor),
            previewerView.topAnchor.constraint(equalTo: view.topAnchor),
            previewerView.rightAnchor.constraint(equalTo: view.rightAnchor),
            previewerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    self.setupResult = .noAuthorized
                }
                self.sessionQueue.resume()
            }
        default:
            setupResult = .noAuthorized
        }

        sessionQueue.async {
            self.configSession()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            switch self.setupResult {
            case .success:
                self.session.startRunning()
                self.isSessionRunning = self.session.isRunning
            case .noAuthorized:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Camera", message: "The app needs to access your camera", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            case .configFailed:
                DispatchQueue.main.async {
                    let alert = UIAlertController(title: "Configurate session failed", message: "Something goes wrong when configurate capture session ", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async {
            guard self.setupResult == .success else { return }
            self.session.stopRunning()
            self.isSessionRunning = self.session.isRunning
        }
        super.viewWillDisappear(animated)
    }
    
    private enum SessionSetupResult {
        case success
        case noAuthorized
        case configFailed
    }
    
    private var sessionQueue = DispatchQueue(label: "me.jewelz.camera")
    
    private var setupResult: SessionSetupResult = .success
    private var isSessionRunning = false
    private func configSession() {
        guard setupResult == .success else { return }
        
        session.beginConfiguration()
        
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            if let defaultCamera = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = defaultCamera
            } else if let wideAngleCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                defaultVideoDevice = wideAngleCamera
            } else if let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                defaultVideoDevice = frontCamera
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configFailed
                session.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configFailed
                session.commitConfiguration()
                return
            }
            
        } catch let error {
            print(error)
            setupResult = .configFailed
            session.commitConfiguration()
            return
        }
        
        // Add video ouput
        if session.canAddOutput(videoOutput) {
            videoOutput.setSampleBufferDelegate(self, queue: sampleBufferCallbackQueue)
            session.addOutput(videoOutput)
        } else {
            setupResult = .configFailed
        }
        
        session.commitConfiguration()
    }
  
    private let sampleBufferCallbackQueue = DispatchQueue(label: "me.jewelz.callback")
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let pixelBuffer = sampleBuffer.imageBuffer {
            previewerView.didReceive(pixelBuffer)
        }
    }
}
