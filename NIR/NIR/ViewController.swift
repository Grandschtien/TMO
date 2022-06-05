//
//  ViewController.swift
//  NIR
//
//  Created by Егор Шкарин on 31.03.2022.
//

import UIKit
import CoreImage

class ViewController: UIViewController, ImagePickerDelegate {
    
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    private var imagePicker: ImagePicker!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.isHidden = true
        activity.isHidden = true
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        imageView.image = UIImage(named: "face9")
        imageView.backgroundColor = .clear
        detect()
    }
    
    @IBAction func newPhoto(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Найти фото",
                                                message: "Вставте сслыку на фото из интернета",
                                                preferredStyle: .alert)
        alertController.addTextField()
        let action = UIAlertAction(title: "Найти", style: .default) {action in
            guard let text = alertController.textFields?.first?.text, !text.isEmpty else {
                self.errorLabel.isHidden = false
                self.setErrorMessage(text: "Вставте ссылку на картинку")
                return
            }
            Task {
                do {
                    self.activity.isHidden = false
                    self.activity.startAnimating()
                    let data = try await NetworkManager.shared.downloadImage(urlString:text)
                    self.setImage(data: data)
                } catch NetworkErrors.badUrl {
                    self.setErrorMessage(text: "Неверный URL, пожалуйста проверьте URL и повторите попвтку")
                    self.activity.stopAnimating()
                    self.activity.isHidden = true
                } catch NetworkErrors.internalError {
                     self.setErrorMessage(text: "Внутренняя ошибка, повторите попытку позже")
                    self.activity.stopAnimating()
                    self.activity.isHidden = true
                } catch NetworkErrors.noInternetConnection {
                     self.setErrorMessage(text: "Нет подключения к интернету, проверьте подлючение и повторите снова")
                    self.activity.stopAnimating()
                    self.activity.isHidden = true
                } catch {
                    self.setErrorMessage(text: "Неизвестная ошибка")
                    self.activity.stopAnimating()
                    self.activity.isHidden = true
                }
            }
        }
        alertController.addAction(action)
        present(alertController, animated: true)
    }
    @MainActor
    private func setErrorMessage(text: String) {
        self.errorLabel.text = text
        self.errorLabel.isHidden = false
    }
    
    @MainActor
    private func setImage(data: Data) {
        imageView.image = UIImage(data: data)
        if imageView.image != nil {
            detect()
        } else {
            self.setErrorMessage(text: "Неизвестная ошибка")
            imageView.backgroundColor = .opaqueSeparator
        }
        activity.stopAnimating()
        activity.isHidden = true
        self.errorLabel.isHidden = true
    }
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        self.imagePicker.present(from: view)
    }
    @IBAction func nextButtonAction(_ sender: UIButton) {
        let randNum = Int.random(in: 9...29)
        self.imageView.image = UIImage(named: "face\(randNum)")
        self.detect()
    }
    
    func detect() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.imageView.subviews.forEach({$0.removeFromSuperview()})
            self?.view.layoutIfNeeded()
        }
        
        guard let image = imageView.image, let personciImage = CIImage(image: image) else {
            return
        }
        let imageOptions =  NSDictionary(object: NSNumber(value: 5) as NSNumber, forKey: CIDetectorImageOrientation as NSString)
        let accuracy = [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        let faceDetector = CIDetector(ofType: CIDetectorTypeFace, context: nil, options: accuracy)
        let faces = faceDetector?.features(in: personciImage, options: imageOptions as? [String : AnyObject])
        
        // Добавили конвертацию координат
        let ciImageSize = personciImage.extent.size
        var transform = CGAffineTransform(scaleX: 1, y: -1)
        transform = transform.translatedBy(x: 0, y: -ciImageSize.height)
        
        if let faces = faces as? [CIFaceFeature], !faces.isEmpty {
            for face in faces {
                
                print("Found face bounds are \(face.bounds)")
                
                // Добавили вычисление фактического положения faceBox
                var faceViewBounds = face.bounds.applying(transform)
                
                let viewSize = imageView.bounds.size
                
                let scale = min(viewSize.width / ciImageSize.width,
                                viewSize.height / ciImageSize.height)
                
                let offsetX = (viewSize.width - ciImageSize.width * scale) / 2
                
                let offsetY = (viewSize.height - ciImageSize.height * scale) / 2
                
                faceViewBounds = faceViewBounds.applying(CGAffineTransform(scaleX: scale, y: scale))
                faceViewBounds.origin.x += offsetX
                faceViewBounds.origin.y += offsetY
                
                let faceBox = UIView(frame: faceViewBounds)
                
                faceBox.layer.borderWidth = 3
                faceBox.layer.borderColor = UIColor.red.cgColor
                faceBox.backgroundColor = UIColor.clear
                
                UIView.animate(withDuration: 0.3) { [weak self] in
                    self?.imageView.addSubview(faceBox)
                    self?.view.layoutIfNeeded()
                }
                
                if face.hasLeftEyePosition {
                    print("Left eye bounds are \(face.leftEyePosition)")
                }
                
                if face.hasRightEyePosition {
                    print("Right eye bounds are \(face.rightEyePosition)")
                }
            }
        } else {
            let alert = UIAlertController(title: "Лица нет",
                                          message: "Ничего не нашлось",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK",
                                          style: .default,
                                          handler: nil))
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }
    func didSelect(image: UIImage?) {
        self.imageView.image = image
        detect()
    }
    
}

// 
