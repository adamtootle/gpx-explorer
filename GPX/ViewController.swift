//
//  ViewController.swift
//  GPX
//
//  Created by Adam Tootle on 7/26/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices
import Mapbox
import GEOSwift

class ViewController: UIViewController, UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIDocumentPickerDelegate, MGLMapViewDelegate {
    @IBOutlet var mapView: MGLMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var containerInnerView: UIView!
    @IBOutlet var buttonsView: UIView!
    @IBOutlet var photosView: UIView!
    @IBOutlet var openFileView: UIView!
    @IBOutlet var arMapView: ARMapView!
    @IBOutlet var dragView: UIView!
    @IBOutlet var dragViewMarker: UIView!
    @IBOutlet var arMapCloseButtonView: UIView!
    @IBOutlet var arMapCloseButton: HighlightButton!
    
    @IBOutlet var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var photosViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var arMapCloseButtonViewTopConstraint: NSLayoutConstraint!
    
    var images: [(image: UIImage, asset: PHAsset)] = []
    
    let containerViewCollapsedHeight: CGFloat = 80.0
    let containerViewExpandedHeight = (UIScreen.main.bounds.size.height / 2) - 15
    var containerViewCollapsedY: CGFloat = 0
    let containerViewExpandedY: CGFloat = UIScreen.main.bounds.size.height / 2
    var gpxResponse: GPXServiceResponse?
    var feedbackGenerator: UISelectionFeedbackGenerator?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(openGPX(_:)), name: .openGPX, object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        PHPhotoLibrary.requestAuthorization { (status) in
            if status == .authorized {
                DispatchQueue.main.async {
//                    self.loadGPX()
                }
            }
        }
        
        self.containerView.layer.cornerRadius = 15
        self.containerView.layer.shadowColor = UIColor.black.cgColor
        self.containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.containerView.layer.shadowOpacity = 0.25
        self.containerView.layer.shadowRadius = 7
        
        self.containerInnerView.layer.cornerRadius = 15
        self.containerInnerView.clipsToBounds = true
        
        self.arMapCloseButtonView.layer.cornerRadius = 21
        self.arMapCloseButtonView.layer.shadowColor = UIColor.black.cgColor
        self.arMapCloseButtonView.layer.shadowOffset = CGSize(width: 0, height: 0)
        self.arMapCloseButtonView.layer.shadowOpacity = 0.25
        self.arMapCloseButtonView.layer.shadowRadius = 7
        
        self.arMapCloseButton.layer.cornerRadius = 21
        self.arMapCloseButton.clipsToBounds = true
        
        self.photosView.layer.cornerRadius = 16
        self.photosView.clipsToBounds = true
        
        self.dragViewMarker.layer.cornerRadius = self.dragViewMarker.bounds.size.height / 2
        
        self.mapView.styleURL = URL(string: "mapbox://styles/adamtootle/cjyzd3ygk0c491cmo0309nr1p")!
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.containerViewCollapsedY = self.containerView.frame.origin.y
        self.arMapCloseButtonViewTopConstraint.constant = self.view.safeAreaInsets.top + 20
        self.view.setNeedsUpdateConstraints()
        self.view.layoutIfNeeded()
        
        self.feedbackGenerator = UISelectionFeedbackGenerator()
        self.feedbackGenerator?.prepare()
    }
    
    @objc func openGPX(_ notification: Notification) {
        self.openFileView.alpha = 0.0
        if let url = notification.userInfo?["url"] as? URL {
            self.gpxResponse = GPXService.processGPX(path: url.path)
            self.renderPolylines()
            self.loadImages(startDate: self.gpxResponse?.startDate, endDate: self.gpxResponse?.endDate)
        }
    }
    
    func renderPolylines() {
        self.mapView.removeOverlays(self.mapView.overlays)
        
        guard let gpxResponse = self.gpxResponse else { return }
        
        var mglPolylines: [MGLPolyline] = []
        for locationsArray in gpxResponse.locations {
            let polyline = MGLPolyline(coordinates: locationsArray.map{$0.coordinate}, count: UInt(locationsArray.count))
            mglPolylines.append(polyline)
            self.mapView.addAnnotation(polyline)
        }
        
        self.mapView.showAnnotations(
            mglPolylines,
            edgePadding: UIEdgeInsets(
                top: 20,
                left: 20,
                bottom: 20,
                right: 20
            ),
            animated: true,
            completionHandler: nil
        )
        
        self.mapView.setVisibleCoordinateBounds(
            MGLCoordinateBounds(
                sw: gpxResponse.southwestCoordinate,
                ne: gpxResponse.northeastCoordinate
            ),
            animated: true
        )
    }
}

