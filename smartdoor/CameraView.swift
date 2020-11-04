import UIKit
import AVFoundation
import Vision

protocol CameraViewDelegate: class {
    func faceServiceResponse()
}


final class CameraView: UIView {
    
    unowned let delegate: CameraViewDelegate
    
    private var captureSession: AVCaptureSession? {
        get {
            return videoPreviewLayer.session
        } set {
            videoPreviewLayer.session = newValue
        }
    }
    
    private var maskLayer = [CAShapeLayer]()
    
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        return layer as! AVCaptureVideoPreviewLayer
    }
    
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    init(delegate: CameraViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        captureSession = AVCaptureSession()
        setupCaptureSession()
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    private func setupCaptureSession() {
        captureSession?.beginConfiguration()
        captureSession?.sessionPreset = .high
        //# DEFINE CAMERA FRONTAL
        let defaultVideoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
        
        
        let input = try! AVCaptureDeviceInput(device: defaultVideoDevice!)
        captureSession?.addInput(input as AVCaptureInput)
        let captureMetadataOutput = AVCaptureVideoDataOutput()
        captureMetadataOutput.alwaysDiscardsLateVideoFrames = true
        captureMetadataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as String): Int(kCVPixelFormatType_32BGRA)]
        captureMetadataOutput.alwaysDiscardsLateVideoFrames = true
        let outputQueue = DispatchQueue(label: "outputQueue")
        captureMetadataOutput.setSampleBufferDelegate(self, queue: outputQueue)
        captureSession?.addOutput(captureMetadataOutput)
        captureSession?.commitConfiguration()
        videoPreviewLayer.connection?.videoOrientation = .portrait
    }
    
    func startCaptureSession() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
            self.captureSession?.startRunning()
        })
    }
    
    func stopCaptureSession() {
        captureSession?.stopRunning()
    }
}


extension CameraView: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let exifOrientation = CGImagePropertyOrientation(rawValue: 0) else
        {
            return
        }
        var requestOptions: [VNImageOption : Any] = [:]
        let key = kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix
        if let cameraIntrinsicData = CMGetAttachment(sampleBuffer, key: key, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: cameraIntrinsicData]
        }
        let imageRequestHandler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: exifOrientation,
            options: requestOptions
        )
        do {
            storeBuffer.shared.actBuffer = sampleBuffer
            let request = VNDetectFaceRectanglesRequest(completionHandler: handleFaces)
            try imageRequestHandler.perform([request])
        } catch {
            print(error)
        }
    }
    
    
    func triggerService(){
        if(!storeBuffer.shared.serviceBlocked){
            storeBuffer.shared.serviceBlocked = true
            Timer.scheduledTimer(withTimeInterval: Config().TIMER_WAITING_TIME, repeats: false) { timer in
                storeBuffer.shared.serviceBlocked = false
            }
            if let img = storeBuffer.shared.actBuffer {
                let uiimageFromBuffer = self.transform(sampleBuffer: img)
                FaceService().request(img: uiimageFromBuffer) { result in
                }
            }
        }
    }
    
    func handleFaces(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [unowned self] in
            guard let results = request.results as? [VNFaceObservation] else {
                return
            }
            
            for mask in self.maskLayer {
                mask.removeFromSuperlayer()
            }
            guard results.isEmpty == false else {
                //                self.delegate.cameraViewFoundNoTargets()
                return
            }
            DispatchQueue.main.async {
                self.triggerService()
            }
            let frames: [CGRect] = results.map {
                let transform = CGAffineTransform(scaleX: 1, y: -1)
                    .translatedBy(x: 0, y: -self.frame.height)
                let translate = CGAffineTransform
                    .identity
                    .scaledBy(x: self.frame.width, y: self.frame.height)
                return $0.boundingBox
                    .applying(translate)
                    .applying(transform)
            }
            frames
                .sorted { ($0.width * $0.height) > ($1.width * $1.height) }
                .enumerated()
                .forEach(self.drawFaceBox)
        }
    }
    
//    func imageFromSampleBuffer(sampleBuffer : CMSampleBuffer) -> UIImage
//    {
//        // Get a CMSampleBuffer's Core Video image buffer for the media data
//        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//        // Lock the base address of the pixel buffer
//        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
//        
//        
//        // Get the number of bytes per row for the pixel buffer
//        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
//        
//        // Get the number of bytes per row for the pixel buffer
//        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
//        // Get the pixel buffer width and height
//        let width = CVPixelBufferGetWidth(imageBuffer!);
//        let height = CVPixelBufferGetHeight(imageBuffer!);
//        
//        // Create a device-dependent RGB color space
//        let colorSpace = CGColorSpaceCreateDeviceRGB();
//        
//        // Create a bitmap graphics context with the sample buffer data
//        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
//        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
//        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
//        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
//        // Create a Quartz image from the pixel data in the bitmap graphics context
//        let quartzImage = context?.makeImage();
//        // Unlock the pixel buffer
//        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
//        
//        // Create an image object from the Quartz image
//        let image = UIImage.init(cgImage: quartzImage!);
//        
//        return (image);
//    }
    
    func transform(sampleBuffer : CMSampleBuffer) -> UIImage {
        var img = UIImage()
        if let cvImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            let ciimage = CIImage(cvImageBuffer: cvImageBuffer)
            let context = CIContext()
            
            if let cgImage = context.createCGImage(ciimage, from: ciimage.extent) {
                img = UIImage(cgImage: cgImage)
            }
        }
        return img
    }
    
    func drawFaceBox(index: Int, frame: CGRect) {
        if index == 0 {
            //            delegate.cameraViewDidTarget(frame: frame)
            createLayer(in: frame, color: UIColor.green.cgColor)
        } else {
            createLayer(in: frame, color: UIColor.yellow.cgColor)
        }
    }
    
    private func createLayer(in rect: CGRect, color: CGColor) {
        let mask = CAShapeLayer()
        mask.frame = rect
        mask.opacity = 0.5
        mask.borderColor = color
        mask.borderWidth = 2
        maskLayer.append(mask)
        layer.insertSublayer(mask, at: 1)
    }
    
}
