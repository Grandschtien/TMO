//
//  NavalNIRa.swift
//  NIR
//
//  Created by Егор Шкарин on 02.06.2022.
//

import UIKit

class NavalNIRa: UIViewController, ImagePickerDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    private var imagePicker: ImagePicker!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    
    @IBOutlet weak var percentLabel: UILabel!
    let imagePredictor = ImagePredictor()
    let predictionsToShow = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        errorLabel.isHidden = true
        activity.isHidden = true
        self.imagePicker = ImagePicker(presentationController: self, delegate: self)
        let startImage = UIImage(named: "face9")
        imageView.image = startImage
        checkImage(image: startImage ?? UIImage())
        imageView.layer.cornerRadius = 20
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .gray
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        percentLabel.layer.cornerRadius = 10
    }
    
    func didSelect(image: UIImage?) {
        self.imageView.image = image
        checkImage(image: image ?? UIImage())
    }
    
    @IBAction func takePhoto(_ sender: UIBarButtonItem) {
        if !errorLabel.isHidden {
            errorLabel.isHidden = true
        }
        self.imagePicker.present(from: view)
    }
    @IBAction func nextButtonAction(_ sender: UIButton) {
        let randNum = Int.random(in: 9...29)
        let randImage = UIImage(named: "face\(randNum)") ?? UIImage()
        self.imageView.image = randImage
        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(randImage)
        }
        if !errorLabel.isHidden {
            errorLabel.isHidden = true
        }
    }
    @IBAction func newPhoto(_ sender: UIBarButtonItem) {
        if !errorLabel.isHidden {
            errorLabel.isHidden = true
        }
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
    func updatePredictionLabel(_ message: String) {
        DispatchQueue.main.async {
            self.percentLabel.text = message
        }
    }
    private func classifyImage(_ image: UIImage) {
        do {
            try self.imagePredictor.makePredictions(for: image,
                                                    completionHandler: imagePredictionHandler)
        } catch {
            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
        }
    }

    /// The method the Image Predictor calls when its image classifier model generates a prediction.
    /// - Parameter predictions: An array of predictions.
    /// - Tag: imagePredictionHandler
    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
        guard let predictions = predictions else {
            updatePredictionLabel("No predictions. (Check console log.)")
            return
        }

        let formattedPredictions = formatPredictions(predictions)

        let predictionString = formattedPredictions.joined(separator: "\n")
        updatePredictionLabel(predictionString)
    }
    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
        // Vision sorts the classifications in descending confidence order.
        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
            var name = prediction.classification

            // For classifications with more than one name, keep the one before the first comma.
            if let firstComma = name.firstIndex(of: ",") {
                name = String(name.prefix(upTo: firstComma))
            }

            return "\(name) - \(prediction.confidencePercentage)%"
        }

        return topPredictions
    }
    
    @MainActor
    private func setErrorMessage(text: String) {
        self.errorLabel.text = text
        self.errorLabel.isHidden = false
    }
    
    @MainActor
    private func setImage(data: Data) {
        let recivedImage = UIImage(data: data) ?? UIImage()
        imageView.image = recivedImage
        if imageView.image != nil {
           print("sfsdfs")
        } else {
            self.setErrorMessage(text: "Неизвестная ошибка")
            imageView.backgroundColor = .opaqueSeparator
        }
        activity.stopAnimating()
        activity.isHidden = true
        self.errorLabel.isHidden = true
        checkImage(image: recivedImage)
    }
    func checkImage(image: UIImage) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.classifyImage(image)
        }
    }
    
}

// -------------------------
//class MainViewController: UIViewController {
//    var firstRun = true
//
//    /// A predictor instance that uses Vision and Core ML to generate prediction strings from a photo.
//    let imagePredictor = ImagePredictor()
//
//    /// The largest number of predictions the main view controller displays the user.
//    let predictionsToShow = 2
//
//    // MARK: Main storyboard outlets
//    @IBOutlet weak var startupPrompts: UIStackView!
//    @IBOutlet weak var imageView: UIImageView!
//    @IBOutlet weak var predictionLabel: UILabel!
//}
//
//extension MainViewController {
//    // MARK: Main storyboard actions
//    /// The method the storyboard calls when the user one-finger taps the screen.
//    @IBAction func singleTap() {
//        // Show options for the source picker only if the camera is available.
//        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
//            present(photoPicker, animated: false)
//            return
//        }
//
//        present(cameraPicker, animated: false)
//    }
//
//    /// The method the storyboard calls when the user two-finger taps the screen.
//    @IBAction func doubleTap() {
//        present(photoPicker, animated: false)
//    }
//}
//
//extension MainViewController {
//    // MARK: Main storyboard updates
//    /// Updates the storyboard's image view.
//    /// - Parameter image: An image.
//    func updateImage(_ image: UIImage) {
//        DispatchQueue.main.async {
//            self.imageView.image = image
//        }
//    }
//
//    /// Updates the storyboard's prediction label.
//    /// - Parameter message: A prediction or message string.
//    /// - Tag: updatePredictionLabel
//    func updatePredictionLabel(_ message: String) {
//        DispatchQueue.main.async {
//            self.predictionLabel.text = message
//        }
//
//        if firstRun {
//            DispatchQueue.main.async {
//                self.firstRun = false
//                self.predictionLabel.superview?.isHidden = false
//                self.startupPrompts.isHidden = true
//            }
//        }
//    }
//    /// Notifies the view controller when a user selects a photo in the camera picker or photo library picker.
//    /// - Parameter photo: A photo from the camera or photo library.
//    func userSelectedPhoto(_ photo: UIImage) {
//        updateImage(photo)
//        updatePredictionLabel("Making predictions for the photo...")
//
//        DispatchQueue.global(qos: .userInitiated).async {
//            self.classifyImage(photo)
//        }
//    }
//
//}
//
//extension MainViewController {
//    // MARK: Image prediction methods
//    /// Sends a photo to the Image Predictor to get a prediction of its content.
//    /// - Parameter image: A photo.
//    private func classifyImage(_ image: UIImage) {
//        do {
//            try self.imagePredictor.makePredictions(for: image,
//                                                    completionHandler: imagePredictionHandler)
//        } catch {
//            print("Vision was unable to make a prediction...\n\n\(error.localizedDescription)")
//        }
//    }
//
//    /// The method the Image Predictor calls when its image classifier model generates a prediction.
//    /// - Parameter predictions: An array of predictions.
//    /// - Tag: imagePredictionHandler
//    private func imagePredictionHandler(_ predictions: [ImagePredictor.Prediction]?) {
//        guard let predictions = predictions else {
//            updatePredictionLabel("No predictions. (Check console log.)")
//            return
//        }
//
//        let formattedPredictions = formatPredictions(predictions)
//
//        let predictionString = formattedPredictions.joined(separator: "\n")
//        updatePredictionLabel(predictionString)
//    }
//    private func formatPredictions(_ predictions: [ImagePredictor.Prediction]) -> [String] {
//        // Vision sorts the classifications in descending confidence order.
//        let topPredictions: [String] = predictions.prefix(predictionsToShow).map { prediction in
//            var name = prediction.classification
//
//            // For classifications with more than one name, keep the one before the first comma.
//            if let firstComma = name.firstIndex(of: ",") {
//                name = String(name.prefix(upTo: firstComma))
//            }
//
//            return "\(name) - \(prediction.confidencePercentage)%"
//        }
//
//        return topPredictions
//    }
//
//}