extension ViewController {
    func showPhotos() {
        self.containerViewLeadingConstraint.constant = 0
        self.containerViewTrailingConstraint.constant = 0
        self.containerViewBottomConstraint.constant = (self.view.safeAreaInsets.bottom * -1) - 15
        self.containerViewHeightConstraint.constant = self.containerViewExpandedHeight
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.buttonsView.alpha = 0.0
            self.photosView.alpha = 1.0
            self.dragView.alpha = 1.0
        }
        
        if let annotations = self.mapView.annotations {
            self.mapView.showAnnotations(
                annotations,
                edgePadding: UIEdgeInsets(
                    top: 20,
                    left: 20,
                    bottom: self.containerViewExpandedY,
                    right: 20
                ),
                animated: true, completionHandler: nil)
        }
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        if self.images.count == 0 {
            self.collectionView.isScrollEnabled = false
        } else {
            self.collectionView.isScrollEnabled = true
        }
    }
    
    func hidePhotos() {
        self.containerViewLeadingConstraint.constant = 25.0
        self.containerViewTrailingConstraint.constant = 25.0
        self.containerViewBottomConstraint.constant = 25.0
        self.containerViewHeightConstraint.constant = self.containerViewCollapsedHeight
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.buttonsView.alpha = 1.0
            self.photosView.alpha = 0.0
            self.dragView.alpha = 0.0
        }
        
        if let annotations = self.mapView.annotations {
            self.mapView.showAnnotations(
                annotations,
                edgePadding: UIEdgeInsets(
                    top: 20,
                    left: 20,
                    bottom: 20 + self.containerViewCollapsedHeight,
                    right: 20
                ),
                animated: true, completionHandler: nil)
        }
    }
    
    func showARMap() {
        self.containerViewLeadingConstraint.constant = 0
        self.containerViewTrailingConstraint.constant = 0
        self.containerViewBottomConstraint.constant = (self.view.safeAreaInsets.bottom * -1) - 15
        self.containerViewHeightConstraint.constant = UIScreen.main.bounds.size.height + 30
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.buttonsView.alpha = 0.0
            self.photosView.alpha = 0.0
            self.dragView.alpha = 0.0
            self.arMapView.alpha = 1.0
            self.arMapCloseButtonView.alpha = 1.0
        }
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        
        if self.images.count == 0 {
            self.collectionView.isScrollEnabled = false
        } else {
            self.collectionView.isScrollEnabled = true
        }
    }
    
    func hideARMapView() {
        self.containerViewLeadingConstraint.constant = 25.0
        self.containerViewTrailingConstraint.constant = 25.0
        self.containerViewBottomConstraint.constant = 25.0
        self.containerViewHeightConstraint.constant = self.containerViewCollapsedHeight
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
            self.buttonsView.alpha = 1.0
            self.photosView.alpha = 0.0
            self.dragView.alpha = 0.0
            self.arMapView.alpha = 0.0
            self.arMapCloseButtonView.alpha = 0.0
        }
    }
}

// MARK: IBActions
extension ViewController {
    @IBAction func didTapOpenFileButton() {
        let types: [String] = [kUTTypeXML as String]
        let documentPicker = UIDocumentPickerViewController(documentTypes: types, in: .import)
        documentPicker.delegate = self
        documentPicker.modalPresentationStyle = .formSheet
        self.present(documentPicker, animated: true, completion: nil)
        self.feedbackGenerator?.selectionChanged()
    }
    
