import Combine
import UIKit
import SwiftUI

final class CameraViewController: UIViewController {


    override func loadView() {
        let view = CameraView(delegate: self)
        self.view = view
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(4), execute: {
            (self.view as? CameraView)?.startCaptureSession()
//        })
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        (view as? CameraView)?.stopCaptureSession()
    }
}

extension CameraViewController: CameraViewDelegate {

        func faceServiceResponse() {
            let alert = UIAlertController(title: "Face reconhecida", message: "Liberando a porta...", preferredStyle: .actionSheet)
            self.present(alert, animated: true) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                       guard self?.presentedViewController == alert else { return }

                       self?.dismiss(animated: true, completion: nil)
                   }
            }

        }
}
