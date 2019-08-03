//
//  ViewController.swift
//  GPX
//
//  Created by Adam Tootle on 7/26/19.
//  Copyright © 2019 Adam Tootle. All rights reserved.
//

import UIKit
import Photos
import MapKit
import MobileCoreServices

extension MKMapView {
    var zoomLevel: Double {
        return log2(360 * ((Double(self.frame.size.width) / 256) / self.region.span.longitudeDelta)) - 1
    }
}

class ViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIDocumentPickerDelegate {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var containerView: UIView!
    @IBOutlet var containerInnerView: UIView!
    @IBOutlet var buttonsView: UIView!
    @IBOutlet var photosView: UIView!
    @IBOutlet var openFileView: UIView!
    @IBOutlet var dragView: UIView!
    @IBOutlet var dragViewMarker: UIView!
    
    @IBOutlet var containerViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewTrailingConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet var containerViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet var photosViewBottomConstraint: NSLayoutConstraint!
    
    var images: [(image: UIImage, asset: PHAsset)] = []
    var polyline: MKPolyline?
    
    let containerViewCollapsedHeight: CGFloat = 80.0
    let containerViewExpandedHeight = (UIScreen.main.bounds.size.height / 2) - 15
    var containerViewCollapsedY: CGFloat = 0
    let containerViewExpandedY: CGFloat = UIScreen.main.bounds.size.height / 2
    
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
        
        containerView.layer.cornerRadius = 15
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 0)
        containerView.layer.shadowOpacity = 0.25
        containerView.layer.shadowRadius = 7
        
        // shadow
        containerInnerView.layer.cornerRadius = 15
        containerInnerView.clipsToBounds = true
        
        self.photosView.layer.cornerRadius = 16
        self.photosView.clipsToBounds = true
        
        self.dragViewMarker.layer.cornerRadius = self.dragViewMarker.bounds.size.height / 2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.containerViewCollapsedY = self.containerView.frame.origin.y
    }
    
    @objc func openGPX(_ notification: Notification) {
        self.openFileView.alpha = 0.0
        if let url = notification.userInfo?["url"] as? URL {
            let gpxResponse: (startDate: Date?, endDate: Date?, polylines: [MKPolyline]) = GPXService.processGPX(path: url.path)
            self.renderPolylines(gpxResponse.polylines)
            self.loadImages(startDate: gpxResponse.startDate, endDate: gpxResponse.endDate)
        }
    }
    
    func renderPolylines(_ polylines: [MKPolyline]) {
        self.mapView.removeOverlays(self.mapView.overlays)
        polylines.forEach { (polyline) in
            self.mapView.addOverlay(polyline)
        }
        
        if let lastPolyline = polylines.last {
            self.polyline = lastPolyline
            
            self.mapView.setVisibleMapRect(
                lastPolyline.boundingMapRect,
                edgePadding: UIEdgeInsets(
                    top: 20,
                    left: 20,
                    bottom: 20 + self.containerViewCollapsedHeight,
                    right: 20
                ),
                animated: true
            )
        }
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
        
        if let polyline = self.polyline {
            // Weirdly, running setVisibleMapRect here normally
            // does this weird UI lock the very first time, running
            // as expected every time after that.
            // Delaying it for 1 millisecond runs as expected.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(1)) {
                self.mapView.setVisibleMapRect(
                    polyline.boundingMapRect,
                    edgePadding: UIEdgeInsets(
                        top: 20,
                        left: 20,
                        bottom: self.containerViewExpandedY,
                        right: 20
                    ),
                    animated: true
                )
            }
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
        
        if let polyline = self.polyline {
            self.mapView.setVisibleMapRect(
                polyline.boundingMapRect,
                edgePadding: UIEdgeInsets(
                    top: 20,
                    left: 20,
                    bottom: 20 + self.containerViewCollapsedHeight,
                    right: 20
                ),
                animated: true
            )
        }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
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
    }
    
    @IBAction func didTapPhotosButton() {
        self.showPhotos()
    }
    
    @IBAction func didTapCameraButton() {
        
    }
    
    @IBAction func didTapCloseButton() {
        self.mapView.removeOverlays(self.mapView.overlays)
        UIView.animate(withDuration: 0.3) {
            self.openFileView.alpha = 1.0
        }
        let resetRegion = MKCoordinateRegion(center: self.mapView.centerCoordinate, span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360))
        self.mapView.setRegion(resetRegion, animated: true)
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
            
            if let polyline = self.polyline {
                self.mapView.setVisibleMapRect(
                    polyline.boundingMapRect,
                    edgePadding: UIEdgeInsets(
                        top: 20,
                        left: 20,
                        bottom: containerViewHeight,
                        right: 20
                    ),
                    animated: false
                )
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
}

// MARK: UIGestureRecognizerDelegate
extension ViewController {
    
}

extension ViewController {
    func loadImages(startDate: Date?, endDate: Date?) {
        guard let startDate = startDate, let endDate = endDate else { return }
        
        let imgManager = PHImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
//        requestOptions.synchronous = true
//        requestOptions.networkAccessAllowed = true
        
        // Fetch the images between the start and end date
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate > %@ AND creationDate < %@", startDate as CVarArg, endDate as CVarArg)
        
        self.images = []
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions)
        
        if fetchResult.count > 0 {
            var accountedFor = 0
            for index in 0..<fetchResult.count {
                let asset = fetchResult.object(at: index)

                imgManager.requestImageData(for: asset, options: requestOptions) { (imageData, dataUTI, orientation, info) in
                    accountedFor += 1
                    
                    if let imageData = imageData {
                        if let image = UIImage(data: imageData) {
                            self.images.append((image: image, asset: asset))
                        }
                    }
                    
                    if accountedFor == fetchResult.count {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
}

// MARK: MKMapViewDelegate
extension ViewController {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 2
            return renderer
            
        } else if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.orange
            renderer.lineWidth = 3
            return renderer
        }
        
        return MKOverlayRenderer()
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
        guard self.images.count > 1 else { return }
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        
        if let location = self.images[indexPath.item].asset.location {
            let annotation = MKPointAnnotation()
            annotation.coordinate = location.coordinate
            self.mapView.addAnnotation(annotation)
        }
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