    @IBAction func didTapPhotosButton() {
        self.showPhotos()
        self.feedbackGenerator?.selectionChanged()
    }
    
    @IBAction func didTapCameraButton() {
        if let gpxResponse = self.gpxResponse {
            self.showARMap()
            self.arMapView.renderScene(gpxResponse: gpxResponse)
            self.feedbackGenerator?.selectionChanged()
        }
    }
    
    @IBAction func didTapCloseButton() {
        UIView.animate(withDuration: 0.3) {
            self.openFileView.alpha = 1.0
        }
        self.mapView.removeOverlays(self.mapView.overlays)
        self.mapView.setZoomLevel(0, animated: true)
        self.feedbackGenerator?.selectionChanged()
    }
    
    @IBAction func handlePan(recognizer: UIPanGestureRecognizer) {
        let yChange = recognizer.translation(in: self.view).y
        guard yChange >= 0 else { return }
        
        let pullProgress = yChange / (self.containerViewCollapsedY - self.containerViewExpandedY)
        
        if pullProgress <= 1 {
            let containerViewHeightDifference = self.containerViewExpandedHeight - self.containerViewCollapsedHeight
            let containerViewHeight = self.containerViewExpandedHeight - (containerViewHeightDifference * pullProgress)
            
            let containerViewBottom = (self.view.safeAreaInsets.bottom * -1) - 15
            let containerViewBottomRange = 25 - containerViewBottom
            
            self.containerViewLeadingConstraint.constant = pullProgress * 25
            self.containerViewTrailingConstraint.constant = pullProgress * 25
            self.containerViewBottomConstraint.constant = containerViewBottom + (pullProgress * containerViewBottomRange)
            self.containerViewHeightConstraint.constant = containerViewHeight
            
            self.photosViewBottomConstraint.constant = 15 - (pullProgress * 15)
            
            self.view.setNeedsUpdateConstraints()
            self.view.layoutIfNeeded()
            self.buttonsView.alpha = 1 * pullProgress
            self.photosView.alpha = 1 - (1 * pullProgress)
            self.dragView.alpha = 1 - (1 * pullProgress)
            
            if let annotations = self.mapView.annotations {
                self.mapView.showAnnotations(
                    annotations,
                    edgePadding: UIEdgeInsets(
                        top: 20,
                        left: 20,
                        bottom: containerViewHeight,
                        right: 20
                    ),
                    animated: true, completionHandler: nil)
            }
            
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
        
        if recognizer.state == .ended {
            if pullProgress >= 0.5 {
                self.hidePhotos()
            } else {
                self.showPhotos()
            }
        }
    }
    
    @IBAction func didTapCloseARButton() {
        self.hideARMapView()
        self.feedbackGenerator?.selectionChanged()
    }
}

// MARK: UIGestureRecognizerDelegate
extension ViewController {
    
}

extension ViewController {
    func loadImages(startDate: Date?, endDate: Date?) {
        guard let startDate = startDate, let endDate = endDate else { return }
         PhotosService.loadPhotos(startDate: startDate, endDate: endDate, completionHandler: { (images) in
            self.images = images
            self.collectionView.reloadData()
        })
    }
}

// MARK: UICollectionView
extension ViewController {
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if self.images.count == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewLabelCell", for: indexPath) as! CollectionViewLabelCell
            cell.text = "No photos found"
            return cell
        }
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewImageCell", for: indexPath) as! CollectionViewImageCell
        cell.image = self.images[indexPath.item].image
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if images.count == 0 {
            return 1
        }
        
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        if self.images.count == 0 {
            return CGSize(width: self.collectionView.frame.size.width - 2, height: self.collectionView.frame.size.height - 2)
        }
        
        let width = (self.collectionView.frame.size.width - 3.0) / 3.0
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard self.images.count > 0 else { return }
    }
}

// MARK: UIDocumentPickerDelegate
extension ViewController {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            NotificationCenter.default.post(name: .openGPX, object: nil, userInfo: ["url":url])
        }
    }
}

// MARK: MGLMapViewDelegate
extension ViewController {
    func mapView(_ mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        return 1
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 2
    }
}
